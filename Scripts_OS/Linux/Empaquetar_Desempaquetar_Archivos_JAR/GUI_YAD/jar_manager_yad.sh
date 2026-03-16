#!/bin/bash

set -euo pipefail

APP_NAME="Jar Manager Pro (YAD)"
LOG_FILE="$HOME/jar_manager.log"

# ---------- VALIDACIONES ----------

check_dependencies() {
    for cmd in jar yad unzip; do
        if ! command -v "$cmd" &> /dev/null; then
            yad --error --text="Dependencia faltante: $cmd"
            exit 1
        fi
    done
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

is_valid_jar() {
    unzip -t "$1" &>/dev/null
}

check_dependencies

# ---------- ACCIÓN ----------

ACTION=$(yad --list --radiolist \
    --title="$APP_NAME - Acción" \
    --column="Sel" --column="Acción" \
    TRUE "unpack" FALSE "pack" \
    --height=200 --width=300)

[[ -z "$ACTION" ]] && exit 0

ACTION=$(echo "$ACTION" | cut -d'|' -f2 | xargs)

OUTPUT_DIR=$(yad --file --directory \
    --title="Seleccionar carpeta de salida")

[[ -z "$OUTPUT_DIR" ]] && exit 0

# ---------- SELECCIÓN DINÁMICA ----------

if [[ "$ACTION" == "unpack" ]]; then

    FILES=$(yad --file \
        --multiple --separator="|" \
        --title="Seleccionar archivos JAR" \
        --file-filter="Archivos JAR | *.jar")

else

    FILES=$(yad --file \
        --multiple --separator="|" \
        --directory \
        --title="Seleccionar carpetas a empaquetar")

fi

[[ -z "$FILES" ]] && exit 0

IFS="|" read -ra FILE_ARRAY <<< "$FILES"

TOTAL=${#FILE_ARRAY[@]}
COUNT=0

(
for FILE in "${FILE_ARRAY[@]}"; do

    COUNT=$((COUNT + 1))
    PERCENT=$((COUNT * 100 / TOTAL))

    FILE=$(realpath "$FILE")

    if [[ "$ACTION" == "unpack" ]]; then

        if ! is_valid_jar "$FILE"; then
            log "ERROR: Archivo no válido: $FILE"
            continue
        fi

        BASENAME=$(basename "$FILE" .jar)
        DEST="$OUTPUT_DIR/$BASENAME"

        mkdir -p "$DEST"

        # EXTRAER CORRECTAMENTE SIN CD
        jar xfv "$FILE" -C "$DEST" >> "$LOG_FILE" 2>&1

        log "Desempaquetado: $FILE -> $DEST"

    else

        BASENAME=$(basename "$FILE")

        CUSTOM_NAME=$(yad --entry \
            --title="Nombre del JAR" \
            --text="Nombre para el JAR generado:" \
            --entry-text="$BASENAME")

        [[ -z "$CUSTOM_NAME" ]] && continue

        DEST_JAR="$OUTPUT_DIR/$CUSTOM_NAME.jar"

        # EMPAQUETADO CORRECTO
        jar cfv "$DEST_JAR" -C "$FILE" . >> "$LOG_FILE" 2>&1

        log "Empaquetado: $FILE -> $DEST_JAR"

    fi

    echo "$PERCENT"
    echo "# Procesando $(basename "$FILE")"

done
) | yad --progress --title="Procesando..." --auto-close

yad --info --text="Proceso completado\nLog: $LOG_FILE"


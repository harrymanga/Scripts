#!/bin/bash

set -euo pipefail

APP_NAME="Jar Manager Pro (Zenity)"
LOG_FILE="$HOME/jar_manager.log"

# ---------- VALIDACIONES ----------

check_dependencies() {
    for cmd in jar zenity unzip; do
        if ! command -v "$cmd" &> /dev/null; then
            zenity --error --text="Dependencia faltante: $cmd"
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

ACTION=$(zenity --list --radiolist \
    --title="$APP_NAME - Acción" \
    --column="Sel" --column="Acción" \
    TRUE "Desempaquetar" FALSE "Empaquetar" \
    --height=200 --width=300)

[[ -z "$ACTION" ]] && exit 0

OUTPUT_DIR=$(zenity --file-selection --directory \
    --title="Seleccionar carpeta de salida")

[[ -z "$OUTPUT_DIR" ]] && exit 0

# ---------- SELECCIÓN DINÁMICA ----------

if [[ "$ACTION" == "Desempaquetar" ]]; then

    FILES=$(zenity --file-selection \
        --multiple --separator="|" \
        --title="Seleccionar archivos JAR" \
        --file-filter="Archivos JAR | *.jar")

else

    FILES=$(zenity --file-selection \
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

    if [[ "$ACTION" == "Desempaquetar" ]]; then

        if ! is_valid_jar "$FILE"; then
            log "ERROR: Archivo no válido: $FILE"
            continue
        fi

        BASENAME=$(basename "$FILE" .jar)
        DEST="$OUTPUT_DIR/$BASENAME"

        mkdir -p "$DEST"
        cd "$DEST" || exit 1

        jar xfv "$FILE" >> "$LOG_FILE" 2>&1

        log "Desempaquetado: $FILE -> $DEST"

    else

        BASENAME=$(basename "$FILE")

        # Pedir nombre personalizado
        CUSTOM_NAME=$(zenity --entry \
            --title="Nombre del JAR" \
            --text="Nombre para el JAR generado:" \
            --entry-text="$BASENAME")

        [[ -z "$CUSTOM_NAME" ]] && continue

        DEST_JAR="$OUTPUT_DIR/$CUSTOM_NAME.jar"

        cd "$FILE" || exit 1
        jar cfv "$DEST_JAR" . >> "$LOG_FILE" 2>&1

        log "Empaquetado: $FILE -> $DEST_JAR"

    fi

    echo "$PERCENT"
    echo "# Procesando $(basename "$FILE")"

done
) | zenity --progress --title="Procesando..." --auto-close

zenity --info --text="Proceso completado\nLog: $LOG_FILE"


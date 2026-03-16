#!/bin/bash

BASE_DIR="$(dirname "$0")/.."

source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/core.sh"

check_dependencies

VERSION="v1.0"
APP_NAME="Jar Manager Pro (YAD) $VERSION"
LOG_FILE="$BASE_DIR/logs/jar_manager.log"

mkdir -p "$(dirname "$LOG_FILE")"

while true; do

    OPTION=$(
    yad --center \
        --width=250 \
        --height=200 \
        --title="$APP_NAME" \
        --window-icon=folder \
        --list \
        --column="Icono:IMG" \
        --column="Acción" \
        --hide-header \
        --separator="" \
        --dclick-action=0 \
        "package-x-generic"  "Desempaquetar" \
        "archive-extract"    "Empaquetar" \
        "text-x-log"         "Ver Log" \
        "application-exit"   "Salir"
    )

    case "$OPTION" in

    "Desempaquetar")

        FILES=$(yad --file --multiple --separator="|" \
            --title="Seleccionar archivos JAR" \
            --file-filter="Archivos JAR | *.jar")

        [[ -z "$FILES" ]] && continue

        IFS="|" read -ra FILE_ARRAY <<< "$FILES"
        
        OUTPUT_DIR=$(yad --file --directory --title="Carpeta de salida")
        [[ -z "$OUTPUT_DIR" ]] && continue

        (
        TOTAL=${#FILE_ARRAY[@]}
        COUNT=0
        START_TIME=$(date +%s)

        for FILE in "${FILE_ARRAY[@]}"; do
            COUNT=$((COUNT+1))
            PERCENT=$((COUNT*100/TOTAL))

            unpack_jar "$FILE" "$OUTPUT_DIR" >> "$LOG_FILE" 2>&1

            ELAPSED=$(( $(date +%s) - START_TIME ))

            echo "$PERCENT"
            echo "# [$COUNT/$TOTAL] Procesando $(basename "$FILE") - ${ELAPSED}s"
        done
        ) | yad --progress \
            --title="Desempaquetando..." \
            --percentage=0 \
            --auto-close \
            --width=400

        yad --info --text="Desempaquetado completado"
        ;;

    "Empaquetar")

        DIRS=$(yad --file --multiple --separator="|" \
            --directory --title="Seleccionar carpetas")

        [[ -z "$DIRS" ]] && continue

        IFS="|" read -ra DIR_ARRAY <<< "$DIRS"
        
        OUTPUT_DIR=$(yad --file --directory --title="Carpeta de salida")
        [[ -z "$OUTPUT_DIR" ]] && continue

        (
        TOTAL=${#DIR_ARRAY[@]}
        COUNT=0
        START_TIME=$(date +%s)

        for DIR in "${DIR_ARRAY[@]}"; do
            COUNT=$((COUNT+1))
            PERCENT=$((COUNT*100/TOTAL))

            NAME=$(basename "$DIR")

            CUSTOM=$(yad --entry \
                --title="Nombre del JAR" \
                --text="Nombre para el JAR:" \
                --entry-text="$NAME")

            [[ -z "$CUSTOM" ]] && continue

            pack_directory "$DIR" "$OUTPUT_DIR" "$CUSTOM" >> "$LOG_FILE" 2>&1

            ELAPSED=$(( $(date +%s) - START_TIME ))

            echo "$PERCENT"
            echo "# [$COUNT/$TOTAL] Procesando $CUSTOM.jar - ${ELAPSED}s"
        done
        ) | yad --progress \
            --title="Empaquetando..." \
            --percentage=0 \
            --auto-close \
            --width=400

        yad --info --text="Empaquetado completado"
        ;;

    "Ver Log")

        yad --text-info \
            --filename="$LOG_FILE" \
            --title="Log del Sistema" \
            --width=750 \
            --height=450 \
            --center
        ;;

    "Salir"|"" )
        break
        ;;
    esac

done

exit 0


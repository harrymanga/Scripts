#!/bin/bash

BASE_DIR="$(dirname "$0")/.."

source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/core.sh"

check_dependencies

APP_NAME="Jar Manager Pro (YAD)"

while true; do

    yad --center \
        --title="$APP_NAME" \
        --window-icon=folder \
        --text="Seleccione una acción:" \
        --button="📦 Desempaquetar:1" \
        --button="🗜 Empaquetar:2" \
        --button="📄 Ver Log:3" \
        --button="❌ Salir:0"

    RESPONSE=$?

    case $RESPONSE in

        1)  # DESempaquetar

            OUTPUT_DIR=$(yad --file --directory --title="Carpeta de salida")
            [[ -z "$OUTPUT_DIR" ]] && continue

            FILES=$(yad --file --multiple --separator="|" \
                --title="Seleccionar archivos JAR" \
                --file-filter="Archivos JAR | *.jar")

            [[ -z "$FILES" ]] && continue

            IFS="|" read -ra FILE_ARRAY <<< "$FILES"

            (
            TOTAL=${#FILE_ARRAY[@]}
            COUNT=0

            for FILE in "${FILE_ARRAY[@]}"; do
                COUNT=$((COUNT+1))
                PERCENT=$((COUNT*100/TOTAL))

                unpack_jar "$FILE" "$OUTPUT_DIR"

                echo "$PERCENT"
                echo "# Procesando $(basename "$FILE")"
            done
            ) | yad --progress --title="Desempaquetando..." --auto-close

            yad --info --text="Desempaquetado completado"
            ;;

        2)  # EMPAQUETAR

            OUTPUT_DIR=$(yad --file --directory --title="Carpeta de salida")
            [[ -z "$OUTPUT_DIR" ]] && continue

            DIRS=$(yad --file --multiple --separator="|" \
                --directory --title="Seleccionar carpetas")

            [[ -z "$DIRS" ]] && continue

            IFS="|" read -ra DIR_ARRAY <<< "$DIRS"

            (
            TOTAL=${#DIR_ARRAY[@]}
            COUNT=0

            for DIR in "${DIR_ARRAY[@]}"; do
                COUNT=$((COUNT+1))
                PERCENT=$((COUNT*100/TOTAL))

                NAME=$(basename "$DIR")
                CUSTOM=$(yad --entry \
                    --title="Nombre del JAR" \
                    --text="Nombre para el JAR:" \
                    --entry-text="$NAME")

                [[ -z "$CUSTOM" ]] && continue

                pack_directory "$DIR" "$OUTPUT_DIR" "$CUSTOM"

                echo "$PERCENT"
                echo "# Procesando $CUSTOM.jar"
            done
            ) | yad --progress --title="Empaquetando..." --auto-close

            yad --info --text="Empaquetado completado"
            ;;

        3)  # VER LOG
            yad --text-info --filename="$BASE_DIR/logs/jar_manager.log" \
                --title="Log del Sistema" \
                --width=700 --height=400
            ;;

        0)
            break
            ;;
    esac

done

exit 0


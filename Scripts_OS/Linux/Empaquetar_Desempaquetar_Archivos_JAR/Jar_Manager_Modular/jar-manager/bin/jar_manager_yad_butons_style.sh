#!/bin/bash

BASE_DIR="$(dirname "$0")/.."

source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/core.sh"

check_dependencies

APP_NAME="Jar Manager Pro (Advanced YAD)"

while true; do

    yad --center \
        --title="$APP_NAME" \
        --width=400 \
        --text="🧲 Arrastra archivos o carpetas en el siguiente selector\n\n📦 JAR → Desempaquetar\n📂 Carpeta → Empaquetar" \
        --button="Seleccionar / Drag & Drop:1" \
        --button="Ver Log:2" \
        --button="Salir:0"

    RESPONSE=$?

    case $RESPONSE in

        1)

            FILES=$(yad --file \
                --multiple \
                --separator="|" \
                --title="Arrastra aquí archivos o carpetas")

            [[ -z "$FILES" ]] && continue

            IFS="|" read -ra ITEMS <<< "$FILES"

            OUTPUT_DIR=$(yad --file --directory --title="Carpeta de salida")
            [[ -z "$OUTPUT_DIR" ]] && continue

            (
            TOTAL=${#ITEMS[@]}
            COUNT=0

            for ITEM in "${ITEMS[@]}"; do

                COUNT=$((COUNT+1))
                PERCENT=$((COUNT*100/TOTAL))

                ITEM=$(realpath "$ITEM")

                if [[ -f "$ITEM" && "$ITEM" == *.jar ]]; then

                    unpack_jar "$ITEM" "$OUTPUT_DIR"

                    # Mostrar manifest si existe
                    if unzip -l "$ITEM" | grep -q "META-INF/MANIFEST.MF"; then
                        unzip -p "$ITEM" META-INF/MANIFEST.MF > /tmp/manifest.tmp
                        yad --text-info --filename="/tmp/manifest.tmp" \
                            --title="MANIFEST.MF - $(basename "$ITEM")" \
                            --width=600 --height=400
                    fi

                elif [[ -d "$ITEM" ]]; then

                    NAME=$(basename "$ITEM")
                    CUSTOM=$(yad --entry \
                        --title="Nombre del JAR" \
                        --text="Nombre para el JAR:" \
                        --entry-text="$NAME")

                    [[ -z "$CUSTOM" ]] && continue

                    pack_directory "$ITEM" "$OUTPUT_DIR" "$CUSTOM"

                fi

                echo "$PERCENT"
                echo "# Procesando $(basename "$ITEM")"

            done
            ) | yad --progress --title="Procesando..." --auto-close

            yad --info --text="Proceso completado"
            ;;

        2)
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


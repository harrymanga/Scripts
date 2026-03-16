#!/bin/bash

BASE_DIR="$(dirname "$0")/.."

source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/core.sh"

check_dependencies

APP_NAME="Jar Manager Pro (YAD)"

while true; do

    ACTION=$(yad --list --radiolist \
        --title="$APP_NAME" \
        --column="Sel" --column="Acción" \
        TRUE "unpack" FALSE "pack" FALSE "exit" \
        --height=250 --width=300)

    [[ -z "$ACTION" ]] && break

    ACTION=$(echo "$ACTION" | cut -d'|' -f2 | xargs)

    if [[ "$ACTION" == "exit" ]]; then
        break
    fi

    OUTPUT_DIR=$(yad --file --directory --title="Carpeta de salida")
    [[ -z "$OUTPUT_DIR" ]] && continue

    if [[ "$ACTION" == "unpack" ]]; then

        FILES=$(yad --file --multiple --separator="|" \
            --title="Seleccionar JAR" \
            --file-filter="Archivos JAR | *.jar")

        [[ -z "$FILES" ]] && continue

        IFS="|" read -ra FILE_ARRAY <<< "$FILES"

        for FILE in "${FILE_ARRAY[@]}"; do
            unpack_jar "$FILE" "$OUTPUT_DIR"
        done

        yad --info --text="Desempaquetado completado"

    elif [[ "$ACTION" == "pack" ]]; then

        DIRS=$(yad --file --multiple --separator="|" \
            --directory --title="Seleccionar carpetas")

        [[ -z "$DIRS" ]] && continue

        IFS="|" read -ra DIR_ARRAY <<< "$DIRS"

        for DIR in "${DIR_ARRAY[@]}"; do
            NAME=$(basename "$DIR")
            CUSTOM=$(yad --entry --title="Nombre del JAR" \
                --text="Nombre para el JAR:" --entry-text="$NAME")

            [[ -z "$CUSTOM" ]] && continue
            pack_directory "$DIR" "$OUTPUT_DIR" "$CUSTOM"
        done

        yad --info --text="Empaquetado completado"

    fi

done

exit 0


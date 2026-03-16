#!/bin/bash

BASE_DIR="$(dirname "$0")/.."

source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/core.sh"

check_dependencies

APP_NAME="Jar Manager Pro (Advanced YAD)"

while true; do

# Zona de arrastre simple
DROP=$(yad --form \
    --title="$APP_NAME" \
    --width=600 \
    --height=200 \
    --center \
    --text="🧲 Arrastra archivos o carpetas aquí" \
    --field="Zona de Arrastre:TXT" "" \
    --button="Continuar:1" \
    --button="Salir:0" \
    --dnd)

[[ $? -eq 0 ]] && break
[[ -z "$DROP" ]] && continue

# Limpiar rutas DND
CLEANED=$(echo "$DROP" \
    | tr -d '\r' \
    | sed 's/file:\/\///g' \
    | sed 's/%20/ /g')

IFS=$'\n' read -rd '' -a ITEMS <<<"$CLEANED"

[[ ${#ITEMS[@]} -eq 0 ]] && continue

# Construir lista visual
LIST_DATA=()

for ITEM in "${ITEMS[@]}"; do
    ITEM=$(echo "$ITEM" | xargs)
    [[ -z "$ITEM" ]] && continue

    if [[ -f "$ITEM" && "$ITEM" == *.jar ]]; then
        TYPE="JAR"
        NAME="-"
    elif [[ -d "$ITEM" ]]; then
        TYPE="CARPETA"
        NAME="$(basename "$ITEM")"
    else
        continue
    fi

    LIST_DATA+=("$ITEM" "$TYPE" "$NAME")
done

# Mostrar lista editable
RESULT=$(yad --list \
    --title="Archivos Seleccionados" \
    --width=700 \
    --height=400 \
    --column="Ruta" \
    --column="Tipo" \
    --column="Nombre JAR (editable)" \
    --editable \
    "${LIST_DATA[@]}" \
    --button="Procesar:1" \
    --button="Cancelar:0")

[[ $? -eq 0 ]] && continue

OUTPUT_DIR=$(yad --file --directory --title="Selecciona carpeta de salida")
[[ -z "$OUTPUT_DIR" ]] && continue

IFS="|" read -ra ROWS <<< "$RESULT"

(
TOTAL=${#ROWS[@]}
COUNT=0

for ROW in "${ROWS[@]}"; do

    IFS="|" read -r PATH TYPE NEWNAME <<< "$ROW"

    COUNT=$((COUNT+1))
    PERCENT=$((COUNT*100/TOTAL))

    if [[ "$TYPE" == "JAR" ]]; then
        unpack_jar "$PATH" "$OUTPUT_DIR"
    elif [[ "$TYPE" == "CARPETA" ]]; then
        [[ -z "$NEWNAME" || "$NEWNAME" == "-" ]] && NEWNAME=$(basename "$PATH")
        pack_directory "$PATH" "$OUTPUT_DIR" "$NEWNAME"
    fi

    echo "$PERCENT"
    echo "# Procesando $(basename "$PATH")"

done
) | yad --progress --title="Procesando..." --auto-close

yad --info --text="Proceso completado"

done



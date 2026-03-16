#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/jar-manager-core.sh"

init
check_jar

command -v yad &>/dev/null || { echo "Yad no instalado"; exit 1; }

ACTION=$(yad --list --radiolist \
    --title="Jar Manager Pro" \
    --column="Sel" --column="Acción" \
    TRUE "Desempaquetar" FALSE "Empaquetar")

[[ -z "$ACTION" ]] && exit 0

OUTPUT=$(yad --file-selection --directory --title="Seleccionar salida")
[[ -z "$OUTPUT" ]] && exit 0

if [[ "$ACTION" == "Desempaquetar" ]]; then
    FILES=$(yad --file-selection --multiple --separator="|" --file-filter="*.jar")
else
    FILES=$(yad --file-selection --multiple --separator="|")
fi

IFS="|" read -ra ITEMS <<< "$FILES"

TOTAL=${#ITEMS[@]}
COUNT=0

(
for item in "${ITEMS[@]}"; do
    COUNT=$((COUNT+1))
    PERCENT=$((COUNT*100/TOTAL))

    if [[ "$ACTION" == "Desempaquetar" ]]; then
        extract_jar "$item" "$OUTPUT"
    else
        pack_jar "$item" "$OUTPUT"
    fi

    echo "$PERCENT"
    echo "# Procesando $item"
done
) | yad --progress --auto-close --title="Procesando..."

yad --info --text="Proceso completado"


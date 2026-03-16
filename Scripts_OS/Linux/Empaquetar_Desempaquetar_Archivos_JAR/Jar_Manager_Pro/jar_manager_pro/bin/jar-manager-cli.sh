#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/jar-manager-core.sh"

init
check_jar

if [[ $# -lt 3 ]]; then
    echo "Uso:"
    echo "  jar-manager-cli extract output_dir archivo1.jar archivo2.jar"
    echo "  jar-manager-cli pack output_dir carpeta1 carpeta2"
    exit 1
fi

ACTION="$1"
OUTPUT="$2"
shift 2

for item in "$@"; do
    if [[ "$ACTION" == "extract" ]]; then
        extract_jar "$item" "$OUTPUT"
    elif [[ "$ACTION" == "pack" ]]; then
        pack_jar "$item" "$OUTPUT"
    else
        echo "Acción inválida"
        exit 1
    fi
done

echo "Proceso completado."


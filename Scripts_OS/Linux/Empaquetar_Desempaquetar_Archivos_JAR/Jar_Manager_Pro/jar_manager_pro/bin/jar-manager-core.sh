#!/bin/bash
set -euo pipefail

LOG_DIR="/var/log/jar-manager"
LOG_FILE="$LOG_DIR/jar-manager.log"

init() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
}

log() {
    echo "[$(date '+%F %T')] $1" >> "$LOG_FILE"
}

check_jar() {
    if ! command -v jar &>/dev/null; then
        echo "ERROR: jar no está instalado."
        exit 1
    fi
}

extract_jar() {
    local file="$1"
    local output="$2"

    local base
    base=$(basename "$file" .jar)
    local dest="$output/$base"

    mkdir -p "$dest"
    (cd "$dest" && jar xfv "$file" >> "$LOG_FILE" 2>&1)

    log "Desempaquetado: $file -> $dest"
}

pack_jar() {
    local folder="$1"
    local output="$2"

    local base
    base=$(basename "$folder")
    local dest="$output/$base.jar"

    (cd "$folder" && jar cfv "$dest" . >> "$LOG_FILE" 2>&1)

    log "Empaquetado: $dest"
}


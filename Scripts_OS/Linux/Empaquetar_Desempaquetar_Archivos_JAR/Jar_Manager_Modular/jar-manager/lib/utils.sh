#!/bin/bash

LOG_DIR="$(dirname "$0")/../logs"
LOG_FILE="$LOG_DIR/jar_manager.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_dependencies() {
    for cmd in jar unzip; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Dependencia faltante: $cmd"
            exit 1
        fi
    done
}

is_valid_jar() {
    unzip -t "$1" &>/dev/null
}


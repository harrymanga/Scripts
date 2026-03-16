#!/bin/bash

unpack_jar() {
    local jar_file="$1"
    local output_dir="$2"

    if ! is_valid_jar "$jar_file"; then
        log "ERROR: Archivo no válido: $jar_file"
        return 1
    fi

    local base
    base=$(basename "$jar_file" .jar)
    local dest="$output_dir/$base"

    mkdir -p "$dest"

    jar xfv "$jar_file" -C "$dest" >> "$LOG_FILE" 2>&1
    log "Desempaquetado: $jar_file -> $dest"
}

pack_directory() {
    local directory="$1"
    local output_dir="$2"
    local custom_name="$3"

    local dest="$output_dir/$custom_name.jar"

    jar cfv "$dest" -C "$directory" . >> "$LOG_FILE" 2>&1
    log "Empaquetado: $directory -> $dest"
}


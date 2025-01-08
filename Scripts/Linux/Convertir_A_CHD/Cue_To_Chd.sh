#!/bin/bash

printf "%s\n" "desc: Convertir la imagen del disco .CUE del juego a .CHD"

# Habilitar busqueda recursiva con globstar
shopt -s globstar

# Buscar archivos .cue y procesarlos
for f in ./**/*.cue
do
    name=${f%.cue} # Remover '.cue' del nombre del archivo
    chdman createcd -i "$name.cue" -o "$name.chd" --force
done
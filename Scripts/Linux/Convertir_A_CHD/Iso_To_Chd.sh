#!/bin/bash

printf "%s\n" "desc: Convertir la imagen del disco .ISO del juego a .CHD"

# Habilitar busqueda recursiva con globstar
shopt -s globstar

# Buscar archivos .iso y procesarlos
for f in ./**/*.iso
do
    name=${f%.iso} # Remover '.iso' del nombre del archivo
    chdman createcd -i "$name.iso" -o "$name.chd" --force
done
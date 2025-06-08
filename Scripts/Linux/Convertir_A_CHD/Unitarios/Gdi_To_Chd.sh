#!/bin/bash

printf "%s\n" "desc: Convertir la imagen del disco .GDI del juego a .CHD"

# Habilitar busqueda recursiva con globstar
shopt -s globstar

# Buscar archivos .gdi y procesarlos
for f in ./**/*.gdi
do
    name=${f%.gdi} # Remover '.gdi' del nombre del archivo
    chdman createcd -i "$name.gdi" -o "$name.chd" --force
done
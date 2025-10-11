#!/bin/bash

printf "%s\n" "desc: Convertir la imagen del disco .CHD del juego a .ISO"

# Habilitar busqueda recursiva con globstar
shopt -s globstar

# Buscar archivos .chd y procesarlos
for f in ./**/*.chd
do
    name=${f%.chd} # Remover '.chd' del nombre del archivo
    chdman extractcd -i "$name.chd" -o "$name.iso" --force
done
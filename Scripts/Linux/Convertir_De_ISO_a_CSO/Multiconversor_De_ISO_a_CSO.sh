#!/bin/bash

# Verificar que zenity y ciso estén instalados
command -v zenity >/dev/null 2>&1 || { echo "Zenity no está instalado. Verifica si tienes Zenity instalado o instálalo"; exit 1; }
command -v ciso >/dev/null 2>&1 || { echo "Ciso no está instalado. Verifica si tienes Ciso instalado o instálalo."; exit 1; }

# Mostrar diálogo para seleccionar tipo de conversión
conversion=$(zenity --list --title="Conversión de Imágenes de Disco" \
  --column="Tipo de Conversión" --width=400 --height=300 \
  "ISO a CSO" "CSO a ISO")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Seleccionar archivos o carpeta
input_files=$(zenity --file-selection --multiple --separator="|" \
  --title="Selecciona los archivos de entrada" --file-filter="*.cso *.iso")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Convertir cada archivo
IFS="|" read -r -a files <<< "$input_files"

for input in "${files[@]}"; do
  base="${input%.*}"
  ext="${input##*.}"

  case "$conversion" in
    "ISO a CSO")
      if [[ "$ext" == "iso" ]]; then
        ciso 9 "$input" "${base}.cso"
      fi
      ;;
    "CSO a ISO")
      if [[ "$ext" == "cso" ]]; then
        ciso 0 "$input" "${base}.iso"
      fi
      ;;
    *)
      zenity --error --text="Conversión no soportada o archivo incorrecto"
      ;;
  esac
done
zenity --info --text="Conversión finalizada exitosamente"

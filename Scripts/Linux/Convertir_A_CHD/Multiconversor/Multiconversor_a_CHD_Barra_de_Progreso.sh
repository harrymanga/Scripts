#!/bin/bash

# Verificar que zenity y chdman estén instalados
command -v zenity >/dev/null 2>&1 || { echo "Zenity no está instalado. Instálalo con: sudo apt install zenity"; exit 1; }
command -v chdman >/dev/null 2>&1 || { echo "chdman no está instalado. Verifica si tienes MAME instalado o instálalo."; exit 1; }

# Mostrar diálogo para seleccionar tipo de conversión
conversion=$(zenity --list --title="Conversión de Imágenes de Disco" \
  --column="Tipo de Conversión" --width=400 --height=300 \
  "CHD a CUE" "CHD a GDI" "CHD a ISO" "CUE a CHD" "GDI a CHD" "ISO a CHD")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Seleccionar archivos o carpeta
input_files=$(zenity --file-selection --multiple --separator="|" \
  --title="Selecciona los archivos de entrada" --file-filter="*.chd *.gdi *.cue *.iso")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Convertir y mostrar progreso
(
IFS="|" read -r -a files <<< "$input_files"
total=${#files[@]}
count=0

for input in "${files[@]}"; do
  base="${input%.*}"
  ext="${input##*.}"
  ((count++))

  echo "# Procesando: $input"

  case "$conversion" in
    "CHD a CUE")
      if [[ "$ext" == "chd" ]]; then
        chdman extractcd -i "$input" -o "${base}.cue" --force
      fi
      ;;
    "CHD a GDI")
      if [[ "$ext" == "chd" ]]; then
        chdman extractcd -i "$input" -o "${base}.gdi" --force
      fi
      ;;
    "CHD a ISO")
      if [[ "$ext" == "chd" ]]; then
        chdman extractcd -i "$input" -o "${base}.iso" --force
      fi
      ;;
    "CUE a CHD")
      if [[ "$ext" == "cue" ]]; then
        chdman createcd -i "$input" -o "${base}.chd" --force
      fi
      ;;
    "GDI a CHD")
      if [[ "$ext" == "gdi" ]]; then
        chdman createcd -i "$input" -o "${base}.chd" --force
      fi
      ;;
    "ISO a CHD")
      if [[ "$ext" == "iso" ]]; then
        chdman createcd -i "$input" -o "${base}.chd" --force
      fi
      ;;
    *)
      zenity --error --text="Conversión no soportada o archivo incorrecto"
      ;;
  esac

  percent=$((count * 100 / total))
  echo "$percent"
done

) | zenity --progress \
  --title="Convirtiendo archivos..." \
  --text="Iniciando..." \
  --percentage=0 \
  --auto-close \
  --auto-kill

# Final
[ $? -eq 0 ] && zenity --info --text="¡Conversión completada!" || zenity --error --text="La conversión fue cancelada o falló."

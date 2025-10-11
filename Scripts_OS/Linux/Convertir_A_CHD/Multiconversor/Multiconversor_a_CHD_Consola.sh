#!/bin/bash

# Verifica que Zenity y chdman estén instalados
command -v zenity >/dev/null 2>&1 || { echo "Zenity no está instalado. Instálalo con: sudo apt install zenity"; exit 1; }
command -v chdman >/dev/null 2>&1 || { echo "chdman no está instalado. Instálalo con: sudo apt install mame-tools"; exit 1; }

# Crear archivo temporal para mostrar salida
LOGFILE=$(mktemp)

# Mostrar diálogo para seleccionar tipo de conversión
conversion=$(zenity --list --title="Conversión de Imágenes de Disco" \
  --column="Tipo de Conversión" --width=400 --height=300 \
  "CHD a CUE" "CHD a GDI" "CHD a ISO" "CUE a CHD" "GDI a CHD" "ISO a CHD")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Seleccionar archivos o carpeta
input_files=$(zenity --file-selection --multiple --separator="|" \
  --title="Selecciona los archivos de entrada" --file-filter="*.chd *.gdi *.cue *.iso")

[ $? -ne 0 ] && exit 0  # Cancelado

# Ejecutar las conversiones en segundo plano y mostrar salida en Zenity
(
  IFS="|" read -r -a files <<< "$input_files"
  for input in "${files[@]}"; do
    base="${input%.*}"
    ext="${input##*.}"

    echo "Procesando: $input" >> "$LOGFILE"

    case "$conversion" in
      "CHD a CUE")
        if [[ "$ext" == "chd" ]]; then
          chdman extractcd -i "$input" -o "${base}.cue" --force >> "$LOGFILE" 2>&1
        fi
        ;;
      "CHD a GDI")
        if [[ "$ext" == "chd" ]]; then
          chdman extractcd -i "$input" -o "${base}.gdi" --force >> "$LOGFILE" 2>&1
        fi
        ;;
      "CHD a ISO")
        if [[ "$ext" == "chd" ]]; then
          chdman extractcd -i "$input" -o "${base}.iso" --force >> "$LOGFILE" 2>&1
        fi
        ;;
      "CUE a CHD")
        if [[ "$ext" == "cue" ]]; then
          chdman createcd -i "$input" -o "${base}.chd" --force >> "$LOGFILE" 2>&1
        fi
        ;;
      "GDI a CHD")
        if [[ "$ext" == "gdi" ]]; then
          chdman createcd -i "$input" -o "${base}.chd" --force >> "$LOGFILE" 2>&1
        fi
        ;;
      "ISO a CHD")
        if [[ "$ext" == "iso" ]]; then
          chdman createcd -i "$input" -o "${base}.chd" --force >> "$LOGFILE" 2>&1
        fi
        ;;
    esac
    echo "-----" >> "$LOGFILE"
  done
) &

# Mostrar salida en vivo usando Zenity
tail -f "$LOGFILE" | zenity --text-info --title="Consola de Conversión" --width=700 --height=500

# Limpieza
rm -f "$LOGFILE"

#!/bin/bash
# Multiconversor_De_ISO_a_CSO.sh — ISO<->CSO (mundo PSP) con ciso + zenity.
# Uso: Multiconversor_De_ISO_a_CSO.sh [es|en]
# Ver README.md.

# --- Idioma: parámetro > $LANG > es ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[ "$1" = "en" ] && LANG_ID="en"
[ "$1" = "es" ] && LANG_ID="es"
# shellcheck disable=SC1090
. "$(dirname "$0")/lang_${LANG_ID}.sh"

# Verificar que zenity y ciso estén instalados
command -v zenity >/dev/null 2>&1 || { echo "$MSG_NO_ZENITY"; exit 1; }
command -v ciso >/dev/null 2>&1 || { zenity --error --text="$MSG_NO_CISO"; exit 1; }

# Mostrar diálogo para seleccionar tipo de conversión
conversion=$(zenity --list --title="$MSG_TITLE_LIST" \
  --column="$MSG_COL" --width=400 --height=300 \
  "$OPT_ISO_CSO" "$OPT_CSO_ISO")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Seleccionar archivos o carpeta
input_files=$(zenity --file-selection --multiple --separator="|" \
  --title="$MSG_TITLE_FILES" --file-filter="*.cso *.iso")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# Convertir cada archivo
IFS="|" read -r -a files <<< "$input_files"

for input in "${files[@]}"; do
  base="${input%.*}"
  ext="${input##*.}"

  case "$conversion" in
    "$OPT_ISO_CSO")
      if [[ "$ext" == "iso" ]]; then
        ciso 9 "$input" "${base}.cso"
      fi
      ;;
    "$OPT_CSO_ISO")
      if [[ "$ext" == "cso" ]]; then
        ciso 0 "$input" "${base}.iso"
      fi
      ;;
    *)
      zenity --error --text="$MSG_UNSUPPORTED"
      ;;
  esac
done
zenity --info --text="$MSG_DONE"

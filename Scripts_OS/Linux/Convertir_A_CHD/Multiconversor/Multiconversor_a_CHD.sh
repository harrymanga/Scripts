#!/bin/bash
# Multiconversor_a_CHD.sh — Versión única consolidada.
# Reemplaza a: Multiconversor_a_CHD.sh (base), _Consola.sh y
# _Barra_de_Progreso.sh. Combina barra de progreso + registro en vivo +
# workaround CHD->ISO (.bin) + i18n + instalación asistida de dependencias.
#
# Uso: Multiconversor_a_CHD.sh [es|en]
# Requiere: zenity, chdman (mame-tools). Si faltan, se intenta instalar.
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

# --- Dependencias (instalación asistida, solo avisa si falla) ---
if ! command -v zenity >/dev/null 2>&1; then
    echo "$MSG_NO_ZENITY"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y zenity || exit 1
    else
        exit 1
    fi
fi

if ! command -v chdman >/dev/null 2>&1; then
    zenity --info --text="$MSG_NO_CHDMAN"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y mame-tools
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y mame-tools
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm mame-tools
    fi
    command -v chdman >/dev/null 2>&1 || { zenity --error --text="$MSG_NO_CHDMAN_MANUAL"; exit 1; }
fi

# --- Tipo de conversión ---
conversion=$(zenity --list --title="$MSG_TITLE_LIST" \
  --column="$MSG_COL" --width=400 --height=300 \
  "$OPT_CHD_CUE" "$OPT_CHD_GDI" "$OPT_CHD_ISO" \
  "$OPT_CUE_CHD" "$OPT_GDI_CHD" "$OPT_ISO_CHD")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

# --- Archivos de entrada ---
input_files=$(zenity --file-selection --multiple --separator="|" \
  --title="$MSG_TITLE_FILES" --file-filter="*.chd *.gdi *.cue *.iso")

[ $? -ne 0 ] && exit 0  # Cancelado por el usuario

LOGFILE=$(mktemp)

# --- Conversión con barra de progreso (el registro queda en LOGFILE) ---
(
IFS="|" read -r -a files <<< "$input_files"
total=${#files[@]}
count=0
for input in "${files[@]}"; do
  base="${input%.*}"
  ext="${input##*.}"
  ((count++))

  # shellcheck disable=SC2059
  printf "# $MSG_PROCESSING\n" "$input"
  # shellcheck disable=SC2059
  printf "$MSG_PROCESSING\n" "$input" >> "$LOGFILE"

  case "$conversion" in
    "$OPT_CHD_CUE")
      if [[ "$ext" == "chd" ]]; then
        chdman extractcd -i "$input" -o "${base}.cue" --force >> "$LOGFILE" 2>&1
      fi
      ;;
    "$OPT_CHD_GDI")
      if [[ "$ext" == "chd" ]]; then
        chdman extractcd -i "$input" -o "${base}.gdi" --force >> "$LOGFILE" 2>&1
      fi
      ;;
    "$OPT_CHD_ISO")
      if [[ "$ext" == "chd" ]]; then
        chdman extractcd -i "$input" -o "${base}.iso" --force >> "$LOGFILE" 2>&1
        if [[ -f "${base}.bin" ]]; then
          rm -f "${base}.iso"
          mv "${base}.bin" "${base}.iso"
          # shellcheck disable=SC2059
          printf "$MSG_GENERATED\n" "${base}.iso" >> "$LOGFILE"
        else
          # shellcheck disable=SC2059
          printf "$MSG_NOBIN\n" "${base}.bin" >> "$LOGFILE"
        fi
      fi
      ;;
    "$OPT_CUE_CHD")
      if [[ "$ext" == "cue" ]]; then
        chdman createcd -i "$input" -o "${base}.chd" --force >> "$LOGFILE" 2>&1
      fi
      ;;
    "$OPT_GDI_CHD")
      if [[ "$ext" == "gdi" ]]; then
        chdman createcd -i "$input" -o "${base}.chd" --force >> "$LOGFILE" 2>&1
      fi
      ;;
    "$OPT_ISO_CHD")
      if [[ "$ext" == "iso" ]]; then
        chdman createcd -i "$input" -o "${base}.chd" --force >> "$LOGFILE" 2>&1
      fi
      ;;
    *)
      echo "$MSG_UNSUPPORTED" >> "$LOGFILE"
      ;;
  esac
  echo "-----" >> "$LOGFILE"

  percent=$((count * 100 / total))
  echo "$percent"
done
) | zenity --progress \
  --title="$MSG_CONVERTING" \
  --text="$MSG_STARTING" \
  --percentage=0 \
  --auto-close \
  --auto-kill

# --- Resultado + registro ---
if [ $? -eq 0 ]; then
    zenity --info --text="$MSG_COMPLETED"
else
    zenity --error --text="$MSG_CANCELLED"
fi
zenity --text-info --title="$MSG_LOG_TITLE" --width=700 --height=500 --filename="$LOGFILE"
rm -f "$LOGFILE"

#!/bin/bash
# Sincronizar_carpetas.sh — alternativa ligera Linux (sin Python).
# Uso: Sincronizar_carpetas.sh [es|en]
# Requiere: zenity, inotify-tools, rsync (los dos primeros se autoinstalan).
# Ver README.md y la versión canónica multiplataforma en
# ../../../Multiplataforma/Sincronizar_Carpetas/sync-auto/.

# --- Idioma: parámetro > $LANG > es ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[ "$1" = "en" ] && LANG_ID="en"
[ "$1" = "es" ] && LANG_ID="es"
# shellcheck disable=SC1090
. "$(dirname "$0")/lang_${LANG_ID}.sh"

# Detectar sistema operativo y distro
detectar_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "desconocido"
    fi
}

# Instalar zenity si no está instalado.
# OJO: aquí NO se puede usar zenity para avisar (no existe aún):
# se informa por consola.
if ! command -v zenity &> /dev/null; then
    distro=$(detectar_distro)
    printf "$MSG_INSTALLING\n" "zenity" "$distro"
    case "$distro" in
        ubuntu|debian)
            sudo apt update && sudo apt install -y zenity
            ;;
        fedora)
            sudo dnf install -y zenity
            ;;
        arch|manjaro|garuda)
            sudo pacman -Sy zenity --noconfirm
            ;;
        *)
            echo "$MSG_UNSUPPORTED"
            exit 1
            ;;
    esac
fi

# Instalar inotifywait si no está instalado
if ! command -v inotifywait &> /dev/null; then
    distro=$(detectar_distro)
    zenity --info --text="$(printf "$MSG_INSTALLING" "inotifywait" "$distro")"
    case "$distro" in
        ubuntu|debian)
            sudo apt update && sudo apt install -y inotify-tools
            ;;
        fedora)
            sudo dnf install -y inotify-tools
            ;;
        arch|manjaro|garuda)
            sudo pacman -Sy inotify-tools --noconfirm
            ;;
        *)
            zenity --info --text="$MSG_UNSUPPORTED"
            exit 1
            ;;
    esac
fi

# Carpeta a monitorear
carpeta_origen=$(zenity --file-selection --directory --title="$MSG_TITLE_SRC")
    [ -z "$carpeta_origen" ] && zenity --error --text="$MSG_NO_SELECTION" && exit 1

# Destinos a sincronizar
carpeta_destino=$(zenity --file-selection --directory --title="$MSG_TITLE_DST")
    [ -z "$carpeta_destino" ] && zenity --error --text="$MSG_NO_SELECTION" && exit 1

# Función para copiar la carpeta
sincronizar() {
    rsync -av --delete "$carpeta_origen/" "$carpeta_destino/"
    zenity --info --text="$(printf "$MSG_SYNCED" "$carpeta_destino")"
}

# Monitoreo en tiempo real usando inotifywait
zenity --info --text="$(printf "$MSG_MONITORING" "$carpeta_origen")"
inotifywait -m -r -e modify,create,delete,move "$carpeta_origen" | while read -r directorio evento archivo; do
    echo "$(printf "$MSG_CHANGED" "$evento" "$archivo")"
    sincronizar
done

#!/bin/bash

# Detectar sistema operativo y distro
detectar_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "desconocido"
    fi
}

# Instalar zenity si no está instalado
if ! command -v zenity &> /dev/null; then
    distro=$(detectar_distro)
    zenity --info --text="Zenity no está instalado. Intentando instalar en $distro..."
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
            zenity --info --text="Distribución no soportada para instalación automática."
            exit 1
            ;;
    esac
fi

# Instalar inotifywait si no está instalado
if ! command -v inotifywait &> /dev/null; then
    distro=$(detectar_distro)
    zenity --info --text="inotifywait no está instalado. Intentando instalar en $distro..."
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
            zenity --info --text="Distribución no soportada para instalación automática."
            exit 1
            ;;
    esac
fi

# Carpeta a monitorear
carpeta_origen=$(zenity --file-selection --directory --title="Selecciona la Carpeta Origen")
    [ -z "$carpeta_origen" ] && zenity --error --text="No se seleccionó una carpeta" && exit 1

# Destinos a sincronizar
carpeta_detino=$(zenity --file-selection --directory --title="Selecciona la Carpeta Destino")
    [ -z "$carpeta_detino" ] && zenity --error --text="No se seleccionó una carpeta" && exit 1

# Función para copiar la carpeta
sincronizar() {
    rsync -av --delete "$carpeta_origen/" "$carpeta_detino/"
    zenity --info --text="✅ Sincronizado con $carpeta_detino"
}

# Monitoreo en tiempo real usando inotifywait
zenity --info --text="🕵️‍♂️ Monitoreando cambios en $carpeta_origen..."
inotifywait -m -r -e modify,create,delete,move "$carpeta_origen" | while read -r directorio evento archivo; do
    zenity --info --text="🔔 Cambio detectado: $evento en $archivo"
    sincronizar
done

#!/bin/bash
# crear_lanzador_de_apps.sh — Versión única canónica.
# Genera lanzadores .desktop (con soporte Wine y acceso directo).
# Uso: crear_lanzador_de_apps.sh [es|en]
# Idioma: parámetro > $LANG > es. Ver README.md.

# --- Idioma ---
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

# Instalar zenity si no está instalado
if ! command -v zenity &> /dev/null; then
    distro=$(detectar_distro)
    # shellcheck disable=SC2059
    printf "$MSG_INSTALLING\n" "$distro"
    case "$distro" in
        ubuntu|debian)
            sudo apt update && sudo apt install -y zenity
            ;;
        fedora)
            sudo dnf install -y zenity
            ;;
        arch|manjaro)
            sudo pacman -Sy zenity --noconfirm
            ;;
        *)
            echo "$MSG_UNSUPPORTED"
            exit 1
            ;;
    esac
fi

# Seleccionar ejecutable
ejecutable=$(zenity --file-selection --title="$MSG_EXE_TITLE")
[ -z "$ejecutable" ] && zenity --error --text="$MSG_NO_EXE" && exit 1

# Nombre del lanzador
nombre_app=$(zenity --entry --title="$MSG_NAME_TITLE" --text="$MSG_NAME_TEXT")
[ -z "$nombre_app" ] && zenity --error --text="$MSG_NO_NAME" && exit 1

# Ícono (opcional)
icono=$(zenity --file-selection --title="$MSG_ICON_TITLE" --file-filter="*.jpg *.png *.svg *.xpm *.ico")
[ -z "$icono" ] && icono=""

# Categorías (valores freedesktop, no se traducen: van al archivo)
categoria=$(zenity --list --checklist   --title="$MSG_CAT_TITLE"   --text="$MSG_CAT_TEXT"   --column="Seleccionado" --column="Categoría"   TRUE Utility   FALSE Development   FALSE Game   FALSE AudioVideo   FALSE Network   FALSE Office   FALSE Settings   FALSE Education   FALSE Graphics   FALSE System   --separator=";")

[ -z "$categoria" ] && categoria="Utility"

# ¿Usa Wine?
usa_wine=$(zenity --question --title="$MSG_WINE_TITLE" --text="$MSG_WINE_TEXT" --ok-label="$MSG_YES" --cancel-label="$MSG_NO")
if [ $? -eq 0 ]; then
    usa_wine=true
    wineprefix=$(zenity --file-selection --directory --title="$MSG_WINEPREFIX_TITLE")
    [ -z "$wineprefix" ] && zenity --error --text="$MSG_NO_WINEPREFIX" && exit 1
    comando="env WINEPREFIX=\"$wineprefix\" wine \"$ejecutable\""
else
    usa_wine=false
    comando="$ejecutable"
fi

# Crear archivo .desktop
archivo_desktop="$HOME/.local/share/applications/$nombre_app.desktop"
mkdir -p "$(dirname "$archivo_desktop")"

cat <<EOF > "$archivo_desktop"
[Desktop Entry]

Type=Application
Name=$nombre_app
Version=1.0
Categories=$categoria;
Comment=Iniciar $nombre_app
GenericName=
Exec=$comando
Icon=${icono:-application-default-icon}
Terminal=false
TerminalOptions=
StartupNotify=true
NoDisplay=false
Path=
X-KDE-SubstituteUID=false
X-KDE-Username=
EOF

chmod +x "$archivo_desktop"

zenity --question --title="$MSG_SHORTCUT_TITLE" --text="$MSG_SHORTCUT_TEXT"
if [[ $? -eq 0 ]]; then
    escritorio_dir="$HOME/Escritorio"
    [ ! -d "$escritorio_dir" ] && escritorio_dir="$HOME/Desktop"
    if [ -d "$escritorio_dir" ]; then
        cp "$archivo_desktop" "$escritorio_dir/"
        chmod +x "$escritorio_dir/$nombre_app.desktop"
        command -v gio &> /dev/null && gio set "$escritorio_dir/$nombre_app.desktop" "metadata::trusted" true 2>/dev/null
    fi
fi

# shellcheck disable=SC2059
zenity --info --text="$(printf "$MSG_DONE" "$archivo_desktop")"

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
    echo "Zenity no está instalado. Intentando instalar en $distro..."
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
            echo "Distribución no soportada para instalación automática."
            exit 1
            ;;
    esac
fi

# Seleccionar ejecutable
ejecutable=$(zenity --file-selection --title="Selecciona el ejecutable de la aplicación")
[ -z "$ejecutable" ] && zenity --error --text="No se seleccionó ningún ejecutable" && exit 1

# Nombre del lanzador
nombre_app=$(zenity --entry --title="Nombre del lanzador" --text="Escribe el nombre del lanzador")
[ -z "$nombre_app" ] && zenity --error --text="No se proporcionó nombre" && exit 1

# Ícono (opcional)
icono=$(zenity --file-selection --title="Selecciona el ícono (opcional)" --file-filter="*.png *.svg *.xpm *.ico")
[ -z "$icono" ] && icono=""

# Categorías
categoria=$(zenity --list --checklist   --title="Selecciona categorías"   --text="Selecciona una o más categorías"   --column="Seleccionado" --column="Categoría"   TRUE Utility   FALSE Development   FALSE Game   FALSE AudioVideo   FALSE Network   FALSE Office   FALSE Settings   FALSE Education   FALSE Graphics   FALSE System   --separator=";")

[ -z "$categoria" ] && categoria="Utility"

# ¿Usa Wine?
usa_wine=$(zenity --question --title="¿Usa Wine?" --text="¿La aplicación se ejecuta con Wine?" --ok-label="Sí" --cancel-label="No")
if [ $? -eq 0 ]; then
    usa_wine=true
    wineprefix=$(zenity --file-selection --directory --title="Selecciona el WINEPREFIX")
    [ -z "$wineprefix" ] && zenity --error --text="No se seleccionó un WINEPREFIX" && exit 1
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

zenity --question --title="Acceso directo" --text="¿Deseas crear también un acceso directo en el escritorio?"
if [[ $? -eq 0 ]]; then
    escritorio_dir="$HOME/Escritorio"
    [ ! -d "$escritorio_dir" ] && escritorio_dir="$HOME/Desktop"
    if [ -d "$escritorio_dir" ]; then
        cp "$archivo_desktop" "$escritorio_dir/"
        chmod +x "$escritorio_dir/$nombre_app.desktop"
        command -v gio &> /dev/null && gio set "$escritorio_dir/$nombre_app.desktop" "metadata::trusted" true 2>/dev/null
    fi
fi

zenity --info --text="✅ Lanzador creado exitosamente: $archivo_desktop"
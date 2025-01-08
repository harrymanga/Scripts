#!/bin/bash

# Función para instalar dependencias
instalar_dependencias() {
    # Lista de dependencias requeridas por los scripts
    DEPENDENCIAS=("zenity")# Incluye 'zenity' como dependencia

    echo "Verificando e instalando dependencias necesarias..."
    for dep in "${DEPENDENCIAS[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "La dependencia '$dep' no está instalada. Intentando instalarla..."

            # Detectar el gestor de paquetes
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y "$dep"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "$dep"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm "$dep"
            else
                echo "Error: No se pudo detectar un gestor de paquetes compatible. Instala '$dep' manualmente."
                exit 1
            fi

            # Verificar si la instalación fue exitosa
            if ! command -v "$dep" &> /dev/null; then
                echo "Error: No se pudo instalar '$dep'. Verifica tu conexión o permisos."
                exit 1
            fi

            echo "La dependencia '$dep' se instaló correctamente."
        else
            echo "La dependencia '$dep' ya está instalada."
        fi
    done
    echo "Todas las dependencias están instaladas."
}

# Solicitar la carpeta al usuario con Zenity
seleccionar_carpeta() {
    folder=$(zenity --file-selection --directory --title="Selecciona la carpeta que contiene los scripts .sh")

    # Verificar si el usuario seleccionó una carpeta o canceló
    if [ $? -eq 0 ]; then
        echo "Carpeta seleccionada: $folder"
    else
        echo "No se seleccionó ninguna carpeta. Saliendo..."
        exit 1
    fi
}

# Ejecutar los scripts en la carpeta seleccionada
ejecutar_scripts() {
    echo "Buscando scripts en la carpeta: $folder"

    # Verificar si hay archivos .sh en la carpeta
    sh_files=("$folder"/*.sh)
    if [ -z "${sh_files[*]}" ] || [ ! -e "${sh_files[0]}" ]; then
        echo "No se encontraron archivos .sh en la carpeta seleccionada."
        zenity --error --text="No se encontraron scripts .sh en la carpeta seleccionada." --title="Error"
        exit 1
    fi

    # Ejecutar cada script
    for file in "${sh_files[@]}"; do
        echo "Ejecutando $file..."
        if bash "$file"; then
            echo "Script $file ejecutado correctamente."
        else
            echo "Error al ejecutar el script $file."
            zenity --error --text="Error al ejecutar el script: $file" --title="Error"
            exit 1
        fi
    done

    zenity --info --text="Todos los scripts se ejecutaron correctamente." --title="Éxito"
}

# Manejo de errores generales
set -e  # Detener el script si ocurre un error

# Función principal
main() {
    echo "Iniciando script..."

    # Verificar e instalar dependencias
    instalar_dependencias

    # Solicitar carpeta
    seleccionar_carpeta

    # Ejecutar los scripts en la carpeta
    ejecutar_scripts
}

# Ejecutar la función principal
main



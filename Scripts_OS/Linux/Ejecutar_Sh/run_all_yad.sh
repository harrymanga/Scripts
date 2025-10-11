#!/bin/bash

# Función para instalar dependencias
instalar_dependencias() {
    # Lista de dependencias requeridas por los scripts
    DEPENDENCIAS=("yad")  # Incluye 'yad' como dependencia

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

# Solicitar la carpeta al usuario con Yad
seleccionar_carpeta() {
    folder=$(yad --file-selection --directory --title="Selecciona la carpeta que contiene los scripts .sh")

    # Verificar si el usuario seleccionó una carpeta o canceló
    if [ $? -eq 0 ]; then
        echo "Carpeta seleccionada: $folder"
    else
        echo "No se seleccionó ninguna carpeta. Saliendo..."
        exit 1
    fi
}

# Ejecutar los scripts en la carpeta seleccionada con barra de progreso
ejecutar_scripts() {
    echo "Buscando scripts en la carpeta: $folder"

    # Verificar si hay archivos .sh en la carpeta
    sh_files=("$folder"/*.sh)
    if [ -z "${sh_files[*]}" ] || [ ! -e "${sh_files[0]}" ]; then
        echo "No se encontraron archivos .sh en la carpeta seleccionada."
        yad --error --text="No se encontraron scripts .sh en la carpeta seleccionada." --title="Error"
        exit 1
    fi

    # Inicializar barra de progreso
    total=${#sh_files[@]}
    progreso=0

    resultados=""

    (
    for file in "${sh_files[@]}"; do
        # Incrementar progreso
        progreso=$((progreso + 100 / total))
        echo "# Ejecutando: $file"
        echo "$progreso"

        # Ejecutar script y registrar el resultado
        if bash "$file"; then
            resultados+="$file: Éxito\n"
        else
            resultados+="$file: Error\n"
        fi
    done
    ) | yad --progress --title="Progreso de Ejecución" --text="Ejecutando scripts..." --percentage=0 --auto-close

    # Mostrar resultados en una ventana de texto
    yad --text-info --title="Resultados de Ejecución" --width=600 --height=400 --text="$resultados"
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


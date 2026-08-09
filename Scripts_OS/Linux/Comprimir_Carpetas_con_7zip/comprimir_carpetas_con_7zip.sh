#!/bin/bash

# Script para comprimir carpetas individualmente con 7zip usando interfaz gráfica
# Requiere: 7zip (p7zip-full) y zenity

# Verificar dependencias
check_dependencies() {
    if ! command -v 7z &> /dev/null; then
        zenity --error --title="Error" --text="7zip no está instalado.\n\nInstálalo con:\nsudo apt install p7zip-full\no\nsudo pacman -S p7zip" 2>/dev/null
        exit 1
    fi

    if ! command -v zenity &> /dev/null; then
        zenity --error --title="Error" --text="zenity no está instalado.\n\nInstálalo con:\nsudo apt install zenity\no\nsudo pacman -S zenity" 2>/dev/null
        exit 1
    fi
}

# Función principal
main() {
    check_dependencies

    # Mostrar diálogo de selección de carpetas
    CARPETAS=$(zenity --file-selection --directory --multiple --title="Selecciona las carpetas a comprimir" 2>/dev/null)

    if [ -z "$CARPETAS" ]; then
        zenity --info --title="Información" --text="No se seleccionaron carpetas." 2>/dev/null
        exit 0
    fi

    # Convertir selección en array
    IFS='|' read -ra CARPETA_ARRAY <<< "$CARPETAS"
    TOTAL=${#CARPETA_ARRAY[@]}

    # Preguntar carpeta de salida
    CARPETA_SALIDA=""
    if zenity --question --title="Carpeta de salida" --text="¿Deseas seleccionar una carpeta de salida específica?\n\nSi seleccionas 'No', los archivos se guardarán en el mismo directorio que las carpetas originales." 2>/dev/null; then
        CARPETA_SALIDA=$(zenity --file-selection --directory --title="Selecciona la carpeta de salida" 2>/dev/null)
        if [ -z "$CARPETA_SALIDA" ]; then
            zenity --warning --title="Advertencia" --text="No se seleccionó carpeta de salida. Los archivos se guardarán en el mismo directorio que las carpetas originales." 2>/dev/null
        fi
    fi

    # Preguntar nivel de compresión
    NIVEL_COMPRESION=$(zenity --list --title="Nivel de compresión" --text="Selecciona el nivel de compresión:" --column="Nivel" --column="Descripción" \
        "0" "Sin compresión (solo almacenar)" \
        "1" "Muy rápido" \
        "3" "Rápido" \
        "5" "Normal (recomendado)" \
        "7" "Máximo" \
        "9" "Ultra" \
        --hide-column=1 --print-column=1 2>/dev/null)

    if [ -z "$NIVEL_COMPRESION" ]; then
        NIVEL_COMPRESION="5"
    fi

    # Preguntar si desea contraseña
    PASSWORD=""
    if zenity --question --title="Contraseña" --text="¿Deseas proteger los archivos con contraseña?" 2>/dev/null; then
        PASSWORD=$(zenity --entry --title="Contraseña" --text="Ingresa la contraseña:" --hide-text 2>/dev/null)
        if [ -z "$PASSWORD" ]; then
            zenity --warning --title="Advertencia" --text="No se ingresó contraseña. Los archivos no estarán protegidos." 2>/dev/null
        fi
    fi

    # Iniciar proceso de compresión
    (
        COUNTER=0
        EXIT_CODE=0
        for CARPETA in "${CARPETA_ARRAY[@]}"; do
            COUNTER=$((COUNTER + 1))
            PORCENTaje=$((COUNTER * 100 / TOTAL))

            # Obtener nombre de la carpeta sin la ruta completa
            NOMBRE_CARPETA=$(basename "$CARPETA")
            
            # Usar carpeta de salida seleccionada o el directorio original
            if [ -n "$CARPETA_SALIDA" ]; then
                ARCHIVO_SALIDA="${CARPETA_SALIDA}/${NOMBRE_CARPETA}.7z"
            else
                DIRECTORIO_PADRE=$(dirname "$CARPETA")
                ARCHIVO_SALIDA="${DIRECTORIO_PADRE}/${NOMBRE_CARPETA}.7z"
            fi

            echo "# Comprimiendo [$COUNTER/$TOTAL]: $NOMBRE_CARPETA"
            echo "$PORCENTaje"

            # Construir comando 7zip - redirigir stderr para no interferir con zenity
            if [ -n "$PASSWORD" ]; then
                7z a -t7z -mhe=on -p"$PASSWORD" -mx="$NIVEL_COMPRESION" "$ARCHIVO_SALIDA" "$CARPETA" >/dev/null 2>&1
            else
                7z a -t7z -mx="$NIVEL_COMPRESION" "$ARCHIVO_SALIDA" "$CARPETA" >/dev/null 2>&1
            fi

            if [ $? -eq 0 ]; then
                echo "✓ $NOMBRE_CARPETA comprimido correctamente"
            else
                echo "✗ Error al comprimir $NOMBRE_CARPETA"
                EXIT_CODE=1
            fi
        done

        echo "# Compresión completada"
        echo "100"
        exit $EXIT_CODE
    ) | zenity --progress --title="Comprimiendo carpetas" --text="Iniciando compresión..." --percentage=0 --auto-close --width=500

    # Mostrar resumen
    if [ -n "$CARPETA_SALIDA" ]; then
        MENSAJE="Se han comprimido $TOTAL carpetas individualmente.\n\nLos archivos .7z se encuentran en:\n$CARPETA_SALIDA"
    else
        MENSAJE="Se han comprimido $TOTAL carpetas individualmente.\n\nLos archivos .7z se encuentran en el mismo directorio que las carpetas originales."
    fi
    zenity --info --title="Completado" --text="$MENSAJE" 2>/dev/null
}

# Ejecutar función principal
main

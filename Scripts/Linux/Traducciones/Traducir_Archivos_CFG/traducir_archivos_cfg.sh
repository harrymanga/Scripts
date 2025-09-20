#!/bin/bash

# ===============================
# Script de traducción de archivos .cfg
# Multiarchivo - Multiidioma - Multimotor
# ===============================

# Dependencias necesarias:
# - translate-shell (paquete: translate-shell)
# - zenity (opcional, para GUI)
# ===============================

# Variables globales de conteo
global_files=0
global_lines=0
global_attempted=0
global_succeeded=0
global_failed=0
report=""

# Función para traducir una línea
translate_line() {
    local text="$1"
    local lang="$2"
    local engine="$3"
    local translated=""

    case "$engine" in
        "translate-shell")
            translated=$(trans -brief :"$lang" "$text" 2>/dev/null)
            ;;
        "google")
            translated=$(trans -e google -brief :"$lang" "$text" 2>/dev/null)
            ;;
        "deepl")
            translated=$(trans -e deepl -brief :"$lang" "$text" 2>/dev/null)
            ;;
        *)
            translated="$text"
            ;;
    esac

    # Si no se obtiene traducción, devolver original
    [ -z "$translated" ] && translated="$text" && ((global_failed++)) || ((global_succeeded++))

    echo "$translated"
}

# Procesar archivo
process_file() {
    local file="$1"
    local lang="$2"
    local engine="$3"
    local dir="$(dirname "$file")/translations"
    mkdir -p "$dir"
    local base="$(basename "$file" .cfg)"
    local output="$dir/${base}_${lang}.cfg"

    local line_count=0
    local attempted=0
    local succeeded=0
    local failed=0

    > "$output"
    while IFS= read -r line; do
        ((line_count++))
        if [[ "$line" == *=* ]]; then
            ((attempted++))
            key="${line%%=*}"
            value="${line#*=}"
            translated=$(translate_line "$value" "$lang" "$engine")
            echo "$key=$translated" >> "$output"
            [[ "$translated" == "$value" ]] && ((failed++)) || ((succeeded++))
        else
            echo "$line" >> "$output"
        fi
    done < "$file"

    # Acumuladores globales
    ((global_files++))
    ((global_lines+=line_count))
    ((global_attempted+=attempted))
    ((global_succeeded+=succeeded))
    ((global_failed+=failed))

    # Reporte por archivo
    report+="Archivo original: $file
Motor: $engine
Idioma destino: $lang
Total líneas: $line_count
Líneas con clave (=): $attempted
Traducciones exitosas: $succeeded
Traducciones con fallback: $failed
Archivo generado: $output
-----------------------------\n\n"
}

# ===============================
# Selección de archivos y parámetros
# ===============================

# Detectar si hay GUI
if command -v zenity >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    # GUI con zenity
    files=$(zenity --file-selection --multiple --separator=" " --file-filter="*.cfg" --title="Seleccione archivo(s) .cfg")
    [ -z "$files" ] && exit 0

    engine=$(zenity --list --title="Seleccione motor de traducción" --radiolist \
        --column="Usar" --column="Motor" TRUE "translate-shell" FALSE "google" FALSE "deepl")
    [ -z "$engine" ] && exit 0

    langs=$(zenity --entry --title="Idiomas destino" --text="Ingrese códigos de idioma separados por espacio (ej: es fr de):")
    [ -z "$langs" ] && exit 0
else
    # Terminal
    read -rp "Ingrese la ruta de archivo(s) .cfg (separados por espacio o use *.cfg): " files
    read -rp "Seleccione motor de traducción (translate-shell/google/deepl): " engine
    read -rp "Ingrese códigos de idioma separados por espacio (ej: es fr de): " langs
fi

# ===============================
# Procesamiento
# ===============================

for file in $files; do
    for lang in $langs; do
        process_file "$file" "$lang" "$engine"
    done
done

# ===============================
# Generación de reporte
# ===============================

dir="$(dirname "${files%% *}")/translations"
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
report_file="$dir/report_$timestamp.txt"

{
    echo "===== REPORTE DE TRADUCCIÓN ====="
    echo "Fecha: $(date)"
    echo
    echo -e "$report"
    echo "===== RESUMEN GLOBAL ====="
    echo "Archivos procesados: $global_files"
    echo "Total líneas: $global_lines"
    echo "Claves (=) detectadas: $global_attempted"
    echo "Traducciones exitosas: $global_succeeded"
    echo "Traducciones con fallback: $global_failed"
} > "$report_file"

# Enlace simbólico al último reporte
ln -sf "$(basename "$report_file")" "$dir/latest_report.txt"

# Mensaje final
if [ -n "$DISPLAY" ] && command -v zenity >/dev/null 2>&1; then
    zenity --info --title="Traducción completada" --text="Archivos traducidos guardados en: $dir\n\nReporte: $report_file"
else
    echo "✅ Traducción completada."
    echo "📄 Reporte: $report_file"
    echo "🔗 Enlace rápido: $dir/latest_report.txt"
fi

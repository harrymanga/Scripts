#!/usr/bin/env bash

###############################################################################
# START SCRIPT TEMPLATE
# Detecta ruta, define nombre de app y realiza inicialización básica
###############################################################################

### CONFIGURACIÓN DE LA APLICACIÓN ###
APP_NAME="MiAplicacion"            # << Cambiar por el nombre real
APP_EXEC="mi_app_binario"          # << Archivo ejecutable
APP_ARGS=""                        # << Argumentos opcionales

### DETECTAR RUTA AUTOMÁTICAMENTE ###
# Obtiene la ubicación exacta del script, incluso con symlinks
SCRIPT_PATH="$(readlink -f "$0")"
BASE_DIR="$(dirname "$SCRIPT_PATH")"

### RUTAS IMPORTANTES ###
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/$APP_NAME-$(date '+%Y%m%d').log"

### FUNCIÓN: Crear carpetas si no existen ###
init_folders() {
    mkdir -p "$LOG_DIR"
}

### FUNCIÓN: Mostrar información ###
info() {
    echo "-----------------------------------------"
    echo " Iniciando $APP_NAME"
    echo " Ruta del script : $SCRIPT_PATH"
    echo " Directorio base : $BASE_DIR"
    echo " Logs            : $LOG_FILE"
    echo "-----------------------------------------"
}

### FUNCIÓN: Ejecutar app ###
start_app() {
    if [[ ! -x "$BASE_DIR/$APP_EXEC" ]]; then
        echo "❌ ERROR: No se encontró el ejecutable: $BASE_DIR/$APP_EXEC"
        exit 1
    fi

    # Ejecutar y guardar logs
    echo "✔ Ejecutando $APP_NAME..."
    "$BASE_DIR/$APP_EXEC" $APP_ARGS >> "$LOG_FILE" 2>&1 &
    PID=$!

    echo "✔ $APP_NAME iniciado con PID $PID"
}

### EJECUCIÓN PRINCIPAL ###
init_folders
info
start_app


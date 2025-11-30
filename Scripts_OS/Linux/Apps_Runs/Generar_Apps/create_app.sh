#!/usr/bin/env bash

###############################################################################
# GENERADOR DE NUEVAS APPS A PARTIR DE LA PLANTILLA
###############################################################################

if [[ -z "$1" ]]; then
    echo "Uso: ./create_app.sh NombreApp"
    exit 1
fi

APP_NAME="$1"
TARGET_DIR="$PWD/$APP_NAME"

echo "📦 Creando nueva app en: $TARGET_DIR"

mkdir -p "$TARGET_DIR"

# Extraer la plantilla
unzip miapp_template.zip -d "$TARGET_DIR" >/dev/null

# Renombrar APP_NAME en common.env
sed -i "s/APP_NAME=\"MiAplicacion\"/APP_NAME=\"$APP_NAME\"/g" \
    "$TARGET_DIR/conf/common.env"

# Renombrar service file
mv "$TARGET_DIR/miapp.service" "$TARGET_DIR/${APP_NAME}.service"

sed -i "s/Mi Aplicacion/${APP_NAME}/g" "$TARGET_DIR/${APP_NAME}.service"
sed -i "s/miapp/start.sh/$APP_NAME/g" "$TARGET_DIR/${APP_NAME}.service"

# Preguntar por el intérprete
echo "Seleccione intérprete:"
echo "1) java"
echo "2) python3"
echo "3) tclsh"
echo "4) node"
echo "5) bash"
read -p "Opción (1-5): " OPT

case $OPT in
    1) INTER="java"; ARGS="-jar"; FILE="app.jar" ;;
    2) INTER="python3"; ARGS=""; FILE="main.py" ;;
    3) INTER="tclsh"; ARGS=""; FILE="app.tcl" ;;
    4) INTER="node"; ARGS=""; FILE="app.js" ;;
    5) INTER="bash"; ARGS=""; FILE="script.sh" ;;
    *) echo "Opción inválida"; exit 1 ;;
esac

# Setear configuración de intérprete
sed -i "s/APP_INTER=.*/APP_INTER=\"$INTER\"/g" "$TARGET_DIR/conf/common.env"
sed -i "s/INTER_ARGS=.*/INTER_ARGS=\"$ARGS\"/g" "$TARGET_DIR/conf/common.env"
sed -i "s/APP_EXEC=.*/APP_EXEC=\"$FILE\"/g" "$TARGET_DIR/conf/common.env"

# Crear archivo ejecutable vacío
touch "$TARGET_DIR/app/$FILE"

# Mensaje final
echo "✅ App generada correctamente."
echo "Directorio: $TARGET_DIR"
echo "Recuerda editar:"
echo "  - start.sh, stop.sh, restart.sh si deseas personalizarlos"
echo "  - conf/*.env"
echo "  - app/$FILE (tu aplicación)"
echo "  - ${APP_NAME}.service si usas systemd"


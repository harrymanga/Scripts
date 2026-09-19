#!/bin/bash
# install.sh — Instala jar_manager en ~/.local/bin (sin sudo) + lanzador .desktop.
set -e
cd "$(dirname "$0")"
DEST="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
mkdir -p "$DEST" "$APPS"
cp jar_manager.sh lang_es.sh lang_en.sh "$DEST/"
mkdir -p "$DEST/lib"
cp lib/jar_core.sh "$DEST/lib/"
chmod +x "$DEST/jar_manager.sh"
cat > "$APPS/jar-manager.desktop" <<EOF
[Desktop Entry]
Name=Jar Manager
Exec=$DEST/jar_manager.sh
Type=Application
Terminal=false
Categories=Utility;
EOF
echo "Instalado en $DEST (asegúrate de tener ~/.local/bin en tu PATH)."

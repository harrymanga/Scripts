#!/bin/bash
set -e

INSTALL_DIR="/usr/local/bin/jar-manager-pro"
DESKTOP_DIR="/usr/share/applications"

sudo mkdir -p "$INSTALL_DIR"
sudo cp -r bin/* "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/"*

# Lanzadores
sudo tee "$DESKTOP_DIR/jar-manager-yad.desktop" > /dev/null <<EOF
[Desktop Entry]
Name=Jar Manager Pro (YAD)
Exec=$INSTALL_DIR/jar-manager-yad
Type=Application
Terminal=false
Categories=Utility;
EOF

sudo tee "$DESKTOP_DIR/jar-manager-zenity.desktop" > /dev/null <<EOF
[Desktop Entry]
Name=Jar Manager Pro (Zenity)
Exec=$INSTALL_DIR/jar-manager-zenity
Type=Application
Terminal=false
Categories=Utility;
EOF

echo "Instalado correctamente."


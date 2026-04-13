#!/bin/bash

# Script para actualizar programas usando yay
# Lee la lista de programas desde un archivo de texto

# Configuración
PROGRAMS_FILE="${1:-packages.txt}"

# Verificar si paru está instalado (yay es un alias de paru en Fish)
AUR_HELPER="paru"
if ! command -v paru &> /dev/null; then
    # Intentar con yay por si acaso
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    else
        echo "Error: ni paru ni yay están instalados o no están en el PATH."
        echo ""
        echo "Diagnóstico:"
        echo "  SHELL: $SHELL"
        echo "  PATH: $PATH"
        exit 1
    fi
fi

# Verificar si el archivo existe
if [ ! -f "$PROGRAMS_FILE" ]; then
    echo "Error: El archivo '$PROGRAMS_FILE' no existe."
    echo "Uso: $0 [archivo_de_paquetes.txt]"
    exit 1
fi

# Leer y filtrar líneas no vacías ni comentadas
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Ignorar líneas vacías y comentarios
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue
    packages+=("$line")
done < "$PROGRAMS_FILE"

if [ ${#packages[@]} -eq 0 ]; then
    echo "No se encontraron paquetes en '$PROGRAMS_FILE'"
    exit 0
fi

echo "Paquetes a actualizar: ${packages[*]}"
echo ""

# Actualizar cada paquete
for pkg in "${packages[@]}"; do
    echo "==> Actualizando: $pkg"
    $AUR_HELPER -S --needed --noconfirm "$pkg"
    if [ $? -eq 0 ]; then
        echo "    ✓ $pkg actualizado"
    else
        echo "    ✗ Error al actualizar $pkg"
    fi
    echo ""
done

echo "Actualización completada."

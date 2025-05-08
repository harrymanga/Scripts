#!/bin/bash

# Verifica que Zenity esté instalado
if ! command -v zenity &> /dev/null; then
    echo "Zenity no está instalado. Instálalo con: sudo apt install zenity"
    exit 1
fi

# Carpeta base de montaje
MOUNT_BASE="/mnt/Isos"
sudo mkdir -p "$MOUNT_BASE"

# Selección de archivos y/o carpetas con Zenity
selection=$(zenity --file-selection --multiple --title="Selecciona archivos .iso o carpetas que los contengan" --separator="|" --file-filter="*.iso" --directory)

if [ -z "$selection" ]; then
    zenity --error --text="No seleccionaste ningún archivo o carpeta. Saliendo."
    exit 1
fi

# Convertir selección en array
IFS="|" read -r -a paths <<< "$selection"

# Procesar cada elemento seleccionado
for path in "${paths[@]}"; do

    if [ -f "$path" ]; then
        # Si es archivo .iso
        if [[ "$path" == *.iso ]]; then
            isofiles+=("$path")
        fi

    elif [ -d "$path" ]; then
        # Buscar archivos .iso dentro del directorio
        while IFS= read -r -d '' file; do
            isofiles+=("$file")
        done < <(find "$path" -type f -iname "*.iso" -print0)
    fi

done

# Verificar si se encontraron archivos .iso
if [ ${#isofiles[@]} -eq 0 ]; then
    zenity --error --text="No se encontraron archivos .iso válidos."
    exit 1
fi

# Montar cada archivo ISO
for isofile in "${isofiles[@]}"; do
    filename="${isofile##*/}"
    filename="${filename%.*}"
    mount_dir="$MOUNT_BASE/$filename"

    echo "Montando $isofile en $mount_dir"

    sudo mkdir -p "$mount_dir"

    if sudo mount -o loop "$isofile" "$mount_dir"; then
        echo "Montado correctamente: $isofile"
    else
        echo "Error al montar: $isofile"
        zenity --error --text="Error al montar: $filename"
        sudo rmdir "$mount_dir"
    fi
done

# Preguntar si desmontar
zenity --question --text="¿Deseas desmontar todos los ISOs montados ahora?" --ok-label="Sí" --cancel-label="No"
if [ $? -eq 0 ]; then
    echo "Desmontando imágenes ISO..."
    for mountpoint in "$MOUNT_BASE"/*; do
        if mountpoint -q "$mountpoint"; then
            sudo umount "$mountpoint"
            echo "Desmontado: $mountpoint"
            sudo rmdir "$mountpoint"
        fi
    done
    zenity --info --text="Todos los ISOs fueron desmontados."
else
    echo "Los ISOs permanecen montados en $MOUNT_BASE"
fi



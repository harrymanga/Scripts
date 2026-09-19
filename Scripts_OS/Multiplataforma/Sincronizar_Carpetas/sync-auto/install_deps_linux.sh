#!/bin/bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "No se pudo detectar la distribución."
    exit 1
fi

echo "Distribución detectada: $DISTRO"

if ! command -v python3 &> /dev/null
then
    echo "Instalando python3..."
    if [[ "$DISTRO" =~ (ubuntu|debian) ]]; then
        sudo apt update
        sudo apt install -y python3 python3-pip
    elif [[ "$DISTRO" =~ (fedora|centos) ]]; then
        sudo dnf install -y python3 python3-pip
    elif [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Sy --noconfirm python python-pip
    elif [[ "$DISTRO" == "opensuse" ]]; then
        sudo zypper install -y python3 python3-pip
    else
        echo "Distribución no soportada para instalación automática."
        exit 1
    fi
fi

if ! command -v pip3 &> /dev/null
then
    echo "pip3 no encontrado, instalando..."
    sudo apt install -y python3-pip
fi

pip3 install --user watchdog

if ! command -v rsync &> /dev/null
then
    echo "Instalando rsync..."
    if [[ "$DISTRO" =~ (ubuntu|debian) ]]; then
        sudo apt install -y rsync
    elif [[ "$DISTRO" =~ (fedora|centos) ]]; then
        sudo dnf install -y rsync
    elif [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Sy --noconfirm rsync
    elif [[ "$DISTRO" == "opensuse" ]]; then
        sudo zypper install -y rsync
    else
        echo "Distribución no soportada para instalación automática de rsync."
        exit 1
    fi
fi

echo "Dependencias instaladas correctamente."

#!/bin/bash
# run.sh — Punto de entrada único: crea .venv, instala dependencias y ejecuta.
# Uso: ./run.sh   (en Windows: run.bat)
# Nota: además requiere ffmpeg (el programa intenta instalarlo solo).
set -e
cd "$(dirname "$0")"
[ -x .venv/bin/python ] || python3 -m venv .venv
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt
exec .venv/bin/python conversor_formatos_audio.py "$@"

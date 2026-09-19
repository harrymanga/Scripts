#!/bin/bash
# run.sh — Punto de entrada único: crea .venv, instala dependencias y ejecuta.
# Uso: ./run.sh   (en Windows: run.bat)
# Entrada: main2.py (GUI tkinter). main.py es la versión CLI con rutas fijas.
set -e
cd "$(dirname "$0")"
[ -x .venv/bin/python ] || python3 -m venv .venv
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt
exec .venv/bin/python main2.py "$@"

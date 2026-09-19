"""Interfaz de Limpieza de Windows (versión única consolidada).

Ubicación canónica: Scripts_OS/Windows/Limpieza_De_Cache/
Requiere Windows. Ejecuta limpieza_completa.bat con el modo elegido:
  full (por defecto), temp o logs.
"""
import locale
import os
import subprocess
import tkinter as tk
from tkinter import scrolledtext

STRINGS = {
    "es": {
        "title": "Interfaz de Limpieza de Windows",
        "btn_full": "Ejecutar Limpieza Completa",
        "btn_logs": "Limpiar Logs",
        "btn_temp": "Limpiar Temporales",
    },
    "en": {
        "title": "Windows Cleanup Interface",
        "btn_full": "Run Full Cleanup",
        "btn_logs": "Clean Logs",
        "btn_temp": "Clean Temp Files",
    },
}


def detect_lang():
    """Español por defecto; inglés si la cultura del sistema es en-*."""
    try:
        code = (locale.getdefaultlocale()[0] or "es")[:2].lower()
    except Exception:
        code = "es"
    return code if code in STRINGS else "es"


T = STRINGS[detect_lang()]

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BAT_PATH = os.path.join(BASE_DIR, "limpieza_completa.bat")


def run_script(mode=""):
    command = f'"{BAT_PATH}" {mode}'.strip()
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        shell=True,
    )
    output, error = process.communicate()
    console.insert(tk.END, output + "\n")
    if error:
        console.insert(tk.END, "ERROR: " + error + "\n")
    console.yview(tk.END)


app = tk.Tk()
app.title(T["title"])

frame = tk.Frame(app)
frame.pack(pady=20)

# Botón para ejecutar la limpieza completa (modo full).
btn_run_all = tk.Button(frame, text=T["btn_full"], command=lambda: run_script("full"))
btn_run_all.pack(side=tk.LEFT, padx=10)

# Botón para limpiar archivos .log y visor de eventos (modo logs).
btn_clean_logs = tk.Button(frame, text=T["btn_logs"], command=lambda: run_script("logs"))
btn_clean_logs.pack(side=tk.LEFT, padx=10)

# Botón para limpiar archivos temporales (modo temp).
btn_clean_temp = tk.Button(frame, text=T["btn_temp"], command=lambda: run_script("temp"))
btn_clean_temp.pack(side=tk.LEFT, padx=10)

# Área de texto desplazable para la salida del script.
console = scrolledtext.ScrolledText(app, height=10, width=100)
console.pack(padx=10, pady=10)

app.mainloop()

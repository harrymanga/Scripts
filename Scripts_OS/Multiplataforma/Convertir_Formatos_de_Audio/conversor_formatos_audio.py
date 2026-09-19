"""Conversor de Formatos de Audio — versión única corregida.

GUI tkinter (hilos) para convertir entre formatos con pydub + ffmpeg.
Las dependencias Python se instalan solas al ejecutar (ver ensure_dep);
ffmpeg (binario de sistema) se intenta instalar solo y, si no es posible,
se indica el comando exacto. El usuario nunca debe instalar nada a mano
antes de ejecutar.
"""
import locale
import os
import platform
import shutil
import subprocess
import sys
import threading
import tkinter as tk
from tkinter import filedialog, messagebox

STRINGS = {
    "es": {
        "title": "Conversor de archivos de audio",
        "btn_search": "Buscar archivo",
        "btn_destdir": "Carpeta destino",
        "btn_export": "Exportar a formato",
        "dlg_file": "Seleccionar archivo",
        "no_file": "Ningún archivo seleccionado",
        "importing": "Importando archivo...",
        "selected": "Archivo seleccionado: ",
        "status_running": "Proceso en curso...",
        "status_done": "Proceso finalizado\nArchivo creado: ",
        "err_title": "Error",
        "err_open": "No pudo completarse la acción",
        "err_unsupported": "Formato no soportado",
        "err_export": "Hubo un problema al realizar la operación",
        "ask_dep": "Falta la librería '{pkg}'.\n¿Quieres instalarla ahora?",
        "dep_title": "Instalar dependencia",
        "dep_fail": "No se pudo instalar '{pkg}':\n{err}",
        "ask_ffmpeg": "Falta 'ffmpeg' (necesario para convertir).\n¿Quieres instalarlo ahora?",
        "ffmpeg_title": "Instalar ffmpeg",
        "ffmpeg_fail": "No se pudo instalar ffmpeg automáticamente.\nInstálalo manualmente:\n{cmd}",
    },
    "en": {
        "title": "Audio file converter",
        "btn_search": "Browse file",
        "btn_destdir": "Destination folder",
        "btn_export": "Export to format",
        "dlg_file": "Select file",
        "no_file": "No file selected",
        "importing": "Importing file...",
        "selected": "Selected file: ",
        "status_running": "Working...",
        "status_done": "Finished\nCreated file: ",
        "err_title": "Error",
        "err_open": "Action could not be completed",
        "err_unsupported": "Unsupported format",
        "err_export": "There was a problem during the operation",
        "ask_dep": "Missing library '{pkg}'.\nDo you want to install it now?",
        "dep_title": "Install dependency",
        "dep_fail": "Could not install '{pkg}':\n{err}",
        "ask_ffmpeg": "Missing 'ffmpeg' (required to convert).\nDo you want to install it now?",
        "ffmpeg_title": "Install ffmpeg",
        "ffmpeg_fail": "Could not install ffmpeg automatically.\nInstall it manually:\n{cmd}",
    },
}

# Formatos ofrecidos (etiqueta de botón -> formato real de pydub/ffmpeg).
FORMATS = ["wav", "mp3", "ogg", "mp2", "mp4", "m4a", "aiff", "au", "flv"]

MANUAL_FFMPEG = {
    "Linux": "sudo apt install -y ffmpeg  (o dnf/pacman según tu distro)",
    "Windows": "winget install -e --id Gyan.FFmpeg",
    "Darwin": "brew install ffmpeg",
}


def detect_lang():
    try:
        code = (locale.getdefaultlocale()[0] or "es")[:2].lower()
    except Exception:
        code = "es"
    return code if code in STRINGS else "es"


T = STRINGS[detect_lang()]


def ensure_dep(module, pkg):
    try:
        return __import__(module)
    except ImportError:
        if not messagebox.askyesno(T["dep_title"], T["ask_dep"].format(pkg=pkg)):
            sys.exit(1)
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", pkg])
        except Exception as e:
            messagebox.showerror("Error", T["dep_fail"].format(pkg=pkg, err=e))
            sys.exit(1)
        return __import__(module)


def detect_distro_linux():
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("ID="):
                    return line.strip().split("=", 1)[1].strip('"').lower()
    except Exception:
        pass
    return ""


def ensure_ffmpeg(parent):
    """Garantiza ffmpeg: intenta instalarlo solo; solo molesta si falla."""
    if shutil.which("ffmpeg"):
        return True
    sistema = platform.system()
    cmd = None
    if sistema == "Linux":
        distro = detect_distro_linux()
        managers = {
            "ubuntu": ["sudo", "apt-get", "install", "-y", "ffmpeg"],
            "debian": ["sudo", "apt-get", "install", "-y", "ffmpeg"],
            "fedora": ["sudo", "dnf", "install", "-y", "ffmpeg"],
            "arch": ["sudo", "pacman", "-Sy", "--noconfirm", "ffmpeg"],
        }
        cmd = managers.get(distro)
    elif sistema == "Windows":
        cmd = ["winget", "install", "-e", "--id", "Gyan.FFmpeg"]
    elif sistema == "Darwin":
        cmd = ["brew", "install", "ffmpeg"]

    if cmd is None:
        messagebox.showerror(
            "Error", T["ffmpeg_fail"].format(cmd=MANUAL_FFMPEG.get(sistema, "ffmpeg"))
        )
        return False
    if not messagebox.askyesno(T["ffmpeg_title"], T["ask_ffmpeg"], parent=parent):
        return False
    try:
        subprocess.check_call(cmd)
    except Exception:
        messagebox.showerror(
            "Error", T["ffmpeg_fail"].format(cmd=MANUAL_FFMPEG.get(sistema, " ".join(cmd)))
        )
        return False
    if not shutil.which("ffmpeg"):
        messagebox.showerror(
            "Error", T["ffmpeg_fail"].format(cmd=MANUAL_FFMPEG.get(sistema, "ffmpeg"))
        )
        return False
    return True


class ConverterApp:
    def __init__(self, root):
        self.root = root
        self.root.title(T["title"])
        self.root.geometry("700x550")

        self.audio = None
        self.nom = ""
        self.ex = ""
        self.ruta = ""
        self.file = ""
        self.ty = ""
        self.executing = False

        self.current_dir = tk.StringVar(value=os.getcwd())

        entry_dir = tk.Entry(root, textvariable=self.current_dir, width=90)
        entry_dir.place(x=0, y=0)

        self.eti_name = tk.Label(root, text=T["no_file"], width=80)
        self.eti_name.place(x=26, y=90)

        tk.Button(root, text=T["btn_search"], command=self.busca_archivo).place(x=294, y=158)

        self.estat = tk.Label(root, width=80)
        self.estat.place(x=26, y=190)

        tk.Button(root, text=T["btn_destdir"], command=self.cambia_dir).place(x=292, y=490)

        positions = [(26, 240), (26, 290), (26, 340), (380, 240), (380, 290),
                     (380, 340), (26, 390), (380, 390), (203, 440)]
        for fmt, (x, y) in zip(FORMATS, positions):
            tk.Button(root, text=f"{T['btn_export']} .{fmt.upper()}", width=40,
                      command=lambda f=fmt: self.inicia(f)).place(x=x, y=y)

    def busca_archivo(self):
        self.eti_name.configure(text=T["importing"])
        if self.executing:
            return
        self.estat.configure(text="")
        ruta = filedialog.askopenfilename(
            initialdir="/", title=T["dlg_file"],
            filetypes=[("Audio", "*.mp3 *.wav *.ogg *.flv *.mp2 *.mp4 *.m4a *.aiff *.aif *.au"),
                       ("Todos", "*.*")])
        if not ruta:
            self.eti_name.configure(
                text=(T["selected"] + self.file) if self.file else T["no_file"])
            return
        self.ruta = ruta
        self.file = ruta.split("/")[-1]
        self.nom, self.ex = os.path.splitext(self.file)
        self.ex = self.ex.lower()
        self.eti_name.configure(text=T["selected"] + self.file)
        self.abrir_archivo()

    def abrir_archivo(self):
        loaders = {
            ".mp3": "from_mp3", ".ogg": "from_ogg", ".wav": "from_wav",
            ".flv": "from_flv", ".mp4": "from_file", ".m4a": "from_file",
            ".aiff": "from_aiff", ".aif": "from_aiff", ".au": "from_au",
        }
        loader = loaders.get(self.ex)
        if loader is None:
            messagebox.showwarning(T["err_title"], T["err_unsupported"])
            self.eti_name.configure(text=T["no_file"])
            self.audio = None
            return
        try:
            self.audio = getattr(pydub.AudioSegment, loader)(self.ruta)
        except Exception:
            messagebox.showwarning(T["err_title"], T["err_open"])
            self.eti_name.configure(text=T["no_file"])
            self.nom = ""
            self.audio = None

    def cambia_dir(self):
        if self.executing:
            return
        directorio = filedialog.askdirectory()
        if directorio:
            os.chdir(directorio)
            self.current_dir.set(os.getcwd())

    def convert(self):
        if self.audio is None:
            return
        self.executing = True
        try:
            self.estat.configure(text=T["status_running"])
            name = self.nom + "." + self.ty
            if name == self.file:
                name = self.nom + "(copia)." + self.ty
            self.audio.export(name, format=self.ty)
            self.estat.configure(text=T["status_done"] + name)
        except Exception:
            messagebox.showwarning(T["err_title"], T["err_export"])
            self.estat.configure(text="")
        self.executing = False

    def inicia(self, tip):
        if self.executing or self.audio is None:
            return
        if not ensure_ffmpeg(self.root):
            return
        self.ty = tip
        threading.Thread(target=self.convert, daemon=True).start()


pydub = None


def main():
    global pydub
    _root = tk.Tk()
    _root.withdraw()
    pydub = ensure_dep("pydub", "pydub")
    _root.destroy()
    root = tk.Tk()
    ConverterApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()

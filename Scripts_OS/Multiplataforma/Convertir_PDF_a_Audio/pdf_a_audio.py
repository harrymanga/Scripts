"""PDF a Audio — versión única consolidada (variante Tk).

Convierte un PDF a MP3 con Google Text-to-Speech. Reemplaza a
Pdf_a_Audio_Qt.py (exigía PyQt5 solo para un diálogo) y Pdf_a_Audio_Tk.py
(fallaba con traceback al cancelar el diálogo).

Las dependencias se instalan solas al ejecutar (ver ensure_dep): el
usuario nunca debe instalar nada manualmente antes.
"""
import locale
import os
import subprocess
import sys
import tkinter as tk
from tkinter import filedialog, messagebox

STRINGS = {
    "es": {
        "ask_file": "Seleccione un archivo PDF",
        "cancelled": "Ningún archivo seleccionado. Saliendo.",
        "reading": "Leyendo PDF. Por favor, espere un momento...",
        "saved": "Audio guardado en: {path}",
        "err_pdf": "No se pudo leer el PDF:\n{err}",
        "err_tts": "No se pudo generar el audio (revisa tu conexión):\n{err}",
        "ask_dep": "Falta la librería '{pkg}'.\n¿Quieres instalarla ahora?",
        "dep_title": "Instalar dependencia",
        "dep_fail": "No se pudo instalar '{pkg}':\n{err}",
    },
    "en": {
        "ask_file": "Select a PDF file",
        "cancelled": "No file selected. Exiting.",
        "reading": "Reading PDF. Please wait...",
        "saved": "Audio saved to: {path}",
        "err_pdf": "Could not read the PDF:\n{err}",
        "err_tts": "Could not generate audio (check your connection):\n{err}",
        "ask_dep": "Missing library '{pkg}'.\nDo you want to install it now?",
        "dep_title": "Install dependency",
        "dep_fail": "Could not install '{pkg}':\n{err}",
    },
}


def detect_lang():
    try:
        code = (locale.getdefaultlocale()[0] or "es")[:2].lower()
    except Exception:
        code = "es"
    return code if code in STRINGS else "es"


T = STRINGS[detect_lang()]


def ensure_dep(module, pkg):
    """Importa module; si falta, ofrece instalar pkg vía pip automáticamente."""
    try:
        return __import__(module)
    except ImportError:
        root = tk.Tk()
        root.withdraw()
        if not messagebox.askyesno(T["dep_title"], T["ask_dep"].format(pkg=pkg)):
            sys.exit(1)
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", pkg])
        except Exception as e:
            messagebox.showerror("Error", T["dep_fail"].format(pkg=pkg, err=e))
            sys.exit(1)
        return __import__(module)


def main():
    pypdf = ensure_dep("pypdf", "pypdf")
    gtts_mod = ensure_dep("gtts", "gTTS")

    root = tk.Tk()
    root.withdraw()
    filelocation = filedialog.askopenfilename(
        title=T["ask_file"], filetypes=[("PDF", "*.pdf")]
    )
    if not filelocation:
        messagebox.showinfo(T["ask_file"], T["cancelled"])
        return

    print(T["reading"])
    try:
        reader = pypdf.PdfReader(filelocation)
        text = "".join((page.extract_text() or "") for page in reader.pages)
    except Exception as e:
        messagebox.showerror("Error", T["err_pdf"].format(err=e))
        sys.exit(1)

    out = os.path.join(os.path.dirname(filelocation),
                       os.path.splitext(os.path.basename(filelocation))[0] + ".mp3")
    try:
        gtts_mod.gTTS(text=text, lang="es", slow=False).save(out)
    except Exception as e:
        messagebox.showerror("Error", T["err_tts"].format(err=e))
        sys.exit(1)

    print(T["saved"].format(path=out))
    messagebox.showinfo(T["ask_file"], T["saved"].format(path=out))


if __name__ == "__main__":
    main()

"""Audio a Texto — versión única corregida.

Convierte un archivo de audio (WAV/AIFF/FLAC) a texto con reconocimiento
de voz de Google. Las dependencias se instalan solas al ejecutar (ver
ensure_dep): el usuario nunca debe instalar nada manualmente antes.
"""
import locale
import os
import subprocess
import sys
import tkinter as tk
from tkinter import filedialog, messagebox

STRINGS = {
    "es": {
        "ask_file": "Ingrese un archivo de audio (WAV, AIFF o FLAC)",
        "cancelled": "Ningún archivo seleccionado. Saliendo.",
        "reading": "Transcribiendo audio. Por favor, espere un momento...",
        "saved": "Texto guardado en: {path}\n\n{text}",
        "err_sr": "Error de reconocimiento: {err}",
        "err_api": "Servicio no disponible (revisa tu conexión).",
        "err_unintelligible": "No se pudo entender el audio.",
        "ask_dep": "Falta la librería '{pkg}'.\n¿Quieres instalarla ahora?",
        "dep_title": "Instalar dependencia",
        "dep_fail": "No se pudo instalar '{pkg}':\n{err}",
    },
    "en": {
        "ask_file": "Select an audio file (WAV, AIFF or FLAC)",
        "cancelled": "No file selected. Exiting.",
        "reading": "Transcribing audio. Please wait...",
        "saved": "Text saved to: {path}\n\n{text}",
        "err_sr": "Recognition error: {err}",
        "err_api": "Service unavailable (check your connection).",
        "err_unintelligible": "Could not understand the audio.",
        "ask_dep": "Missing library '{pkg}'.\nDo you want to install it now?",
        "dep_title": "Install dependency",
        "dep_fail": "Could not install '{pkg}':\n{err}",
    },
}

# Idioma de reconocimiento (código BCP-47). Español por defecto.
RECOGNIZE_LANG = os.environ.get("AUDIO_LANG", "es-ES")


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
    sr = ensure_dep("speech_recognition", "SpeechRecognition")

    root = tk.Tk()
    root.withdraw()
    print(T["ask_file"])
    filelocation = filedialog.askopenfilename(
        filetypes=[("Audio", "*.wav *.aiff *.aif *.flac"), ("Todos", "*.*")]
    )
    if not filelocation:
        print(T["cancelled"])
        return

    r = sr.Recognizer()
    print(T["reading"])
    try:
        with sr.AudioFile(filelocation) as source:
            audio = r.listen(source)
        text = r.recognize_google(audio, language=RECOGNIZE_LANG)
    except sr.UnknownValueError:
        messagebox.showerror("Error", T["err_unintelligible"])
        sys.exit(1)
    except sr.RequestError:
        messagebox.showerror("Error", T["err_api"])
        sys.exit(1)
    except Exception as e:
        messagebox.showerror("Error", T["err_sr"].format(err=e))
        sys.exit(1)

    out = os.path.join(os.path.dirname(filelocation),
                       os.path.splitext(os.path.basename(filelocation))[0] + ".txt")
    with open(out, "w", encoding="utf-8") as f:
        f.write(text)
    print(T["saved"].format(path=out, text=text))


if __name__ == "__main__":
    main()

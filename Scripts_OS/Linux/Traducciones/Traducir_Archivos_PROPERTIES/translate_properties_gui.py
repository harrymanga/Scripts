#!/usr/bin/env python3
# translate_properties_gui.py
# GUI sencillo en Tkinter para traducir archivos .properties usando DeepL
# - Selección de carpeta origen y destino
# - Selección de idiomas (source/target)
# - Proceso visual con log y reporte
#
# Dependencias: requests, tkinter (incluido en Python estándar), ttk (tkinter)
# Instalación de requests: pip install requests

import os
import sys
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import requests
import time

API_URL = "https://api-free.deepl.com/v2/translate"

class TranslatorGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Traductor .properties (DeepL)")
        self.geometry("720x520")
        self.create_widgets()

    def create_widgets(self):
        frm = ttk.Frame(self, padding=10)
        frm.pack(fill=tk.BOTH, expand=True)

        # Entrada: carpeta origen y destino
        ttk.Label(frm, text="Carpeta origen:").grid(row=0, column=0, sticky=tk.W)
        self.src_entry = ttk.Entry(frm, width=60)
        self.src_entry.grid(row=0, column=1, sticky=tk.W)
        ttk.Button(frm, text="…", width=3, command=self.browse_src).grid(row=0, column=2)

        ttk.Label(frm, text="Carpeta destino:").grid(row=1, column=0, sticky=tk.W)
        self.dst_entry = ttk.Entry(frm, width=60)
        self.dst_entry.grid(row=1, column=1, sticky=tk.W)
        ttk.Button(frm, text="…", width=3, command=self.browse_dst).grid(row=1, column=2)

        ttk.Label(frm, text="DeepL API Key:").grid(row=2, column=0, sticky=tk.W)
        self.key_entry = ttk.Entry(frm, width=60, show="*")
        self.key_entry.grid(row=2, column=1, sticky=tk.W)

        ttk.Label(frm, text="Idioma origen:").grid(row=3, column=0, sticky=tk.W)
        self.src_lang = ttk.Entry(frm, width=10)
        self.src_lang.insert(0, "EN")
        self.src_lang.grid(row=3, column=1, sticky=tk.W)

        ttk.Label(frm, text="Idioma destino:").grid(row=3, column=1, sticky=tk.E)
        self.tgt_lang = ttk.Entry(frm, width=10)
        self.tgt_lang.insert(0, "ES")
        self.tgt_lang.grid(row=3, column=2, sticky=tk.W)

        self.start_btn = ttk.Button(frm, text="Traducir .properties", command=self.start_translate)
        self.start_btn.grid(row=4, column=0, columnspan=3, pady=10)

        ttk.Label(frm, text="Log:").grid(row=5, column=0, sticky=tk.W, pady=(5,0))
        self.log = scrolledtext.ScrolledText(frm, width=90, height=20)
        self.log.grid(row=6, column=0, columnspan=3, sticky=tk.NSEW)

        # Configurar grid weight
        frm.rowconfigure(6, weight=1)
        frm.columnconfigure(1, weight=1)

    def browse_src(self):
        d = filedialog.askdirectory()
        if d: self.src_entry.delete(0, tk.END); self.src_entry.insert(0, d)

    def browse_dst(self):
        d = filedialog.askdirectory()
        if d: self.dst_entry.delete(0, tk.END); self.dst_entry.insert(0, d)

    def start_translate(self):
        src = self.src_entry.get().strip()
        dst = self.dst_entry.get().strip()
        key = self.key_entry.get().strip()
        src_l = self.src_lang.get().strip().upper()
        tgt_l = self.tgt_lang.get().strip().upper()

        if not src or not dst or not key:
            messagebox.showerror("Error", "Selecciona carpeta origen, destino y proporciona la API key de DeepL.")
            return
        os.makedirs(dst, exist_ok=True)
        self.start_btn.config(state=tk.DISABLED)
        threading.Thread(target=self.translate_folder, args=(src, dst, key, src_l, tgt_l), daemon=True).start()

    def log_msg(self, msg):
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        self.log.insert(tk.END, f"[{timestamp}] {msg}\n")
        self.log.see(tk.END)
        self.update_idletasks()

    def should_translate(self, v):
        v = v.strip()
        if v == "": return False
        if v.lower() in ("true","false","on","off"): return False
        if all(ch.isdigit() or ch in "., " for ch in v): return False
        if any(tok in v for tok in ("/","\\","http:","https:","ftp:","@","%s","%d","${","{0}")): return False
        return True

    def translate_block(self, texts, key, api_key, src_lang, tgt_lang):
        # texts: list of strings to translate; join with a delimiter unlikely to appear
        delimiter = "\u001F"
        block = delimiter.join(texts)
        for attempt in range(5):
            try:
                r = requests.post(API_URL, data={
                    "auth_key": api_key,
                    "text": block,
                    "source_lang": src_lang,
                    "target_lang": tgt_lang
                }, timeout=30)
                r.raise_for_status()
                j = r.json()
                translated = j["translations"][0]["text"]
                return translated.split(delimiter)
            except Exception as e:
                self.log_msg(f"Intento {attempt+1} fallido para {key}: {e}")
                time.sleep(2 ** attempt)
        return None

    def process_file(self, path, dst, api_key, src_lang, tgt_lang):
        base = os.path.basename(path)
        out = os.path.join(dst, base.replace(".properties", "_traducido.properties"))
        self.log_msg(f"Procesando {path} -> {out}")
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()

        indices = []
        originals = []
        for i, line in enumerate(lines):
            if line.strip() == "" or line.lstrip().startswith(("#","!")):
                continue
            if "=" in line or ":" in line:
                sep_pos = line.find("=") if "=" in line else line.find(":")
                key = line[:sep_pos].strip()
                val = line[sep_pos+1:].strip()
                if self.should_translate(val):
                    indices.append(i)
                    originals.append(val)
            else:
                if self.should_translate(line):
                    indices.append(i)
                    originals.append(line)

        if not indices:
            self.log_msg(f"No hay valores traducibles en {path}. Copiando.")
            with open(out, "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + ("\n" if lines and lines[-1] != "" else ""))
            return True

        translated = self.translate_block(originals, base, api_key, src_lang, tgt_lang)
        if translated is None:
            self.log_msg(f"ERROR: No se pudo traducir {path}")
            return False

        for idx, tr in zip(indices, translated):
            line = lines[idx]
            if "=" in line or ":" in line:
                sep_pos = line.find("=") if "=" in line else line.find(":")
                prefix = line[:sep_pos+1]
                lines[idx] = f"{prefix}{tr}"
            else:
                lines[idx] = tr

        with open(out, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + ("\n" if lines and lines[-1] != "" else ""))

        self.log_msg(f"[OK] {path} -> {out}")
        return True

    def translate_folder(self, src, dst, api_key, src_lang, tgt_lang):
        files = [os.path.join(src, f) for f in os.listdir(src) if f.endswith(".properties")]
        if not files:
            self.log_msg("No se encontraron archivos .properties en la carpeta origen.")
            self.start_btn.config(state=tk.NORMAL)
            return
        for f in files:
            try:
                self.process_file(f, dst, api_key, src_lang, tgt_lang)
            except Exception as e:
                self.log_msg(f"ERROR procesando {f}: {e}")
        self.log_msg("Traducción finalizada.")
        self.start_btn.config(state=tk.NORMAL)


if __name__ == '__main__':
    app = TranslatorGUI()
    app.mainloop()

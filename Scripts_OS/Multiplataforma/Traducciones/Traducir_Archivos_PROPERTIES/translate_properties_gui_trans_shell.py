#!/usr/bin/env python3
# translate_properties_gui_trans_shell.py
# - GUI en Tkinter que utiliza translate-shell ('trans') a través de subprocess
# - Multiarchivo, multi-idioma, multimotor (según trans)
# - Preserva keys y placeholders
#
# Dependencias: Python 3, tkinter, translate-shell instalado (comando 'trans')
#
# Uso: Ejecutar el script y seleccionar carpetas y opciones en la GUI.

import os
import subprocess
import threading
import time
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext

def check_trans():
    from shutil import which
    return which("trans") is not None

class App(ttk.Frame):
    def __init__(self, master):
        super().__init__(master, padding=10)
        self.master = master
        master.title("Traductor .properties (trans)")
        master.geometry("760x540")
        self.grid(sticky="nsew")
        self.create_widgets()

    def create_widgets(self):
        ttk.Label(self, text="Carpeta origen:").grid(row=0, column=0, sticky="w")
        self.src = ttk.Entry(self, width=60)
        self.src.grid(row=0, column=1, sticky="w")
        ttk.Button(self, text="...", width=3, command=self.browse_src).grid(row=0, column=2)

        ttk.Label(self, text="Carpeta destino:").grid(row=1, column=0, sticky="w")
        self.dst = ttk.Entry(self, width=60)
        self.dst.grid(row=1, column=1, sticky="w")
        ttk.Button(self, text="...", width=3, command=self.browse_dst).grid(row=1, column=2)

        ttk.Label(self, text="Motor (engine):").grid(row=2, column=0, sticky="w")
        self.engine = ttk.Combobox(self, values=["google", "bing", "yandex", "deepl", "apertium"], width=12)
        self.engine.set("google")
        self.engine.grid(row=2, column=1, sticky="w")

        ttk.Label(self, text="Idioma origen:").grid(row=3, column=0, sticky="w")
        self.src_lang = ttk.Entry(self, width=10); self.src_lang.insert(0, "auto")
        self.src_lang.grid(row=3, column=1, sticky="w")

        ttk.Label(self, text="Idioma destino:").grid(row=3, column=1, sticky="e")
        self.dst_lang = ttk.Entry(self, width=10); self.dst_lang.insert(0, "es")
        self.dst_lang.grid(row=3, column=2, sticky="w")

        self.start_btn = ttk.Button(self, text="Traducir .properties", command=self.start)
        self.start_btn.grid(row=4, column=0, columnspan=3, pady=8)

        ttk.Label(self, text="Log:").grid(row=5, column=0, sticky="w")
        self.log = scrolledtext.ScrolledText(self, width=100, height=20)
        self.log.grid(row=6, column=0, columnspan=3, sticky="nsew")

        self.rowconfigure(6, weight=1)
        self.columnconfigure(1, weight=1)

    def browse_src(self):
        d = filedialog.askdirectory()
        if d: self.src.delete(0, tk.END); self.src.insert(0, d)

    def browse_dst(self):
        d = filedialog.askdirectory()
        if d: self.dst.delete(0, tk.END); self.dst.insert(0, d)

    def log_msg(self, msg):
        ts = time.strftime("%Y-%m-%d %H:%M:%S")
        self.log.insert(tk.END, f"[{ts}] {msg}\n")
        self.log.see(tk.END)
        self.update_idletasks()

    def should_translate(self, v: str) -> bool:
        v = v.strip()
        if not v: return False
        if v.lower() in ("true","false","on","off"): return False
        if all(ch.isdigit() or ch in "., " for ch in v): return False
        if any(tok in v for tok in ("/","\\","http:","https:","ftp:","@","%s","%d","${","{0}")): return False
        return True

    def translate_block(self, texts, engine, src_lang, dst_lang):
        delimiter = "\u001F"
        block = delimiter.join(texts)
        cmd = ["trans", "-e", engine, "-b", f"{src_lang}:{dst_lang}", block]
        attempts = 0
        while attempts < 5:
            try:
                res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
                if res.returncode == 0:
                    return res.stdout.split(delimiter)
                else:
                    self.log_msg(f"trans error (code {res.returncode}): {res.stderr.strip()}")
            except Exception as e:
                self.log_msg(f"Exception running trans: {e}")
            attempts += 1
            time.sleep(2 ** attempts)
        return None

    def process_file(self, path, dst_dir, engine, src_lang, dst_lang):
        base = os.path.basename(path)
        out = os.path.join(dst_dir, base.replace(".properties", "_traducido.properties"))
        self.log_msg(f"Procesando {path} -> {out}")
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()

        indices = []
        originals = []
        for i, line in enumerate(lines):
            if line.strip() == "" or line.lstrip().startswith(("#","!")):
                continue
            if "=" in line or ":" in line:
                sep = "=" if "=" in line else ":"
                sep_pos = line.find(sep)
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

        translated = self.translate_block(originals, engine, src_lang, dst_lang)
        if translated is None:
            self.log_msg(f"ERROR: No se pudo traducir {path}")
            return False

        for idx, tr in zip(indices, translated):
            line = lines[idx]
            if "=" in line or ":" in line:
                sep = "=" if "=" in line else ":"
                sep_pos = line.find(sep)
                prefix = line[:sep_pos+1]
                lines[idx] = f"{prefix}{tr}"
            else:
                lines[idx] = tr

        with open(out, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + ("\n" if lines and lines[-1] != "" else ""))
        self.log_msg(f"[OK] {path} -> {out}")
        return True

    def start(self):
        if not check_trans():
            messagebox.showerror("Error", "translate-shell ('trans') no está instalado o no está en PATH.")
            return
        src = self.src.get().strip()
        dst = self.dst.get().strip()
        engine = self.engine.get().strip()
        src_lang = self.src_lang.get().strip() or "auto"
        dst_lang = self.dst_lang.get().strip() or "es"
        if not src or not dst:
            messagebox.showerror("Error", "Selecciona carpeta origen y destino.")
            return
        os.makedirs(dst, exist_ok=True)
        self.start_btn.config(state="disabled")
        threading.Thread(target=self.run_translation, args=(src,dst,engine,src_lang,dst_lang), daemon=True).start()

    def run_translation(self, src, dst, engine, src_lang, dst_lang):
        files = [os.path.join(src,f) for f in os.listdir(src) if f.endswith(".properties")]
        if not files:
            self.log_msg("No se encontraron archivos .properties en la carpeta origen.")
            self.start_btn.config(state="normal")
            return
        for f in files:
            try:
                self.process_file(f, dst, engine, src_lang, dst_lang)
            except Exception as e:
                self.log_msg(f"ERROR procesando {f}: {e}")
        self.log_msg("Traducción finalizada.")
        self.start_btn.config(state="normal")

if __name__ == '__main__':
    root = tk.Tk()
    app = App(root)
    root.mainloop()

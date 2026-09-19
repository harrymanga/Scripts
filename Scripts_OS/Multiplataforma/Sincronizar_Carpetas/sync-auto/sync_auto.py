import locale
import os
import platform
import subprocess
import sys
import threading
import tkinter as tk
from tkinter import messagebox, filedialog

STRINGS = {
    "es": {
        "ask_dep_title": "Instalar dependencia",
        "ask_dep": "La librería 'watchdog' no está instalada.\n¿Quieres instalarla ahora?",
        "dep_needed": "La librería watchdog es necesaria. Cerrando programa.",
        "warn_title": "Aviso",
        "no_distro": "No se pudo detectar o no está soportada la distro '{distro}'.\nPor favor instala rsync manualmente.",
        "ask_rsync_title": "Instalar rsync",
        "ask_rsync": "No se encontró 'rsync' instalado.\n¿Quieres instalarlo ahora con '{cmd}'?",
        "rsync_ok": "rsync instalado correctamente.",
        "rsync_fail": "No se pudo instalar rsync automáticamente:\n{err}",
        "rsync_needed": "rsync es necesario para la sincronización. Cerrando programa.",
        "bad_os": "Sistema operativo {sistema} no soportado.",
        "sync_error": "Error al sincronizar: {err}",
        "sync_done": "Sincronización completa.",
        "err_no_src": "La carpeta origen no existe.",
        "warn_no_dst": "La carpeta destino {d} no existe.",
        "monitoring": "Monitoreando cambios...",
        "title": "Sincronizador Automático de Carpetas",
        "lbl_src": "Carpeta Origen:",
        "btn_src": "Seleccionar Origen",
        "lbl_dst": "Carpetas Destino (una por línea):",
        "btn_start": "Iniciar Monitoreo",
    },
    "en": {
        "ask_dep_title": "Install dependency",
        "ask_dep": "The 'watchdog' library is not installed.\nDo you want to install it now?",
        "dep_needed": "The watchdog library is required. Closing program.",
        "warn_title": "Warning",
        "no_distro": "Could not detect or distro '{distro}' is not supported.\nPlease install rsync manually.",
        "ask_rsync_title": "Install rsync",
        "ask_rsync": "No 'rsync' found installed.\nDo you want to install it now with '{cmd}'?",
        "rsync_ok": "rsync installed successfully.",
        "rsync_fail": "Could not install rsync automatically:\n{err}",
        "rsync_needed": "rsync is required for synchronization. Closing program.",
        "bad_os": "Operating system {sistema} not supported.",
        "sync_error": "Error while syncing: {err}",
        "sync_done": "Synchronization complete.",
        "err_no_src": "Source folder does not exist.",
        "warn_no_dst": "Destination folder {d} does not exist.",
        "monitoring": "Monitoring changes...",
        "title": "Automatic Folder Synchronizer",
        "lbl_src": "Source Folder:",
        "btn_src": "Select Source",
        "lbl_dst": "Destination Folders (one per line):",
        "btn_start": "Start Monitoring",
    },
}


def detect_lang():
    """Español por defecto; inglés si el locale del sistema es en-*."""
    try:
        code = (locale.getdefaultlocale()[0] or "es")[:2].lower()
    except Exception:
        code = "es"
    return code if code in STRINGS else "es"


T = STRINGS[detect_lang()]

# Intentar importar watchdog, si no está, instalarlo
def instalar_watchdog():
    try:
        import watchdog
    except ImportError:
        respuesta = messagebox.askyesno(
            T["ask_dep_title"],
            T["ask_dep"]
        )
        if respuesta:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "watchdog"])
        else:
            messagebox.showerror("Error", T["dep_needed"])
            sys.exit()

instalar_watchdog()
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


def detectar_distro_linux():
    try:
        with open("/etc/os-release") as f:
            lines = f.readlines()
        info = {}
        for line in lines:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                info[k] = v.strip('"')
        return info.get("ID", "").lower()
    except Exception:
        return ""


def instalar_rsync_linux():
    distro = detectar_distro_linux()
    if subprocess.call(["which", "rsync"], stdout=subprocess.DEVNULL) == 0:
        return  # rsync ya instalado

    gestores = {
        "ubuntu": ["sudo", "apt-get", "install", "-y", "rsync"],
        "debian": ["sudo", "apt-get", "install", "-y", "rsync"],
        "fedora": ["sudo", "dnf", "install", "-y", "rsync"],
        "centos": ["sudo", "yum", "install", "-y", "rsync"],
        "arch": ["sudo", "pacman", "-Sy", "rsync"],
        "opensuse": ["sudo", "zypper", "install", "-y", "rsync"],
    }

    comando = gestores.get(distro)
    if comando is None:
        messagebox.showwarning(
            T["warn_title"],
            T["no_distro"].format(distro=distro),
        )
        sys.exit()

    respuesta = messagebox.askyesno(
        T["ask_rsync_title"],
        T["ask_rsync"].format(cmd=' '.join(comando)),
    )
    if respuesta:
        try:
            subprocess.check_call(comando)
            messagebox.showinfo(T["ask_rsync_title"], T["rsync_ok"])
        except Exception as e:
            messagebox.showerror("Error", T["rsync_fail"].format(err=e))
            sys.exit()
    else:
        messagebox.showerror("Error", T["rsync_needed"])
        sys.exit()


def comprobar_instalar_rsync():
    sistema = platform.system()
    if sistema in ["Linux", "Darwin"]:
        instalar_rsync_linux()
    elif sistema == "Windows":
        # robocopy viene preinstalado
        pass
    else:
        messagebox.showerror("Error", T["bad_os"].format(sistema=sistema))
        sys.exit()


class CambioHandler(FileSystemEventHandler):
    def __init__(self, origen, destinos):
        self.origen = origen
        self.destinos = destinos

    def on_any_event(self, event):
        sync(self.origen, self.destinos)


def sync(origen, destinos):
    sistema = platform.system()
    for dest in destinos:
        if sistema in ["Linux", "Darwin"]:
            cmd = ["rsync", "-av", "--delete", origen + "/", dest + "/"]
        elif sistema == "Windows":
            cmd = ["robocopy", origen, dest, "/MIR", "/NFL", "/NDL"]
        else:
            messagebox.showerror("Error", T["bad_os"].format(sistema=sistema))
            return

        try:
            resultado = subprocess.run(cmd, capture_output=True, text=True)
            print(resultado.stdout)
        except Exception as e:
            messagebox.showerror("Error", T["sync_error"].format(err=e))

    status_label.config(text=T["sync_done"])


def iniciar_monitor():
    origen = origen_entry.get()
    destinos = destinos_text.get("1.0", tk.END).strip().split('\n')

    if not os.path.exists(origen):
        messagebox.showerror("Error", T["err_no_src"])
        return
    for d in destinos:
        if not os.path.exists(d):
            messagebox.showwarning(T["warn_title"], T["warn_no_dst"].format(d=d))

    global observer
    if 'observer' in globals():
        observer.stop()
        observer.join()

    event_handler = CambioHandler(origen, destinos)
    observer = Observer()
    observer.schedule(event_handler, path=origen, recursive=True)
    observer.start()

    status_label.config(text=T["monitoring"])

    # El observer se queda bloqueado en join() dentro de un hilo daemon:
    # sin busy-loop, sin consumo de CPU.
    threading.Thread(target=observer.join, daemon=True).start()


# --- INTERFAZ GRÁFICA ---
root = tk.Tk()
root.title(T["title"])

tk.Label(root, text=T["lbl_src"]).pack(pady=(10,0))
origen_entry = tk.Entry(root, width=50)
origen_entry.pack(pady=(0,5))
tk.Button(root, text=T["btn_src"], command=lambda: origen_entry.delete(0, tk.END) or origen_entry.insert(0, filedialog.askdirectory())).pack()

tk.Label(root, text=T["lbl_dst"]).pack(pady=(10,0))
destinos_text = tk.Text(root, height=5, width=50)
destinos_text.pack()
tk.Button(root, text=T["btn_start"], command=iniciar_monitor).pack(pady=10)

status_label = tk.Label(root, text="")
status_label.pack()

# Al iniciar, comprobar rsync/robocopy
comprobar_instalar_rsync()

root.mainloop()
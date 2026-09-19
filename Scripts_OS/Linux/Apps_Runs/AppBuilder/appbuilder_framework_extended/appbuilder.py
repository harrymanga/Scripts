#!/usr/bin/env python3
import tkinter as tk
from tkinter import filedialog, ttk, messagebox
import os, sys
from core.generator import create_app_project

class AppBuilderGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("AppBuilder Framework – GUI")
        self.geometry("700x520")
        self.resizable(False, False)
        self.create_widgets()

    def create_widgets(self):
        title = tk.Label(self, text="AppBuilder Framework", font=("Arial", 18, "bold"))
        title.pack(pady=10)

        frame = tk.Frame(self)
        frame.pack(pady=10, padx=10, fill='x')

        # Nombre del proyecto
        tk.Label(frame, text="Nombre de la aplicación:").grid(row=0, column=0, sticky="w")
        self.app_name = tk.Entry(frame, width=50)
        self.app_name.grid(row=0, column=1, pady=5, columnspan=2)

        # Ruta destino
        tk.Label(frame, text="Ruta destino:").grid(row=1, column=0, sticky="w")
        self.target_dir = tk.Entry(frame, width=50)
        self.target_dir.grid(row=1, column=1, pady=5)
        tk.Button(frame, text="Examinar", command=self.select_directory).grid(row=1, column=2, padx=5)

        # Intérprete
        tk.Label(frame, text="Intérprete:").grid(row=2, column=0, sticky="w")
        self.interpreter_var = tk.StringVar(value="java")
        interpreters = ["java", "python3", "tclsh", "node", "bash"]
        self.interpreter_menu = ttk.Combobox(frame, textvariable=self.interpreter_var, values=interpreters, width=47)
        self.interpreter_menu.grid(row=2, column=1, pady=5, columnspan=2)

        # Argumentos del intérprete
        tk.Label(frame, text="Argumentos del intérprete:").grid(row=3, column=0, sticky="w")
        self.inter_args = tk.Entry(frame, width=50)
        self.inter_args.insert(0, "-jar")
        self.inter_args.grid(row=3, column=1, pady=5, columnspan=2)

        # Archivo principal
        tk.Label(frame, text="Archivo principal:").grid(row=4, column=0, sticky="w")
        self.app_exec = tk.Entry(frame, width=50)
        self.app_exec.insert(0, "app.jar")
        self.app_exec.grid(row=4, column=1, pady=5, columnspan=2)

        # Botones
        btn_frame = tk.Frame(self)
        btn_frame.pack(pady=20)
        tk.Button(btn_frame, text="Crear Aplicación", font=("Arial", 12), bg="#4CAF50", fg="white", command=self.create_application).grid(row=0, column=0, padx=10)
        tk.Button(btn_frame, text="Empaquetar (ZIP)", font=("Arial", 12), command=self.package_project).grid(row=0, column=1, padx=10)
        tk.Button(btn_frame, text="Abrir Carpeta", font=("Arial", 12), command=self.open_folder).grid(row=0, column=2, padx=10)
        tk.Button(btn_frame, text="Salir", font=("Arial", 12), command=self.quit).grid(row=0, column=3, padx=10)

        # Status box
        self.status = tk.Text(self, height=8, state='disabled')
        self.status.pack(fill='x', padx=10, pady=10)

    def select_directory(self):
        folder = filedialog.askdirectory()
        if folder:
            self.target_dir.delete(0, tk.END)
            self.target_dir.insert(0, folder)

    def create_application(self):
        name = self.app_name.get().strip()
        dest = self.target_dir.get().strip() or os.getcwd()
        interpreter = self.interpreter_var.get()
        inter_args = self.inter_args.get().strip()
        exec_file = self.app_exec.get().strip()

        if not name:
            messagebox.showerror("Error", "Debe completar el nombre de la aplicación")
            return

        ok, msg = create_app_project(name=name, destination=dest, interpreter=interpreter, interpreter_args=inter_args, exec_file=exec_file)
        self._log(msg)
        if ok:
            messagebox.showinfo("Éxito", f"Proyecto '{name}' creado correctamente en {dest}")
        else:
            messagebox.showerror("Error", msg)

    def package_project(self):
        dest = self.target_dir.get().strip() or os.getcwd()
        name = self.app_name.get().strip()
        if not name:
            messagebox.showerror("Error", "Especifique el nombre del proyecto para empaquetar")
            return
        project_dir = os.path.join(dest, name)
        if not os.path.isdir(project_dir):
            messagebox.showerror("Error", f"No existe el proyecto: {project_dir}")
            return
        zip_path = os.path.join(dest, f"{name}.zip")
        try:
            shutil.make_archive(os.path.splitext(zip_path)[0], 'zip', project_dir)
            self._log(f"Empaquetado creado: {zip_path}")
            messagebox.showinfo("Éxito", f"Paquete creado: {zip_path}")
        except Exception as e:
            self._log(f"Error empaquetando: {e}")
            messagebox.showerror("Error", f"No se pudo empaquetar: {e}")

    def open_folder(self):
        dest = self.target_dir.get().strip() or os.getcwd()
        name = self.app_name.get().strip()
        project_dir = os.path.join(dest, name)
        if os.path.isdir(project_dir):
            if sys.platform.startswith('linux'):
                os.system(f'xdg-open "{project_dir}" &')
            elif sys.platform == 'darwin':
                os.system(f'open "{project_dir}" &')
            else:
                os.startfile(project_dir)
        else:
            messagebox.showerror("Error", f"No existe el proyecto: {project_dir}")

    def _log(self, message):
        self.status.configure(state='normal')
        self.status.insert('end', message + "\n")
        self.status.configure(state='disabled')
        self.status.see('end')

if __name__ == "__main__":
    AppBuilderGUI().mainloop()


#!/usr/bin/env python
# -*- coding: utf-8 -*-

from googletrans import Translator
import tkinter as tk
from tkinter import filedialog

# Crear una ventana para seleccionar el archivo
root = tk.Tk()
root.withdraw()  # Ocultar la ventana principal

# Solicitar al usuario que seleccione el archivo a traducir
ruta_archivo = filedialog.askopenfilename()

# Abrir el archivo y leer su contenido
with open(ruta_archivo, 'r', encoding="utf_8") as archivo:
    texto = archivo.read()

# Activar el motor traductor de Google
traductor = Translator() 

# Traducir el texto al inglés
traduccion = traductor.translate(texto, dest='en') 

# Grabar la traducción en un nuevo archivo de texto
ruta_salida = 'C:/visual_studio/datos_txt/salida.txt'
with open(ruta_salida, "a") as salida:  # Modo de aprendizaje
    salida.write(traduccion.text)

print('****listo****')
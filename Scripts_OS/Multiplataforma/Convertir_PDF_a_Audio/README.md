# Convertir_PDF_a_Audio — versión única

Convierte un archivo PDF a MP3 (voz en español, Google TTS).

## Requisitos

- Python 3 con tkinter. **Nada más que instalar a mano**: al ejecutar,
  el programa instala solo `pypdf` y `gTTS` (pregunta antes).
- Conexión a internet (el servicio TTS es en línea).
- Nota: se usa `pypdf` (Python puro) en lugar del antiguo `pdftotext`,
  que exigía la librería de sistema poppler e impedía la autoinstalación.

## Uso

```bash
./run.sh        # crea .venv, instala dependencias y ejecuta (Linux/macOS)
```

En Windows: `run.bat`. (Equivalente manual: `python pdf_a_audio.py`,
previa instalación de `requirements.txt`.)

1. Elige el PDF en el diálogo (si cancelas, sale limpiamente).
2. Espera el mensaje de guardado: el MP3 queda junto al PDF con el
   mismo nombre (`documento.pdf` → `documento.mp3`).

## Idiomas (es/en)

- Diccionario interno es/en (detección por `locale`, español por defecto).

## Cambios respecto a las versiones anteriores

- Unificadas las variantes Qt (requería PyQt5 solo para un diálogo) y Tk.
- Corregido: cancelar el diálogo ya no provoca traceback.
- Salida junto al PDF con el nombre base (antes siempre `audio.mp3` en
  el directorio actual).
- Errores de lectura y de red con diálogo en lugar de traza.

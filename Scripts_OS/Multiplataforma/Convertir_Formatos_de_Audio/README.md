# Convertir_Formatos_de_Audio — versión única

Convierte archivos de audio entre 9 formatos (wav, mp3, ogg, mp2, mp4,
m4a, aiff, au, flv) con GUI tkinter.

## Requisitos

- Python 3 con tkinter. **Nada más que instalar a mano**:
  - `pydub` se instala solo al ejecutar (pregunta antes).
  - `ffmpeg` (binario de sistema) se intenta instalar solo (apt/dnf/pacman
    en Linux, winget en Windows, brew en macOS, siempre preguntando antes).
    Si la autoinstalación falla, el programa muestra el comando exacto.

## Uso

```bash
./run.sh        # crea .venv, instala dependencias y ejecuta (Linux/macOS)
```

En Windows: `run.bat`. (Equivalente manual:
`python conversor_formatos_audio.py`, previa instalación de
`requirements.txt`.)

1. **Buscar archivo** y elige el audio origen.
2. Pulsa el botón del formato destino (hilo en segundo plano, la GUI no
   se congela).
3. El archivo se crea en la **carpeta destino** (botón inferior; por
   defecto el directorio actual). Si ya existe un archivo con ese nombre,
   se crea `(copia)` para no sobrescribir.

## Idiomas (es/en)

- Diccionario interno es/en para toda la GUI (detección por `locale`).

## Cambios respecto a las versiones anteriores

- Eliminado `from tkinter import *` (imports explícitos) y lógica
  reorganizada en clase `ConverterApp` (sin globales).
- Corregido: el botón "AAC" exportaba `aiff`; ahora cada botón mapea a su
  formato real (incluido `m4a`).
- `ffmpeg` verificado al convertir (antes fallaba sin explicación si
  faltaba).
- Hilo `daemon` (antes no daemon: la app podía no cerrar limpiamente).

# sync-auto — Sincronizador Automático de Carpetas (versión única canónica)

Sincronización en tiempo real de una carpeta origen hacia uno o varios
destinos, con interfaz tkinter. Multiplataforma: usa `rsync` en
Linux/macOS y `robocopy /MIR` en Windows.

## Requisitos

- Python 3 con tkinter (incluido por defecto; en Linux puede requerir
  `python3-tk` según la distro).
- Ver también `instrucciones.txt` (versión en texto de `instrucciones.pdf`).
- La primera ejecución instala lo que falte (pregunta antes):
  - librería `watchdog` (`pip install watchdog`, ver `install_deps_*.sh/.bat`),
  - `rsync` en Linux (detecta apt/dnf/pacman/yum/zypper; en Windows usa
    `robocopy`, preinstalado).

## Uso

```bash
./run.sh        # crea .venv, instala dependencias y ejecuta (Linux/macOS)
```

En Windows: `run.bat`. (Equivalente manual: `python sync_auto.py`,
previa instalación de `requirements.txt`.)

1. Pulsa **Seleccionar Origen** y elige la carpeta a monitorear.
2. Escribe las carpetas destino (una por línea).
3. Pulsa **Iniciar Monitoreo**: desde ese momento, cualquier cambio en el
   origen se replica a los destinos (`--delete`/`/MIR`: los destinos
   quedan espejo del origen, **los archivos borrados en origen se borran
   en destino**).

## Idiomas (es/en)

- Diccionario interno es/en con detección por `locale` (español por
  defecto). Si la GUI crece, migrar a `locales/es.json` + `locales/en.json`.

## Alternativa ligera (solo Linux, sin Python)

`../../../Linux/Sincronizar_carpetas/Bash/Sincronizar_carpetas.sh`
(mismo principio con `inotifywait` + `rsync`, un solo destino).

## Cambios respecto a las versiones anteriores

- Corregido busy-loop (`while True: pass` consumía CPU) → hilo daemon con
  `observer.join()`.
- La versión PyQt6 de `Proyectos/.../Corregir/Sincronizar_Carpetas`
  (con bug: `copytree` falla si el destino existe) fue retirada; esta es
  la versión canónica.

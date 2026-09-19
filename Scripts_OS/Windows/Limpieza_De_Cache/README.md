# Limpieza_De_Cache — versión única

## Contenido (canónico, dentro del repositorio)

- `limpieza_completa.bat [full|temp|logs]`: limpieza de temporales, registros
  (.log + visor de eventos), SoftwareDistribution, prefetch y DNS.
  - `full` (por defecto): todo lo anterior.
  - `temp`: solo temporales y prefetch (reemplaza al antiguo `limpiar.bat`).
  - `logs`: solo .log y visor de eventos.
- `limpieza.py`: GUI tkinter que ejecuta cada modo real (corrige el bug anterior,
  donde los 3 botones hacían lo mismo porque el .bat ignoraba los parámetros).

## Requisitos

- Windows con permisos de Administrador.
- GUI (`limpieza.py`): Python 3 con tkinter (incluido por defecto en
  python.org; no requiere paquetes extra).

## Uso

### Opción A — doble clic (modo completo)

1. Clic derecho en `limpieza_completa.bat` → **Ejecutar como administrador**.
2. Sin parámetros ejecuta el modo `full` en español (o inglés si tu
   Windows está en inglés).
3. Al terminar, presiona cualquier tecla para salir.

### Opción B — consola (modo e idioma a elegir)

Abre `cmd` **como administrador**, entra a esta carpeta y ejecuta:

```bat
limpieza_completa.bat            :: full + idioma automático
limpieza_completa.bat temp       :: solo temporales
limpieza_completa.bat logs       :: solo registros
limpieza_completa.bat full en    :: full en inglés
limpieza_completa.bat temp es    :: temporales en español
```

### Opción C — interfaz gráfica

```bat
python limpieza.py
```

Pulsa el botón del modo deseado y mira el resultado en la consola
integrada. (La ventana debe ejecutarse como administrador para que la
limpieza tenga efecto.)

### Qué hace cada modo

- `full`: temporales (`c:\windows\temp`, `%temp%`), prefetch, `.log`,
  visor de eventos, reinicio de SoftwareDistribution y `ipconfig /flushdns`.
- `temp`: solo temporales y prefetch.
- `logs`: solo `.log` y visor de eventos.

### Si algo falla

- `Intenta de nuevo como Administrador` → relanza con clic derecho.
- Sin PowerShell instalado, el idioma cae a español (seguro, sin error).

## Idiomas (es/en)

- `lang_es.bat` / `lang_en.bat`: 6 claves (`MSG_ADMIN`, `MSG_ANYKEY`,
  `MSG_TEMP_DONE`, `MSG_LOGS_DONE`, `MSG_FULL_DONE`, `MSG_CLEANING`).
- Detección: parámetro `es|en` > cultura del sistema (`Get-Culture`) >
  español por defecto. Ej.: `limpieza_completa.bat full en`.
- `limpieza.py`: diccionario interno es/en con detección por `locale`
  (si crece, migrar a `locales/es.json` + `locales/en.json`).

## Cambios respecto a las versiones anteriores

- Se eliminó `deltree` (obsoleto desde Windows XP) → `rd /s /q`.
- Se eliminó `del c:\WIN386.SWP` (archivo de Windows 9x, inexistente hoy).
- Se eliminó `msg *` (falla si el servicio de mensajes no está activo).
- Rutas de borrado protegidas con `2>nul` para no abortar ante accesos denegados.
- El duplicado `Proyectos/.../Corregir/Limpieza_De_Temporales/limpieza.bat`
  (idéntico) fue retirado; la versión canónica es esta.

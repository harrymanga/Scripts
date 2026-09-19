# Inventario_Programas — versión única

## Contenido (canónico, dentro del repositorio)

- `menu.bat`: selector de las 3 variantes.
- `inventario_winget.bat`: `winget export` con versiones (recomendado).
- `inventario_powershell.ps1`: lee el registro Uninstall (nombre, versión,
  editor, fecha).
- `inventario_cmd.bat`: `wmic product` clásico (obsoleto en Windows 11,
  se conserva por compatibilidad).

## Uso

### Opción A — menú (recomendado)

1. Haz doble clic en `menu.bat` (o `menu.bat en` para inglés).
2. Elige `1` (Winget), `2` (PowerShell) o `3` (WMIC).
3. El reporte se guarda en tu **Escritorio**:
   - `Programas_Instalados_winget.txt`
   - `Programas_instalados_powershell.txt`
   - `programas_instalados_cmd.txt`

### Opción B — script directo

```bat
inventario_winget.bat
inventario_cmd.bat
powershell -ExecutionPolicy Bypass -File inventario_powershell.ps1
```

### Requisitos

- `inventario_winget.bat`: herramienta `winget` (Windows 10 1809+ / 11).
- `inventario_powershell.ps1`: PowerShell (incluido en Windows; el menú
  ya evita el bloqueo de `ExecutionPolicy`, al ejecutarlo a mano usa el
  comando de arriba).
- `inventario_cmd.bat`: `wmic` (obsoleto en Windows 11; si falla, usa
  las otras dos opciones).

## Por qué se conservan las 3 variantes

Cada fuente cubre programas que las otras no ven (Winget solo lo instalado
por Winget/MS Store, el registro cubre instaladores clásicos, wmic otra
vista legacy). Son complementarias, no duplicadas.

## Cambios respecto a las versiones anteriores

- Ruta de salida parametrizada (`%USERPROFILE%\Desktop`) en lugar de la ruta
  fija `C:\Users\harry\Desktop` (máquina concreta).
- Reunidas en una sola carpeta con menú y nombres sin espacios.

## Idiomas (es/en)

- `lang_es.bat` / `lang_en.bat`: 6 claves (`MSG_TITLE`, `MSG_OPT1`,
  `MSG_OPT2`, `MSG_OPT3`, `MSG_OPT0`, `MSG_CHOOSE`), usadas solo por
  `menu.bat` (los inventarios casi no tienen mensajes).
- Detección: parámetro `es|en` > cultura del sistema (`Get-Culture`) >
  español por defecto. Ej.: `menu.bat en`.

## No incluido aquí

- `../Actualizar_Programas/Winget/Upgrade Programas winget.bat`: actualiza programas
  (`winget upgrade --all`), función distinta a inventariar.

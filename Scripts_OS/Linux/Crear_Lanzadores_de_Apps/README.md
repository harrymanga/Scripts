# Crear_Lanzadores_de_Apps — versión única

Genera lanzadores `.desktop` (menú + escritorio) con soporte Wine,
categorías freedesktop e ícono opcional.

## Contenido

- `crear_lanzador_de_apps.sh [es|en]`: script canónico con i18n
  (20 claves en `lang_es.sh` / `lang_en.sh`; las categorías no se
  traducen: son valores de la especificación freedesktop).
- `CrearLanzador.AppDir/`: paquete AppDir distribuible (`AppRun` +
  `.desktop`). Su copia de `crear_lanzador_de_apps.sh` + `lang_*.sh` es
  **idéntica a la canónica** (copia de distribución autocontenida; si la
  modificas, re-sincroniza los 3 archivos).

## Requisitos

- `zenity` (autoinstalación asistida en ubuntu/debian, fedora,
  arch/manjaro).

## Uso

```bash
./crear_lanzador_de_apps.sh         # idioma según $LANG
./crear_lanzador_de_apps.sh en      # inglés forzado
```

1. Elige el ejecutable, el nombre y el ícono (opcional).
2. Marca categorías (por defecto `Utility`).
3. Indica si usa Wine (pide `WINEPREFIX` en ese caso).
4. El `.desktop` queda en `~/.local/share/applications/` (+ copia al
   escritorio si lo aceptas).

## Ejemplo relacionado

`../Crear_Archivos_Desktop/modelo_para_aplicaciones_con_Wine.desktop`:
plantilla manual de `.desktop` para apps con Wine.

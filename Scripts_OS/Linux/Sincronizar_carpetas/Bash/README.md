# Sincronizar_carpetas.sh — alternativa ligera (solo Linux, sin Python)

Monitoreo en tiempo real de una carpeta origen hacia un destino con
`inotifywait` + `rsync --delete` e interfaz `zenity`.

## Requisitos

- Linux con `zenity` e `inotify-tools` (`rsync` casi siempre preinstalado).
  Si faltan los dos primeros, el script intenta instalarlos solo
  (ubuntu/debian, fedora, arch/manjaro/garuda; pide `sudo`).

## Uso

```bash
chmod +x Sincronizar_carpetas.sh
./Sincronizar_carpetas.sh         # español o según $LANG
./Sincronizar_carpetas.sh en      # inglés forzado
```

1. Elige la **carpeta origen** en el diálogo.
2. Elige la **carpeta destino** en el diálogo.
3. Desde ese momento, cada cambio se replica (`--delete`: el destino
   queda espejo del origen). Deja la terminal abierta; `Ctrl+C` detiene.

## Idiomas (es/en)

- `lang_es.sh` / `lang_en.sh`: 8 claves (`MSG_INSTALLING`,
  `MSG_UNSUPPORTED`, `MSG_TITLE_SRC`, `MSG_TITLE_DST`, `MSG_NO_SELECTION`,
  `MSG_SYNCED`, `MSG_MONITORING`, `MSG_CHANGED`).
- Detección: parámetro `es|en` > `$LANG` > español por defecto.

## Versión canónica

La versión multiplataforma (múltiples destinos, Windows/macOS) vive en
`../../../Multiplataforma/Sincronizar_Carpetas/sync-auto/`.
Este `.sh` se conserva como alternativa sin dependencias Python.

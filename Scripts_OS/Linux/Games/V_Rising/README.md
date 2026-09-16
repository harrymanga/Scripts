# vrising.sh — Lanzador de V Rising (Wine) con GUI

Lanza un juego Windows (Unity) con Wine usando un **prefix aislado**, DXVK,
Esync/Fsync y optimizaciones para AMD (RADV). Sin rutas fijas: todo se pide
por GUI o por flags CLI.

## Ubicación

Este script vive en el repo de scripts. El prefix de V Rising está en
`~/Games/vrising-prefix` (ext4, no tocar `~/.wine`).

## Requisitos

- `wine`, `winetricks`
- `yad` o `zenity` para la GUI (nota: `yad` 15 no trae `--info/--error/--question`;
  el script usa `yad` solo para el formulario y `zenity` para los diálogos)
- Drivers Vulkan (`vulkan-radeon` + `lib32-vulkan-radeon` en AMD)

## Uso GUI (sin argumentos)

```bash
./vrising.sh
```

1. Pide **carpeta del prefix**, **carpeta del juego** y **ejecutable** (parte de `$HOME`, sin valores fijos).
2. **Regla de prefix**: si ya existe uno ahí, pregunta si usarlo (si dices que no,
   vuelve a pedir carpeta); si no existe, ofrece crearlo e instalar lo necesario
   (**Windows 10 + vcrun2019 + DXVK**, con descarga de internet y barra de progreso).
3. Lo elegido se guarda en `~/.config/vrising-launcher.conf` como sugerencia futura.
4. Opciones: mostrar FPS (`DXVK_HUD`), guardar log en `/tmp`.

## Uso CLI

```bash
./vrising.sh --prefix DIR --game-dir DIR --exe NOMBRE|RUTA [--fps] [--log ARCHIVO]
./vrising.sh --setup --prefix DIR   # solo crea el prefix, sin lanzar
./vrising.sh --check --prefix DIR --game-dir DIR --exe NOMBRE
./vrising.sh --kill --prefix DIR    # detiene el wineserver del prefix
./vrising.sh --gui                  # fuerza GUI
./vrising.sh --help
```

Sin flags (y sin conf previo) el modo CLI falla indicando lo que falta.

## Variables de entorno aplicadas al juego

| Variable | Valor | Para qué |
|---|---|---|
| `WINEESYNC` / `WINEFSYNC` | `1` | Rendimiento (sincronización) |
| `WINEDEBUG` | `-all` | Log limpio |
| `DXVK_LOG_LEVEL` | `info` | Diagnóstico DXVK |
| `DXVK_HUD` | `fps,compiler` (con `--fps`) | Contador FPS |
| `RADV_PERFTEST` | `gpl` | Pipelines gráficos en AMD |
| `MESA_SHADER_CACHE_MAX_SIZE` | `10G` | Menos stutter al rejugar |

El juego arranca con CWD en su carpeta (Unity exige `VRising_Data` al lado del exe).

## Notas

- Discos NTFS (`fuseblk`) funcionan pero rinden menos que ext4; si hay tirones,
  copiar el juego a `~/Games/` ayuda.
- `_Redist/dxwebsetup.exe` y `_Windows 7 Fix/` de los repacks se ignoran
  (obsoletos; el prefix ya va en modo Windows 10).

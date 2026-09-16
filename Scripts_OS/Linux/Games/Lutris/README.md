# lutris-bulk-import.sh — Importación masiva a Lutris con GUI

Registra en Lutris carpetas de juegos ya instalados **sin agregarlos uno por uno**:
escribe el `.yml` en `~/.local/share/lutris/games/` y la fila en `pga.db`.

- Carpeta Windows → runner `wine` (versión `Proton-CachyOS Latest`)
- Carpeta Linux → runner `linux` (`.sh`, `.x86_64`, binario, `.jar` con java, `.AppImage`)

## Requisitos

- `lutris`, `sqlite3`, `python3-yaml` (reescritura de yml)
- `wine`, `winetricks` (solo si se crean prefixes)
- `yad` o `zenity` para la GUI (`yad` solo el formulario; mensajes por `zenity`)
- `java` (detección de `.jar`), `gamemode`/`lib32-gamemode` (opcional, se activa en el yml)

## Uso GUI (sin argumentos)

```bash
./lutris-bulk-import.sh
```

Formulario único: carpetas Windows/Linux, **modo de prefix**, **FPS**,
log detallado, aplicar a ya registrados, re-point y registro. Muestra informe
final en ventana. Lo elegido se guarda en `~/.config/lutris-bulk-import.conf`.

## Uso CLI

```bash
# Solo informe (recomendado primero)
./lutris-bulk-import.sh --win DIR --linux DIR
# Registrar (cerrar Lutris antes)
./lutris-bulk-import.sh --win DIR --linux DIR --apply [--force]
# Prefix compartido
./lutris-bulk-import.sh --win DIR --apply --shared-prefix DIR        # existente
./lutris-bulk-import.sh --win DIR --apply --new-shared-prefix DIR    # crearlo
# FPS y log en el yml (como vrising.sh --fps/--log)
./lutris-bulk-import.sh --win DIR --linux DIR --fps dxvk --log --apply
./lutris-bulk-import.sh --win DIR --linux DIR --fps mangohud --apply
# Aplicar FPS/log a los ya registrados (sin duplicar)
./lutris-bulk-import.sh --win DIR --linux DIR --fps dxvk --log --update-existing --apply
# Cambiar el prefix de TODOS los Wine registrados
./lutris-bulk-import.sh --set-prefix DIR [--exclude v-rising,otro] [--apply]
./lutris-bulk-import.sh --help
```

## Modos de prefix (juegos Wine)

| Modo | Comportamiento |
|---|---|
| Uno por juego (defecto) | `~/Games/prefixes/<slug>`, se crea al primer lanzamiento |
| Existente compartido | Pide ubicación, valida que sea prefix real |
| Nuevo compartido | Pide ubicación y lo crea (`wineboot + win10 + vcrun2019 + DXVK`) |

Regla general: antes de usar un prefix se pregunta; si no existe, se ofrece crearlo.

## Opciones por juego (al `.yml`)

| Opción | Efecto en el yml |
|---|---|
| `--fps dxvk` | `system.env.DXVK_HUD: fps,compiler` |
| `--fps mangohud` | `system.mangohud: true` (excluyente con DXVK_HUD) |
| `--log` | `system.env.DXVK_LOG_LEVEL: info` (detalle en Lutris → *Show logs*) |

## Detección automática

- **Windows**: exe de primer nivel (excluye `unins*`, `*crash*`, `*setup*`, `*redist*`,
  `RapidCRC`, servidores, etc.), preferencia por coincidencia de nombre y tamaño;
  respaldo en profundidad (UE/Starbound/Hytale); desciende un nivel en carpetas
  contenedoras (`GOG Games` → `Diablo`).
- **Linux**: `start_game_bepinex.sh`/`start.sh`/`hytale.sh`/`start.bash` > `*.sh` >
  `*.x86_64` > binario ELF (con coincidencia de nombre) > `.jar` (`java -jar`) >
  `.AppImage`; desciende un nivel (`GOG_Games` → `Northgard`, `RimWorld`).
- Nombres limpios (`V_Rising_V1.1...` → `V Rising`); duplicados con sufijo `[2]`;
  nunca duplica lo ya registrado (matchea por slug **y** por nombre: `flood-land`).
- Omite carpetas auxiliares (`Engine`, `mods`, `saves`, `docs`…) e instaladores.

## Seguridad

- **Cerrar Lutris** antes de `--apply` (o `--force` bajo tu riesgo).
- Respaldo de `pga.db` (`pga.db.bak-<epoch>`) en cada `--apply`.
- Re-point respalda cada yml como `.bak-<epoch>`.
- `SKIP`/`EXCLUIDO`/`IGUAL` se informan siempre; revisar el informe tras cada corrida.

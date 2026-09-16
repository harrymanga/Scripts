#!/usr/bin/env bash
# Importa a Lutris carpetas de juegos ya instalados sin hacerlo uno por uno.
#  - Carpeta Windows -> runner wine (prefix propio en ~/Games/prefixes/<slug>)
#  - Carpeta Linux   -> runner linux (sh / .x86_64 / binario / .jar)
# Escribe el yml en ~/.local/share/lutris/games/ y la fila en pga.db.
#
# Sin argumentos : GUI (pide carpetas y modo de prefix con ventanas, muestra resultados).
# Con argumentos : modo CLI.
# Uso CLI: lutris-bulk-import.sh --win DIR --linux DIR [--apply] [--force]
#          [--shared-prefix DIR | --new-shared-prefix DIR]
#          [--fps dxvk|mangohud] [--log] [--update-existing] [--help]
#          [--set-prefix DIR] (cambia el prefix de TODOS los Wine registrados)
# Prefix Wine (pregunta en GUI, flags en CLI):
#   - por defecto: uno por juego en ~/Games/prefixes/<slug>
#   - --shared-prefix DIR: usa el prefix existente DIR para todos
#   - --new-shared-prefix DIR: crea un prefix compartido en DIR para todos
# FPS y log (como vrising.sh --fps/--log) para el .yml de cada juego:
#   --fps dxvk     -> system.env.DXVK_HUD=fps,compiler
#   --fps mangohud -> system.mangohud=true
#   --log          -> system.env.DXVK_LOG_LEVEL=info (detalle en Lutris -> Show logs)
#   --update-existing: aplica FPS/log a juegos ya registrados (detectados de nuevo)
# Sin --apply: solo muestra lo detectado (dry-run, recomendado primero).
# Con --apply: registra en Lutris (cierra Lutris antes, o usa --force).
set -u

TITLE="Importar juegos a Lutris"
CONFIG="$HOME/.config/lutris-bulk-import.conf"
IMPORT_LOG="/tmp/lutris-bulk-import.log"

WIN_DIR=""; LINUX_DIR=""; APPLY=0; FORCE=0; CLI_MODE=0
PREFIX_MODE="per-game"; SHARED_PREFIX=""
FPS_MODE="none"; SAVE_LOG=0; DO_UPDATE=0
REPOINT=0; SET_PREFIX=""; EXCLUDE=""
[ -f "$CONFIG" ] && . "$CONFIG"

while [ $# -gt 0 ]; do
  CLI_MODE=1
  case "$1" in
    --win) WIN_DIR="${2%/}"; shift 2 ;;
    --win=*) WIN_DIR="${1#--win=}"; WIN_DIR="${WIN_DIR%/}"; shift ;;
    --linux) LINUX_DIR="${2%/}"; shift 2 ;;
    --linux=*) LINUX_DIR="${1#--linux=}"; LINUX_DIR="${LINUX_DIR%/}"; shift ;;
    --apply) APPLY=1; shift ;;
    --force) FORCE=1; shift ;;
    --fps) FPS_MODE="$2"; shift 2 ;;
    --fps=*) FPS_MODE="${1#--fps=}"; shift ;;
    --log) SAVE_LOG=1; shift ;;
    --update-existing) DO_UPDATE=1; shift ;;
    --set-prefix) REPOINT=1; SET_PREFIX="${2%/}"; shift 2 ;;
    --set-prefix=*) REPOINT=1; SET_PREFIX="${1#--set-prefix=}"; SET_PREFIX="${SET_PREFIX%/}"; shift ;;
    --exclude) EXCLUDE="$2"; shift 2 ;;
    --exclude=*) EXCLUDE="${1#--exclude=}"; shift ;;
    --shared-prefix) PREFIX_MODE="shared"; SHARED_PREFIX="${2%/}"; shift 2 ;;
    --shared-prefix=*) PREFIX_MODE="shared"; SHARED_PREFIX="${1#--shared-prefix=}"; SHARED_PREFIX="${SHARED_PREFIX%/}"; shift ;;
    --new-shared-prefix) PREFIX_MODE="shared-new"; SHARED_PREFIX="${2%/}"; shift 2 ;;
    --new-shared-prefix=*) PREFIX_MODE="shared-new"; SHARED_PREFIX="${1#--new-shared-prefix=}"; SHARED_PREFIX="${SHARED_PREFIX%/}"; shift ;;
    --help|-h) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "Opcion desconocida: $1"; exit 1 ;;
  esac
done
case "$FPS_MODE" in
  none|dxvk|mangohud) ;;
  *) echo "ERROR: --fps debe ser dxvk o mangohud"; exit 1 ;;
esac

LUTRIS_DIR="$HOME/.local/share/lutris"
GAMES_DIR="$LUTRIS_DIR/games"
PGA="$LUTRIS_DIR/pga.db"
PREFIX_BASE="$HOME/Games/prefixes"
WINE_VER="Proton-CachyOS Latest"
EPOCH=$(date +%s)

# ---------- GUI helpers (yad solo formulario; mensajes por zenity) ----------
GUI=""
command -v yad >/dev/null && GUI="yad"
[ -z "$GUI" ] && command -v zenity >/dev/null && GUI="zenity"
have_zenity() { command -v zenity >/dev/null; }
gui_info() {
  if have_zenity; then zenity --info --title="$TITLE" --text="$1" --width=550;
  else echo "$1" | yad --text-info --title="$TITLE" --width=550 --height=300 --button=Aceptar:0 >/dev/null; fi
}
gui_error() {
  if have_zenity; then zenity --error --title="$TITLE" --text="$1" --width=550;
  else echo "$1" | yad --text-info --title="$TITLE - error" --width=550 --height=300 --button=Aceptar:1 >/dev/null; fi
}
gui_question() {
  if have_zenity; then zenity --question --title="$TITLE" --text="$1" --width=550;
  else echo "$1" | yad --text-info --title="$TITLE" --width=550 --height=300 --button=Sí:0 --button=No:1 >/dev/null; fi
}
gui_progress() {
  if have_zenity; then
    zenity --progress --pulsate --auto-close --no-cancel --title="$TITLE" --text="$1" --width=450
  else
    yad --progress --pulsate --auto-close --title="$TITLE" --text="$1" --width=450
  fi
}
gui_results() {
  if have_zenity; then zenity --text-info --title="$TITLE - resultado" --filename="$1" --width=800 --height=600;
  else yad --text-info --title="$TITLE - resultado" --filename="$1" --width=800 --height=600 --button=Cerrar:0 >/dev/null; fi
}

# ---------- utilidades ----------
slugify() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-\+//; s/-\+$//'; }
norm()    { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9'; }
sq()      { printf "%s" "$1" | sed "s/'/''/g"; } # escape SQL
exebase() { # basename sin .exe (insensible a mayusculas) para comparar nombres
  local b
  b=$(basename "$1")
  echo "${b%.[Ee][Xx][Ee]}"
}

pretty() { # "V_Rising_V1.1.13.0-r99712-b17" -> "V Rising"
  echo "$1" | sed -E \
    -e 's/[-_ .]?(PiviGames\.blog|GoldBerg).*//I' \
    -e 's/[-_ .]?[Bb]uild.*//' \
    -e 's/[-_]Linux$//' \
    -e 's/[-_ .]v[0-9]+.*//I' \
    -e 's/[-_]v[0-9]+$//I' \
    -e 's/[-_ .][0-9]+\..*//' \
    -e 's/[._]+/ /g' \
    -e 's/ +/ /g; s/^ //; s/ $//' \
    -e 's/ \([^()]*\)$//' \
    -e 's/ v$//I'
}

EXISTING_SLUGS=""
USED_SLUGS=""
unique_slug() { # $1 base -> deja el slug unico en $UNIQ_SLUG (sin subshell: $(...) perderia el acumulado)
  local base s n
  base="$1"; s="$base"; n=2
  while echo "$USED_SLUGS" | grep -qx "$s"; do s="$base-$n"; n=$((n+1)); done
  if [ -z "$USED_SLUGS" ]; then USED_SLUGS="$s"; else USED_SLUGS=$(printf '%s\n%s' "$USED_SLUGS" "$s"); fi
  UNIQ_SLUG="$s"
}
already_in_db() { echo "$EXISTING_SLUGS" | grep -qx "$1"; }
db_slug_by_name() { # $1 nombre normalizado -> slug en BD con igual nombre (o vacio)
  local line s n
  sqlite3 "$PGA" "SELECT slug, name FROM games;" | while IFS='|' read -r s n; do
    [ "$(norm "$n")" = "$1" ] && { echo "$s"; break; }
  done
}

JUNK='unins|crashhandler|crash_report|/setup|setup_|redist|vcredist|dotnet|dxsetup|oalinst|patch|updater|update_|uninstall|ue4prereq|prereq|report|goglog|dosbox|scummvm|winhttp|rapidcrc|checksum|sfv'
SKIPDIRS='^(engine|redist|_redist|commonredist|_commonredist|docs|support|directx|dotnet|_installer|__installer|install|extras|userdata|savedata|savegames|binaries|redistributables|locale|config|saves|mods|data|assets|resources|jre|java)$'

pick_largest() { # rutas por stdin -> la mas pesada (o nada)
  local best bestsize f s
  best=""; bestsize=-1
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    s=$(stat -c%s "$f" 2>/dev/null || echo 0)
    if [ "$s" -gt "$bestsize" ]; then bestsize=$s; best=$f; fi
  done
  [ -n "$best" ] && echo "$best"
  [ -n "$best" ]
}
match_or_largest() { # $1 core: primero coincidencia de nombre, si no la mas pesada
  local core cands matches f en
  core="$1"
  [ -z "$core" ] && return 1
  cands=$(cat)
  [ -z "$cands" ] && return 1
  matches=""
  while IFS= read -r f; do
    en=$(norm "$(exebase "$f")")
    if [[ "$en" == *"$core"* ]] || { [ ${#en} -ge 4 ] && [[ "$core" == *"$en"* ]]; }; then
      if [ -z "$matches" ]; then matches="$f"; else matches="$matches
$f"; fi
    fi
  done <<< "$cands"
  [ -n "$matches" ] && cands="$matches"
  echo "$cands" | pick_largest
}
match_only() { # $1 core: solo si hay coincidencia de nombre (para busqueda profunda)
  local core cands matches f en
  core="$1"
  [ -z "$core" ] && return 1
  cands=$(cat)
  [ -z "$cands" ] && return 1
  matches=""
  while IFS= read -r f; do
    en=$(norm "$(exebase "$f")")
    if [[ "$en" == *"$core"* ]] || { [ ${#en} -ge 4 ] && [[ "$core" == *"$en"* ]]; }; then
      if [ -z "$matches" ]; then matches="$f"; else matches="$matches
$f"; fi
    fi
  done <<< "$cands"
  [ -z "$matches" ] && return 1
  echo "$matches" | pick_largest
}

top_exes() { # $1 carpeta -> exes de primer nivel sin basura
  find "$1" -maxdepth 1 -iname '*.exe' 2>/dev/null | grep -viE "$JUNK" || true
}
deep_exes() { # $1 carpeta -> exes profundos sin basura ni herramientas
  find "$1" -maxdepth 6 -iname '*.exe' 2>/dev/null \
    | grep -viE "$JUNK|server|editor" \
    | grep -viE '/(redist|_redist|commonredist|_commonredist|__installer|_installer|support|docs|directx|dotnet|vcredist|engine/extras)/' || true
}

find_win_top() { # $1 carpeta $2 core
  local cands
  cands=$(top_exes "$1")
  [ -z "$cands" ] && return 1
  echo "$cands" | match_or_largest "$2"
}
find_win_deep() { # $1 carpeta $2 core (exige coincidencia de nombre)
  local cands
  cands=$(deep_exes "$1")
  [ -z "$cands" ] && return 1
  echo "$cands" | match_only "$2"
}

find_linux_launch() { # $1 carpeta $2 core -> "exe|args" o return 1
  local dir core f cands
  dir="$1"; core="$2"
  for pat in start_game_bepinex.sh start.sh hytale.sh start.bash; do
    [ -f "$dir/$pat" ] && { echo "$dir/$pat|"; return 0; }
  done
  f=$(find "$dir" -maxdepth 1 -iname '*.sh' 2>/dev/null | grep -viE 'uninstall|server|setup|config' | head -n 1)
  [ -n "$f" ] && { echo "$f|"; return 0; }
  f=$(find "$dir" -maxdepth 1 -iname '*.x86_64' 2>/dev/null | head -n 1)
  [ -n "$f" ] && { echo "$f|"; return 0; }
  cands=$(find "$dir" -maxdepth 3 -type f -executable ! -name '*.*' 2>/dev/null \
    | grep -viE '/(docs|support|locale|java|server|jre|config|saves|mods|data)/' || true)
  if [ -n "$cands" ]; then
    f=$(echo "$cands" | match_only "$core")
    [ -n "$f" ] && { echo "$f|"; return 0; }
  fi
  f=$(find "$dir" -maxdepth 1 -iname '*.jar' 2>/dev/null | grep -vi server | head -n 1)
  if [ -n "$f" ] && command -v java >/dev/null; then
    echo "$(command -v java)|-jar \"$(basename "$f")\""; return 0
  fi
  f=$(find "$dir" -maxdepth 1 -iname '*.AppImage' 2>/dev/null | head -n 1)
  [ -n "$f" ] && { echo "$f|"; return 0; }
  return 1
}

skip_dir() { # $1 nombre -> 0 si es carpeta auxiliar (no juego)
  echo "$1" | grep -qiE "$SKIPDIRS"
}

# ---------- prefix Wine ----------
is_prefix() { [ -f "$1/drive_c/windows/system32/kernel32.dll" ]; }
prefix_for() { # $1 slug -> prefix que le toca segun el modo elegido
  if [ "$PREFIX_MODE" = "per-game" ]; then echo "$PREFIX_BASE/$1"; else echo "$SHARED_PREFIX"; fi
}
create_shared_steps() { # crea SHARED_PREFIX con win10 + vcrun2019 + dxvk
  export WINEPREFIX="$SHARED_PREFIX" WINEARCH=win64 WINEDEBUG=-all
  echo "== creando prefix compartido en $SHARED_PREFIX =="
  mkdir -p "$SHARED_PREFIX" || return 1
  wineboot --init || return 1
  winetricks -q win10 || return 1
  winetricks -q vcrun2019 dxvk || return 1
  is_prefix "$SHARED_PREFIX"
}
validate_prefix_opts() { # return 1 si el modo/ruta de prefix no es usable (mensaje en $PERR)
  PERR=""
  case "$PREFIX_MODE" in
    per-game) return 0 ;;
    shared)
      [ -z "$SHARED_PREFIX" ] && { PERR="Falta la ubicación del prefix existente."; return 1; }
      is_prefix "$SHARED_PREFIX" || { PERR="No hay un prefix válido en:\n$SHARED_PREFIX"; return 1; }
      return 0 ;;
    shared-new)
      [ -z "$SHARED_PREFIX" ] && { PERR="Falta la ubicación para el prefix compartido."; return 1; }
      [ "$SHARED_PREFIX" = "$HOME" ] && { PERR="El prefix no puede ser tu HOME: elige una subcarpeta."; return 1; }
      if is_prefix "$SHARED_PREFIX"; then PERR="Ya existe un prefix en:\n$SHARED_PREFIX\nSe usará tal cual."; fi
      return 0 ;;
  esac
  PERR="Modo de prefix desconocido: $PREFIX_MODE"
  return 1
}

# ---------- registro ----------
build_sysblock() { # deja en $SYSBLK el bloque system: segun FPS_MODE/SAVE_LOG
  SYSBLK="system:
  gamemode: true"
  if [ "$FPS_MODE" = "mangohud" ]; then
    SYSBLK=$(printf '%s\n  mangohud: true' "$SYSBLK")
  fi
  ENVBLK=""
  if [ "$FPS_MODE" = "dxvk" ]; then
    ENVBLK=$(printf '%s\n      DXVK_HUD: fps,compiler' "$ENVBLK")
  fi
  if [ "$SAVE_LOG" -eq 1 ]; then
    ENVBLK=$(printf '%s\n      DXVK_LOG_LEVEL: info' "$ENVBLK")
  fi
  if [ -n "$ENVBLK" ]; then
    SYSBLK=$(printf '%s\n  env:%s' "$SYSBLK" "$ENVBLK")
  fi
}
do_register() { # $1 runner $2 nombre $3 slug $4 dir $5 exe $6 args $7 prefix
  local runner name slug dir exe args prefix cfg now
  runner="$1"; name="$2"; slug="$3"; dir="$4"; exe="$5"; args="$6"; prefix="$7"
  cfg="$slug-$EPOCH"; [ -f "$GAMES_DIR/$cfg.yml" ] && cfg="$cfg-$$"
  now=$(date +%s)
  build_sysblock
  if [ "$APPLY" -eq 1 ]; then
    if [ "$runner" = "wine" ]; then
      cat > "$GAMES_DIR/$cfg.yml" <<EOF
game:
  args: ''
  exe: $exe
  prefix: $prefix
  working_dir: $dir
$SYSBLK
wine:
  version: $WINE_VER
EOF
      sqlite3 "$PGA" "INSERT INTO games(name,slug,platform,runner,updated,lastplayed,installed,installed_at,configpath) VALUES('$(sq "$name")','$slug','Windows','wine',$now,0,1,$now,'$cfg');"
    else
      cat > "$GAMES_DIR/$cfg.yml" <<EOF
game:
  args: '$args'
  exe: $exe
  working_dir: $dir
$SYSBLK
EOF
      sqlite3 "$PGA" "INSERT INTO games(name,slug,platform,runner,updated,lastplayed,installed,installed_at,configpath) VALUES('$(sq "$name")','$slug','Linux','linux',$now,0,1,$now,'$cfg');"
    fi
  fi
}

update_yml() { # $1 yml -> aplica FPS_MODE/SAVE_LOG al system: existente (0 ok)
  FPS_MODE="$FPS_MODE" SAVE_LOG="$SAVE_LOG" YML="$1" python3 - <<'PYEOF'
import os, yaml
p = os.environ['YML']
mode = os.environ['FPS_MODE']
log = os.environ['SAVE_LOG'] == '1'
with open(p) as f:
    d = yaml.safe_load(f) or {}
sysd = d.get('system') or {}
if mode == 'mangohud':
    sysd['mangohud'] = True
    env = sysd.get('env') or {}
    env.pop('DXVK_HUD', None)
    if env: sysd['env'] = env
    else: sysd.pop('env', None)
elif mode == 'dxvk':
    sysd.pop('mangohud', None)
    env = sysd.get('env') or {}
    env['DXVK_HUD'] = 'fps,compiler'
    sysd['env'] = env
if log:
    env = sysd.get('env') or {}
    env['DXVK_LOG_LEVEL'] = 'info'
    sysd['env'] = env
d['system'] = sysd
with open(p, 'w') as f:
    yaml.safe_dump(d, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
PYEOF
}

emit_game() { # $1 runner $2 folder-name $3 dir $4 exe(ruta completa) $5 args
  local runner folder dir exe args name base slug prefix
  runner="$1"; folder="$2"; dir="$3"; exe="$4"; args="$5"
  name=$(pretty "$folder")
  [ -z "$name" ] && name="$folder"
  base=$(slugify "$name")
  if ! already_in_db "$base"; then
    # mismo juego con otro slug (ej. flood-land): usa el real, nunca dupliques
    m=$(db_slug_by_name "$(norm "$name")")
    [ -n "$m" ] && base="$m"
  fi
  if already_in_db "$base"; then
    if [ "$DO_UPDATE" -eq 1 ] && { [ "$FPS_MODE" != "none" ] || [ "$SAVE_LOG" -eq 1 ]; }; then
      cfg=$(sqlite3 "$PGA" "SELECT configpath FROM games WHERE slug='$base';")
      if [ -n "$cfg" ] && [ -f "$GAMES_DIR/$cfg.yml" ]; then
        if [ "$APPLY" -eq 1 ]; then
          update_yml "$GAMES_DIR/$cfg.yml" && echo "UPDATE | $base ($cfg.yml)" || echo "UPDATE-FAIL | $base"
        else
          echo "UPDATE (pendiente) | $base"
        fi
      else
        echo "SKIP (ya en Lutris, sin yml): $folder"
      fi
      return
    fi
    echo "SKIP (ya en Lutris): $folder"; return
  fi
  unique_slug "$base"; slug="$UNIQ_SLUG"
  [ "$slug" != "$base" ] && name="$name [${slug##*-}]"
  if [ "$runner" = "wine" ]; then
    prefix=$(prefix_for "$slug")
    echo "WINE  | $name | $exe"
    do_register wine "$name" "$slug" "$dir" "$exe" "" "$prefix"
    echo "  yml=$slug-$EPOCH.yml prefix=$prefix"
  else
    echo "LINUX | $name | $exe $args"
    do_register linux "$name" "$slug" "$dir" "$exe" "$args" ""
    echo "  yml=$slug-$EPOCH.yml"
  fi
}

process_win() { # $1 carpeta $2 depth $3 nombre-origen (para exe profundos en subcarpeta)
  local dir depth folder core exe sub origin
  dir="$1"; depth="$2"; origin="$3"
  folder=$(basename "$dir")
  [ "$depth" -eq 1 ] && skip_dir "$folder" && { echo "SKIP (auxiliar): $dir"; return; }
  core=$(norm "$(pretty "$folder")")
  if exe=$(find_win_top "$dir" "$core"); then
    emit_game wine "$folder" "$dir" "$exe" ""
    return
  fi
  if exe=$(find_win_deep "$dir" "$core"); then
    # exe profundo: nombra por la carpeta origen (ej. FactoryGame -> Satisfactory)
    [ "$depth" -eq 1 ] && folder="$origin"
    emit_game wine "$folder" "$(dirname "$exe")" "$exe" ""
    return
  fi
  if [ "$depth" -eq 0 ]; then
    for sub in "$dir"/*/; do
      [ -d "$sub" ] || continue
      process_win "${sub%/}" 1 "$folder"
    done
  else
    echo "SKIP (sin exe): $dir"
  fi
}

process_linux() {
  local dir depth folder core out exe args sub
  dir="$1"; depth="$2"
  folder=$(basename "$dir")
  [ "$depth" -eq 1 ] && skip_dir "$folder" && { echo "SKIP (auxiliar): $dir"; return; }
  core=$(norm "$(pretty "$folder")")
  if out=$(find_linux_launch "$dir" "$core"); then
    exe="${out%%|*}"; args="${out#*|}"
    emit_game linux "$folder" "$dir" "$exe" "$args"
    return
  fi
  if [ "$depth" -eq 0 ]; then
    for sub in "$dir"/*/; do
      [ -d "$sub" ] || continue
      process_linux "${sub%/}" 1
    done
  else
    echo "SKIP (sin lanzador): $dir"
  fi
}

# ---------- cambio de prefix para todos los registrados ----------
ensure_target_prefix() { # pregunta antes de usar/crear SET_PREFIX (regla de siempre)
  if is_prefix "$SET_PREFIX"; then
    if [ "$CLI_MODE" -eq 0 ]; then
      gui_question "¿Usar el prefix existente en:\n$SET_PREFIX\npara TODOS los juegos Wine?" || return 1
    else
      echo "Usando prefix existente: $SET_PREFIX"
    fi
    return 0
  fi
  if [ "$APPLY" -eq 0 ]; then
    echo "No hay prefix en $SET_PREFIX (se crearía con --apply)."
    return 0
  fi
  if [ "$CLI_MODE" -eq 0 ]; then
    gui_question "No hay prefix en:\n$SET_PREFIX\n¿Crearlo ahora (Windows 10 + vcrun2019 + DXVK, descarga de internet)?" || return 1
  else
    echo "Creando prefix en $SET_PREFIX ..."
  fi
  SHARED_PREFIX="$SET_PREFIX"
  create_shared_steps || { echo "ERROR: no se pudo crear el prefix."; return 1; }
  return 0
}

repoint_prefixes() { # cambia game.prefix de todos los Wine registrados a SET_PREFIX
  local rows slug cfg yml old n upd skip
  echo "== REPOINT de prefix: todos los Wine -> $SET_PREFIX =="
  ensure_target_prefix || return 1
  rows=$(sqlite3 "$PGA" "SELECT slug, configpath FROM games WHERE runner='wine';")
  [ -z "$rows" ] && { echo "No hay juegos Wine registrados."; return 0; }
  n=0; upd=0; skip=0
  while IFS='|' read -r slug cfg; do
    if [[ ",$EXCLUDE," == *",$slug,"* ]]; then echo "EXCLUIDO: $slug"; continue; fi
    yml="$GAMES_DIR/$cfg.yml"
    if [ ! -f "$yml" ]; then echo "SKIP (sin yml): $slug"; skip=$((skip+1)); continue; fi
    old=$(python3 -c "import yaml,sys; d=yaml.safe_load(open(sys.argv[1])) or {}; print((d.get('game') or {}).get('prefix',''))" "$yml")
    if [ -z "$old" ]; then echo "SKIP (sin prefix): $slug"; skip=$((skip+1)); continue; fi
    if [ "$old" = "$SET_PREFIX" ]; then echo "IGUAL: $slug (ya apunta ahí)"; continue; fi
    n=$((n+1))
    if [ "$APPLY" -eq 1 ]; then
      cp "$yml" "$yml.bak-$EPOCH"
      if SET_PREFIX="$SET_PREFIX" python3 - "$yml" <<'PYEOF'
import os, sys, yaml
p = sys.argv[1]
t = os.environ['SET_PREFIX']
d = yaml.safe_load(open(p)) or {}
g = d.get('game') or {}
g['prefix'] = t
d['game'] = g
open(p, 'w').write(yaml.safe_dump(d, default_flow_style=False, allow_unicode=True, sort_keys=False))
PYEOF
      then echo "UPDATE | $slug"; upd=$((upd+1))
      else echo "UPDATE-FAIL | $slug"; fi
    else
      echo "REPOINT (pendiente) | $slug"
      echo "  $old"
      echo "  -> $SET_PREFIX"
    fi
  done <<< "$rows"
  if [ "$APPLY" -eq 1 ]; then
    echo "Actualizados: $upd (ya estaban: $((n-upd)), omitidos: $skip). Reinicia Lutris."
  else
    echo "Juegos a cambiar: $n (omitidos: $skip). Repite con --apply."
  fi
}

# ---------- importacion ----------
run_import() {
  if [ "$REPOINT" -eq 1 ]; then repoint_prefixes; return $?; fi
  if [ "$APPLY" -eq 1 ]; then
    echo "== APLICANDO (escribiendo en Lutris) =="
  else
    echo "== DRY-RUN (sin --apply no se escribe nada) =="
  fi
  echo "-- Prefix: $PREFIX_MODE${SHARED_PREFIX:+ ($SHARED_PREFIX)} | FPS: $FPS_MODE | Log: $SAVE_LOG | Update: $DO_UPDATE"
  if [ -n "$WIN_DIR" ] && [ "$PREFIX_MODE" = "shared-new" ]; then
    if [ "$APPLY" -eq 1 ]; then
      if ! is_prefix "$SHARED_PREFIX"; then
        create_shared_steps || { echo "ERROR: no se pudo crear el prefix compartido."; return 1; }
      else
        echo "--- Prefix compartido ya existente: $SHARED_PREFIX ---"
      fi
    else
      echo "--- Prefix compartido a crear en: $SHARED_PREFIX ---"
    fi
  fi
  if [ -n "$WIN_DIR" ] && [ "$PREFIX_MODE" = "shared" ]; then
    echo "--- Prefix compartido (existente): $SHARED_PREFIX ---"
  fi
  if [ -n "$WIN_DIR" ]; then
    echo "--- Windows: $WIN_DIR ---"
    for sub in "$WIN_DIR"/*/; do
      [ -d "$sub" ] || continue
      process_win "${sub%/}" 0 ""
    done
  fi
  if [ -n "$LINUX_DIR" ]; then
    echo "--- Linux: $LINUX_DIR ---"
    for sub in "$LINUX_DIR"/*/; do
      [ -d "$sub" ] || continue
      process_linux "${sub%/}" 0
    done
  fi
  if [ "$APPLY" -eq 1 ]; then
    echo "Listo. Reinicia Lutris para verlos."
    if [ "$PREFIX_MODE" = "per-game" ]; then
      echo "Cada juego Wine usa su prefix en $PREFIX_BASE/<slug> (se crea al lanzarlo o con vrising.sh --setup --prefix ...)."
    else
      echo "Todos los juegos Wine usan el prefix compartido: $SHARED_PREFIX"
    fi
  else
    echo "Revisa la lista y repite con --apply para registrar."
  fi
}

save_config() {
  mkdir -p "$(dirname "$CONFIG")"
  printf 'WIN_DIR="%s"\nLINUX_DIR="%s"\nPREFIX_MODE="%s"\nSHARED_PREFIX="%s"\nFPS_MODE="%s"\nSAVE_LOG="%s"\nSET_PREFIX="%s"\n' \
    "$WIN_DIR" "$LINUX_DIR" "$PREFIX_MODE" "$SHARED_PREFIX" "$FPS_MODE" "$SAVE_LOG" "$SET_PREFIX" > "$CONFIG"
}

gui_ask() { # pide carpetas + modo de prefix + FPS/log; return 1 si cancela
  local out cb_opts cb_fps mode_sel fps_sel
  cb_opts="Uno por juego!Usar uno existente!Crear uno compartido"
  case "$PREFIX_MODE" in
    shared) cb_opts="Usar uno existente!Uno por juego!Crear uno compartido" ;;
    shared-new) cb_opts="Crear uno compartido!Uno por juego!Usar uno existente" ;;
  esac
  cb_fps="Ninguno!DXVK_HUD!MangoHud"
  case "$FPS_MODE" in
    dxvk) cb_fps="DXVK_HUD!Ninguno!MangoHud" ;;
    mangohud) cb_fps="MangoHud!Ninguno!DXVK_HUD" ;;
  esac
  out=$(yad --form --title="$TITLE" --width=650 \
    --text="Carpetas con juegos ya instalados" \
    --field="Juegos Windows:DIR" "${WIN_DIR:-$HOME}" \
    --field="Juegos Linux:DIR" "${LINUX_DIR:-$HOME}" \
    --field="Prefix para juegos Wine:CB" "$cb_opts" \
    --field="Prefix compartido (existente o a crear):DIR" "${SHARED_PREFIX:-$HOME}" \
    --field="Mostrar FPS:CB" "$cb_fps" \
    --field="Log detallado DXVK:CHK" FALSE \
    --field="Aplicar FPS/log a ya registrados:CHK" FALSE \
    --field="Solo cambiar prefix de registrados:CHK" FALSE \
    --field="Excluir slugs (separados por coma):TEXT" "" \
    --field="Registrar en Lutris:CHK" FALSE)
  [ $? -ne 0 ] && return 1
  WIN_DIR=$(echo "$out" | cut -d'|' -f1 | sed 's:/*$::')
  LINUX_DIR=$(echo "$out" | cut -d'|' -f2 | sed 's:/*$::')
  mode_sel=$(echo "$out" | cut -d'|' -f3)
  case "$mode_sel" in
    "Usar uno existente") PREFIX_MODE="shared" ;;
    "Crear uno compartido") PREFIX_MODE="shared-new" ;;
    *) PREFIX_MODE="per-game" ;;
  esac
  SHARED_PREFIX=$(echo "$out" | cut -d'|' -f4 | sed 's:/*$::')
  [ "$SHARED_PREFIX" = "$HOME" ] && SHARED_PREFIX=""
  fps_sel=$(echo "$out" | cut -d'|' -f5)
  case "$fps_sel" in
    "DXVK_HUD") FPS_MODE="dxvk" ;;
    "MangoHud") FPS_MODE="mangohud" ;;
    *) FPS_MODE="none" ;;
  esac
  [ "$(echo "$out" | cut -d'|' -f6)" = "TRUE" ] && SAVE_LOG=1
  [ "$(echo "$out" | cut -d'|' -f7)" = "TRUE" ] && DO_UPDATE=1
  [ "$(echo "$out" | cut -d'|' -f8)" = "TRUE" ] && REPOINT=1
  EXCLUDE=$(echo "$out" | cut -d'|' -f9)
  [ "$(echo "$out" | cut -d'|' -f10)" = "TRUE" ] && APPLY=1
  # re-point reutiliza el unico campo de prefix compartido (f4)
  [ "$REPOINT" -eq 1 ] && SET_PREFIX="$SHARED_PREFIX"
  return 0
}

check_env() { # verificaciones previas, return 1 si no se puede seguir
  command -v sqlite3 >/dev/null || { echo "ERROR: falta sqlite3"; return 1; }
  [ -f "$PGA" ] || { echo "ERROR: no existe $PGA"; return 1; }
  mkdir -p "$GAMES_DIR" "$PREFIX_BASE"
  if [ -z "$WIN_DIR" ] && [ -z "$LINUX_DIR" ]; then
    echo "ERROR: indica carpetas de juegos"
    return 1
  fi
  [ -n "$WIN_DIR" ] && [ ! -d "$WIN_DIR" ] && { echo "ERROR: no existe $WIN_DIR"; return 1; }
  [ -n "$LINUX_DIR" ] && [ ! -d "$LINUX_DIR" ] && { echo "ERROR: no existe $LINUX_DIR"; return 1; }
  if [ "$APPLY" -eq 1 ] && [ "$FORCE" -eq 0 ] && pgrep -x lutris >/dev/null; then
    echo "ERROR: cierra Lutris antes de importar (o usa --force)."
    return 1
  fi
  return 0
}

# ---------- modo GUI (sin flags de carpetas) ----------
if [ "$CLI_MODE" -eq 0 ]; then
  [ -z "$GUI" ] && { echo "ERROR: instala yad o zenity para la GUI (o usa --win/--linux)."; exit 1; }
  while true; do
    if [ "$GUI" = "yad" ]; then
      gui_ask || exit 0
    else
      WIN_DIR=$(zenity --file-selection --directory --title="Carpeta con juegos Windows" --filename="${WIN_DIR:-$HOME}/" 2>/dev/null | sed 's:/*$::') || exit 0
      LINUX_DIR=$(zenity --file-selection --directory --title="Carpeta con juegos Linux" --filename="${LINUX_DIR:-$HOME}/" 2>/dev/null | sed 's:/*$::') || exit 0
      mode_sel=$(zenity --list --radiolist --title="$TITLE" --text="Prefix para los juegos Wine" \
        --column="" --column="Modo" TRUE "Uno por juego" FALSE "Usar uno existente" FALSE "Crear uno compartido" 2>/dev/null) || exit 0
      case "$mode_sel" in
        "Usar uno existente") PREFIX_MODE="shared" ;;
        "Crear uno compartido") PREFIX_MODE="shared-new" ;;
        *) PREFIX_MODE="per-game" ;;
      esac
      if [ "$PREFIX_MODE" != "per-game" ]; then
        SHARED_PREFIX=$(zenity --file-selection --directory --title="Prefix compartido (existente o a crear)" --filename="${SHARED_PREFIX:-$HOME}/" 2>/dev/null | sed 's:/*$::') || exit 0
        [ "$SHARED_PREFIX" = "$HOME" ] && SHARED_PREFIX=""
      fi
      fps_sel=$(zenity --list --radiolist --title="$TITLE" --text="Mostrar FPS en los juegos" \
        --column="" --column="Modo" TRUE "Sin HUD" FALSE "HUD DXVK" FALSE "MangoHud" 2>/dev/null) || exit 0
      case "$fps_sel" in
        "HUD DXVK") FPS_MODE="dxvk" ;;
        "MangoHud") FPS_MODE="mangohud" ;;
        *) FPS_MODE="none" ;;
      esac
      gui_question "¿Guardar log detallado DXVK en cada juego?" && SAVE_LOG=1
      gui_question "¿Aplicar FPS/log también a los ya registrados?" && DO_UPDATE=1
      gui_question "¿Solo cambiar el prefix de los ya registrados (sin escanear carpetas)?" && REPOINT=1
      if [ "$REPOINT" -eq 1 ]; then
        # reutiliza el unico campo de prefix compartido
        SHARED_PREFIX=$(zenity --file-selection --directory --title="Prefix compartido (existente o a crear)" --filename="${SHARED_PREFIX:-$HOME}/" 2>/dev/null | sed 's:/*$::') || exit 0
        [ "$SHARED_PREFIX" = "$HOME" ] && SHARED_PREFIX=""
        SET_PREFIX="$SHARED_PREFIX"
        EXCLUDE=$(zenity --entry --title="$TITLE" --text="Excluir slugs (separados por coma, vacío = ninguno)" 2>/dev/null) || EXCLUDE=""
      fi
      gui_question "¿Registrar lo detectado en Lutris?\n(No = solo mostrar informe)" && APPLY=1
    fi
    if [ "$REPOINT" -eq 1 ]; then
      if [ -z "$SET_PREFIX" ]; then
        gui_error "Indica el nuevo prefix para todos."
        continue
      fi
      break
    fi
    if [ -z "$WIN_DIR" ] && [ -z "$LINUX_DIR" ]; then
      gui_error "Debes elegir al menos una carpeta."
      continue
    fi
    [ -z "$WIN_DIR" ] && break # solo Linux: no hay prefix que validar
    validate_prefix_opts && break
    gui_error "$PERR"
  done
  EXISTING_SLUGS=$(sqlite3 "$PGA" "SELECT slug FROM games;")
  if [ "$APPLY" -eq 1 ] && [ "$FORCE" -eq 0 ] && pgrep -x lutris >/dev/null; then
    gui_error "Cierra Lutris antes de importar."
    exit 1
  fi
  mkdir -p "$GAMES_DIR" "$PREFIX_BASE"
  if [ "$APPLY" -eq 1 ]; then
    cp "$PGA" "$LUTRIS_DIR/pga.db.bak-$EPOCH" 2>/dev/null
  fi
  : > "$IMPORT_LOG"
  ( run_import >>"$IMPORT_LOG" 2>&1 ) | gui_progress "Escaneando juegos..."
  save_config
  gui_results "$IMPORT_LOG"
  exit 0
fi

# ---------- modo CLI ----------
EXISTING_SLUGS=$(sqlite3 "$PGA" "SELECT slug FROM games;")
command -v sqlite3 >/dev/null || { echo "ERROR: falta sqlite3"; exit 1; }
[ -f "$PGA" ] || { echo "ERROR: no existe $PGA"; exit 1; }
mkdir -p "$GAMES_DIR" "$PREFIX_BASE"
if [ -z "$WIN_DIR" ] && [ -z "$LINUX_DIR" ] && [ "$REPOINT" -eq 0 ]; then
  echo "ERROR: indica --win DIR y/o --linux DIR (o --set-prefix DIR)"
  exit 1
fi
if [ "$REPOINT" -eq 1 ] && [ -z "$SET_PREFIX" ]; then
  echo "ERROR: --set-prefix necesita una carpeta."
  exit 1
fi
if [ -n "$WIN_DIR" ]; then
  validate_prefix_opts || { printf 'ERROR: %b\n' "$PERR"; exit 1; }
fi
if [ "$APPLY" -eq 1 ]; then
  if [ "$FORCE" -eq 0 ] && pgrep -x lutris >/dev/null; then
    echo "ERROR: cierra Lutris antes de importar (o usa --force)."
    exit 1
  fi
  cp "$PGA" "$LUTRIS_DIR/pga.db.bak-$EPOCH" && echo "Respaldo: pga.db.bak-$EPOCH"
fi
run_import

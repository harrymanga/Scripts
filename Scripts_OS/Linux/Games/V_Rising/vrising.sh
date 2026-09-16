#!/usr/bin/env bash
# V Rising en Manjaro + Wine - lanzador con GUI (yad/zenity) + modo CLI
#
# Sin rutas fijas: prefix, carpeta del juego y ejecutable se piden
# en la GUI, o se pasan por flags en CLI. Lo elegido se guarda en
# ~/.config/vrising-launcher.conf y se reutiliza como sugerencia.
#
# Regla de prefix: antes de usarlo se pregunta al usuario.
#  - Si ya existe uno y lo confirma, se usa.
#  - Si no existe (o no lo quiere), se crea e instala lo necesario
#    (Windows 10 + vcrun2019 + DXVK, con descarga de internet).
#
# Sin argumentos : abre la GUI (pide prefix, carpeta del juego y ejecutable)
# Con argumentos : modo CLI directo
#
# CLI: ./vrising.sh --prefix DIR --game-dir DIR --exe NOMBRE|RUTA
#                   [--fps] [--log ARCHIVO] [--kill] [--check] [--setup] [--gui] [--help]
set -u

TITLE="V Rising - Wine"
CONFIG="$HOME/.config/vrising-launcher.conf"
CREATE_LOG="/tmp/vrising-prefix-create.log"

# Sin valores fijos: solo lo que haya en el .conf de una eleccion anterior
PREFIX=""
GAME_DIR=""
EXE=""
[ -f "$CONFIG" ] && . "$CONFIG"

SHOW_FPS=0
LOGFILE=""
FORCE_GUI=0
CLI_MODE=0
DO_KILL=0
DO_CHECK=0
DO_SETUP=0

usage() {
  echo "Uso GUI : $0   (sin argumentos, pide prefix, juego y ejecutable con ventanas)"
  echo "Uso CLI : $0 --prefix DIR --game-dir DIR --exe NOMBRE|RUTA"
  echo "             [--fps] [--log ARCHIVO] [--kill] [--check] [--setup] [--gui] [--help]"
  echo "  --setup crea el prefix y descarga lo necesario sin lanzar el juego"
}

# ---------- deteccion GUI ----------
GUI=""
command -v yad >/dev/null && GUI="yad"
[ -z "$GUI" ] && command -v zenity >/dev/null && GUI="zenity"

# yad 15 no trae --info/--error/--question ni --no-cancel: esos dialogos
# van por zenity. yad solo se usa para el formulario (--form).
# Si no hay zenity, se emulan con yad --text-info + botones.
have_zenity() { command -v zenity >/dev/null; }
gui_info() {
  if have_zenity; then zenity --info --title="$TITLE" --text="$1" --width=450;
  else echo "$1" | yad --text-info --title="$TITLE" --width=450 --height=200 --button=Aceptar:0 >/dev/null; fi
}
gui_error() {
  if have_zenity; then zenity --error --title="$TITLE" --text="$1" --width=450;
  else echo "$1" | yad --text-info --title="$TITLE - error" --width=450 --height=200 --button=Aceptar:1 >/dev/null; fi
}
gui_question() { # $1 texto -> return 0 si Si
  if have_zenity; then zenity --question --title="$TITLE" --text="$1" --width=450;
  else echo "$1" | yad --text-info --title="$TITLE" --width=450 --height=200 --button=Sí:0 --button=No:1 >/dev/null; fi
}
gui_progress() { # lee stdin, se cierra con EOF (--auto-close)
  if have_zenity; then
    zenity --progress --pulsate --auto-close --no-cancel --title="$TITLE" --text="$1" --width=450
  else
    yad --progress --pulsate --auto-close --title="$TITLE" --text="$1" --width=450
  fi
}
gui_logview() { # $1 archivo
  if have_zenity; then zenity --text-info --title="$TITLE - errores" --filename="$1" --width=700 --height=500;
  else yad --text-info --title="$TITLE - errores" --filename="$1" --width=700 --height=500 --button=Cerrar:0 >/dev/null; fi
}

# ---------- validaciones ----------
is_prefix() { [ -f "$1/drive_c/windows/system32/kernel32.dll" ]; }
has_dxvk() { # override nativo de d3d11 en el prefix (winetricks lo guarda como *d3d11)
  WINEPREFIX="$1" WINEDEBUG=-all wine reg query "HKCU\\Software\\Wine\\DllOverrides" 2>/dev/null | grep -qi "d3d11.*native"
}

# ---------- creacion de prefix ----------
create_prefix_steps() { # salida a CREATE_LOG; stdout queda para el dialogo de progreso
  export WINEPREFIX="$PREFIX" WINEARCH=win64 WINEDEBUG=-all
  echo "== wineboot --init =="
  wineboot --init || return 1
  echo "== winetricks win10 =="
  winetricks -q win10 || return 1
  echo "== winetricks vcrun2019 dxvk =="
  winetricks -q vcrun2019 dxvk || return 1
  return 0
}

# Pregunta antes de usar el prefix. Retorna:
#   0 = listo para usar | 1 = fatal/cancelado | 2 = elegir otra carpeta
ensure_prefix() {
  if is_prefix "$PREFIX"; then
    if ! gui_question "Ya existe un prefix de Wine en:\n$PREFIX\n\n¿Quieres usarlo para este juego?"; then
      return 2
    fi
    if ! has_dxvk "$PREFIX"; then
      if gui_question "El prefix existe pero sin DXVK.\n¿Instalar vcrun2019 + DXVK ahora?"; then
        : > "$CREATE_LOG"
        ( create_prefix_steps >>"$CREATE_LOG" 2>&1 ) | gui_progress "Instalando librerias en el prefix..."
        rc=${PIPESTATUS[0]}
        [ "$rc" -eq 0 ] && gui_info "Librerias instaladas." \
          || { gui_error "Fallo la instalacion. Revisa $CREATE_LOG"; return 1; }
      fi
    else
      gui_info "Usando el prefix existente:\n$PREFIX"
    fi
    return 0
  fi
  gui_question "No hay un prefix de Wine en:\n$PREFIX\n\n¿Crear el prefix e instalar lo necesario (Windows 10 + vcrun2019 + DXVK)?\nTarda unos minutos (descarga de internet)." || return 1
  mkdir -p "$PREFIX"
  : > "$CREATE_LOG"
  ( create_prefix_steps >>"$CREATE_LOG" 2>&1 ) | gui_progress "Creando prefix e instalando dependencias..."
  rc=${PIPESTATUS[0]}
  if [ "$rc" -eq 0 ] && is_prefix "$PREFIX"; then
    gui_info "Prefix creado correctamente en:\n$PREFIX"
    return 0
  fi
  gui_error "No se pudo crear el prefix. Revisa $CREATE_LOG"
  if gui_question "¿Ver el registro de errores?"; then
    gui_logview "$CREATE_LOG"
  fi
  return 1
}

# ---------- creacion de prefix (modo texto, para CLI) ----------
cli_setup_prefix() {
  mkdir -p "$PREFIX"
  echo "Prefix: $PREFIX"
  echo "Esto descarga vcrun2019 + DXVK (requiere internet, unos minutos)..."
  echo "Detalle en $CREATE_LOG"
  : > "$CREATE_LOG"
  create_prefix_steps 2>&1 | tee "$CREATE_LOG"
  rc=${PIPESTATUS[0]}
  if [ "$rc" -eq 0 ] && is_prefix "$PREFIX"; then
    echo "Prefix listo en $PREFIX"
    return 0
  fi
  echo "ERROR: no se pudo crear el prefix. Revisa $CREATE_LOG"
  return 1
}

# ---------- GUI: pedir datos (sin rutas fijas, parten de $HOME) ----------
gui_ask_yad() {
  start_exe="$HOME"
  [ -n "$GAME_DIR" ] && [ -n "$EXE" ] && [ -f "$GAME_DIR/$EXE" ] && start_exe="$GAME_DIR/$EXE"
  out=$(yad --form --title="$TITLE" --width=600 \
    --text="Elige prefix, juego y ejecutable (se guarda para la proxima vez)" \
    --field="Carpeta del prefix:DIR" "${PREFIX:-$HOME}" \
    --field="Carpeta del juego:DIR" "${GAME_DIR:-$HOME}" \
    --field="Ejecutable:FL" "$start_exe" \
    --field="Mostrar FPS:CHK" FALSE \
    --field="Guardar log en /tmp:CHK" FALSE)
  [ $? -ne 0 ] && return 1
  PREFIX=$(echo "$out" | cut -d'|' -f1 | sed 's:/*$::')
  GAME_DIR=$(echo "$out" | cut -d'|' -f2 | sed 's:/*$::')
  full_exe=$(echo "$out" | cut -d'|' -f3)
  EXE=$(basename "$full_exe")
  [ "$(dirname "$full_exe")" != "." ] && GAME_DIR=$(dirname "$full_exe")
  [ "$(echo "$out" | cut -d'|' -f4)" = "TRUE" ] && SHOW_FPS=1
  [ "$(echo "$out" | cut -d'|' -f5)" = "TRUE" ] && LOGFILE="/tmp/vrising-$(date +%Y%m%d-%H%M%S).log"
  return 0
}

gui_ask_zenity() {
  PREFIX=$(zenity --file-selection --directory --title="Elige la carpeta del prefix" --filename="${PREFIX:-$HOME}/" 2>/dev/null | sed 's:/*$::') || return 1
  GAME_DIR=$(zenity --file-selection --directory --title="Elige la carpeta del juego" --filename="${GAME_DIR:-$HOME}/" 2>/dev/null | sed 's:/*$::') || return 1
  full_exe=$(zenity --file-selection --title="Elige el ejecutable" --filename="$GAME_DIR/" --file-filter="*.exe" 2>/dev/null) || return 1
  EXE=$(basename "$full_exe")
  GAME_DIR=$(dirname "$full_exe")
  opts=$(zenity --list --checklist --title="$TITLE" --text="Opciones" --column="" --column="Opcion" \
    FALSE "Mostrar FPS" FALSE "Guardar log en /tmp" 2>/dev/null) || return 1
  echo "$opts" | grep -q "Mostrar FPS" && SHOW_FPS=1
  echo "$opts" | grep -q "Guardar log" && LOGFILE="/tmp/vrising-$(date +%Y%m%d-%H%M%S).log"
  return 0
}

save_config() {
  mkdir -p "$(dirname "$CONFIG")"
  printf 'PREFIX="%s"\nGAME_DIR="%s"\nEXE="%s"\n' "$PREFIX" "$GAME_DIR" "$EXE" > "$CONFIG"
}

# ---------- lanzamiento ----------
launch() {
  export WINEPREFIX="$PREFIX" WINEARCH=win64
  export WINEESYNC=1 WINEFSYNC=1 WINEDEBUG=-all
  export DXVK_LOG_LEVEL=info
  export RADV_PERFTEST=gpl
  export MESA_SHADER_CACHE_MAX_SIZE=10G
  [ "$SHOW_FPS" -eq 1 ] && export DXVK_HUD="fps,compiler"
  cd "$GAME_DIR" || exit 1
  if [ -n "$LOGFILE" ]; then
    wine "$EXE" 2>&1 | tee "$LOGFILE"
  else
    exec wine "$EXE"
  fi
}

# ---------- parseo CLI ----------
while [ $# -gt 0 ]; do
  CLI_MODE=1
  case "$1" in
    --prefix)   PREFIX="${2%/}"; shift 2 ;;
    --prefix=*) PREFIX="${1#--prefix=}"; PREFIX="${PREFIX%/}"; shift ;;
    --game-dir)   GAME_DIR="${2%/}"; shift 2 ;;
    --game-dir=*) GAME_DIR="${1#--game-dir=}"; GAME_DIR="${GAME_DIR%/}"; shift ;;
    --exe) EXE="$2"; shift 2 ;;
    --exe=*) EXE="${1#--exe=}"; shift ;;
    --fps) SHOW_FPS=1; shift ;;
    --log) LOGFILE="$2"; shift 2 ;;
    --log=*) LOGFILE="${1#--log=}"; shift ;;
    --kill) DO_KILL=1; shift ;;
    --check) DO_CHECK=1; shift ;;
    --setup) DO_SETUP=1; shift ;;
    --gui) FORCE_GUI=1; CLI_MODE=0; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Opcion desconocida: $1"; usage; exit 1 ;;
  esac
done

# --exe puede venir como ruta completa
case "$EXE" in
  */*) GAME_DIR=$(dirname "$EXE"); EXE=$(basename "$EXE") ;;
esac

# En CLI no hay valores implicitos: lo que falte se pide por flags o via GUI
if [ "$CLI_MODE" -eq 1 ]; then
  if [ "$DO_KILL" -eq 1 ]; then
    [ -z "$PREFIX" ] && { echo "ERROR: falta --prefix (o ejecuta sin argumentos para la GUI)."; exit 1; }
  elif [ "$DO_SETUP" -eq 1 ]; then
    [ -z "$PREFIX" ] && { echo "ERROR: --setup necesita --prefix (o ejecuta sin argumentos para la GUI)."; exit 1; }
  else
    missing=""
    [ -z "$PREFIX" ] && missing="$missing --prefix"
    [ -z "$GAME_DIR" ] && missing="$missing --game-dir"
    [ -z "$EXE" ] && missing="$missing --exe"
    if [ -n "$missing" ]; then
      echo "ERROR: faltan rutas:$missing"
      echo "Pasaselas por flags o ejecuta sin argumentos: la GUI las pide y las guarda en $CONFIG."
      exit 1
    fi
  fi
fi

# ---------- acciones CLI sin GUI ----------
if [ "$DO_KILL" -eq 1 ]; then
  WINEPREFIX="$PREFIX" wineserver -k 2>/dev/null || true
  echo "Prefix detenido."
  exit 0
fi

if [ "$DO_CHECK" -eq 1 ]; then
  fail=0
  [ -d "$GAME_DIR" ] || { echo "ERROR: sin GAME_DIR (disco montado?)"; fail=1; }
  [ -f "$GAME_DIR/$EXE" ] || { echo "ERROR: sin $EXE"; fail=1; }
  is_prefix "$PREFIX" || { echo "ERROR: $PREFIX no es un prefix"; fail=1; }
  has_dxvk "$PREFIX" || echo "AVISO: prefix sin override DXVK nativo"
  [ "$fail" -eq 1 ] && exit 1
  echo "OK: $GAME_DIR/$EXE + prefix $PREFIX ($(wine --version))"
  echo "GUI detectada: ${GUI:-(ninguna: instala yad o zenity)}"
  exit 0
fi

# ---------- modo GUI ----------
if [ "$CLI_MODE" -eq 0 ] || [ "$FORCE_GUI" -eq 1 ]; then
  [ -z "$GUI" ] && { echo "ERROR: instala yad o zenity para la GUI (o usa flags CLI)."; exit 1; }
  while true; do
    if [ "$GUI" = "yad" ]; then gui_ask_yad || exit 0
    else gui_ask_zenity || exit 0; fi
    if [ -z "$PREFIX" ] || [ -z "$GAME_DIR" ] || [ -z "$EXE" ] || [ "$PREFIX" = "$HOME" ]; then
      gui_error "Debes elegir las tres rutas (prefix, carpeta del juego y ejecutable).\nEl prefix no puede ser tu $HOME directamente: elige o crea una subcarpeta."
      continue
    fi
    [ -f "$GAME_DIR/$EXE" ] || { gui_error "No existe el ejecutable:\n$GAME_DIR/$EXE"; exit 1; }
    if [ ! -d "$GAME_DIR/${EXE%.exe}_Data" ]; then
      gui_question "Aviso: no se ve carpeta ${EXE%.exe}_Data junto al exe.\n¿Continuar igualmente?" || exit 0
    fi
    ensure_prefix
    rc=$?
    [ "$rc" -eq 0 ] && break
    [ "$rc" -eq 2 ] && continue # eligio otro prefix: vuelve a pedir rutas
    exit 1
  done
  save_config
  launch
  exit 0
fi

# ---------- modo CLI directo (crea el prefix si falta) ----------
if [ ! -f "$GAME_DIR/$EXE" ] && [ "$DO_SETUP" -eq 0 ]; then
  echo "ERROR: sin $GAME_DIR/$EXE"
  exit 1
fi
if ! is_prefix "$PREFIX"; then
  echo "No hay prefix en $PREFIX, creandolo y descargando lo necesario..."
  cli_setup_prefix || exit 1
elif ! has_dxvk "$PREFIX"; then
  echo "El prefix existe pero sin DXVK, instalando librerias..."
  cli_setup_prefix || exit 1
else
  echo "Usando prefix existente: $PREFIX"
fi
if [ "$DO_SETUP" -eq 1 ]; then
  echo "Setup OK sin lanzar el juego."
  exit 0
fi
save_config
launch

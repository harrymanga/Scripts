#!/bin/bash
# jar_manager.sh — Versión única canónica (empaquetar/desempaquetar JAR).
# Fusiona: GUI_YAD, GUI_ZENITY, Jar_Manager_Modular y Jar_Manager_Pro.
# Uso GUI: jar_manager.sh [es|en]
# Uso CLI: jar_manager.sh [--cli] pack|unpack SALIDA items...
#   Ej: jar_manager.sh --cli unpack ~/salida app1.jar app2.jar
# Requiere: jar (JDK), unzip + yad o zenity (instalación asistida).
# Ver README.md. Log: $HOME/jar_manager.log

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

# --- Idioma: parámetro > $LANG > es ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[[ "${1:-}" == "en" ]] && { LANG_ID="en"; shift; }
[[ "${1:-}" == "es" ]] && { LANG_ID="es"; shift; }
# shellcheck disable=SC1090
. "$SCRIPT_DIR/lang_${LANG_ID}.sh"

LOG_FILE="${LOG_FILE:-$HOME/jar_manager.log}"
# shellcheck disable=SC1090
. "$SCRIPT_DIR/lib/jar_core.sh"

# --- Dependencias (instalación asistida) ---
ensure_dep() {
    local cmd="$1" pkg_apt="$2" pkg_dnf="$3" pkg_pac="$4"
    command -v "$cmd" &>/dev/null && return 0
    # shellcheck disable=SC2059
    printf "$MSG_DEP_MISSING\n" "$cmd"
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg_apt" || { echo "$MSG_DEP_FAIL" | sed "s/%s/$cmd/"; return 1; }
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg_dnf" || { echo "$MSG_DEP_FAIL" | sed "s/%s/$cmd/"; return 1; }
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "$pkg_pac" || { echo "$MSG_DEP_FAIL" | sed "s/%s/$cmd/"; return 1; }
    else
        echo "$MSG_DEP_FAIL" | sed "s/%s/$cmd/"
        return 1
    fi
}

ensure_dep jar default-jdk-headless java-latest-openjdk jdk-openjdk || exit 1
ensure_dep unzip unzip unzip unzip || exit 1

if command -v yad &>/dev/null; then
    GUI="yad"
elif command -v zenity &>/dev/null; then
    GUI="zenity"
else
    ensure_dep yad yad yad yad || ensure_dep zenity zenity zenity zenity || exit 1
    command -v yad &>/dev/null && GUI="yad" || GUI="zenity"
fi

# ---------- Diálogos (yad/zenity) ----------
dlg_action() {
    if [[ "$GUI" == "yad" ]]; then
        local a
        a=$(yad --list --radiolist --title="$MSG_APP" \
            --column="Sel" --column="Acción" \
            TRUE "unpack" FALSE "pack" FALSE "exit" \
            --height=250 --width=300) || return 1
        echo "$a" | cut -d'|' -f2 | xargs
    else
        zenity --list --title="$MSG_APP" --column="Acción" \
            "unpack" "pack" "exit" || return 1
    fi
}

dlg_outdir() {
    if [[ "$GUI" == "yad" ]]; then
        yad --file --directory --title="$MSG_OUTDIR" || return 1
    else
        zenity --file-selection --directory --title="$MSG_OUTDIR" || return 1
    fi
}

dlg_pick_jar() {
    if [[ "$GUI" == "yad" ]]; then
        yad --file --multiple --separator="|" \
            --title="$MSG_PICK_JAR" --file-filter="*.jar" || return 1
    else
        zenity --file-selection --multiple --separator="|" \
            --title="$MSG_PICK_JAR" --file-filter="*.jar" || return 1
    fi
}

dlg_pick_dirs() {
    if [[ "$GUI" == "yad" ]]; then
        yad --file --multiple --separator="|" --directory \
            --title="$MSG_PICK_DIR" || return 1
    else
        zenity --file-selection --multiple --separator="|" --directory \
            --title="$MSG_PICK_DIR" || return 1
    fi
}

dlg_name() {
    local base="$1"
    if [[ "$GUI" == "yad" ]]; then
        yad --entry --title="$MSG_JAR_NAME" --text="$MSG_JAR_NAME_TEXT" \
            --entry-text="$base" || return 1
    else
        zenity --entry --title="$MSG_JAR_NAME" --text="$MSG_JAR_NAME_TEXT" \
            --entry-text="$base" || return 1
    fi
}

dlg_info() {
    if [[ "$GUI" == "yad" ]]; then
        yad --info --text="$1"
    else
        zenity --info --text="$1"
    fi
}

# ---------- CLI ----------
if [[ "${1:-}" == "--cli" ]]; then
    shift
    [[ $# -lt 3 ]] && { echo "$MSG_CLI_USE"; exit 1; }
    ACTION="$1" OUTPUT="$2"
    shift 2
    mkdir -p "$OUTPUT"
    for item in "$@"; do
        if [[ "$ACTION" == "unpack" ]]; then
            unpack_jar "$item" "$OUTPUT"
        elif [[ "$ACTION" == "pack" ]]; then
            pack_directory "$item" "$OUTPUT" "$(basename "$item")"
        else
            echo "$MSG_BAD_ACTION"
            exit 1
        fi
    done
    echo "$MSG_DONE_CLI"
    exit 0
fi

# ---------- GUI (bucle) ----------
while true; do
    ACTION=$(dlg_action) || break
    [[ "$ACTION" == "exit" ]] && break

    OUTPUT_DIR=$(dlg_outdir) || continue

    if [[ "$ACTION" == "unpack" ]]; then
        FILES=$(dlg_pick_jar) || continue
        IFS="|" read -ra FILE_ARRAY <<< "$FILES"
        for FILE in "${FILE_ARRAY[@]}"; do
            unpack_jar "$FILE" "$OUTPUT_DIR"
        done
        dlg_info "$MSG_UNPACK_DONE"
    elif [[ "$ACTION" == "pack" ]]; then
        DIRS=$(dlg_pick_dirs) || continue
        IFS="|" read -ra DIR_ARRAY <<< "$DIRS"
        for DIR in "${DIR_ARRAY[@]}"; do
            CUSTOM=$(dlg_name "$(basename "$DIR")") || continue
            pack_directory "$DIR" "$OUTPUT_DIR" "$CUSTOM"
        done
        dlg_info "$MSG_PACK_DONE"
    fi
done

exit 0

#!/bin/bash

# ==========================================================
# TRADUCTOR .LANG PRO 5.1 (versión única canónica)
# Google principal + fallback inteligente + placeholders
# Reemplaza a: pro, pro_fix, as, exd, ultra_pro (ver README del grupo).
# Uso: fui.sh [es|en]   Idioma: parámetro > $LANG > es.
# ==========================================================

# --- Idioma ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[ "$1" = "en" ] && LANG_ID="en"
[ "$1" = "es" ] && LANG_ID="es"
# shellcheck disable=SC1090
. "$(dirname "$0")/lang_multimotor_${LANG_ID}.sh"

APP_NAME="Traductor .lang PRO"
VERSION="5.1"

BASE_DIR="$HOME/.traductor_lang_pro"
CACHE_DIR="$BASE_DIR/cache"
BACKUP_DIR="$BASE_DIR/backups"
LOG_DIR="$BASE_DIR/logs"
CONFIG_FILE="$BASE_DIR/config.conf"

mkdir -p "$CACHE_DIR" "$BACKUP_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S).log"

# ==========================================================
# UTILIDADES
# ==========================================================

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

error_msg() {
    yad --error --title="Error" --text="$1"
}

escape_json() {
    echo "$1" | jq -Rs .
}

hash_text() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

check_cache() {
    FILE="$CACHE_DIR/$(hash_text "$1").txt"
    [ -f "$FILE" ] && cat "$FILE" && return 0
    return 1
}

save_cache() {
    echo "$2" > "$CACHE_DIR/$(hash_text "$1").txt"
}

# ==========================================================
# PLACEHOLDERS (port de pro/fix/as: <tag>, %s/%d, {var})
# Sin subshell: escriben PROTECTED_TEXT / RESTORED_TEXT y usan
# el contador global PH_COUNTER (válido para lotes completos).
# ==========================================================

protect_patterns() {
    local text="$1"
    mapfile -t MATCHES < <(echo "$text" | grep -oE '<[^>]+>|%[sd]|\{[^}]+\}')
    local m
    for m in "${MATCHES[@]}"; do
        local token="⟦$PH_COUNTER⟧"
        PLACEHOLDERS[$PH_COUNTER]="$m"
        text="${text//$m/$token}"
        PH_COUNTER=$((PH_COUNTER+1))
    done
    PROTECTED_TEXT="$text"
}

restore_patterns() {
    local text="$1"
    local i
    for i in "${!PLACEHOLDERS[@]}"; do
        local token="⟦$i⟧"
        text="${text//$token/${PLACEHOLDERS[$i]}}"
    done
    RESTORED_TEXT="$text"
}

# ==========================================================
# CONFIG API KEYS
# ==========================================================

load_config() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
}

save_config() {
cat > "$CONFIG_FILE" <<EOF
GOOGLE_API_KEY="$GOOGLE_API_KEY"
DEEPL_API_KEY="$DEEPL_API_KEY"
OPENAI_API_KEY="$OPENAI_API_KEY"
EOF
}

configure_keys() {
FORM=$(yad --form \
  --title="$MSG_CFG_TITLE" \
  --separator="|" \
  --field="$MSG_FLD_GOOGLE" "$GOOGLE_API_KEY" \
  --field="$MSG_FLD_DEEPL" "$DEEPL_API_KEY" \
  --field="$MSG_FLD_OPENAI" "$OPENAI_API_KEY")

[ -z "$FORM" ] && return

IFS="|" read GOOGLE_API_KEY DEEPL_API_KEY OPENAI_API_KEY <<< "$FORM"
save_config
}

# ==========================================================
# GOOGLE (PRINCIPAL) - BATCH MODE
# ==========================================================

translate_google_batch() {

    TARGET="$1"
    shift
    TEXTS=("$@")

    JSON_TEXTS=""
    for T in "${TEXTS[@]}"; do
        JSON_TEXTS="$JSON_TEXTS $(escape_json "$T"),"
    done

    JSON_TEXTS="[${JSON_TEXTS%,}]"

    RESPONSE=$(curl -s \
      -X POST \
      "https://translation.googleapis.com/language/translate/v2?key=$GOOGLE_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
            \"q\": $JSON_TEXTS,
            \"target\": \"$TARGET\",
            \"format\": \"text\"
          }")

    ERROR=$(echo "$RESPONSE" | jq -r '.error.message')

    if [ "$ERROR" != "null" ]; then
        log "Google error: $ERROR"
        echo "__ERROR__"
        return
    fi

    echo "$RESPONSE" | jq -r '.data.translations[].translatedText'
}

# ==========================================================
# GOOGLE (FREE)
# ==========================================================

translate_trans_shell() {
    RESULT=$(trans -brief :"$2" "$1" 2>/dev/null)

    if [ -z "$RESULT" ]; then
        echo "__ERROR__"
        return
    fi

    echo "$RESULT"
}

# ==========================================================
# FALLBACK: DEEPL
# ==========================================================

translate_deepl() {
    RESPONSE=$(curl -s https://api-free.deepl.com/v2/translate \
      -d auth_key="$DEEPL_API_KEY" \
      -d text="$1" \
      -d target_lang="$2")

    echo "$RESPONSE" | jq -r '.translations[0].text'
}

# ==========================================================
# FALLBACK: OPENAI
# ==========================================================

translate_openai() {

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"gpt-4o-mini\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"Traduce al idioma $2. Devuelve solo el texto.\"},
      {\"role\": \"user\", \"content\": \"$1\"}
    ]
  }")

echo "$RESPONSE" | jq -r '.choices[0].message.content'
}

# ==========================================================
# FALLBACK: Translate
# ==========================================================

translate_with_fallback() {

    TARGET="$1"
    shift
    TEXTS=("$@")

    # 1️⃣ Intentar Google API
    RESULTS=$(translate_google_batch "$TARGET" "${TEXTS[@]}")

    if [ "$RESULTS" != "__ERROR__" ]; then
        echo "$RESULTS"
        return
    fi

    log "Google API falló → usando trans-shell"

    # 2️⃣ Intentar trans-shell uno por uno
    TEMP_RESULTS=""
    for T in "${TEXTS[@]}"; do
        R=$(translate_trans_shell "$T" "$TARGET")
        [ "$R" = "__ERROR__" ] && R="$T"
        TEMP_RESULTS+="$R"$'\n'
    done

    echo "$TEMP_RESULTS"
}

# ==========================================================
# PROCESAR ARCHIVO CON BATCH INTELIGENTE
# ==========================================================

procesar_archivo() {

FILE="$1"
TARGET="$2"

cp "$FILE" "$BACKUP_DIR/$(basename "$FILE").bak"

OUTPUT="${FILE%.lang}_$TARGET.lang"
> "$OUTPUT"

declare -a VALUES
declare -a KEYS

while IFS= read -r LINE; do

    if [[ "$LINE" =~ ^# ]] || [[ "$LINE" != *=* ]]; then
        echo "$LINE" >> "$OUTPUT"
        continue
    fi

    KEY="${LINE%%=*}"
    VALUE="${LINE#*=}"

    KEYS+=("$KEY")
    VALUES+=("$VALUE")

done < "$FILE"

# Batch Google (con placeholders protegidos)

declare -a PROTECTED
PH_COUNTER=0
PLACEHOLDERS=()
for VALUE in "${VALUES[@]}"; do
    protect_patterns "$VALUE"
    PROTECTED+=("$PROTECTED_TEXT")
done

RESULTS=$(translate_with_fallback "$TARGET" "${PROTECTED[@]}")

if [ "$RESULTS" = "__ERROR__" ]; then
    error_msg "$MSG_GOOGLE_FAIL"
fi

i=0
while read -r TRANS; do
    restore_patterns "$TRANS"
    echo "${KEYS[$i]}=$RESTORED_TEXT" >> "$OUTPUT"
    i=$((i+1))
done <<< "$RESULTS"

log "$MSG_PROCESSED $FILE"
}

# ==========================================================
# MAIN LOOP
# ==========================================================

load_config

while true; do

FORM=$(yad --form \
  --title="$APP_NAME v$VERSION" \
  --separator="|" \
  --field="$MSG_LANG" "" \
  --field="$MSG_CFG_CHK:CHK" FALSE)

[ -z "$FORM" ] && break

IFS="|" read TARGET CONFIGURE <<< "$FORM"

[ "$CONFIGURE" = "TRUE" ] && configure_keys && continue

FILES=$(yad --file --multiple --file-filter="*.lang")
[ -z "$FILES" ] && continue

IFS="|" read -ra FILE_ARRAY <<< "$FILES"

TOTAL=${#FILE_ARRAY[@]}
COUNT=0

(
for FILE in "${FILE_ARRAY[@]}"; do
    COUNT=$((COUNT+1))
    # shellcheck disable=SC2059
    printf "# $MSG_PROC\n" "$COUNT" "$TOTAL"
    procesar_archivo "$FILE" "$TARGET"
    echo $((COUNT*100/TOTAL))
done
) | yad --progress --auto-close --auto-kill

# shellcheck disable=SC2059
yad --question \
--text="$(printf "$MSG_DONE_1\n\n$MSG_FILES %s\n\n$MSG_NEW" "$TOTAL")" \
--button="$MSG_YES":0 \
--button="$MSG_EXIT":1

[ $? -eq 0 ] && continue || break

done

exit 0

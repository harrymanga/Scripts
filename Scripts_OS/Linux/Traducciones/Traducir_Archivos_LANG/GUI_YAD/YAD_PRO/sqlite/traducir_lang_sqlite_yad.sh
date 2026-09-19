#!/bin/bash
# dr.sh — Traductor .lang con caché SQLite (variante conservada, ver README).
# Uso: dr.sh [es|en]   Idioma: parámetro > $LANG > es.

# --- Idioma ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[ "$1" = "en" ] && LANG_ID="en"
[ "$1" = "es" ] && LANG_ID="es"
# shellcheck disable=SC1090
. "$(dirname "$0")/lang_sqlite_${LANG_ID}.sh"

APP_NAME="Lang Translator PRO INDUSTRIAL"
TMPDIR="/tmp/lang_translate_pro"
CACHE_DB="$TMPDIR/cache.db"
LOGFILE="$TMPDIR/app.log"

mkdir -p "$TMPDIR"

# ===============================
# INIT CACHE
# ===============================

init_db() {
sqlite3 "$CACHE_DB" <<EOF
CREATE TABLE IF NOT EXISTS translations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    method TEXT,
    target_lang TEXT,
    original TEXT,
    translated TEXT,
    UNIQUE(method,target_lang,original)
);
EOF
}
init_db

# ===============================
# CACHE FUNCTIONS
# ===============================

cache_get() {
sqlite3 "$CACHE_DB" \
"SELECT translated FROM translations
 WHERE method='$METHOD'
 AND target_lang='$TARGET_LANG'
 AND original=$(printf "%q" "$1")
 LIMIT 1;"
}

cache_save() {
sqlite3 "$CACHE_DB" \
"INSERT OR IGNORE INTO translations
(method,target_lang,original,translated)
VALUES('$METHOD','$TARGET_LANG',
$(printf "%q" "$1"),
$(printf "%q" "$2"));"
}

# ===============================
# UUID TOKEN GENERATOR
# ===============================

generate_token() {
    echo "__PH_$(uuidgen | tr -d '-')__"
}

# ===============================
# PLACEHOLDER PROTECTION (UUID)
# ===============================

protect_patterns() {
    local text="$1"
    PLACEHOLDER_MAP=()

    local regex='(<[^>]+>|%[sd]|\\n|\{[^}]+\})'

    while [[ "$text" =~ $regex ]]; do
        match="${BASH_REMATCH[0]}"
        token=$(generate_token)
        PLACEHOLDER_MAP+=("$token|$match")
        text="${text/$match/$token}"
    done

    echo "$text"
}

restore_patterns() {
    local text="$1"

    for pair in "${PLACEHOLDER_MAP[@]}"; do
        token="${pair%%|*}"
        original="${pair#*|}"
        text="${text//$token/$original}"
    done

    echo "$text"
}

# ===============================
# VALIDATION
# ===============================

validate_placeholders() {
    local translated="$1"

    for pair in "${PLACEHOLDER_MAP[@]}"; do
        token="${pair%%|*}"
        if [[ "$translated" != *"$token"* ]]; then
            return 1
        fi
    done

    return 0
}

# ===============================
# TRANSLATION CORE
# ===============================

translate_api() {

    case "$METHOD" in
        "Google")
            trans -brief :"$TARGET_LANG" "$1"
            ;;
        "DeepL")
            RESULT=$(curl -s -X POST "https://api-free.deepl.com/v2/translate" \
                -d auth_key="$DEEPL_KEY" \
                -d text="$1" \
                -d target_lang="$TARGET_LANG" | jq -r '.translations[0].text')
            echo "$RESULT"
            ;;
        "OpenAI")
            curl -s https://api.openai.com/v1/chat/completions \
                -H "Authorization: Bearer $OPENAI_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"model\":\"gpt-4o-mini\",
                    \"messages\":[
                        {\"role\":\"system\",\"content\":\"Translate to $TARGET_LANG. DO NOT modify tokens like __PH_xxx__. Keep them EXACTLY.\"},
                        {\"role\":\"user\",\"content\":\"$1\"}
                    ]
                }" | jq -r '.choices[0].message.content'
            ;;
    esac
}

translate_text() {

    local original="$1"

    # CACHE
    cached=$(cache_get "$original")
    if [[ -n "$cached" ]]; then
        echo "$cached"
        return
    fi

    protected=$(protect_patterns "$original")

    # Intentos con validación
    for attempt in {1..3}; do

        result=$(translate_api "$protected")

        if validate_placeholders "$result"; then
            restored=$(restore_patterns "$result")
            cache_save "$original" "$restored"
            echo "$restored"
            return
        fi

    done

    # Si falla validación
    echo "$original"
}

# ===============================
# MULTIPROCESS WORKER
# ===============================

process_file() {

    local FILE="$1"
    OUTPUT="${FILE%.lang}_${TARGET_LANG}.lang"

    cp "$FILE" "${FILE}.backup"

    TOTAL=$(grep -c "=" "$FILE")
    COUNT=0

    exec 3> "$OUTPUT"

    while IFS= read -r line; do

        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            TRANSLATED=$(translate_text "$VALUE")

            echo "$KEY=$TRANSLATED" >&3

            ((COUNT++))
            echo $((COUNT*100/TOTAL))
            echo "# $COUNT / $TOTAL"

        else
            echo "$line" >&3
        fi

    done < "$FILE"

    exec 3>&-
}

# ===============================
# MAIN LOOP
# ===============================

while true; do

FORM=$(yad --form \
    --title="$APP_NAME" \
    --width=500 \
    --button="$MSG_BTN_GO":0 \
    --button="$MSG_EXIT":1 \
    --field="$MSG_METHOD:CB" "Google!DeepL!OpenAI" \
    --field="$MSG_LANG" "")

[ $? -eq 1 ] && exit

IFS="|" read METHOD TARGET_LANG <<< "$FORM"

FILES=$(yad --file \
    --multiple \
    --title="$MSG_FILES" \
    --file-filter="*.lang")

[ -z "$FILES" ] && continue
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

# ===============================
# CALCULAR TOTAL GLOBAL
# ===============================

TOTAL_LINES=0
for FILE in "${FILE_ARRAY[@]}"; do
    LINES=$(grep -c "=" "$FILE")
    TOTAL_LINES=$((TOTAL_LINES + LINES))
done

GLOBAL_COUNT=0
CANCELLED=0

# ===============================
# PROCESO EN BACKGROUND
# ===============================

(
for FILE in "${FILE_ARRAY[@]}"; do

    OUTPUT="${FILE%.lang}_${TARGET_LANG}.lang"
    cp "$FILE" "${FILE}.backup"

    FILE_TOTAL=$(grep -c "=" "$FILE")
    FILE_COUNT=0

    exec 3> "$OUTPUT"

    while IFS= read -r line; do

        if [[ "$line" == *=* ]]; then

            KEY="${line%%=*}"
            VALUE="${line#*=}"

            TRANSLATED=$(translate_text "$VALUE")

            echo "$KEY=$TRANSLATED" >&3

            ((FILE_COUNT++))
            ((GLOBAL_COUNT++))

            PERCENT=$((GLOBAL_COUNT*100/TOTAL_LINES))

            echo "$PERCENT"
            echo "# Archivo: $(basename "$FILE") ($FILE_COUNT/$FILE_TOTAL)  |  Total: $GLOBAL_COUNT/$TOTAL_LINES"

        else
            echo "$line" >&3
        fi

    done < "$FILE"

    exec 3>&-

done

echo 100

) &

PROCESS_PID=$!

# ===============================
# BARRA YAD
# ===============================

yad --progress \
    --title="$MSG_WORKING" \
    --percentage=0 \
    --auto-close \
    --button="Cancelar":1 \
    --width=600 \
    < <(tail -f /proc/$PROCESS_PID/fd/1 2>/dev/null) &

YAD_PID=$!

wait $PROCESS_PID
PROCESS_EXIT=$?

wait $YAD_PID
YAD_EXIT=$?

# ===============================
# CANCELACIÓN REAL
# ===============================

if [ "$YAD_EXIT" -eq 1 ]; then
    CANCELLED=1
    pkill -P $PROCESS_PID 2>/dev/null
    kill -9 $PROCESS_PID 2>/dev/null
    yad --warning --text="$MSG_CANCELLED"
    continue
fi

if [ "$PROCESS_EXIT" -ne 0 ]; then
    yad --error --text="$MSG_ERR"
    continue
fi

yad --info --text="$MSG_DONE"

done

#!/bin/bash

APP_NAME="Lang Translator PRO FIXED"
TMPDIR="$HOME/.traductor_lang_pro"
CACHE_DIR="$TMPDIR/cache"
BACKUP_DIR="$TMPDIR/backups"
LOG_DIR="$TMPDIR/logs"

mkdir -p "$TMPDIR" "$CACHE_DIR" "$BACKUP_DIR" "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/$TIMESTAMP.log"

# ==================================================
# DEPENDENCIAS
# ==================================================

for cmd in yad jq curl md5sum; do
    command -v "$cmd" >/dev/null || {
        echo "Error: $cmd no está instalado."
        exit 1
    }
done

# ==================================================
# UTILIDADES
# ==================================================

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

error_msg() {
    yad --error --title="Error" --text="$1"
}

info_msg() {
    yad --info --title="$APP_NAME" --text="$1"
}

# ==================================================
# SISTEMA DE CACHÉ
# ==================================================

generate_hash() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

check_cache() {
    local TEXT="$1"
    local HASH=$(generate_hash "$TEXT")
    local FILE="$CACHE_DIR/$HASH.txt"

    if [ -f "$FILE" ]; then
        cat "$FILE"
        return 0
    fi

    return 1
}

save_cache() {
    local TEXT="$1"
    local TRANSLATION="$2"
    local HASH=$(generate_hash "$TEXT")
    echo "$TRANSLATION" > "$CACHE_DIR/$HASH.txt"
}


# ---------- GUI CONFIG ----------
FORM=$(yad --form \
    --title="$APP_NAME" \
    --width=500 \
    --field="Método:CB" "Google!DeepL!OpenAI" \
    --field="Idioma destino (ej: es=Español;en=Ingles):" "" \
    --field="Reemplazos personalizados (ej: Tin=Estaño;Bench=Banco):" "")

[ -z "$FORM" ] && exit

IFS="|" read METHOD TARGET_LANG REPLACE_RULES <<< "$FORM"

FILES=$(yad --file \
    --multiple \
    --title="Seleccionar Archivos" \
    --text="Selecciona los archivos que deseas:" \
    --file-filter="Archivos .lang | *.lang")

[ -z "$FILES" ] && exit
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

# ---------- PROTECT PLACEHOLDERS SAFELY ----------
protect_patterns() {
    local text="$1"
    PLACEHOLDERS=()

    mapfile -t MATCHES < <(echo "$text" | grep -oE '<[^>]+>|%[sd]|\{[^}]+\}')

    for i in "${!MATCHES[@]}"; do
        token="⟦$i⟧"
        PLACEHOLDERS[$i]="${MATCHES[$i]}"
        text="${text//${MATCHES[$i]}/$token}"
    done

    echo "$text"
}

restore_patterns() {
    local text="$1"

    for i in "${!PLACEHOLDERS[@]}"; do
        token="⟦$i⟧"
        text="${text//$token/${PLACEHOLDERS[$i]}}"
    done

    echo "$text"
}

# ==================================================
# TRADUCCIÓN
# ==================================================

translate_text() {
    local text="$1"

    # 🔹 CACHE
    if RESULT=$(check_cache "$text"); then
        printf "%s" "$RESULT"
        return
    fi

    local OUTPUT=""

    case "$METHOD" in
        "Google")
            OUTPUT=$(trans -brief :"$TARGET_LANG" "$text" 2>/dev/null || true)
            ;;
        "DeepL")
            API_KEY=$(<"$TMPDIR/deepl.key" 2>/dev/null || true)
            [[ -z "$API_KEY" ]] && API_KEY=$(yad --entry --title="DeepL API Key")
            printf "%s" "$API_KEY" > "$TMPDIR/deepl.key"

            OUTPUT=$(curl -s -X POST "https://api-free.deepl.com/v2/translate" \
                -d auth_key="$API_KEY" \
                -d text="$text" \
                -d target_lang="$TARGET_LANG" |
                jq -r '.translations[0].text')
            ;;
        "OpenAI")
            API_KEY=$(<"$TMPDIR/openai.key" 2>/dev/null || true)
            [[ -z "$API_KEY" ]] && API_KEY=$(yad --entry --title="OpenAI API Key")
            printf "%s" "$API_KEY" > "$TMPDIR/openai.key"

            JSON=$(jq -n \
                --arg lang "$TARGET_LANG" \
                --arg txt "$text" \
                '{
                    model: "gpt-4o-mini",
                    messages: [
                        {role: "system", content: ("Translate to " + $lang + " preserving placeholders exactly.")},
                        {role: "user", content: $txt}
                    ]
                }')

            OUTPUT=$(curl -s https://api.openai.com/v1/chat/completions \
                -H "Authorization: Bearer $API_KEY" \
                -H "Content-Type: application/json" \
                -d "$JSON" |
                jq -r '.choices[0].message.content')
            ;;
    esac

    [[ -n "$OUTPUT" ]] && save_cache "$text" "$OUTPUT"
    printf "%s" "$OUTPUT"
}

# ==================================================
# PROCESAMIENTO
# ==================================================

for FILE in "${FILE_ARRAY[@]}"; do

    OUTPUT="${FILE%.lang}_${TARGET_LANG}.lang"
    cp "$FILE" "$BACKUP_DIR/${BASENAME}_$TIMESTAMP.bak"

    TOTAL_LINES=$(grep -c "=" "$FILE")
    CURRENT=0

    exec 3> "$OUTPUT"

    (
    while IFS= read -r line; do

        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            PLACEHOLDERS=()
            PROTECTED=$(protect_patterns "$VALUE")
            TRANSLATED=$(translate_text "$PROTECTED")

            [ -z "$TRANSLATED" ] && TRANSLATED="$VALUE"

            FINAL=$(restore_patterns "$TRANSLATED")

            echo "$KEY=$FINAL" >&3   # ← ESCRIBE AL ARCHIVO

            ((CURRENT++))
            PERCENT=$((CURRENT*100/TOTAL_LINES))
            echo "$PERCENT"
            echo "# Procesando línea $CURRENT de $TOTAL_LINES"

        else
            echo "$line" >&3
        fi

    done < "$FILE"
    ) | yad --progress \
        --title="$APP_NAME - $(basename "$FILE")" \
        --auto-close \
        --width=500

    exec 3>&-

done

yad --info --text="Aplicación finalizada.

Logs guardados en:
$LOG_DIR

Backups en:
$BACKUP_DIR"

exit 0


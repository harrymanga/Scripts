#!/bin/bash
set -euo pipefail

APP_NAME="Lang Translator PRO ULTRA"
TMPDIR="$HOME/.traductor_lang_pro"
CACHE_DIR="$TMPDIR/cache"
BACKUP_DIR="$TMPDIR/backups"
LOG_DIR="$TMPDIR/logs"

mkdir -p "$CACHE_DIR" "$BACKUP_DIR" "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/$TIMESTAMP.log"

# ==================================================
# DEPENDENCIAS
# ==================================================
for cmd in yad jq curl md5sum xargs; do
    command -v "$cmd" >/dev/null || {
        echo "Error: $cmd no está instalado."
        exit 1
    }
done

# ==================================================
# HASH NORMALIZADO
# ==================================================
generate_hash() {
    local CLEAN
    CLEAN=$(printf "%s" "$1" | tr -d '\r' | sed 's/[[:space:]]*$//')
    printf "%s" "$CLEAN" | md5sum | awk '{print $1}'
}

check_cache() {
    local TEXT="$1"
    local HASH
    HASH=$(generate_hash "$TEXT")
    local FILE="$CACHE_DIR/$HASH.txt"

    [[ -f "$FILE" ]] && cat "$FILE" && return 0
    return 1
}

save_cache() {
    local TEXT="$1"
    local TRANSLATION="$2"
    local HASH
    HASH=$(generate_hash "$TEXT")
    printf "%s" "$TRANSLATION" > "$CACHE_DIR/$HASH.txt"
}

# ==================================================
# PROTEGER PLACEHOLDERS
# ==================================================
protect_patterns() {
    local text="$1"
    PLACEHOLDERS=()

    mapfile -t MATCHES < <(grep -oE '<[^>]+>|%[sd]|\{[^}]+\}' <<< "$text")

    for i in "${!MATCHES[@]}"; do
        token="__PH_$i__"
        PLACEHOLDERS[$i]="${MATCHES[$i]}"
        text="${text//${MATCHES[$i]}/$token}"
    done

    printf "%s" "$text"
}

restore_patterns() {
    local text="$1"

    for i in "${!PLACEHOLDERS[@]}"; do
        token="__PH_$i__"
        text="${text//$token/${PLACEHOLDERS[$i]}}"
    done

    printf "%s" "$text"
}

# ==================================================
# TRADUCCIÓN POR BLOQUES
# ==================================================
translate_block() {
    local BLOCK="$1"

    API_KEY=$(<"$TMPDIR/openai.key" 2>/dev/null || true)
    [[ -z "$API_KEY" ]] && API_KEY=$(yad --entry --title="OpenAI API Key")
    printf "%s" "$API_KEY" > "$TMPDIR/openai.key"

    JSON=$(jq -n \
        --arg txt "$BLOCK" \
        --arg lang "$TARGET_LANG" \
        '{
            model: "gpt-4o-mini",
            messages: [
                {role: "system", content: ("Translate each line separately to " + $lang + ". Preserve placeholders exactly. Keep line order.")},
                {role: "user", content: $txt}
            ]
        }')

    curl -s https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$JSON" | jq -r '.choices[0].message.content'
}

# ==================================================
# PROCESAR ARCHIVO
# ==================================================
process_file() {

    local FILE="$1"
    BASENAME=$(basename "$FILE")
    OUTPUT="${FILE%.lang}_${TARGET_LANG}.lang"

    cp "$FILE" "$BACKUP_DIR/${BASENAME}_$TIMESTAMP.bak"

    mapfile -t LINES < "$FILE"

    declare -A KEYS
    declare -a TO_TRANSLATE
    declare -a INDEX_MAP

    for i in "${!LINES[@]}"; do
        line="${LINES[$i]}"
        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"
            VALUE="${VALUE//$'\r'/}"

            if CACHED=$(check_cache "$VALUE"); then
                LINES[$i]="$KEY=$CACHED"
            else
                PROTECTED=$(protect_patterns "$VALUE")
                KEYS[$i]="$KEY"
                TO_TRANSLATE+=("$PROTECTED")
                INDEX_MAP+=("$i")
            fi
        fi
    done

    if [[ "${#TO_TRANSLATE[@]}" -gt 0 ]]; then

        BLOCK=$(printf "%s\n" "${TO_TRANSLATE[@]}")
        RESULT=$(translate_block "$BLOCK")

        mapfile -t TRANSLATED_LINES <<< "$RESULT"

        for j in "${!TRANSLATED_LINES[@]}"; do
            index="${INDEX_MAP[$j]}"
            restored=$(restore_patterns "${TRANSLATED_LINES[$j]}")
            save_cache "${TO_TRANSLATE[$j]}" "$restored"
            LINES[$index]="${KEYS[$index]}=$restored"
        done
    fi

    printf "%s\n" "${LINES[@]}" > "$OUTPUT"
}

export -f generate_hash check_cache save_cache protect_patterns restore_patterns translate_block process_file
export TMPDIR CACHE_DIR BACKUP_DIR TARGET_LANG TIMESTAMP

# ==================================================
# GUI
# ==================================================
FORM=$(yad --form \
    --title="$APP_NAME" \
    --width=500 \
    --field="Idioma destino (ej: ES):" "")

[[ -z "$FORM" ]] && exit 0
TARGET_LANG="$FORM"

FILES=$(yad --file \
    --multiple \
    --title="Seleccionar Archivos" \
    --file-filter="Archivos .lang | *.lang")

[[ -z "$FILES" ]] && exit 0
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

# ==================================================
# PARALELIZACIÓN
# ==================================================
printf "%s\n" "${FILE_ARRAY[@]}" | xargs -I {} -P 3 bash -c 'process_file "$@"' _ {}

yad --info --text="Traducción completada 🚀

Backups en:
$BACKUP_DIR

Cache en:
$CACHE_DIR"

exit 0



























    case "$METHOD" in
        "Google")
            trans -brief :"$TARGET_LANG" "$text"
            ;;
        "DeepL")
            API_KEY=$(cat "$TMPDIR/deepl.key" 2>/dev/null)
            [ -z "$API_KEY" ] && API_KEY=$(yad --entry --title="DeepL API Key")
            echo "$API_KEY" > "$TMPDIR/deepl.key"

            curl -s -X POST "https://api-free.deepl.com/v2/translate" \
                -d auth_key="$API_KEY" \
                -d text="$text" \
                -d target_lang="$TARGET_LANG" | jq -r '.translations[0].text'
            ;;
        "OpenAI")
            API_KEY=$(cat "$TMPDIR/openai.key" 2>/dev/null)
            [ -z "$API_KEY" ] && API_KEY=$(yad --entry --title="OpenAI API Key")
            echo "$API_KEY" > "$TMPDIR/openai.key"

            curl -s https://api.openai.com/v1/chat/completions \
                -H "Authorization: Bearer $API_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"model\": \"gpt-4o-mini\",
                    \"messages\": [
                        {\"role\": \"system\", \"content\": \"Translate to $TARGET_LANG preserving placeholders exactly.\"},
                        {\"role\": \"user\", \"content\": \"$text\"}
                    ]
                }" | jq -r '.choices[0].message.content'
            ;;
    esac

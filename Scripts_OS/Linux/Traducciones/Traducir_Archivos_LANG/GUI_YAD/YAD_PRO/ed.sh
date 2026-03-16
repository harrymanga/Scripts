#!/bin/bash

APP_NAME="Lang Translator PRO+"
TMPDIR="$HOME/lang_translate_pro"
LOGFILE="$TMPDIR/translation.log"
CACHE_DB="$TMPDIR/translation_cache.db"

mkdir -p "$TMPDIR"

# ---------- INIT CACHE DB ----------
init_cache_db() {
sqlite3 "$CACHE_DB" <<EOF
CREATE TABLE IF NOT EXISTS translations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    method TEXT,
    target_lang TEXT,
    original TEXT,
    translated TEXT,
    UNIQUE(method, target_lang, original)
);
EOF
}
init_cache_db

# ---------- CACHE FUNCTIONS ----------

sql_escape() {
    local s="$1"

    # eliminar carriage return
    s="${s//$'\r'/}"

    # escapar comillas simples
    s="${s//\'/\'\'}"

    echo "$s"
}


get_cached_translation() {

    local text
    text=$(sql_escape "$1")

    sqlite3 "$CACHE_DB" "
        SELECT translated FROM translations
        WHERE method='$METHOD'
        AND target_lang='$TARGET_LANG'
        AND original='$text'
        LIMIT 1;
    "
}

save_translation_cache() {

    local original
    local translated

    original=$(sql_escape "$1")
    translated=$(sql_escape "$2")

    sqlite3 "$CACHE_DB" "
        INSERT OR IGNORE INTO translations
        (method, target_lang, original, translated)
        VALUES (
            '$METHOD',
            '$TARGET_LANG',
            '$original',
            '$translated'
        );
    "
}

# ---------- GUI ----------
FORM=$(yad --form \
    --title="$APP_NAME" \
    --width=500 \
    --field="Método:CB" "Google!DeepL!OpenAI" \
    --field="Idioma destino (ej: ES, EN):" "")

[ -z "$FORM" ] && exit

IFS="|" read METHOD TARGET_LANG <<< "$FORM"

FILES=$(yad --file \
    --multiple \
    --title="Seleccionar Archivos" \
    --file-filter="Archivos .lang | *.lang")

[ -z "$FILES" ] && exit
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

# ---------- PLACEHOLDER PROTECTION ----------
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

# ---------- TRANSLATE ----------
translate_text() {

    local text="$1"

    # 🔎 Buscar en caché primero
    CACHED=$(get_cached_translation "$text")
    if [ -n "$CACHED" ]; then
        echo "$CACHED"
        return
    fi

    case "$METHOD" in
        "Google")
            RESULT=$(trans -brief :"$TARGET_LANG" "$text")
            ;;
        "DeepL")
            API_KEY=$(cat "$TMPDIR/deepl.key" 2>/dev/null)
            [ -z "$API_KEY" ] && API_KEY=$(yad --entry --title="DeepL API Key")
            echo "$API_KEY" > "$TMPDIR/deepl.key"

            RESULT=$(curl -s -X POST "https://api-free.deepl.com/v2/translate" \
                -d auth_key="$API_KEY" \
                -d text="$text" \
                -d target_lang="$TARGET_LANG" | jq -r '.translations[0].text')
            ;;
        "OpenAI")
            API_KEY=$(cat "$TMPDIR/openai.key" 2>/dev/null)
            [ -z "$API_KEY" ] && API_KEY=$(yad --entry --title="OpenAI API Key")
            echo "$API_KEY" > "$TMPDIR/openai.key"

            RESULT=$(curl -s https://api.openai.com/v1/chat/completions \
                -H "Authorization: Bearer $API_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"model\": \"gpt-4o-mini\",
                    \"messages\": [
                        {\"role\": \"system\", \"content\": \"Translate to $TARGET_LANG preserving placeholders exactly.\"},
                        {\"role\": \"user\", \"content\": \"$text\"}
                    ]
                }" | jq -r '.choices[0].message.content')
            ;;
    esac

    # 💾 Guardar en caché
    if [ -n "$RESULT" ]; then
        save_translation_cache "$text" "$RESULT"
    fi

    echo "$RESULT"
}

# ---------- PROCESS ----------
for FILE in "${FILE_ARRAY[@]}"; do

    OUTPUT="${FILE%.lang}_${TARGET_LANG}.lang"
    cp "$FILE" "${FILE}.backup"

    TOTAL_LINES=$(grep -c "=" "$FILE")
    CURRENT=0

    exec 3> "$OUTPUT"

    CANCELLED=0

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
            echo "$KEY=$FINAL" >&3

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
        --width=500 \
        --button="Cancelar":1

    if [ $? -eq 1 ]; then
        CANCELLED=1
        exec 3>&-
        rm -f "$OUTPUT"
        yad --warning --text="Proceso cancelado por el usuario"
        exit 1
    fi

    exec 3>&-

done

yad --info --text="✅ Traducción completada\nBackups creados\nCaché activa"

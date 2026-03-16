#!/bin/bash

APP_NAME="Lang Translator PRO"
TMPDIR="/tmp/lang_translate_pro"
LOGFILE="$TMPDIR/translation.log"

mkdir -p "$TMPDIR"

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

# ---------- PROTECT SPECIAL PATTERNS ----------
protect_patterns() {
    local text="$1"

    text=$(echo "$text" | sed -E 's/<[^>]+>/@@TAG@@/g')
    text=$(echo "$text" | sed -E 's/%[sd]/@@VAR@@/g')
    text=$(echo "$text" | sed -E 's/\{[^\}]+\}/@@BRACE@@/g')
    text=$(echo "$text" | sed -E 's/\\n/@@NEWLINE@@/g')

    echo "$text"
}

restore_patterns() {
    local translated="$1"
    local original="$2"

    for tag in $(echo "$original" | grep -o '<[^>]\+>'); do
        translated=$(echo "$translated" | sed "0,/@@TAG@@/s//${tag}/")
    done

    for var in $(echo "$original" | grep -o '%[sd]'); do
        translated=$(echo "$translated" | sed "0,/@@VAR@@/s//${var}/")
    done

    for brace in $(echo "$original" | grep -o '{[^}]\+}'); do
        translated=$(echo "$translated" | sed "0,/@@BRACE@@/s//${brace}/")
    done

    translated=$(echo "$translated" | sed "s/@@NEWLINE@@/\\\\n/g")

    echo "$translated"
}

# ---------- TRANSLATE ----------
translate_text() {
    local text="$1"

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
                        {\"role\": \"system\", \"content\": \"Translate to $TARGET_LANG preserving placeholders and tags exactly.\"},
                        {\"role\": \"user\", \"content\": \"$text\"}
                    ]
                }" | jq -r '.choices[0].message.content'
            ;;
    esac
}

# ---------- APPLY CUSTOM REPLACEMENTS ----------
apply_replacements() {
    local text="$1"

    IFS=";" read -ra RULES <<< "$REPLACE_RULES"
    for rule in "${RULES[@]}"; do
        KEY="${rule%%=*}"
        VALUE="${rule#*=}"
        text=$(echo "$text" | sed "s/$KEY/$VALUE/g")
    done

    echo "$text"
}

# ---------- PROCESS ----------
TOTAL_FILES=${#FILE_ARRAY[@]}
COUNT=0

(
for FILE in "${FILE_ARRAY[@]}"; do

    OUTPUT="${FILE%.lang}_${TARGET_LANG}.lang"
    cp "$FILE" "${FILE}.backup"

    while IFS= read -r line; do
        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            PROTECTED=$(protect_patterns "$VALUE")
            TRANSLATED=$(translate_text "$PROTECTED")
            FINAL=$(restore_patterns "$TRANSLATED" "$VALUE")
            FINAL=$(apply_replacements "$FINAL")

            echo "$KEY=$FINAL"
        else
            echo "$line"
        fi
    done < "$FILE" > "$OUTPUT"

    COUNT=$((COUNT+1))
    PERCENT=$((COUNT*100/TOTAL_FILES))
    echo "$PERCENT"
    echo "# Procesando $FILE"

done
) | yad --progress \
        --title="$APP_NAME" \
        --auto-close \
        --width=400

yad --info --text="✅ Traducción completada\nBackups creados\nArchivos generados"


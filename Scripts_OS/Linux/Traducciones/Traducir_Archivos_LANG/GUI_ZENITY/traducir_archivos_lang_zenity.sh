#!/bin/bash

# ---------- CONFIG ----------
TMPDIR="/tmp/lang_translate"
mkdir -p "$TMPDIR"

# ---------- GUI: Elegir método ----------
METHOD=$(zenity --list \
    --title="Traductor .lang" \
    --text="Selecciona método de traducción" \
    --column="Método" \
    "Google (translate-shell)" \
    "DeepL API" \
    "OpenAI API")

[ -z "$METHOD" ] && exit

# ---------- Seleccionar archivos ----------
FILES=$(zenity --file-selection \
    --multiple \
    --file-filter="Archivos .lang | *.lang")

[ -z "$FILES" ] && exit

IFS="|" read -ra FILE_ARRAY <<< "$FILES"

# ---------- Función para proteger etiquetas ----------
protect_tags() {
    echo "$1" | sed -E 's/<[^>]+>/@@TAG@@/g'
}

# ---------- Restaurar etiquetas ----------
restore_tags() {
    local translated="$1"
    local original="$2"

    TAGS=$(echo "$original" | grep -o '<[^>]\+>')
    for tag in $TAGS; do
        translated=$(echo "$translated" | sed "0,/@@TAG@@/s//${tag}/")
    done

    echo "$translated"
}

# ---------- Función traducir ----------
translate_text() {
    local text="$1"

    case "$METHOD" in
        "Google (translate-shell)")
            trans -brief :es "$text"
            ;;
        "DeepL API")
            API_KEY=$(zenity --entry --title="DeepL API Key")
            curl -s -X POST "https://api-free.deepl.com/v2/translate" \
                -d auth_key="$API_KEY" \
                -d text="$text" \
                -d target_lang="ES" | jq -r '.translations[0].text'
            ;;
        "OpenAI API")
            API_KEY=$(zenity --entry --title="OpenAI API Key")
            curl -s https://api.openai.com/v1/chat/completions \
                -H "Authorization: Bearer $API_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"model\": \"gpt-4o-mini\",
                    \"messages\": [
                        {\"role\": \"system\", \"content\": \"Translate to Spanish preserving XML-like tags exactly.\"},
                        {\"role\": \"user\", \"content\": \"$text\"}
                    ]
                }" | jq -r '.choices[0].message.content'
            ;;
    esac
}

# ---------- Procesar archivos ----------
for FILE in "${FILE_ARRAY[@]}"; do
    OUTPUT="${FILE%.lang}_es.lang"
    > "$OUTPUT"

    while IFS= read -r line; do
        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            PROTECTED=$(protect_tags "$VALUE")
            TRANSLATED=$(translate_text "$PROTECTED")
            FINAL=$(restore_tags "$TRANSLATED" "$VALUE")

            echo "$KEY=$FINAL" >> "$OUTPUT"
        else
            echo "$line" >> "$OUTPUT"
        fi
    done < "$FILE"

done

zenity --info --text="Traducción completada ✅"


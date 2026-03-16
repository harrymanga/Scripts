#!/bin/bash

APP="Lang Translator ULTRA PRO"
WORKDIR="$HOME/.lang_ultra"
CACHEDB="$WORKDIR/cache.db"
LOGDIR="$WORKDIR/logs"
BACKUPDIR="$WORKDIR/backups"

mkdir -p "$WORKDIR" "$LOGDIR" "$BACKUPDIR"

# ---------- INIT CACHE ----------
sqlite3 "$CACHEDB" "CREATE TABLE IF NOT EXISTS translations (
    original TEXT,
    translated TEXT,
    target_lang TEXT,
    PRIMARY KEY(original, target_lang)
);"

log() {
    echo "$(date '+%F %T') - $1" >> "$LOGDIR/session.log"
}

detect_spanish() {
    echo "$1" | grep -qiE " el | la | de | que | y "
}

protect() {
    local text="$1"
    text=$(echo "$text" | sed -E 's/<[^>]+>/@@TAG@@/g')
    text=$(echo "$text" | sed -E 's/%[sd]/@@VAR@@/g')
    text=$(echo "$text" | sed -E 's/\{[^\}]+\}/@@BRACE@@/g')
    text=$(echo "$text" | sed -E 's/\\n/@@NL@@/g')
    echo "$text"
}

restore() {
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

    translated=$(echo "$translated" | sed 's/@@NL@@/\\n/g')
    echo "$translated"
}

cache_lookup() {
    sqlite3 "$CACHEDB" \
        "SELECT translated FROM translations WHERE original='$1' AND target_lang='$2';"
}

cache_save() {
    sqlite3 "$CACHEDB" \
        "INSERT OR REPLACE INTO translations VALUES('$1','$2','$3');"
}

translate_google() {
    trans -brief :"$TARGET" "$1"
}

translate_openai() {
    curl -s https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"gpt-4o-mini\",
            \"messages\": [
                {\"role\":\"system\",\"content\":\"Translate to $TARGET preserving placeholders exactly.\"},
                {\"role\":\"user\",\"content\":\"$1\"}
            ]
        }" | jq -r '.choices[0].message.content'
}

translate_engine() {
    local text="$1"

    if detect_spanish "$text"; then
        echo "$text"
        return
    fi

    CACHED=$(cache_lookup "$text" "$TARGET")
    if [ -n "$CACHED" ]; then
        echo "$CACHED"
        return
    fi

    RESULT=$(translate_google "$text")

    if [ -z "$RESULT" ]; then
        RESULT=$(translate_openai "$text")
    fi

    cache_save "$text" "$RESULT" "$TARGET"
    echo "$RESULT"
}

# ---------- GUI ----------
FORM=$(yad --form \
    --title="$APP" \
    --width=600 \
    --field="Idioma destino:" "ES" \
    --field="API OpenAI (opcional):" "" \
    --field="Modo revisión:CHK" "FALSE")

IFS="|" read TARGET OPENAI_KEY REVIEW <<< "$FORM"

FILES=$(yad --file-selection --multiple --file-filter="*.lang")
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

TOTAL_LINES=0
for f in "${FILE_ARRAY[@]}"; do
    TOTAL_LINES=$((TOTAL_LINES + $(grep -c "=" "$f")))
done

CURRENT=0

(
for FILE in "${FILE_ARRAY[@]}"; do

    BASENAME=$(basename "$FILE")
    cp "$FILE" "$BACKUPDIR/$BASENAME.bak"

    OUTPUT="${FILE%.lang}_${TARGET}.lang"

    while IFS= read -r line; do
        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            PROT=$(protect "$VALUE")
            TRANS=$(translate_engine "$PROT")
            FINAL=$(restore "$TRANS" "$VALUE")

            if [ "$REVIEW" = "TRUE" ]; then
                FINAL=$(yad --entry \
                    --title="Revisión" \
                    --text="$VALUE" \
                    --entry-text="$FINAL")
            fi

            echo "$KEY=$FINAL"
        else
            echo "$line"
        fi

        CURRENT=$((CURRENT+1))
        PERCENT=$((CURRENT*100/TOTAL_LINES))
        echo "$PERCENT"
        echo "# Traduciendo línea $CURRENT de $TOTAL_LINES"

    done < "$FILE" > "$OUTPUT"

done
) | yad --progress --auto-close --width=500 --title="$APP"

yad --info --text="🚀 Traducción completada\nCache activa\nBackups guardados\nModo ULTRA PRO"


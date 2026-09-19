#!/bin/bash
# minecraft_hytale.sh — Traductor .lang+.json por proyectos para juegos
# (especialidad Minecraft/Hytale). Uso: *.sh [es|en]
# Idioma: parámetro > $LANG > es.

# --- Idioma ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[ "$1" = "en" ] && LANG_ID="en"
[ "$1" = "es" ] && LANG_ID="es"
# shellcheck disable=SC1090
. "$(dirname "$0")/lang_minecraft_${LANG_ID}.sh"

BASE="$HOME/.langforge"
mkdir -p "$BASE/projects"

APP="LangForge – Minecraft/Hytale Industrial"

PROJECT=$(yad --entry --title="$APP" --text="$MSG_PROJECT")
[ -z "$PROJECT" ] && exit

PROJDIR="$BASE/projects/$PROJECT"
mkdir -p "$PROJDIR/backups"

DB="$PROJDIR/cache.db"

sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS translations(
original TEXT,
translated TEXT,
target TEXT,
PRIMARY KEY(original,target)
);"

CONFIG=$(yad --form \
--title="$APP" \
--field="$MSG_LANG" "" \
--field="$MSG_REVIEW:CHK" "FALSE")

IFS="|" read TARGET REVIEW <<< "$CONFIG"

FILES=$(yad --file --multiple)
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

translate_cached() {

    TEXT="$1"

    CACHED=$(sqlite3 "$DB" \
    "SELECT translated FROM translations WHERE original='$TEXT' AND target='$TARGET';")

    if [ -n "$CACHED" ]; then
        echo "$CACHED"
        return
    fi

    RESULT=$(trans -brief :"${TARGET:0:2}" "$TEXT")

    sqlite3 "$DB" \
    "INSERT OR REPLACE INTO translations VALUES('$TEXT','$RESULT','$TARGET');"

    echo "$RESULT"
}

process_lang() {

    FILE="$1"
    OUTPUT="${FILE%.lang}_${TARGET}.lang"

    cp "$FILE" "$PROJDIR/backups/$(basename "$FILE").bak"

    while IFS= read -r line; do
        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            TRANS=$(translate_cached "$VALUE")

            echo "$KEY=$TRANS"
        else
            echo "$line"
        fi
    done < "$FILE" > "$OUTPUT"
}

process_json() {

    FILE="$1"
    OUTPUT="${FILE%.json}_${TARGET}.json"

    cp "$FILE" "$PROJDIR/backups/$(basename "$FILE").bak"

    jq 'to_entries' "$FILE" | jq -c '.[]' | while read entry; do

        KEY=$(echo "$entry" | jq -r '.key')
        VALUE=$(echo "$entry" | jq -r '.value')

        TRANS=$(translate_cached "$VALUE")

        if [ "$REVIEW" = "TRUE" ]; then
            TRANS=$(yad --entry --title="$MSG_REVIEW_TITLE" --text="$VALUE" --entry-text="$TRANS")
        fi

        echo "\"$KEY\": \"$TRANS\""
    done | awk 'BEGIN{print "{"} {print (NR>1?",":"") $0} END{print "}"}' > "$OUTPUT"
}

for FILE in "${FILE_ARRAY[@]}"; do
    case "$FILE" in
        *.lang)
            process_lang "$FILE"
            ;;
        *.json)
            process_json "$FILE"
            ;;
    esac
done

yad --info --text="$MSG_DONE"


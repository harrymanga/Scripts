#!/bin/bash
# industrial_modder.sh — Traductor .lang por proyectos (caché SQLite, modo revisión).
# Versión única del par industrial/modder. Uso: *.sh [es|en]
# Idioma: parámetro > $LANG > es.

# --- Idioma ---
LANG_ID="es"
case "${LANG:0:2}" in
    en|EN) LANG_ID="en" ;;
esac
[ "$1" = "en" ] && LANG_ID="en"
[ "$1" = "es" ] && LANG_ID="es"
# shellcheck disable=SC1090
. "$(dirname "$0")/lang_modder_${LANG_ID}.sh"

BASE="$HOME/.lang_modder"
mkdir -p "$BASE/projects"

APP="Lang Modder Industrial"

PROJECT=$(yad --entry --title="$APP" --text="$MSG_PROJECT")
[ -z "$PROJECT" ] && exit

PROJDIR="$BASE/projects/$PROJECT"
mkdir -p "$PROJDIR/backups" "$PROJDIR/logs"

DB="$PROJDIR/cache.db"
STATE="$PROJDIR/state.hash"

sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS translations(
original TEXT,
translated TEXT,
target TEXT,
PRIMARY KEY(original,target)
);"

CONFIG=$(yad --form \
--title="$APP" \
--field="$MSG_LANG" "ES" \
--field="$MSG_REVIEW:CHK" "FALSE")

IFS="|" read TARGET REVIEW <<< "$CONFIG"

FILES=$(yad --file --multiple --file-filter="*.lang")
IFS="|" read -ra FILE_ARRAY <<< "$FILES"

hash_project() {
    cat "${FILE_ARRAY[@]}" | md5sum | awk '{print $1}'
}

OLD_HASH=$(cat "$STATE" 2>/dev/null)
NEW_HASH=$(hash_project)

if [ "$OLD_HASH" = "$NEW_HASH" ]; then
    yad --info --text="$MSG_NO_CHANGES"
    exit
fi

translate_line() {

    TEXT="$1"

    CACHED=$(sqlite3 "$DB" \
    "SELECT translated FROM translations WHERE original='$TEXT' AND target='$TARGET';")

    if [ -n "$CACHED" ]; then
        echo "$CACHED"
        return
    fi

    RESULT=$(trans -brief :"$TARGET" "$TEXT")

    sqlite3 "$DB" \
    "INSERT OR REPLACE INTO translations VALUES('$TEXT','$RESULT','$TARGET');"

    echo "$RESULT"
}

TOTAL=0
for f in "${FILE_ARRAY[@]}"; do
    TOTAL=$((TOTAL + $(grep -c "=" "$f")))
done

COUNT=0

(
for FILE in "${FILE_ARRAY[@]}"; do

    cp "$FILE" "$PROJDIR/backups/$(basename "$FILE").bak"

    OUTPUT="${FILE%.lang}_${TARGET}.lang"

    while IFS= read -r line; do

        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            TRANS=$(translate_line "$VALUE")

            if [ "$REVIEW" = "TRUE" ]; then
                TRANS=$(yad --entry --title="$MSG_REVIEW_TITLE" --text="$VALUE" --entry-text="$TRANS")
            fi

            echo "$KEY=$TRANS"
        else
            echo "$line"
        fi

        COUNT=$((COUNT+1))
        PERCENT=$((COUNT*100/TOTAL))
        echo "$PERCENT"
        # shellcheck disable=SC2059
        printf "# $MSG_PROC\n" "$COUNT" "$TOTAL"

    done < "$FILE" > "$OUTPUT"

done
) | yad --progress --auto-close --width=500 --title="$APP"

echo "$NEW_HASH" > "$STATE"

yad --info --text="$MSG_DONE"


#!/bin/bash

BASE="$HOME/.lang_industrial"
mkdir -p "$BASE/projects" "$BASE/logs"

APP="Lang Industrial Suite"

select_project() {
    PROJECT=$(yad --entry \
        --title="$APP" \
        --text="Nombre del proyecto:")

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
}

select_files() {
    FILES=$(yad --file --multiple)
    IFS="|" read -ra FILE_ARRAY <<< "$FILES"
}

translate_line() {
    local TEXT="$1"

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

process_file() {

    FILE="$1"
    OUTPUT="${FILE}_${TARGET}"

    cp "$FILE" "$PROJDIR/backups/$(basename "$FILE").bak"

    while IFS= read -r line; do
        if [[ "$line" == *=* ]]; then
            KEY="${line%%=*}"
            VALUE="${line#*=}"

            TRANS=$(translate_line "$VALUE")

            echo "$KEY=$TRANS"
        else
            echo "$line"
        fi
    done < "$FILE" > "$OUTPUT"
}

# ---------- GUI CONFIG ----------
CONFIG=$(yad --form \
    --title="$APP" \
    --field="Idioma destino (Ejemplo Spanish = es):" "" \
    --field="Modo Git inteligente:CHK" "FALSE")

IFS="|" read TARGET GITMODE <<< "$CONFIG"

select_project
select_files

for FILE in "${FILE_ARRAY[@]}"; do
    process_file "$FILE"
done

if [ "$GITMODE" = "TRUE" ]; then
    cd "$PROJDIR"
    git init
    git add .
    git commit -m "Traducción automática industrial"
fi

yad --info --text="🏭 Proyecto procesado correctamente"

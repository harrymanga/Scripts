#!/bin/bash

# ==================================================
# CONFIGURACIÓN GENERAL
# ==================================================
APP_NAME="Traductor .lang PRO"
VERSION="3.0"

BASE_DIR="$HOME/.traductor_lang_pro"
CACHE_DIR="$BASE_DIR/cache"
BACKUP_DIR="$BASE_DIR/backups"
LOG_DIR="$BASE_DIR/logs"
CONFIG_FILE="$BASE_DIR/config.conf"

mkdir -p "$CACHE_DIR" "$BACKUP_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S).log"

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
# CARGAR O CONFIGURAR API KEYS
# ==================================================

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
GOOGLE_API_KEY="$GOOGLE_API_KEY"
DEEPL_API_KEY="$DEEPL_API_KEY"
OPENAI_API_KEY="$OPENAI_API_KEY"
EOF
}

configure_keys() {
    FORM=$(yad --form \
        --title="Configurar API Keys" \
        --separator="|" \    
        --field="Google API Key:" "$GOOGLE_API_KEY" \
        --field="DeepL API Key:" "$DEEPL_API_KEY" \
        --field="OpenAI API Key:" "$OPENAI_API_KEY")

    [ -z "$FORM" ] && return

    IFS="|" read GOOGLE_API_KEY DEEPL_API_KEY OPENAI_API_KEY <<< "$FORM"
    save_config
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

# ==================================================
# FUNCIÓN DE TRADUCCIÓN REAL (PLANTILLA)
# ==================================================

translate_text() {

    local TEXT="$1"
    local METHOD="$2"
    local TARGET="$3"

    # Revisar caché primero
    
    CACHED=$(check_cache "$TEXT")
    if [ $? -eq 0 ]; then
        echo "$CACHED"
        return
    fi

    case "$METHOD" in
        "Google")
            trans -brief :"$TARGET_LANG" "$TEXT"
            ;;
        "DeepL")
            API_KEY=$(cat "$TMPDIR/deepl.key" 2>/dev/null)
            [ -z "$API_KEY" ] && API_KEY=$(yad --entry --title="DeepL API Key")
            echo "$API_KEY" > "$TMPDIR/deepl.key"

            curl -s -X POST "https://api-free.deepl.com/v2/translate" \
                -d auth_key="$API_KEY" \
                -d text="$TEXT" \
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
                        {\"role\": \"user\", \"content\": \"$TEXT\"}
                    ]
                }" | jq -r '.choices[0].message.content'
            ;;
    esac  
    
    # Guardar en caché
    
    save_cache "$TEXT" "$TRANSLATED"
    
    echo "$TRANSLATED"    
    
}

# ==================================================
# PROCESAR ARCHIVO .lang
# ==================================================
procesar_archivo() {
    local FILE="$1"
    local METHOD="$2"
    local TARGET="$3"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BASENAME=$(basename "$FILE")

    # Backup
    cp "$FILE" "$BACKUP_DIR/${BASENAME}_$TIMESTAMP.bak"

    OUTPUT_FILE="${FILE%.lang}_$TARGET.lang"

    > "$OUTPUT_FILE"

    while IFS= read -r LINE; do
        if [[ "$LINE" == *=* ]]; then
            KEY="${LINE%%=*}"
            VALUE="${LINE#*=}"

            TRANSLATED=$(translate_text "$VALUE" "$METHOD" "$TARGET")
            echo "$KEY=$TRANSLATED" >> "$OUTPUT_FILE"
        else
            echo "$LINE" >> "$OUTPUT_FILE"
        fi
    done < "$FILE"

    log "Procesado: $FILE → $OUTPUT_FILE"
}

# ==================================================
# MAIN LOOP
# ==================================================
load_config

while true; do

    FORM=$(yad --form \
        --title="$APP_NAME v$VERSION" \
        --width=500 \
        --separator="|" \
        --field="Método:CB" "Google!Google Cloud!DeepL!OpenAI" \
        --field="Idioma destino (ej: es=Español;en=Ingles):" "" \
        --field="Configurar API Keys:CHK" FALSE)

    [ -z "$FORM" ] && break

    IFS="|" read METHOD TARGET_LANG CONFIGURE <<< "$FORM"

    if [ "$CONFIGURE" = "TRUE" ]; then
        configure_keys
        continue
    fi

    if [ -z "$TARGET_LANG" ]; then
        error_msg "Debes indicar idioma destino."
        continue
    fi

    FILES=$(yad --file \
        --multiple \
        --title="Seleccionar archivos .lang" \
        --text="Selecciona los archivos que deseas:" \        
        --file-filter="Archivos .lang | *.lang")

    [ -z "$FILES" ] && continue

    IFS="|" read -ra FILE_ARRAY <<< "$FILES"
    TOTAL=${#FILE_ARRAY[@]}

    COUNT=0
    START_TIME=$(date +%s)

    (
        for FILE in "${FILE_ARRAY[@]}"; do
            COUNT=$((COUNT + 1))

            echo "# Procesando ($COUNT de $TOTAL): $(basename "$FILE")"

            procesar_archivo "$FILE" "$METHOD" "$TARGET_LANG"

            PERCENT=$((COUNT * 100 / TOTAL))
            echo "$PERCENT"
        done
    ) | yad --progress \
            --title="Procesando traducciones" \
            --percentage=0 \
            --auto-close \
            --auto-kill

    if [ $? -ne 0 ]; then
        yad --warning --text="Proceso cancelado."
        continue
    fi

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    yad --question \
        --title="Proceso completado" \
        --width=400 \
        --text="✅ Traducción completada

Método: $METHOD
Idioma: $TARGET_LANG
Archivos: $TOTAL
Tiempo total: ${DURATION}s

¿Deseas realizar otra traducción?" \
        --button="Nueva traducción":0 \
        --button="Salir":1

    [ $? -eq 0 ] && continue || break

done

yad --info --text="Aplicación finalizada.

Logs guardados en:
$LOG_DIR

Backups en:
$BACKUP_DIR"

exit 0

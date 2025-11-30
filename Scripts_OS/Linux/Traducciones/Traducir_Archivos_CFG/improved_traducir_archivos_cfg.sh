#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# improved_traducir_archivos_cfg.sh
# - Traduce archivos .cfg preservando keys/format
# - Agrupa valores traducibles para que DeepL tenga contexto (un único request por archivo)
# - No traduce valores numéricos, rutas, URLs, placeholders ni líneas de configuración técnica
# - Reintentos con backoff exponencial si falla la API
# - Genera logs y reporte final
#
# Dependencias: curl, jq
# Uso: ./improved_traducir_archivos_cfg.sh [DIRECTORIO_ORIGEN] [DIRECTORIO_SALIDA] [API_KEY] [SRC_LANG] [TGT_LANG]
# Ejemplo: ./improved_traducir_archivos_cfg.sh cfg_originales cfg_traducidos "mi_api_key" EN ES

DIRECTORIO="${1:-cfg_originales}"
DIR_SALIDA="${2:-cfg_traducidos}"
API_KEY="${3:-${DEEPL_API_KEY:-}}"
LANG_SOURCE="${4:-EN}"
LANG_TARGET="${5:-ES}"
LOG="${DIR_SALIDA}/traducciones.log"
REPORT="${DIR_SALIDA}/latest_report.txt"

# Verificaciones
if [[ -z "$API_KEY" ]]; then
  echo "ERROR: API key requerida. Pasa la API key como tercer argumento o exporta DEEPL_API_KEY." >&2
  exit 1
fi

mkdir -p "$DIRECTORIO" "$DIR_SALIDA"

echo "Inicio: $(date --iso-8601=seconds)" > "$LOG"
echo "Reporte: $(date --iso-8601=seconds)" > "$REPORT"
echo "Traduciendo archivos .cfg en $DIRECTORIO -> $DIR_SALIDA" | tee -a "$LOG"

# Heurística para identificar valores que NO deben traducirse:
# - Vacíos o puramente numéricos
# - booleanos true/false/on/off
# - contienen rutas (/, \), URLs (http, https, ftp), emails (@), placeholders {0}, %s, %d, ${...}
# - líneas que comienzan con ; o # (comentarios) se copian tal cual
should_translate_value() {
  local v="$1"
  # Quitar espacios extremos
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  if [[ -z "$v" ]]; then return 1; fi
  if [[ "$v" =~ ^[0-9]+([.,][0-9]+)?$ ]]; then return 1; fi
  case "${v,,}" in
    true|false|on|off) return 1;;
  esac
  if [[ "$v" =~ /|\\|http:|https:|ftp:|@|\{[0-9]+\}|\%s|\%d|\$\{.+\} ]]; then return 1; fi
  return 0
}

# Traduce un bloque único (varios valores unidos con un separador seguro) con reintentos
translate_block() {
  local block="$1"
  local attempt=0 max_attempts=5
  local backoff=1
  while (( attempt < max_attempts )); do
    if response=$(curl -sS -X POST "https://api-free.deepl.com/v2/translate" \
      -d "auth_key=$API_KEY" \
      -d "text=$block" \
      -d "source_lang=$LANG_SOURCE" \
      -d "target_lang=$LANG_TARGET"); then
        # Extraer texto traducido (puede venir con caracteres especiales)
        translated=$(echo "$response" | jq -r '.translations[0].text' 2>/dev/null || true)
        if [[ -n "$translated" ]]; then
          printf '%s' "$translated"
          return 0
        fi
    fi
    attempt=$((attempt+1))
    sleep $backoff
    backoff=$((backoff * 2))
  done
  return 1
}

process_file() {
  local archivo="$1"
  local base="$(basename "$archivo")"
  local out="${DIR_SALIDA}/${base%.*}_traducido.${base##*.}"

  echo "Procesando $archivo -> $out" | tee -a "$LOG"
  # Arrays temporales
  mapfile -t lines < "$archivo"

  # Identificar qué líneas se traducen y construir bloque
  local delimiter=$'\u001F'   # unit separator — improbable que aparezca en contenido
  local -a indices=()
  local -a original_values=()
  local -a translated_values=()
  local block=""

  for i in "${!lines[@]}"; do
    line="${lines[i]}"
    # Comentarios y líneas en blanco copiarlas tal cual
    if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*[\#;\!].* ]]; then
      continue
    fi
    # Si tiene un = o : considerar key=value (muchos .cfg usan = o :)
    if [[ "$line" =~ ^([^=:\ ]+)[[:space:]]*[:=][[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      if should_translate_value "$val"; then
        indices+=("$i")
        original_values+=("$val")
        # Escape delimiter si aparece en el valor
        safe_val="${val//$delimiter/ }"
        if [[ -z "$block" ]]; then block="$safe_val"; else block+="$delimiter$safe_val"; fi
      fi
    else
      # Línea que no tiene key=value: intentar decidir si traducirla
      if should_translate_value "$line"; then
        indices+=("$i")
        original_values+=("$line")
        safe_val="${line//$delimiter/ }"
        if [[ -z "$block" ]]; then block="$safe_val"; else block+="$delimiter$safe_val"; fi
      fi
    fi
  done

  if [[ ${#indices[@]} -eq 0 ]]; then
    echo "No hay valores traducibles en $archivo. Copiando archivo." | tee -a "$LOG"
    cp "$archivo" "$out"
    echo "COPIADO: $archivo -> $out" >> "$REPORT"
    return 0
  fi

  # Traducir el bloque completo para mantener contexto
  translated_block=$(translate_block "$block") || {
    echo "ERROR: Falló la traducción de $archivo" | tee -a "$LOG"
    echo "ERROR: $archivo" >> "$REPORT"
    return 1
  }

  # Separar el resultado por delimiter
  IFS="$delimiter" read -r -a translated_values <<< "$translated_block"

  # Reconstruir el archivo: reemplazar solo los valores traducibles
  for idx in "${!indices[@]}"; do
    line_index="${indices[idx]}"
    orig="${original_values[idx]}"
    tr_value="${translated_values[idx]:-}"   # si falla, queda vacío
    orig_line="${lines[line_index]}"

    if [[ "$orig_line" =~ ^([^=:\ ]+)([[:space:]]*[:=][[:space:]]*)(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
      lines[line_index]="${prefix}${tr_value}"
    else
      lines[line_index]="${tr_value}"
    fi
  done

  # Escribir salida preservando permisos si es posible
  printf "%s\n" "${lines[@]}" > "$out"
  chmod --reference="$archivo" "$out" 2>/dev/null || true

  echo "[OK] $archivo -> $out" | tee -a "$LOG"
  echo "[OK] $archivo -> $out" >> "$REPORT"
}

shopt -s nullglob
for archivo in "$DIRECTORIO"/*.cfg; do
  process_file "$archivo" || echo "Aviso: error procesando $archivo" | tee -a "$LOG"
done

echo "Fin: $(date --iso-8601=seconds)" | tee -a "$LOG"
echo "Última ejecución: $(date --iso-8601=seconds)" >> "$REPORT"

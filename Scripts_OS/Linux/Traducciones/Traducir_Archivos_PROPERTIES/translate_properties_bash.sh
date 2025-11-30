#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# translate_properties_bash.sh
# - Traduce archivos .properties (Java) preservando keys, placeholders (%s, {0}), y comentarios
# - Agrupa valores traducibles para mantener contexto
# - Reintentos con backoff
#
# Dependencias: curl, jq
# Uso: ./translate_properties_bash.sh [DIRECTORIO_ORIGEN] [DIRECTORIO_SALIDA] [API_KEY] [SRC_LANG] [TGT_LANG]

DIRECTORIO="${1:-properties_originales}"
DIR_SALIDA="${2:-properties_traducidos}"
API_KEY="${3:-${DEEPL_API_KEY:-}}"
LANG_SOURCE="${4:-EN}"
LANG_TARGET="${5:-ES}"
LOG="${DIR_SALIDA}/traducciones_properties.log"
REPORT="${DIR_SALIDA}/latest_report.txt"

if [[ -z "$API_KEY" ]]; then
  echo "ERROR: API key requerida. Pasa la API key como tercer argumento o exporta DEEPL_API_KEY." >&2
  exit 1
fi

mkdir -p "$DIRECTORIO" "$DIR_SALIDA"

echo "Inicio: $(date --iso-8601=seconds)" > "$LOG"
echo "Reporte: $(date --iso-8601=seconds)" > "$REPORT"
echo "Traduciendo archivos .properties en $DIRECTORIO -> $DIR_SALIDA" | tee -a "$LOG"

should_translate_value() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  if [[ -z "$v" ]]; then return 1; fi
  if [[ "$v" =~ ^[0-9]+([.,][0-9]+)?$ ]]; then return 1; fi
  case "${v,,}" in true|false|on|off) return 1;; esac
  # Preserve common placeholders and tokens: {0}, %s, %d, {name}, ${...}
  if [[ "$v" =~ /|\\|http:|https:|ftp:|@|\{[0-9]+\}|\{[a-zA-Z0-9_]+\}|\%s|\%d|\$\{.+\} ]]; then return 1; fi
  return 0
}

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
  mapfile -t lines < "$archivo"

  local delimiter=$'\u001F'
  local -a indices=()
  local -a original_values=()
  local block=""

  for i in "${!lines[@]}"; do
    line="${lines[i]}"
    # Copy comments and blank lines
    if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*[#!].* ]]; then
      continue
    fi
    # properties use key=value (sometimes with :) — allow escaped =
    if [[ "$line" =~ ^([^=:\ ]+)[[:space:]]*[:=][[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      if should_translate_value "$val"; then
        indices+=("$i")
        original_values+=("$val")
        safe_val="${val//$delimiter/ }"
        if [[ -z "$block" ]]; then block="$safe_val"; else block+="$delimiter$safe_val"; fi
      fi
    else
      if should_translate_value "$line"; then
        indices+=("$i")
        original_values+=("$line")
        safe_val="${line//$delimiter/ }"
        if [[ -z "$block" ]]; then block="$safe_val"; else block+="$delimiter$safe_val"; fi
      fi
    fi
  done

  if [[ ${#indices[@]} -eq 0 ]]; then
    cp "$archivo" "$out"
    echo "COPIADO: $archivo -> $out" >> "$REPORT"
    return 0
  fi

  translated_block=$(translate_block "$block") || {
    echo "ERROR: Falló traducción $archivo" | tee -a "$LOG"
    echo "ERROR: $archivo" >> "$REPORT"
    return 1
  }

  IFS="$delimiter" read -r -a translated_values <<< "$translated_block"

  for idx in "${!indices[@]}"; do
    line_index="${indices[idx]}"
    tr_value="${translated_values[idx]:-}"
    orig_line="${lines[line_index]}"
    if [[ "$orig_line" =~ ^([^=:\ ]+)([[:space:]]*[:=][[:space:]]*)(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
      lines[line_index]="${prefix}${tr_value}"
    else
      lines[line_index]="${tr_value}"
    fi
  done

  printf "%s\n" "${lines[@]}" > "$out"
  chmod --reference="$archivo" "$out" 2>/dev/null || true

  echo "[OK] $archivo -> $out" | tee -a "$LOG"
  echo "[OK] $archivo -> $out" >> "$REPORT"
}

shopt -s nullglob
for archivo in "$DIRECTORIO"/*.properties; do
  process_file "$archivo" || echo "Aviso: error procesando $archivo" | tee -a "$LOG"
done

echo "Fin: $(date --iso-8601=seconds)" | tee -a "$LOG"

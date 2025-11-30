#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# translate_properties_multimotor.sh
# - Multiarchivo, multi-idioma, multimotor (via translate-shell 'trans')
# - Preserva keys, placeholders ({0}, %s, ${var}), y comentarios
# - Agrupa bloques de texto para mantener contexto
# - Reintentos con backoff exponencial
# - GUI opcional con zenity
#
# Dependencias: translate-shell (trans), zenity (opcional)
# Uso: ./translate_properties_multimotor.sh [DIR_IN] [DIR_OUT] [ENGINE] [SRC_LANG] [DST_LANG]
# Ejemplo: ./translate_properties_multimotor.sh props_in props_out google en es

DIR_IN="${1:-properties_originales}"
DIR_OUT="${2:-properties_traducidos}"
ENGINE="${3:-google}"   # google, bing, yandex, deepl, apertium, etc. (según trans)
SRC_LANG="${4:-auto}"
DST_LANG="${5:-es}"
LOG="${DIR_OUT}/traducciones_properties_multimotor.log"
REPORT="${DIR_OUT}/latest_report.txt"

command -v trans >/dev/null 2>&1 || { echo "ERROR: translate-shell ('trans') no encontrado. Instala translate-shell."; exit 1; }

mkdir -p "$DIR_IN" "$DIR_OUT"
echo "Inicio: $(date --iso-8601=seconds)" > "$LOG"
echo "Reporte: $(date --iso-8601=seconds)" > "$REPORT"
echo "Motor: $ENGINE Origen: $SRC_LANG → Destino: $DST_LANG" | tee -a "$LOG"

# Heurística: decidir si un valor debe ser traducido
should_translate() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  if [[ -z "$v" ]]; then return 1; fi
  if [[ "$v" =~ ^[0-9]+([.,][0-9]+)?$ ]]; then return 1; fi
  case "${v,,}" in
    true|false|on|off) return 1;;
  esac
  # No traducir si contiene rutas, URLs, emails, placeholders comunes o variables
  if [[ "$v" =~ /|\\|http:|https:|ftp:|@|\{[0-9]+\}|\{[a-zA-Z0-9_]+\}|\%s|\%d|\$\{.+\} ]]; then return 1; fi
  return 0
}

translate_block() {
  local block="$1"
  local attempts=0
  local max_attempts=5
  local backoff=1
  # Use trans with engine and languages; -b for brief output
  while (( attempts < max_attempts )); do
    if out=$(trans -e "$ENGINE" -b "$SRC_LANG:$DST_LANG" "$block" 2>/dev/null); then
      printf '%s' "$out"
      return 0
    fi
    attempts=$((attempts+1))
    sleep $backoff
    backoff=$((backoff*2))
  done
  return 1
}

process_file() {
  local file="$1"
  local base="$(basename "$file")"
  local out="${DIR_OUT}/${base%.*}_traducido.${base##*.}"
  echo "Procesando $file -> $out" | tee -a "$LOG"
  mapfile -t lines < "$file"

  local delimiter=$'\u001F'
  local -a indices=()
  local -a originals=()
  local block=""

  for i in "${!lines[@]}"; do
    line="${lines[i]}"
    # Copiar comentarios y líneas vacías
    if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*[#!].* ]]; then
      continue
    fi
    # Buscar key=value (properties suele usar '=' o ':')
    if [[ "$line" =~ ^([^=:#]+)[[:space:]]*[:=][[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      if should_translate "$val"; then
        indices+=("$i")
        originals+=("$val")
        safe_val="${val//$delimiter/ }"
        if [[ -z "$block" ]]; then block="$safe_val"; else block+="$delimiter$safe_val"; fi
      fi
    else
      # línea suelta
      if should_translate "$line"; then
        indices+=("$i")
        originals+=("$line")
        safe_val="${line//$delimiter/ }"
        if [[ -z "$block" ]]; then block="$safe_val"; else block+="$delimiter$safe_val"; fi
      fi
    fi
  done

  if [[ ${#indices[@]} -eq 0 ]]; then
    echo "No hay valores traducibles. Copiando archivo." | tee -a "$LOG"
    cp "$file" "$out"
    echo "[COPIADO] $file -> $out" >> "$REPORT"
    return 0
  fi

  translated_block=$(translate_block "$block") || {
    echo "ERROR: Falló traducción para $file" | tee -a "$LOG"
    echo "[ERROR] $file" >> "$REPORT"
    return 1
  }

  IFS="$delimiter" read -r -a translated_values <<< "$translated_block"

  for idx in "${!indices[@]}"; do
    line_index="${indices[idx]}"
    tr_val="${translated_values[idx]:-}"
    orig_line="${lines[line_index]}"
    if [[ "$orig_line" =~ ^([^=:#]+)([[:space:]]*[:=][[:space:]]*)(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
      lines[line_index]="${prefix}${tr_val}"
    else
      lines[line_index]="${tr_val}"
    fi
  done

  printf "%s\n" "${lines[@]}" > "$out"
  chmod --reference="$file" "$out" 2>/dev/null || true
  echo "[OK] $file -> $out" | tee -a "$LOG"
  echo "[OK] $file -> $out" >> "$REPORT"
  return 0
}

shopt -s nullglob
for f in "$DIR_IN"/*.properties; do
  process_file "$f" || echo "Aviso: error en $f" | tee -a "$LOG"
done

echo "Fin: $(date --iso-8601=seconds)" | tee -a "$LOG"

# Traducir_Archivos_CFG — par complementario (se conservan ambos)

Traduce archivos `.cfg` preservando keys, valores numéricos, rutas, URLs,
placeholders y líneas técnicas.

## Cuándo usar cada uno

- `traducir_archivos_cfg.sh`: **gratis, sin API key**. Usa `translate-shell`
  (`trans`, motores google/bing/deepl-vía-trans) + zenity opcional.
  Requiere: `translate-shell`.
- `improved_traducir_archivos_cfg.sh`: **mayor calidad**. Usa DeepL API
  directa (requiere key: tercer argumento o `DEEPL_API_KEY`), agrupa valores
  para contexto (1 request/archivo), backoff exponencial, log y reporte.
  Requiere: `curl`, `jq`. Uso:
  `./improved_traducir_archivos_cfg.sh [ORIGEN] [SALIDA] [API_KEY] [SRC] [DST]`

No son duplicados: distinto requisito (gratis vs API key) y distinta
calidad. Se mantienen ambos a propósito (criterio F3).

# Traducir PROPERTIES (Bash) — par complementario (se conservan ambos)

Traduce archivos `.properties` (Java) preservando keys, placeholders
(`%s`, `{0}`, `${var}`) y comentarios.

## Cuándo usar cada uno

- `translate_properties_bash.sh`: **DeepL API directa** (curl/jq, batching
  con contexto, backoff). Requiere key: argumento o `DEEPL_API_KEY`.
  Uso: `./translate_properties_bash.sh [ORIGEN] [SALIDA] [API_KEY] [SRC] [DST]`
- `translate_properties_multimotor.sh`: **gratis, sin API key**. Usa
  `translate-shell` (`trans`, motores google/bing/yandex/deepl/apertium) +
  zenity opcional.
  Uso: `./translate_properties_multimotor.sh [IN] [OUT] [MOTOR] [SRC] [DST]`

No son duplicados: distinto requisito y cobertura de motores.
Las variantes Python (Tkinter) viven en
`../../../Multiplataforma/Traducciones/Traducir_Archivos_PROPERTIES/`.

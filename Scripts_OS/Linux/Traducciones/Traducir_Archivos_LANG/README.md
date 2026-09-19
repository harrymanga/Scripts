# Traducir_Archivos_LANG — versiones únicas (Bash)

Traduce archivos `.lang` (y `.json` en la variante Minecraft) preservando
formato. Todas con i18n es/en (`lang_*_es.sh` / `lang_*_en.sh`;
detección: parámetro `es|en` > `$LANG` > español).

## Conservadas (5)

- `GUI_YAD/YAD_PRO/multimotor/traducir_lang_multimotor_yad.sh` — **canónica multimotor**: Google-batch + trans-shell + DeepL + OpenAI con fallback, caché md5, backups, config persistente y **placeholders** (`<tag>`, `%s/%d`, `{var}`). Uso: `./traducir_lang_multimotor_yad.sh [es|en]`.
- `GUI_YAD/YAD_PRO/sqlite/traducir_lang_sqlite_yad.sh` — alternativa con **caché SQLite** (trans+DeepL+OpenAI, token, `validate_placeholders`).

Cada script vive en su subcarpeta con sus idiomas (`lang_*_es.sh` / `lang_*_en.sh`).
- `GUI_YAD/YAD_INDUSTRIAL/traducir_archivos_lang_yad_industrial_modder.sh` — modo **proyectos** (workspaces con SQLite + hash md5 + revisión manual).
- `GUI_YAD/YAD_MINECRAFT_HYTALE/traducir_archivos_lang_yad_minecraft_hytale.sh` — especialidad **juegos**: `.lang` + `.json`, workspaces.
- `GUI_ZENITY/traducir_archivos_lang_zenity.sh` — único espejo **Zenity** (Google/trans/DeepL/OpenAI; el idioma elegido es también el destino).

## Requisitos

- `yad` (o `zenity`), `curl`, `jq`, `trans` (translate-shell) según variante; `sqlite3` para dr/modder/minecraft. API keys según motor.

## Retiradas en B2 (subsumidas por `fui.sh` tras portar placeholders)

- `pro` (⊂ fix), `pro_fix`, `as`, `exd` (DeepL+trans ⊂ multimotor), `ultra_pro` (⊂ multimotor; se pierde `detect_spanish`, menor), `ds`/`ed` (⊂ `dr`), `industrial` (gemelo de `modder` sin md5).

## Versión Python

Las GUI Python viven en `../../../Multiplataforma/Traducciones/` (`TraductorPro` = candidato canónico final del grupo B, fase B3).

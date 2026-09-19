# Convertir_De_ISO_a_CSO — versión única

Conversión ISO↔CSO (formato comprimido de PSP) con `ciso` e interfaz zenity.
Función distinta a `Convertir_A_CHD/` (mundo MAME, herramienta `chdman`).

## Requisitos

- `zenity` y `ciso` (si faltan, el script avisa; `ciso` no tiene paquete
  estándar en todas las distros, por eso su instalación es manual).

## Uso

```bash
./Multiconversor_De_ISO_a_CSO.sh         # idioma según $LANG
./Multiconversor_De_ISO_a_CSO.sh en      # inglés forzado
```

1. Elige `ISO a CSO` (comprime, nivel 9) o `CSO a ISO` (descomprime).
2. Selecciona uno o varios archivos.

## Idiomas (es/en)

- `lang_es.sh` / `lang_en.sh`: 10 claves. Detección: parámetro > `$LANG` >
  español por defecto.

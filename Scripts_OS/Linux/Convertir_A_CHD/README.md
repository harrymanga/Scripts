# Convertir_A_CHD — versión única

Conversión de imágenes de disco (CHD↔CUE/GDI/ISO) con `chdman` (mame-tools)
e interfaz zenity.

## Contenido

- `Multiconversor/Multiconversor_a_CHD.sh`: conversor único con barra de
  progreso + registro en vivo + workaround CHD→ISO (`.bin`) + i18n es/en
  (`lang_es.sh`/`lang_en.sh`, 21 claves).
- `Unitarios/game2chd.sh`: alternativa CLI por argumentos con cola de
  tareas opcional. **Código de terceros (gotbletu)**: se conserva tal cual,
  con su ayuda integrada (`-h`).

## Requisitos

- `zenity` y `chdman`. Si faltan, el Multiconversor intenta instalarlos
  solo (apt/dnf/pacman) y solo avisa si no es posible.

## Uso

```bash
./Multiconversor/Multiconversor_a_CHD.sh         # idioma según $LANG
./Multiconversor/Multiconversor_a_CHD.sh en      # inglés forzado
```

1. Elige el tipo de conversión en la lista.
2. Selecciona uno o varios archivos.
3. Sigue la barra de progreso; al final se muestra el registro completo.

CLI por lotes (sin GUI):

```bash
./Unitarios/game2chd.sh *.cue
./Unitarios/game2chd.sh -h   # ayuda completa
```

## Idiomas (es/en)

- Detección: parámetro `es|en` > `$LANG` > español por defecto.

## Cambios respecto a las versiones anteriores

- Unificadas las 3 variantes Multiconversor (base + Consola + Progreso).
- Restaurado el workaround `.bin`→`.iso` (las variantes Consola/Progreso
  lo habían perdido).
- Retirados los 6 Unitarios de 1 línea (subsumidos por el Multiconversor).

## Lado Windows

Ver `../../../Windows/Convertir_A_CHD/` (`CHDman/` + proyecto externo
`ToCHD_V0.13/`): implementaciones propias de Windows, no duplicadas.

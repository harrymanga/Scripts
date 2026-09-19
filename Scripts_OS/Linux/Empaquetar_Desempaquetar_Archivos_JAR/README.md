# Empaquetar_Desempaquetar_Archivos_JAR — versión única (Bash)

Empaqueta carpetas a `.jar` y desempaqueta `.jar` con el JDK, en GUI
(auto yad→zenity) o CLI. i18n es/en (`lang_es.sh` / `lang_en.sh`, 18 claves).

## Contenido

- `jar_manager.sh [es|en]` — GUI en bucle (unpack/pack/exit).
- `jar_manager.sh --cli pack|unpack SALIDA items...` — modo consola.
- `lib/jar_core.sh` — núcleo compartido (validación, log, pack, unpack).
- `install.sh` / `uninstall.sh` — instalación sin sudo en `~/.local/bin`
  + lanzador `.desktop`.

## Requisitos

- `jar` (JDK), `unzip` + `yad` o `zenity`. Instalación asistida
  (apt/dnf/pacman); solo avisa si falla. Log: `~/jar_manager.log`.

## Uso

```bash
./jar_manager.sh                 # GUI, idioma según $LANG
./jar_manager.sh en              # GUI en inglés
./jar_manager.sh --cli unpack ~/salida app.jar
./jar_manager.sh --cli pack ~/salida mi_carpeta
./install.sh                     # instala en ~/.local/bin
```

## Versión Python

La GUI Qt completa (lotes, temas, 6 idiomas, tests) es
`../../Proyectos_De_Software/Python/JarTool/` (canónica Python del grupo;
`run.sh`). Este script es la alternativa ligera sin dependencias Python.

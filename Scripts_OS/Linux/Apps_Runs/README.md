# Apps_Runs — generador de aplicaciones (versión única)

Crea proyectos de app (plantilla + lanzadores + servicio systemd opcional)
desde GUI Tkinter o CLI.

## Contenido

- `AppBuilder/appbuilder_framework_extended/` — **versión canónica**:
  GUI (`appbuilder.py`), CLI (`cli/appbuilder_cli.py`), i18n es/en,
  build (`build/build.sh`). Sin dependencias (stdlib).
  - GUI: `python3 appbuilder.py`
  - CLI: `python3 cli/appbuilder_cli.py --name MiApp --dest . --inter python3 --args "" --exec main.py`
- `plantilla_start.sh` — plantilla de script `start.sh` (referencia).
- Retirados en D2: `appbuilder_framework/` (núcleo idéntico al extended,
  verificado por diff) y `Generar_Apps/` (`create_app.sh` ⊂ CLI extended;
  `miapp_template.zip` duplicado exacto).

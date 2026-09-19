# TraductorPro — canónico oficial del grupo Traducciones

Aplicación multiplataforma de traducción de archivos con interfaz gráfica Qt.

## Cobertura (verificada B3)

| Formato | Handler | Placeholders |
|---|---|---|
| `.cfg` | `CfgFileHandler` | `<tag>`, `%s/%d`, `{var}` |
| `.lang` | `LangFileHandler` | `<tag>`, `%s/%d`, `{var}` (Minecraft OK) |
| `.txt` | `TxtFileHandler` | — |
| `.properties` | `PropertiesFileHandler` | `{0}`, `%s`, `${var}` (+ comentarios `#!/!` preservados) |

Motores: Google (googletrans, sin key), DeepL, OpenAI. Caché MD5, backups,
reportes, keyring. Suite: 47 tests (`pytest`).

## Características

- **Multi-formato**: Traduce archivos `.cfg`, `.lang`, `.txt` y `.properties`
- **Multi-motor**: Google Translate, DeepL, OpenAI
- **Multi-idioma**: Selección flexible de idioma origen y destino
- **Protección de placeholders**: Preserva marcadores como `<tag>`, `%s`, `%d`, `{var}`
- **Caché inteligente**: Evita traducciones duplicadas con hash MD5
- **Reemplazos personalizados**: Correcciones post-traducción
- **Reportes detallados**: Log de operaciones por archivo
- **Backups automáticos**: Respaldo de archivos originales
- **Gestión segura de API keys**: Usa keyring del sistema operativo

## Arquitectura

Clean Architecture con 4 capas:

```
Domain → Application → Infrastructure → Presentation
```

- **Domain**: Entidades y puertos (interfaces abstractas)
- **Application**: Casos de uso (orquestación de reglas de negocio)
- **Infrastructure**: Adaptadores (traductores, handlers de archivo, caché, seguridad)
- **Presentation**: GUI Qt (carga .ui de Qt Designer)

## Instalación y uso (recomendado)

```bash
./run.sh        # crea .venv, instala dependencias y ejecuta (Linux/macOS)
```

En Windows: `run.bat`. El lanzador hace todo solo; la instalación manual
siguiente solo es necesaria si trabajas sin él:

```bash
python -m venv venv
source venv/bin/activate  # Linux/macOS
pip install -e ".[dev]"
```

## Uso manual

```bash
python main.py
```

## Desarrollo

### Ejecutar pruebas

```bash
pytest
```

### Linting

```bash
flake8 src/ tests/
mypy src/
black --check src/ tests/
```

### Editar la UI

Abrir `ui/main_window.ui` con Qt Designer:

```bash
designer ui/main_window.ui
```

## Licencia

MIT

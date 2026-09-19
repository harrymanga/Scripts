# Industrial Language Translator

## Overview
Advanced industrial-grade translation tool with:
- GUI (PySide6)
- Google Translate support
- Batch optimization
- Parallel processing
- SQLite cache
- Docker-ready deployment

## Supported Formats
- .lang
- .json
- .xml
- .yaml

## Run Locally (recomendado)

```bash
./run.sh        # crea .venv, instala dependencias y ejecuta (Linux/macOS)
```

En Windows: `run.bat`. Equivalente manual:

```bash
pip install -r requirements.txt
python -m app.main
```

## Run with Docker

```bash
docker compose up --build
```

## Architecture

- GUI Layer
- Core (Batch, Cache, Rate Limiting)
- Providers (Google, DeepL ready)
- Utils (Placeholder Protection)

## Performance Features

- Batch API calls
- Thread pool execution
- Cost estimation ready
- Retry with exponential backoff
- Persistent cache

## Production Ready

Designed for scalability and extension into enterprise systems.

# Convertir_Audio_a_Texto — versión única

Transcribe un archivo de audio a texto (reconocimiento de Google).

## Requisitos

- Python 3 con tkinter. **Nada más que instalar a mano**: al ejecutar,
  el programa instala solo `SpeechRecognition` (pregunta antes).
- Conexión a internet. Formatos: WAV, AIFF/AIF, FLAC.
- No requiere micrófono ni PyAudio (solo archivos).

## Uso

```bash
./run.sh        # crea .venv, instala dependencias y ejecuta (Linux/macOS)
```

En Windows: `run.bat`. (Equivalente manual: `python audio_a_texto.py`,
previa instalación de `requirements.txt`.)

1. Elige el archivo de audio en el diálogo (ver `muestra.wav` para probar).
2. El texto se muestra en consola y se guarda junto al audio con el mismo
   nombre (`entrevista.wav` → `entrevista.txt`).
3. Idioma de reconocimiento: español por defecto; para otro idioma:
   `AUDIO_LANG=en-US python audio_a_texto.py`.

## Idiomas (es/en)

- Diccionario interno es/en (interfaz + mensajes, detección por `locale`).

## Cambios respecto a las versiones anteriores

- `recognize_google(..., language="es-ES")` configurable (antes usaba el
  inglés por defecto, inadecuado para audio español).
- `except:` desnudo → excepciones específicas (`UnknownValueError`,
  `RequestError`) con mensajes propios.
- Salida junto al audio con el nombre base (antes nombre fijo).
- Chequeo de cancelación del diálogo.

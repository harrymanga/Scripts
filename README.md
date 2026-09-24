# Scripts

Colección de scripts de apoyo para diversas tareas de automatización y administración.

## Contenido

### Scripts_OS

#### Linux

- **Apps_Runs**: generador único extended (GUI+CLI, ver su README)
- **Convertir_A_CHD**: `Multiconversor_a_CHD.sh` único (progreso+log, es/en) + `game2chd.sh` CLI terceros (ver su README)
- **Convertir_De_ISO_a_CSO**: `Multiconversor_De_ISO_a_CSO.sh` único con ciso (es/en, ver su README)
- **Crear_Archivos\_.Desktop**: Creación de lanzadores
- **Crear_Lanzadores_de_Apps**: `crear_lanzador_de_apps.sh` único es/en + AppDir sincronizado (ver su README)
- **Discos**: Gestión de discos
- **Ejecutar_Sh**: Ejecución de scripts shell
- **Empaquetar_Desempaquetar_Archivos_JAR**: `jar_manager.sh` único (GUI auto yad→zenity + CLI, es/en, ver su README)
- **Encabezado_de_Archivos_Sh**: Plantillas para scripts shell
- **Montar Isos**: Montaje de imágenes ISO
- **Sincronizar_carpetas/Bash**: alternativa ligera sin Python (inotifywait+rsync, es/en; ver su README)
- **Traducciones**: Bash/YAD/Zenity con i18n (LANG: 5 únicos + READMEs; CFG y PROPERTIES como pares complementarios documentados)
- **Yay_Update**: Actualización con yay (AUR helper)

#### Windows

- **Actualizar_Programas/Winget**: `Upgrade Programas winget.bat` (actualizar todo con Winget)
- **Convertir_A_CHD**: `CHDman/` (chdman.exe + .bat) y `ToCHD_V0.13/` (tochd.py multiplataforma)
- **Colocar_Contraseña_a_Carpetas**: `Carpeta_Con_Contrasena.bat` único (ofuscación CLSID, no cifrado; ver su README)
- **Limpieza_De_Cache**: `limpieza_completa.bat [full|temp|logs]` + GUI `limpieza.py` (ver su README)
- **Inventario_Programas**: inventario vía Winget/PowerShell/WMIC con `menu.bat` selector (ver su README)

#### Multiplataforma

Scripts Python que corren en Linux y Windows (y macOS), organizados por función:

- **Sincronizar_Carpetas/sync-auto**: versión canónica (tkinter+watchdog, múltiples destinos, es/en, con Uso en su README)
- **Traducciones**: proyecto independiente en `../Proyectos_De_Software/Python/TraductorPro/` (canónico oficial; las variantes Python PROPERTIES/TXT fueron absorbidas)
- **Empaquetar JAR (Python)**: GUI Qt completa en `../Proyectos_De_Software/Python/JarTool/` (canónica Python del grupo; `run.sh`)
- **Convertir_PDF_a_Audio**: PDF→MP3 con Tkinter (auto-deps, es/en, ver su README)
- **Convertir_Audio_a_Texto**: audio→texto con reconocimiento Google es-ES (auto-deps, ver su README)
- **Convertir_Formatos_de_Audio**: conversor 9 formatos con Tkinter (auto-deps + ffmpeg, ver su README)

## Tecnologías

- Shell Script (Bash)
- Python
- PyQt/PySide para interfaces gráficas

## Uso

Cada script incluye instrucciones de uso en su README o comentarios.

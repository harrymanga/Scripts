# Avance de sesión — Ordenamiento y depuración de proyectos y scripts

**Fecha:** 2026-09-18
**Ámbito:** `/run/media/handerson/0CD2ACE7D2ACD66C/Carreras/Programacion/`
**Sistema de trabajo:** `AI_SOFTWARE_ENGINEERING_SYSTEM.md` v1.0
**Ruta del sistema:**
`/run/media/handerson/0CD2ACE7D2ACD66C/Carreras/Programacion/GitHub/Scripts/Scripts_OS/Multiplataforma/Pronts/Desarrollo_de_software/AI_SOFTWARE_ENGINEERING_SYSTEM.md`
(Interacción siempre en español; informe final por tarea según punto 44.)

## Reglas permanentes adoptadas esta sesión

1. Versión única consolidada vive **dentro del repositorio** (para push).
2. Todo README de proyecto/script incluye **Requisitos + Uso paso a paso + Qué esperar + Si algo falla**.
3. **i18n es/en** por defecto (español fallback): `.bat`/`menu` con `lang_*.bat`, `.sh` con `lang_*.sh`, Python con diccionario interno (migrar a `locales/` si crece).
4. **Auto-dependencias**: ningún programa exige instalación manual previa; instalan solas y solo avisan ante errores o decisión necesaria.
5. Estándar **`run.sh`/`run.bat`**: crea `.venv`, instala deps (`requirements.txt` o `pip install -e .`) y ejecuta. Punto de entrada documentado.
6. Sin `LEEME.txt`: al retirar duplicados fuera de repos no se deja puntero; **carpetas vacías se eliminan**.
7. Sin commits ni push sin autorización explícita. Cambios reversibles en working tree.
8. **Nombres funcionales** para proyectos y archivos (sin crípticos tipo `dr.sh`/`fui.sh`).
9. **Proyecto multi-archivo → carpeta + subcarpetas** (`src/`, `data/`, etc.) manteniendo operatividad (rutas relativas, imports intactos).
10. **Subcarpeta por script principal**: si una carpeta reúne varios scripts principales, cada uno va a su subcarpeta con sus archivos asociados (idiomas, etc.).

## Completado

### Reorganización inicial (Scripts_OS)
- Nueva carpeta `Scripts_OS/Multiplataforma/` por función: `Sincronizar_Carpetas/sync-auto`, `Traducciones/*` (Python), `Empaquetar_Desempaquetar_Archivos_JAR/Python_GUI`. Los `.sh` con yad/zenity quedaron en `Linux/`. `README.md` principal actualizado.

### Grupo F — Utilidades Windows ✅ cerrado
- `Limpieza_De_Cache/`: `limpieza_completa.bat [full|temp|logs]` + GUI corregida + README.
- `Colocar_Contraseña_a_Carpetas/`: `Carpeta_Con_Contrasena.bat` único (ofuscación, no cifrado) + README.
- `Inventario_Programas/`: 3 variantes + `menu.bat` + README. `Upgrade` aparte en `Actualizar_Programas/Winget/` (traslado externo del usuario, adaptado).
- i18n es/en en los 3 scripts + Uso en 4 READMEs.

### Grupo C — Sincronizar ✅ cerrado
- Canónico `sync-auto` (busy-loop corregido + i18n 21 claves + README + `requirements.txt` + `run.sh/bat`).
- Alternativa Bash conservada (3 bugs corregidos + i18n 8 claves + README).
- PyQt6 de `Corregir/` retirado (bug `copytree`); carpetas vacías eliminadas.

### Grupo J — Multimedia ✅ cerrado
- `Convertir_PDF_a_Audio/`, `Convertir_Audio_a_Texto/` (es-ES), `Convertir_Formatos_de_Audio/` (fix AAC→aiff, ffmpeg auto-check): únicos + auto-deps + i18n + requirements + README + `run.sh/bat` + 2 muestras. `.exe` (67 MB) eliminados. Retiros en `Corregir/` con carpetas eliminadas.

### Grupo E — CHD/CSO ✅ cerrado
- `Multiconversor_a_CHD.sh` único (progreso+log+workaround `.bin`+i18n 21 claves+autodeps) + README; 2 variantes + 6 unitarios eliminados; `game2chd.sh` (terceros) intacto. `ISO_a_CSO` con i18n + README. Lado `Windows/Convertir_A_CHD/` intacto (trabajo externo del usuario).

### Transversales
- ** pills i18n piloto (F) + extensión a C/J/E.**
- **`run.sh`/`run.bat` en 15 proyectos** (9 Scripts + PDS×4 + Extraer_Strings + JarTool_Ui) + 4 `requirements.txt` nuevos + fix req JarTool_Ui (PyQt6). Validación viva: J2 end-to-end OK, TraductorPro `pip install -e` OK.
- **Re-escaneo + depuración**: 268 `.pyc` + 83 `__pycache__` + `logs/` vacíos eliminados; 6 venvs eliminados (~1.1 GB: TraductorPro 282 MB, Extraer 191 MB, CheatEngine 54 MB, myenv 30 MB, .venv 6.5 MB, .qtcreator-venv 638 MB). Ojo: parte de los `.pyc` estaban commiteados → `Proyectos_De_Software` (28) y `Clases` (8) muestran esas bajas (correcto, se consolidan con `git add -A`).

## Lista de redundancia (estado)

| ID | Grupo | Estado |
|----|-------|--------|
| A | JAR ✅ cerrado (bash único `jar_manager.sh` GUI-auto+CLI+i18n+install; 9 variantes Python fuera, canónica PDS JarTool; renombres funcionales B2: `traducir_lang_multimotor/sqlite_yad.sh`) |
| B | Traducciones ✅ cerrado (B1+B2+B3: TraductorPro canónico con `.properties` + cfg-placeholders, 47 tests OK) |
| C | Sincronizar | ✅ cerrado |
| D | Lanzadores/AppImage ✅ cerrado (lanzador único i18n + AppDir sync; extended canónico, framework base + Generar_Apps fuera; manual AppImage como legacy) |
| I | Firmware Alarma ✅ sin cambios (A1 evoluciona A; MPLAB es blink de prueba; resto distinto) |
| E | CHD/CSO | ✅ cerrado (lado Windows: trabajo del usuario) |
| F | Utilidades Windows | ✅ cerrado |
| G | Cheat Engine (tablas vs bridge) | ⏳ no fusionar (distinto enfoque) |
| H | Ejercicios "Hola mundo" | ⏳ sin acción (didáctico) |
| I | Firmware Alarma Nivel A (mikroC vs MPLAB X vs EasyEDA) | ⏳ pendiente de verificar |
| J | Multimedia Python | ✅ cerrado |

## Pendiente

1. Tareas profundas de pulido por proyecto (tras lista A–J cerrada).
2. Grupos **B, A, D, I** (orden sugerido; B y A son los grandes, por fases).
2. **Commit/push** de todo lo anterior (ver `git status` en `GitHub/Scripts`, `Proyectos_De_Software`, `Clases_De_Programacion_Idat`).
3. **Pruebas reales**: GUIs, `run.bat` en Windows, conversores con ISOs, `ffmpeg`/red.
4. READMEs que referencien `run.sh`: CheatEngine (solo CLAUDE.md), JarTool_Ui (sin README).
5. Diferidos YAGNI (lanzadores al consolidar): 9 variantes JAR Python_GUI, Buscar_Magnet/Zip, Extraer_Texto, AppBuilder.
6. Recrear venvs eliminados si se retoma un proyecto (`python -m venv .venv` o vía su `run.sh`).

## Deuda técnica registrada

- **TD-F1**: F2 es ofuscación, no cifrado + contraseña en texto plano (documentado en su README).
- **TD-F2**: `wmic` obsoleto (conservado, documentado).
- `ciso` sin autoinstalación (documentado). `gTTS`/`recognize_google` dependen de Google en línea.
- `instrucciones.pdf` de sync-auto no verificable aquí (se conserva + `instrucciones.txt`).

## Cómo continuar

1. Leer el sistema (ruta arriba) y este archivo.
2. `git status` en los repos para ver el working tree pendiente.
3. Elegir siguiente grupo (sugerido: **B** por fases, o **D**), inspeccionar (Fase 0), diagnosticar, proponer plan y **pedir confirmación antes de eliminar**.

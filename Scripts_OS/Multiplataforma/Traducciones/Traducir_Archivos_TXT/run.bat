@echo off
REM run.bat — Punto de entrada único en Windows: crea .venv, instala deps y ejecuta.
REM Uso: run.bat
REM Entrada: main2.py (GUI tkinter). main.py es la versión CLI con rutas fijas.
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
    where py >nul 2>&1
    if %errorlevel%==0 ( py -3 -m venv .venv ) else ( python -m venv .venv )
)
".venv\Scripts\python.exe" -m pip install -q --upgrade pip
".venv\Scripts\python.exe" -m pip install -q -r requirements.txt
".venv\Scripts\python.exe" main2.py %*

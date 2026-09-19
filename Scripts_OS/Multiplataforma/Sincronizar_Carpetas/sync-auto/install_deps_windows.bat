@echo off
where python >nul 2>nul
if errorlevel 1 (
    echo Python no esta instalado. Por favor instala Python 3 desde https://python.org
    pause
    exit /b 1
)
python -m pip show watchdog >nul 2>nul
if errorlevel 1 (
    echo Instalando watchdog...
    python -m pip install watchdog
)
echo Dependencias instaladas correctamente.
pause

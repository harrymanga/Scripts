@echo off
REM =====================================================================
REM  limpieza_completa.bat — Versión única consolidada
REM  Reemplaza a: limpiar.bat (simple) y limpieza.bat (completa).
REM  Ubicación canónica: Scripts_OS/Windows/Limpieza_De_Cache/
REM
REM  Uso: limpieza_completa.bat [full ^| temp ^| logs] [es ^| en]
REM    full  (por defecto): limpieza completa del sistema.
REM    temp:  solo carpetas temporales y prefetch.
REM    logs:  solo archivos .log y visor de eventos.
REM  Idioma: parámetro es/en, cultura del sistema o español por defecto.
REM  Requiere: Windows con permisos de Administrador.
REM =====================================================================

REM --- Detección de idioma (parámetro > cultura del sistema > es) ---
set "LANG_ID=es"
for /f "tokens=*" %%C in ('powershell -noprofile -command "(Get-Culture).Name" 2^>nul') do set "CULTURE=%%C"
if defined CULTURE set "LANG2=%CULTURE:~0,2%"
if /I "%LANG2%"=="en" set "LANG_ID=en"
if /I "%~2"=="en" set "LANG_ID=en"
if /I "%~2"=="es" set "LANG_ID=es"
call "%~dp0lang_%LANG_ID%.bat"

call :checkPermissions

if /I "%~1"=="temp" goto :mode_temp
if /I "%~1"=="logs" goto :mode_logs
goto :mode_full

:mode_temp
REM --- Limpieza de temporales ---
rd /s /q c:\windows\temp 2>nul
md c:\windows\temp 2>nul
del /s /f /q C:\WINDOWS\Prefetch 2>nul
del /s /f /q %temp%\*.* 2>nul
rd /s /q %temp% 2>nul
md %temp% 2>nul
echo %MSG_TEMP_DONE%
goto :end

:mode_logs
REM --- Limpieza de registros ---
cd /d %systemdrive%\ 2>nul
del *.log /a /s /q /f 2>nul
for /F "tokens=*" %%G in ('wevtutil.exe el') DO (call :do_clear "%%G")
echo %MSG_LOGS_DONE%
goto :end

:mode_full
REM --- Limpieza completa: temporales + registros + update + dns ---
cd /d %systemdrive%\ 2>nul
del *.log /a /s /q /f 2>nul
del *.tmp /s /f /q 2>nul

net stop wuauserv 2>nul
net stop UsoSvc 2>nul
rd /s /q C:\Windows\SoftwareDistribution 2>nul
md C:\Windows\SoftwareDistribution 2>nul

rd /s /q c:\windows\temp 2>nul
md c:\windows\temp 2>nul
rd /s /q c:\windows\tmp 2>nul
del /s /f /q C:\WINDOWS\Prefetch 2>nul
del /s /f /q %temp%\*.* 2>nul
rd /s /q %temp% 2>nul
md %temp% 2>nul
rd /s /q c:\windows\tempor~1 2>nul
rd /s /q c:\windows\history 2>nul
rd /s /q c:\windows\cookies 2>nul
rd /s /q c:\windows\recent 2>nul
rd /s /q "c:\windows\spool\printers" 2>nul

for /F "tokens=*" %%G in ('wevtutil.exe el') DO (call :do_clear "%%G")
cls
ipconfig /flushdns
echo %MSG_FULL_DONE%
goto :end

:checkPermissions
REM Verifica permisos de administrador.
fsutil dirty query %systemdrive% >nul
if %errorLevel% NEQ 0 (
    echo %MSG_ADMIN%
    echo.
    echo %MSG_ANYKEY%
    pause > nul
    exit
)
exit /b

:do_clear
REM Limpia un registro del visor de eventos.
echo %MSG_CLEANING% %1
wevtutil.exe cl %1
goto :eof

:end
echo.
echo %MSG_ANYKEY%
pause > nul
exit

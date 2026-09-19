@echo off
REM Menú selector de inventario de programas instalados.
REM Uso: menu.bat [es ^| en]. Idioma: parámetro, cultura del sistema o es.
set "LANG_ID=es"
for /f "tokens=*" %%C in ('powershell -noprofile -command "(Get-Culture).Name" 2^>nul') do set "CULTURE=%%C"
if defined CULTURE set "LANG2=%CULTURE:~0,2%"
if /I "%LANG2%"=="en" set "LANG_ID=en"
if /I "%~1"=="en" set "LANG_ID=en"
if /I "%~1"=="es" set "LANG_ID=es"
call "%~dp0lang_%LANG_ID%.bat"
:menu
echo.
echo %MSG_TITLE%
echo %MSG_OPT1%
echo %MSG_OPT2%
echo %MSG_OPT3%
echo %MSG_OPT0%
echo.
set /p "op=%MSG_CHOOSE%"
if "%op%"=="1" call "%~dp0inventario_winget.bat"
if "%op%"=="2" powershell -ExecutionPolicy Bypass -File "%~dp0inventario_powershell.ps1"
if "%op%"=="3" call "%~dp0inventario_cmd.bat"
if "%op%"=="0" exit /b
goto :menu

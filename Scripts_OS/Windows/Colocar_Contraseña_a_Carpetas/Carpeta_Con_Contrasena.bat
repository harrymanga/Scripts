cls
@ECHO OFF
REM =====================================================================
REM  Carpeta_Con_Contrasena.bat — Versión única consolidada
REM  Reemplaza a: "Carpeta Con Contraseña.bat" y
REM                "Colocar Contraseñas a Carpetas.bat" (casi idénticos).
REM  Ubicación canónica: Scripts_OS/Windows/Colocar_Contraseña_a_Carpetas/
REM
REM  Uso: Carpeta_Con_Contrasena.bat [es ^| en]
REM  Idioma: parámetro es/en, cultura del sistema o español por defecto.
REM
REM  CONFIGURA TU CONTRASEÑA en la variable PASSWORD (línea siguiente).
REM
REM  ADVERTENCIA: esto es OFUSCACIÓN (CLSID Control Panel + atributos
REM  oculto/sistema), NO cifrado. Cualquiera con conocimientos puede
REM  revertirlo. No lo uses para información sensible.
REM =====================================================================
set "PASSWORD=CAMBIA_ESTA_CONTRASENA"
REM --- Detección de idioma (parámetro > cultura del sistema > es) ---
set "LANG_ID=es"
for /f "tokens=*" %%C in ('powershell -noprofile -command "(Get-Culture).Name" 2^>nul') do set "CULTURE=%%C"
if defined CULTURE set "LANG2=%CULTURE:~0,2%"
if /I "%LANG2%"=="en" set "LANG_ID=en"
if /I "%~1"=="en" set "LANG_ID=en"
if /I "%~1"=="es" set "LANG_ID=es"
call "%~dp0lang_%LANG_ID%.bat"
CHCP 65001 >nul
title Folder CarpetaProtegida
if EXIST "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}" goto UNLOCK
if NOT EXIST CarpetaProtegida goto MDLOCKER
:CONFIRM
echo %MSG_CONFIRM%
set/p "cho="
if %cho%==S goto LOCK
if %cho%==s goto LOCK
if %cho%==Y goto LOCK
if %cho%==y goto LOCK
if %cho%==n goto NOLOCK
if %cho%==N goto NOLOCK
echo %MSG_INVALID%
goto CONFIRM
:LOCK
ren CarpetaProtegida "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
attrib +h +s "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
echo %MSG_LOCKED%
goto End
:NOLOCK
echo %MSG_NOTLOCKED%
goto End
:UNLOCK
echo %MSG_ASKPASS%
set/p "pass="
if NOT "%pass%"=="%PASSWORD%" goto FAIL
attrib -h -s "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
ren "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}" CarpetaProtegida
echo %MSG_UNLOCKED%
goto End
:FAIL
echo %MSG_BADPASS%
goto End
:MDLOCKER
md CarpetaProtegida
echo %MSG_CREATED%
goto End
:End
@pause

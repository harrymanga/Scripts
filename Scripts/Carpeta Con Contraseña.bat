cls
@ECHO OFF
:: Seteamos la codificación actual al latino,
:: para poder usar los acentos latinos.
:: CHCP 1252 1>NUL
CHCP 65001
title Folder CarpetaProtegida
if EXIST "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}" goto UNLOCK
if NOT EXIST CarpetaProtegida goto MDLOCKER
:CONFIRM
echo Quiere ocultar la CarpetaProtegida? (S/N)
set/p "cho="
if %cho%==S goto LOCK
if %cho%==s goto LOCK
if %cho%==n goto NOLOCK
if %cho%==N goto NOLOCK
echo Elección no válida.
goto CONFIRM
:LOCK
ren CarpetaProtegida "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
attrib +h +s "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
echo Carpeta bloqueada exitosamente
goto End
:NOLOCK
echo La carpeta no esta bloqueda
goto End
:UNLOCK
echo Introduzca la contraseña para mostrar la CarpetaProtegida
set/p "pass="
if NOT %pass%== Mimamamemimamucho goto FAIL
attrib -h -s "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
ren "Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}" CarpetaProtegida
echo Carpeta desbloqueada exitosamente
goto End
:FAIL
echo Contraseña invalida
goto End
:MDLOCKER
md CarpetaProtegida
echo CarpetaProtegida creado exitosamente
goto End
:End
@pause
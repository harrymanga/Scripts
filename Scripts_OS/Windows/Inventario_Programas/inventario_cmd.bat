@echo off
REM Inventario de programas instalados vía WMIC (línea de comandos clásica).
REM Nota: wmic está obsoleto en Windows 11; si falla, usa inventario_winget.bat
REM o inventario_powershell.ps1. Salida en el Escritorio del usuario actual.
wmic /output:"%USERPROFILE%\Desktop\programas_instalados_cmd.txt" product get name,version
@pause

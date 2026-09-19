@echo off
REM Inventario de programas instalados vía Winget (exporta con versiones).
REM Salida en el Escritorio del usuario actual.
winget export -o "%USERPROFILE%\Desktop\Programas_Instalados_winget.txt" --include-versions
@pause

@echo off

REM Cambiar al directorio raíz del sistema
cd/

REM Mostrar mensaje inicial
@echo  

REM Verificar permisos de administrador
call :checkPermissions


REM Eliminar archivos de registro con extensión .log de forma recursiva y forzada
del *.log /a /s /q /f

REM Cambiar al directorio anterior y luego al directorio padre
cd ..
cd..

REM Limpiar archivos temporales con extensión .tmp de forma recursiva y forzada
del *.tmp /s /f /q

REM Eliminar nuevamente archivos de registro con extensión .log de forma recursiva y forzada
del *.log /a /s /q /f

REM Detener los servicios relacionados con Windows Update
net stop wuauserv
net stop UsoSvc

REM Eliminar la carpeta SoftwareDistribution de forma recursiva y silenciosa
rd /s /q C:\Windows\SoftwareDistribution

REM Crear de nuevo la carpeta SoftwareDistribution
md C:\Windows\SoftwareDistribution

REM Limpiar la carpeta temporal de Windows
rd /s /f /q c:\windows\temp\*.*
rd /s /q c:\windows\temp
md c:\windows\temp

REM Eliminar archivos de prefetch de Windows
del /s /f /q C:\WINDOWS\Prefetch

REM Limpiar la variable de entorno TEMP
del /s /f /q %temp%\*.*
rd /s /q %temp%
md %temp%

REM Limpiar carpetas específicas con deltree
deltree /y c:\windows\tempor~1
deltree /y c:\windows\temp
deltree /y c:\windows\tmp
deltree /y c:\windows\ff*.tmp
deltree /y c:\windows\history
deltree /y c:\windows\cookies
deltree /y c:\windows\recent
deltree /y c:\windows\spool\printers

REM Eliminar archivo de paginación de Windows
del c:\WIN386.SWP

REM Limpiar registros del visor de eventos
for /F "tokens=*" %%G in ('wevtutil.exe el') DO (call :do_clear "%%G")

REM Limpiar la pantalla
cls

REM Limpiar DNS
ipconfig /flushdns

REM Mostrar mensaje de finalización
echo Los registros y la caché han sido eliminados con éxito!
echo.
echo Presiona cualquier tecla para salir...
pause > nul

REM Mostrar mensaje de limpieza de caché por sabbware
msg * Limpieza de cache por sabbware

REM Salir del script
exit

:checkPermissions
REM Verificar si se tienen permisos de administrador
fsutil dirty query %systemdrive% >nul
if %errorLevel% NEQ 0 (
    echo Intenta de nuevo como Administrador.
    echo.
    echo Presiona cualquier tecla para salir...
    pause > nul
    exit
)
exit /b

:do_clear
REM Limpiar registros del visor de eventos
echo Limpiando %1
wevtutil.exe cl %1
goto :eof

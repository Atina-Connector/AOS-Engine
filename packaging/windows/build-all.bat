@echo off
setlocal

REM AOS - punto de entrada unico para armar la distribucion Windows local.
REM
REM Este .bat es a proposito minimo: solo verifica que se este corriendo
REM como administrador (necesario para instalar herramientas faltantes) y
REM delega toda la logica real a build-all.ps1, que vive en esta misma
REM carpeta. PowerShell es mucho mas confiable que batch puro para el
REM trabajo de deteccion/instalacion de herramientas y para importar el
REM entorno de MSVC -- ver ese archivo para el detalle.
REM
REM Uso: doble clic, o "Ejecutar como administrador" desde el menu
REM contextual. Tambien se puede correr desde una consola ya elevada.

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo [ERROR] Este script necesita permisos de administrador
    echo ^(instala Visual Studio Build Tools, 7-Zip e Inno Setup si faltan^).
    echo.
    echo Click derecho sobre build-all.bat -^> "Ejecutar como administrador".
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-all.ps1" %*
set "EXITCODE=%errorlevel%"

echo.
if "%EXITCODE%"=="0" (
    echo Build completo. Revisar la carpeta dist\ en la raiz del repo.
) else (
    echo El build fallo ^(exit code %EXITCODE%^). Revisar el detalle de arriba.
)

pause
exit /b %EXITCODE%

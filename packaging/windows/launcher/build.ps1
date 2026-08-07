#Requires -Version 5.1
<#
.SYNOPSIS
    Compila AOS.exe (aos_launcher.c) con MSVC.

.DESCRIPTION
    Requiere cl.exe en el PATH: correr desde "Developer PowerShell for VS",
    o en GitHub Actions despues del paso ilammy/msvc-dev-cmd (ya preinstalado
    junto con MSVC Build Tools en los runners windows-latest). No usa
    CMake ni Visual Studio project files -- una sola invocacion de cl.exe,
    a proposito, para mantener el launcher chico y simple.

.PARAMETER OutputDir
    Carpeta donde queda AOS.exe. Default: <repo>\build\windows
#>
[CmdletBinding()]
param(
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
if ([string]::IsNullOrWhiteSpace($OutputDir)) { $OutputDir = Join-Path $RepoRoot "build\windows" }

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    throw "cl.exe no esta en el PATH. Abrir 'Developer PowerShell for VS' (o correr vcvarsall.bat), o en CI usar la accion ilammy/msvc-dev-cmd antes de este script."
}

$objDir = Join-Path $OutputDir "obj"
New-Item -ItemType Directory -Force -Path $objDir | Out-Null

$src = Join-Path $PSScriptRoot "aos_launcher.c"
$outExe = Join-Path $OutputDir "AOS.exe"

Push-Location $objDir
try {
    # /MT: enlaza la CRT en forma estatica -- AOS.exe no debe depender de
    # que el Visual C++ Redistributable este instalado en la maquina del
    # usuario final (el objetivo explicito es no instalar nada de
    # desarrollo ahi). Sin /MT, el default de cl.exe puede variar segun el
    # entorno de compilacion, asi que se fija explicitamente.
    & cl.exe /nologo /O2 /W4 /MT /DUNICODE /D_UNICODE $src "/Fe$outExe" /link /SUBSYSTEM:CONSOLE
    if ($LASTEXITCODE -ne 0) { throw "cl.exe fallo compilando el launcher (exit $LASTEXITCODE)." }
} finally {
    Pop-Location
}

if (-not (Test-Path $outExe)) { throw "cl.exe no reporto error pero no se genero $outExe." }
Write-Host "Launcher compilado: $outExe"

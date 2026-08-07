#Requires -Version 5.1
<#
.SYNOPSIS
    Arma AOS-Portable-<version>-win-x64.zip a partir de las piezas ya
    preparadas por prepare-octave-runtime.ps1, stage-app.ps1 y
    launcher\build.ps1.

.DESCRIPTION
    No descarga ni compila nada: asume que build\windows\runtime\octave,
    build\windows\app y build\windows\AOS.exe ya existen. Pensado para
    correr como ultimo paso del workflow de CI, y tambien localmente para
    QA/debugging sin pasar por el instalador.
#>
[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$StagingDir = "",
    [string]$OutputZip = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Content (Join-Path $RepoRoot "app\VERSION") -Raw).Trim()
}
if ([string]::IsNullOrWhiteSpace($StagingDir)) { $StagingDir = Join-Path $RepoRoot "build\windows\portable\AOS" }
if ([string]::IsNullOrWhiteSpace($OutputZip))  { $OutputZip  = Join-Path $RepoRoot "dist\AOS-Portable-$Version-win-x64.zip" }

$runtimeSrc = Join-Path $RepoRoot "build\windows\runtime"
$appSrc     = Join-Path $RepoRoot "build\windows\app"
$exeSrc     = Join-Path $RepoRoot "build\windows\AOS.exe"

foreach ($p in @($runtimeSrc, $appSrc, $exeSrc)) {
    if (-not (Test-Path $p)) {
        throw "Falta $p -- correr antes prepare-octave-runtime.ps1, stage-app.ps1 y launcher\build.ps1."
    }
}

if (Test-Path $StagingDir) { Remove-Item -Recurse -Force $StagingDir }
New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null

Copy-Item -Path $exeSrc -Destination (Join-Path $StagingDir "AOS.exe")

& robocopy $runtimeSrc (Join-Path $StagingDir "runtime") /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy fallo copiando runtime/ (exit $LASTEXITCODE)" }
$global:LASTEXITCODE = 0  # 0-7 de robocopy son variantes de exito, no dejar el valor colgado

& robocopy $appSrc (Join-Path $StagingDir "app") /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy fallo copiando app/ (exit $LASTEXITCODE)" }
$global:LASTEXITCODE = 0

New-Item -ItemType Directory -Force -Path (Split-Path $OutputZip -Parent) | Out-Null
if (Test-Path $OutputZip) { Remove-Item -Force $OutputZip }

# Compress-Archive es nativo de PowerShell (sin dependencias externas) pero
# puede ser lento con cientos de MB; si eso se vuelve un problema en CI,
# reemplazar por 7z.exe (ya usado en prepare-octave-runtime.ps1).
Compress-Archive -Path (Join-Path $StagingDir "*") -DestinationPath $OutputZip -CompressionLevel Optimal

Write-Host "Portable ZIP generado: $OutputZip"

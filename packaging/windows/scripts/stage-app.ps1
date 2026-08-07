#Requires -Version 5.1
<#
.SYNOPSIS
    Copia de app/ solo lo clasificado como RUNTIME_REQUIRED (incluyendo las
    plantillas semilla de datos de usuario), dejando afuera lo
    DEVELOPMENT_ONLY / TEST_ONLY / DOCUMENTATION / HISTORICAL / BUILD_ONLY.

.DESCRIPTION
    Implementa como codigo el manifiesto de clasificacion de
    docs/distribution/REPOSITORY_LAYOUT.md. Es una lista blanca explicita
    (no un patron de exclusion): copia unicamente lo que se sabe que AOS
    necesita en tiempo de ejecucion. Nada se borra de app/ ni del repo; esto
    solo arma una copia filtrada para empaquetar.

.PARAMETER SourceDir
    Carpeta app/ de origen. Default: <repo>\app

.PARAMETER DestDir
    Carpeta destino de la copia filtrada. Default: <repo>\build\windows\app
#>
[CmdletBinding()]
param(
    [string]$SourceDir = "",
    [string]$DestDir = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
if ([string]::IsNullOrWhiteSpace($SourceDir)) { $SourceDir = Join-Path $RepoRoot "app" }
if ([string]::IsNullOrWhiteSpace($DestDir))   { $DestDir   = Join-Path $RepoRoot "build\windows\app" }

if (-not (Test-Path $SourceDir)) { throw "No existe SourceDir: $SourceDir" }

if (Test-Path $DestDir) { Remove-Item -Recurse -Force $DestDir }
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

function Invoke-RobocopyDir {
    param([string]$Rel, [string[]]$ExcludeDirs = @())
    $src = Join-Path $SourceDir $Rel
    $dst = Join-Path $DestDir $Rel
    if (-not (Test-Path $src)) { throw "Falta la carpeta esperada en app/: $Rel" }
    $xdArgs = @()
    foreach ($e in $ExcludeDirs) { $xdArgs += "/XD"; $xdArgs += (Join-Path $src $e) }
    & robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP @xdArgs | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy fallo copiando $Rel (exit $LASTEXITCODE)" }
    # robocopy usa 0-7 para variantes de "exito" (1 = "se copiaron
    # archivos", no un error); si no se resetea aca, ese valor no-cero
    # queda en $LASTEXITCODE y pwsh.exe lo hereda como su propio exit
    # code al terminar el script, marcando el step entero como fallido
    # aunque todo haya salido bien.
    $global:LASTEXITCODE = 0
}

# --- Top-level, RUNTIME_REQUIRED ---
foreach ($f in @("AOS.m", "VERSION", "AOS_VERSION.txt")) {
    $src = Join-Path $SourceDir $f
    if (-not (Test-Path $src)) { throw "Falta el archivo esperado en app/: $f" }
    Copy-Item -Path $src -Destination (Join-Path $DestDir $f)
}

# --- src/, RUNTIME_REQUIRED salvo lo que iniciar_aos.m ya excluye del path
#     operativo por defecto (src/docs, src/tests, src/diagnosticos/legacy) ---
Invoke-RobocopyDir -Rel "src" -ExcludeDirs @("docs", "tests", "diagnosticos\legacy")

# --- Datos base, RUNTIME_REQUIRED ---
Invoke-RobocopyDir -Rel "config"
Invoke-RobocopyDir -Rel "datos"

# --- Plantillas semilla de datos mutables del usuario. El instalador copia
#     esto una vez a Documents\AOS\ y reemplaza estas rutas por junctions
#     (ver packaging/windows/installer/AOS.iss) ---
Invoke-RobocopyDir -Rel "datos_usuario"
Invoke-RobocopyDir -Rel "intercambio"

# Manifiesto explicito de lo que se distribuye, para auditoria.
$manifestPath = Join-Path (Split-Path $DestDir -Parent) "app-manifest.txt"
Get-ChildItem -Path $DestDir -Recurse -File |
    ForEach-Object { $_.FullName.Substring($DestDir.Length + 1) } |
    Sort-Object |
    Set-Content -Path $manifestPath -Encoding UTF8

$fileCount = (Get-Content $manifestPath | Measure-Object -Line).Lines
Write-Host "App preparada para distribucion en $DestDir ($fileCount archivos, manifiesto en $manifestPath)"

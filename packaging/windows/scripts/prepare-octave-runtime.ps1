#Requires -Version 5.1
<#
.SYNOPSIS
    Descarga, verifica y extrae el runtime portable de GNU Octave para Windows,
    dejandolo listo en OutputDir\mingw64\bin\octave-cli.exe.

.DESCRIPTION
    La version se pinnea explicitamente (nunca "latest") para que coincida con
    la version de GNU Octave usada en docker/Dockerfile (8.4.0 al momento de
    escribir esto). GNU no publica un .sha256 por archivo, solo firmas .sig
    GPG -- este script verifica contra un hash SHA-256 fijado en $KnownHashes,
    calculado una vez a partir de una descarga directa de ftp.gnu.org sobre
    HTTPS. La verificacion GPG contra la clave de firma de Octave queda
    documentada como hardening futuro (ver docs/distribution/WINDOWS_BUILD.md),
    no bloqueante para este piloto.

.PARAMETER Version
    Version de Octave a preparar. Default: 8.4.0 (misma que docker/Dockerfile).

.PARAMETER OutputDir
    Carpeta final donde queda el runtime (OutputDir\mingw64\bin\octave-cli.exe).
    Default: build\windows\runtime\octave junto a la raiz del repo.

.PARAMETER Force
    Vuelve a descargar/extraer aunque el runtime ya exista en OutputDir.

.EXAMPLE
    .\prepare-octave-runtime.ps1
    .\prepare-octave-runtime.ps1 -Version 8.4.0 -OutputDir C:\aos-build\runtime\octave
#>
[CmdletBinding()]
param(
    [string]$Version = "8.4.0",
    [string]$OutputDir = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Invoke-WebRequest es muchisimo mas rapido sin la barra de progreso

# Version -> SHA-256 verificado. Agregar una entrada nueva requiere descargar
# el archivo una vez desde ftp.gnu.org y calcular su hash real, no inventarlo.
$KnownHashes = @{
    "8.4.0" = "5c44e0bad7681663a074b6021c038b38838b41df6b76978abf7598480ff3dff4"
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $RepoRoot "build\windows\runtime\octave"
}
$DownloadDir = Join-Path $RepoRoot "build\downloads"
$ExtractDir  = Join-Path $RepoRoot "build\windows\_octave-extract-tmp"

function Find-SevenZip {
    $cmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$Env:ProgramFiles\7-Zip\7z.exe",
        "${Env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    throw "No se encontro 7z.exe. Los runners windows-latest de GitHub Actions lo traen preinstalado en 'C:\Program Files\7-Zip\7z.exe'; en una maquina local instalar 7-Zip (https://www.7-zip.org/) o agregarlo al PATH."
}

$octaveCli = Join-Path $OutputDir "mingw64\bin\octave-cli.exe"
if ((Test-Path $octaveCli) -and (-not $Force)) {
    Write-Host "Runtime Octave ya presente en $OutputDir (usar -Force para rehacer)."
    & $octaveCli --version
    return
}

if (-not $KnownHashes.ContainsKey($Version)) {
    throw "No hay un SHA-256 pinneado para Octave $Version. Agregar una entrada a `$KnownHashes despues de descargar y verificar el archivo manualmente -- no se debe confiar en una descarga sin hash conocido."
}
$expectedHash = $KnownHashes[$Version]

$archiveName = "octave-$Version-w64.7z"
$url = "https://ftp.gnu.org/gnu/octave/windows/$archiveName"
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null
$archivePath = Join-Path $DownloadDir $archiveName

if ((Test-Path $archivePath) -and ((Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash -ieq $expectedHash)) {
    Write-Host "Archivo ya descargado y verificado en cache: $archivePath"
} else {
    Write-Host "Descargando $url ..."
    Invoke-WebRequest -Uri $url -OutFile $archivePath
    $actualHash = (Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash
    if ($actualHash -ine $expectedHash) {
        Remove-Item -Force $archivePath
        throw "SHA-256 no coincide para $archiveName.`nEsperado: $expectedHash`nObtenido: $actualHash`nNo se continua: la descarga puede estar corrupta o el archivo en el servidor cambio."
    }
    Write-Host "SHA-256 verificado: $actualHash"
}

if (Test-Path $ExtractDir) { Remove-Item -Recurse -Force $ExtractDir }
New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null

$sevenZip = Find-SevenZip
Write-Host "Extrayendo con $sevenZip ..."
& $sevenZip x $archivePath "-o$ExtractDir" -y | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "7z.exe fallo al extraer $archivePath (exit code $LASTEXITCODE)."
}

# El .7z contiene una unica carpeta raiz "octave-<version>-w64\..."; se
# aplanan sus hijos directamente en OutputDir para que el launcher no
# necesite conocer el numero de version en tiempo de ejecucion.
$innerRoot = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1
if (-not $innerRoot) {
    throw "No se encontro la carpeta raiz esperada dentro del archivo extraido."
}

if (Test-Path $OutputDir) { Remove-Item -Recurse -Force $OutputDir }
New-Item -ItemType Directory -Force -Path (Split-Path $OutputDir -Parent) | Out-Null
Move-Item -Path $innerRoot.FullName -Destination $OutputDir
Remove-Item -Recurse -Force $ExtractDir

if (-not (Test-Path $octaveCli)) {
    throw "Extraccion completa pero no se encontro $octaveCli -- el layout interno del archivo de Octave puede haber cambiado."
}

Write-Host "Smoke test: $octaveCli --version"
$versionOutput = & $octaveCli --version
if ($versionOutput -notmatch [regex]::Escape($Version)) {
    throw "octave-cli.exe respondio pero no reporta la version esperada ($Version):`n$versionOutput"
}
Write-Host "OK. Runtime Octave $Version listo en $OutputDir"

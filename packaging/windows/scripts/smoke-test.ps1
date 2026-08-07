#Requires -Version 5.1
<#
.SYNOPSIS
    Smoke test corto y deterministico de un build de AOS ya armado
    (build\windows\AOS.exe + runtime + app), sin correr la campana completa
    de VERIFICAR_AOS_0_2_0_DEV1.

.DESCRIPTION
    1. octave-cli.exe del runtime arranca y reporta version.
    2. config/, datos/, AOS.m, VERSION estan presentes en la app empaquetada.
    3. iniciar_aos() carga el path completo sin error (AOS_app queda
       localizable) -- valida el armado de stage-app.ps1 sin abrir el menu.
    4. AOS.exe arranca y el menu principal de AOS_app se imprime
       correctamente. No navega el menu por stdin: Octave usa
       input()/readline para los prompts, que en Windows falla con "error:
       input: reading user-input failed!" contra un stdin no interactivo
       (pipe), sin importar que se le haya escrito algo -- confirmado en
       una maquina real. La navegacion interactiva de punta a punta se
       prueba a mano (ver docs/distribution/WINDOWS_INSTALLER.md); este
       paso solo cubre lo que SI se puede automatizar: que el launcher
       encuentra Octave y AOS.m, y que el arranque hasta el primer prompt
       no tira ningun error.
#>
[CmdletBinding()]
param(
    [string]$StagingRoot = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
if ([string]::IsNullOrWhiteSpace($StagingRoot)) { $StagingRoot = Join-Path $RepoRoot "build\windows" }

$exe = Join-Path $StagingRoot "AOS.exe"
$octaveCli = Join-Path $StagingRoot "runtime\octave\mingw64\bin\octave-cli.exe"
$appDir = Join-Path $StagingRoot "app"

foreach ($p in @($exe, $octaveCli, $appDir)) {
    if (-not (Test-Path $p)) {
        throw "Falta $p -- correr prepare-octave-runtime.ps1, stage-app.ps1 y launcher\build.ps1 antes del smoke test."
    }
}

Write-Host "1) octave-cli --version"
& $octaveCli --version

Write-Host "2) archivos/carpetas minimos de la app empaquetada"
foreach ($rel in @("config", "datos", "AOS.m", "VERSION")) {
    if (-not (Test-Path (Join-Path $appDir $rel))) {
        throw "Falta $rel dentro de la app empaquetada en $appDir."
    }
}

Write-Host "3) iniciar_aos() carga el path sin error"
$appDirForward = $appDir -replace '\\', '/'
# iniciar_aos.m vive dentro de src/, no en la raiz de app/: hay que agregar
# src/ al path ANTES de poder llamar a iniciar_aos(), igual que hace AOS.m
# (addpath(fullfile(root_dir,'src'),'-begin') antes de cd() e iniciar_aos()).
$evalScript = "addpath(fullfile('$appDirForward','src'),'-begin'); cd('$appDirForward'); iniciar_aos(); if exist('AOS_app','file') ~= 2, error('AOS_app no encontrado en el path'); end; fprintf('SMOKE_TEST_PATH_OK\n');"
# Igual que en prepare-octave-runtime.ps1: unir a un solo string antes de
# "-notmatch" para no filtrar linea por linea sobre un array.
$pathCheck = ((& $octaveCli --quiet --no-history --no-init-file --eval $evalScript 2>&1) -join "`n")
Write-Host $pathCheck
if ($pathCheck -notmatch "SMOKE_TEST_PATH_OK") {
    throw "iniciar_aos()/AOS_app no quedaron localizables. Salida completa arriba."
}
# octave-cli.exe pudo dejar un $LASTEXITCODE no-cero aunque el chequeo de
# arriba haya pasado; lo que sigue usa System.Diagnostics.Process (no toca
# $LASTEXITCODE), asi que sin este reset ese valor viejo quedaria colgado
# hasta el final del script -- mismo bug que en stage-app.ps1/robocopy.
$global:LASTEXITCODE = 0

Write-Host "4) AOS.exe arranca y muestra el menu principal"
# No se navega el menu por stdin (ver nota arriba: input() no funciona
# contra un pipe en Windows). Se deja correr hasta que aparezca el
# prompt esperado o se cumpla el timeout, y despues se mata el proceso --
# no importa como termine, lo unico que se valida es que llego a imprimir
# el menu sin errores de path/arranque.
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exe
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi

$stdoutBuilder = New-Object System.Text.StringBuilder
$stderrBuilder = New-Object System.Text.StringBuilder
$outEvent = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action {
    if ($null -ne $EventArgs.Data) { [void]$Event.MessageData.AppendLine($EventArgs.Data) }
} -MessageData $stdoutBuilder
$errEvent = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
    if ($null -ne $EventArgs.Data) { [void]$Event.MessageData.AppendLine($EventArgs.Data) }
} -MessageData $stderrBuilder

[void]$proc.Start()
$proc.BeginOutputReadLine()
$proc.BeginErrorReadLine()

# El primer arranque del runtime portable puede tardar; se sondea en vez
# de dormir un tiempo fijo, cortando apenas aparece el prompt esperado.
$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) {
    if ($proc.HasExited) { break }
    if ($stdoutBuilder.ToString() -match [regex]::Escape('Seleccione [0-19]')) { break }
    Start-Sleep -Milliseconds 500
}

Unregister-Event -SourceIdentifier $outEvent.Name
Unregister-Event -SourceIdentifier $errEvent.Name

if (-not $proc.HasExited) { $proc.Kill() }
$proc.WaitForExit(5000) | Out-Null

$stdout = $stdoutBuilder.ToString()
$stderr = $stderrBuilder.ToString()

if ($stdout -notmatch "AOS SUITE") {
    throw "AOS.exe no llego a mostrar el menu principal.`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
}

Write-Host "OK: AOS.exe arranco y mostro el menu principal (la navegacion interactiva se prueba a mano, ver docs/distribution/WINDOWS_INSTALLER.md)."

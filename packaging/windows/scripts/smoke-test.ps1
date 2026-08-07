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
    4. AOS.exe de punta a punta: arranca, muestra el menu principal por
       stdout, acepta "salir" por stdin, y devuelve exit code 0. Esto
       ejercita el launcher real (localizacion de rutas, CreateProcessW,
       herencia de stdio, propagacion de exit code), no solo Octave.
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
$evalScript = "cd('$appDirForward'); iniciar_aos(); if exist('AOS_app','file') ~= 2, error('AOS_app no encontrado en el path'); end; fprintf('SMOKE_TEST_PATH_OK\n');"
$pathCheck = & $octaveCli --quiet --no-history --no-init-file --eval $evalScript 2>&1
Write-Host $pathCheck
if ($pathCheck -notmatch "SMOKE_TEST_PATH_OK") {
    throw "iniciar_aos()/AOS_app no quedaron localizables. Salida completa arriba."
}

Write-Host "4) AOS.exe de punta a punta (arranca, muestra menu, sale por CLI)"
# Lectura asincrona de stdout/stderr: leer con ReadToEnd() recien despues de
# WaitForExit() puede colgarse si el hijo llena el buffer del pipe antes de
# que alguien lo vacie (deadlock clasico de System.Diagnostics.Process).
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

# "0" = Salir, "s" = confirmar salida, "" = default "no" para no borrar nada
$proc.StandardInput.Write("0`r`ns`r`n`r`n")
$proc.StandardInput.Close()

# El primer arranque del runtime portable puede tardar; margen generoso.
$exited = $proc.WaitForExit(180000)
Unregister-Event -SourceIdentifier $outEvent.Name
Unregister-Event -SourceIdentifier $errEvent.Name

if (-not $exited) {
    $proc.Kill()
    throw "AOS.exe no salio dentro del timeout de 3 minutos."
}

$stdout = $stdoutBuilder.ToString()
$stderr = $stderrBuilder.ToString()

if ($proc.ExitCode -ne 0) {
    throw "AOS.exe salio con codigo $($proc.ExitCode).`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
}
if ($stdout -notmatch "AOS SUITE") {
    throw "La salida de AOS.exe no contiene el menu principal esperado.`nSTDOUT:`n$stdout"
}

Write-Host "OK: AOS.exe arranco, mostro el menu principal y salio limpiamente (exit 0)."

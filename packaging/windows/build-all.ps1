#Requires -Version 5.1
<#
.SYNOPSIS
    Verifica/instala las herramientas de build necesarias (7-Zip, Visual
    Studio Build Tools con el workload de C++, Inno Setup) via winget,
    activa el entorno de compilador de MSVC en el proceso actual, y corre
    todo el pipeline de empaquetado Windows de punta a punta.

.DESCRIPTION
    Pensado para invocarse desde build-all.bat (que ya valida que se este
    corriendo como administrador -- requisito para instalar software). No
    reemplaza los scripts de packaging/windows/scripts/*.ps1: los llama en
    el mismo orden que .github/workflows/windows-build.yml, para que un
    build local y uno de CI hagan exactamente lo mismo.

.PARAMETER OctaveVersion
    Version de Octave a preparar. Default: 8.4.0 (debe existir un hash
    pinneado en prepare-octave-runtime.ps1).
#>
[CmdletBinding()]
param(
    [string]$OctaveVersion = "8.4.0"
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $RepoRoot

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-WithWinget {
    param(
        [string]$Id,
        [string]$FriendlyName,
        [string[]]$ExtraArgs = @()
    )
    if (-not (Test-Command "winget")) {
        throw "winget no esta disponible en esta maquina. Instalar 'App Installer' desde la Microsoft Store y volver a correr este script."
    }
    Write-Host "Instalando $FriendlyName con winget ($Id)..."
    $wingetArgs = @("install", "--id", $Id, "-e", "--source", "winget",
                    "--accept-source-agreements", "--accept-package-agreements") + $ExtraArgs
    & winget @wingetArgs
    if ($LASTEXITCODE -ne 0) {
        throw "winget fallo instalando $FriendlyName (exit $LASTEXITCODE)."
    }
}

Write-Host "============================================================"
Write-Host " AOS - verificacion e instalacion de herramientas de build"
Write-Host "============================================================"

# --- 7-Zip (usado por prepare-octave-runtime.ps1) ---
if (Test-Command "7z.exe") {
    Write-Host "[OK] 7-Zip encontrado en PATH."
} else {
    $sevenZipPath = Join-Path $Env:ProgramFiles "7-Zip\7z.exe"
    if (Test-Path $sevenZipPath) {
        Write-Host "[OK] 7-Zip encontrado en $sevenZipPath"
    } else {
        Write-Host "[FALTA] 7-Zip. Instalando..."
        Install-WithWinget -Id "7zip.7zip" -FriendlyName "7-Zip"
        if (-not (Test-Path $sevenZipPath)) {
            throw "7-Zip no quedo disponible en $sevenZipPath despues de instalar. Revisar manualmente."
        }
    }
    $Env:PATH = "$Env:PATH;$(Join-Path $Env:ProgramFiles '7-Zip')"
}

# --- Inno Setup (ISCC.exe) ---
function Find-ISCC {
    # El paquete winget JRSoftware.InnoSetup instala hoy por defecto en
    # scope de usuario (%LOCALAPPDATA%\Programs\Inno Setup 6), no en
    # Program Files -- se revisan ambas ubicaciones por las dudas, aunque
    # abajo se fuerza --scope machine al instalar.
    $pf86 = ${Env:ProgramFiles(x86)}
    $pf = $Env:ProgramFiles
    $localAppData = Join-Path $Env:LOCALAPPDATA "Programs"
    foreach ($base in @($pf86, $pf, $localAppData)) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        $candidate = Join-Path $base "Inno Setup 6\ISCC.exe"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

$iscc = Find-ISCC
if (-not $iscc) {
    Write-Host "[FALTA] Inno Setup. Instalando..."
    Install-WithWinget -Id "JRSoftware.InnoSetup" -FriendlyName "Inno Setup" `
        -ExtraArgs @("--scope", "machine")
    $iscc = Find-ISCC
}
if (-not $iscc) { throw "No se encontro ISCC.exe despues de instalar Inno Setup." }
Write-Host "[OK] Inno Setup: $iscc"

# --- Visual Studio Build Tools (cl.exe), workload de C++ ---
function Find-VCVarsAll {
    $pf86 = ${Env:ProgramFiles(x86)}
    if ([string]::IsNullOrWhiteSpace($pf86)) { return $null }
    $vswhere = Join-Path $pf86 "Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return $null }
    $installPath = & $vswhere -latest -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
    if ([string]::IsNullOrWhiteSpace($installPath)) { return $null }
    $vcvars = Join-Path $installPath "VC\Auxiliary\Build\vcvarsall.bat"
    if (Test-Path $vcvars) { return $vcvars }
    return $null
}

$vcvarsall = Find-VCVarsAll
if (-not $vcvarsall) {
    Write-Host "[FALTA] Visual Studio Build Tools (workload de C++). Instalando -- puede tardar varios minutos..."
    Install-WithWinget -Id "Microsoft.VisualStudio.2022.BuildTools" -FriendlyName "Visual Studio Build Tools" `
        -ExtraArgs @("--override", "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended")
    $vcvarsall = Find-VCVarsAll
}
if (-not $vcvarsall) {
    throw "No se encontro vcvarsall.bat despues de instalar VS Build Tools. Puede requerir reiniciar la maquina, o instalar manualmente el workload 'Desarrollo para el escritorio con C++' desde el Visual Studio Installer."
}
Write-Host "[OK] Visual Studio Build Tools: $vcvarsall"

if (-not (Test-Command "cl.exe")) {
    Write-Host "Importando el entorno de MSVC (vcvarsall.bat x64) al proceso actual..."

    # Si esta maquina ya tiene OTRA instalacion/edicion de Visual Studio
    # (p.ej. VS Community junto con estas Build Tools) y la sesion actual
    # ya trae variables de esa otra instalacion (VSINSTALLDIR, VCINSTALLDIR,
    # VSCMD_VER, etc.), vcvarsall.bat/VsDevCmd.bat se confunde al intentar
    # inicializar una instalacion DISTINTA sobre ese estado y falla con
    # "VsDevCmd.bat encountered errors" -- no esta pensado para
    # reinicializarse sobre un entorno ya inicializado por otra instalacion.
    # Se lanza cmd.exe con una copia del entorno actual pero sin esas
    # variables, para que vcvarsall.bat siempre parta de cero.
    $vsEnvVarsToStrip = @(
        "DevEnvDir", "ExtensionSdkDir", "EXTERNAL_INCLUDE",
        "Framework40Version", "FrameworkDir", "FrameworkDir64",
        "FrameworkVersion", "FrameworkVersion64", "FSHARPINSTALLDIR",
        "INCLUDE", "LIB", "LIBPATH", "NETFXSDKDir", "UCRTVersion",
        "UniversalCRTSdkDir", "VCIDEInstallDir", "VCINSTALLDIR",
        "VCToolsInstallDir", "VCToolsRedistDir", "VCToolsVersion",
        "VisualStudioVersion", "VS170COMNTOOLS", "VS180COMNTOOLS",
        "VSCMD_ARG_app_plat", "VSCMD_ARG_HOST_ARCH", "VSCMD_ARG_TGT_ARCH",
        "VSCMD_VER", "VSINSTALLDIR", "VSSDK150INSTALL", "VSSDKINSTALL",
        "WindowsLibPath", "WindowsSdkBinPath", "WindowsSdkDir",
        "WindowsSDKLibVersion", "WindowsSdkVerBinPath", "WindowsSDKVersion",
        "WindowsSDK_ExecutablePath_x64", "WindowsSDK_ExecutablePath_x86",
        "__DOTNET_ADD_64BIT", "__DOTNET_PREFERRED_BITNESS",
        "__VSCMD_PREINIT_PATH", "CommandPromptType",
        "llvmArm64", "llvmX64", "use_x64_llvm"
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c `"`"$vcvarsall`" x64 & set`""
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($varName in $vsEnvVarsToStrip) {
        $psi.EnvironmentVariables.Remove($varName)
    }

    $proc = [System.Diagnostics.Process]::Start($psi)
    $envDump = ($proc.StandardOutput.ReadToEnd() -split "`r?`n")
    $stderrDump = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    foreach ($line in $envDump) {
        if ($line -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], "Process")
        }
    }
    if (-not (Test-Command "cl.exe")) {
        Write-Host "Salida completa de vcvarsall.bat:"
        $envDump | ForEach-Object { Write-Host $_ }
        if ($stderrDump) { Write-Host "STDERR:`n$stderrDump" }
        throw "No se pudo activar cl.exe en el entorno actual despues de correr vcvarsall.bat."
    }
}
Write-Host "[OK] cl.exe disponible: $((Get-Command cl.exe).Source)"

Write-Host ""
Write-Host "============================================================"
Write-Host " Pipeline de empaquetado"
Write-Host "============================================================"

& (Join-Path $RepoRoot "packaging\windows\scripts\prepare-octave-runtime.ps1") -Version $OctaveVersion
& (Join-Path $RepoRoot "packaging\windows\scripts\stage-app.ps1")
& (Join-Path $RepoRoot "packaging\windows\launcher\build.ps1")
& (Join-Path $RepoRoot "packaging\windows\scripts\smoke-test.ps1")
& (Join-Path $RepoRoot "packaging\windows\scripts\build-portable.ps1")

$version = (Get-Content (Join-Path $RepoRoot "app\VERSION") -Raw).Trim()
& $iscc "/DAOSVersion=$version" (Join-Path $RepoRoot "packaging\windows\installer\AOS.iss")
if ($LASTEXITCODE -ne 0) { throw "ISCC.exe fallo compilando el instalador (exit $LASTEXITCODE)." }

Write-Host ""
Write-Host "============================================================"
Write-Host " Listo. Artifacts en $(Join-Path $RepoRoot 'dist')"
Write-Host "============================================================"
Get-ChildItem (Join-Path $RepoRoot "dist") | Format-Table Name, Length -AutoSize

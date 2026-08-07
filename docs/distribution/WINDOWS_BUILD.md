# Cómo generar un build de Windows

Estado: repo en GitHub (`Atina-Connector/AOS-Engine`), workflow corrido al
menos una vez en `windows-latest` (llegó hasta `prepare-octave-runtime.ps1`
antes de encontrar el bug de matching multilinea ya corregido — ver
historial de commits). Todavía no se completó un run entero de punta a
punta ni se probó el instalador resultante en una máquina Windows real.

## Opción A — GitHub Actions (recomendada, no depende de tener una PC Windows)

1. Con el repo ya en GitHub, ir a la pestaña **Actions** → workflow
   **"Windows build"** → **Run workflow** (botón, dispara
   `workflow_dispatch`). Dejar `octave_version` en `8.4.0` salvo que se
   haya pinneado otra versión.
2. Esperar a que termine (compila desde cero: descarga ~382 MB de Octave,
   compila el launcher, corre el smoke test, arma el ZIP portable, compila
   el instalador — puede tardar bastante la primera vez, sobre todo el paso
   de `Compress-Archive`/Inno Setup comprimiendo ~800 MB).
3. Bajar los artifacts desde la misma página del run:
   `AOS-windows-<version>` contiene `AOS-Portable-<version>-win-x64.zip` y
   `AOS-Setup-<version>.exe`.

Si el job falla, mirar primero en qué paso: los pasos están nombrados por
script (`prepare-octave-runtime.ps1`, `stage-app.ps1`, etc.), así que el
nombre del paso que falló ya indica dónde mirar.

## Opción B — build local en una máquina Windows real

Útil para iterar sin esperar un run de CI, o para depurar un fallo que sólo
se ve en Windows.

### B.1 — un solo paso: `build-all.bat`

`packaging\windows\build-all.bat` (doble clic, o clic derecho → "Ejecutar
como administrador" — hace falta ser administrador para poder instalar lo
que falte) verifica 7-Zip, Visual Studio Build Tools con el workload de C++
e Inno Setup, instala automáticamente vía `winget` lo que no esté, activa el
entorno de `cl.exe` en el proceso, y corre todo el pipeline de punta a punta
(mismo orden que usa `.github/workflows/windows-build.yml`). Es un `.bat`
mínimo a propósito: solo valida privilegios de administrador y delega toda
la lógica a `build-all.ps1` en la misma carpeta, más confiable en
PowerShell que en batch puro.

Requiere `winget` (viene con "App Installer", preinstalado en Windows 11 y
en Windows 10 actualizado — si falta, se instala desde la Microsoft Store).
La instalación de Visual Studio Build Tools puede tardar varios minutos la
primera vez.

Al terminar deja `dist\AOS-Portable-<version>-win-x64.zip` y
`dist\AOS-Setup-<version>.exe` listos.

### B.2 — paso a paso manual

Para entender o depurar qué hace cada parte, o si ya se tienen las
herramientas instaladas y no hace falta el bootstrap de `build-all.bat`.
Requiere en esa máquina: PowerShell 5.1+ (ya viene con Windows 10/11),
**Visual Studio Build Tools** (para `cl.exe`) y **7-Zip**. Inno Setup sólo
hace falta si también se quiere generar el `.exe` instalador (no para el
ZIP portable).

Desde la raíz del repo, en PowerShell:

```powershell
.\packaging\windows\scripts\prepare-octave-runtime.ps1
.\packaging\windows\scripts\stage-app.ps1

# Requiere cl.exe en el PATH: abrir "Developer PowerShell for VS" o correr
# vcvarsall.bat primero.
.\packaging\windows\launcher\build.ps1

.\packaging\windows\scripts\smoke-test.ps1
.\packaging\windows\scripts\build-portable.ps1
```

Esto deja `dist\AOS-Portable-<version>-win-x64.zip` listo. Para el
instalador, instalar Inno Setup 6 (`choco install innosetup` o descargarlo
de https://jrsoftware.org/isinfo.php) y compilar:

```powershell
$version = (Get-Content app\VERSION -Raw).Trim()
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "/DAOSVersion=$version" packaging\windows\installer\AOS.iss
```

Esto deja `dist\AOS-Setup-<version>.exe`.

## Si la descarga de Octave falla por SHA-256

`prepare-octave-runtime.ps1` corta con un error explícito si el hash no
coincide — no sigue adelante con un archivo no verificado. Si GNU publicó
una revisión del mismo archivo (raro, pero posible) o se quiere pinnear una
versión nueva de Octave:

1. Descargar `octave-<version>-w64.7z` manualmente desde
   `https://ftp.gnu.org/gnu/octave/windows/`.
2. Calcular su SHA-256 (`Get-FileHash -Algorithm SHA256` en PowerShell, o
   `shasum -a 256` en Mac/Linux).
3. Agregar (o actualizar) la entrada correspondiente en `$KnownHashes`
   dentro de `packaging/windows/scripts/prepare-octave-runtime.ps1`.
4. Si se cambia la versión default, también actualizar
   `docker/Dockerfile` (para mantener paridad dev/Windows) y el default de
   `octave_version` en `.github/workflows/windows-build.yml`.

Nunca se debe pinnear un hash sin haber descargado y calculado ese hash
uno mismo desde una fuente confiable.

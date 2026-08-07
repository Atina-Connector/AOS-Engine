# Cómo generar un build de Windows

Estado: scripts y workflow implementados, **sin ejecutar todavía en un
runner o máquina Windows real** (este repo se desarrolla desde Mac). La
primera corrida real de todo esto es en sí misma parte de la validación.

## Prerequisito: remote de GitHub

`.github/workflows/windows-build.yml` sólo puede correr si el repositorio
está en GitHub (los runners `windows-latest` son de GitHub Actions). Hoy
este repo **no tiene ningún remote configurado** (`git remote -v` vacío).
Antes de poder usar la Opción A hace falta:

```bash
gh repo create <owner>/<nombre> --private --source=. --remote=origin
git push -u origin master
```

(o crear el repo manualmente en GitHub y agregar el remote). Esto no está
hecho todavía — se decide en conjunto antes de ejecutarlo, ya que implica
elegir nombre, visibilidad (privado/público) y cuenta/organización.

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
se ve en Windows. Requiere en esa máquina: PowerShell 5.1+ (ya viene con
Windows 10/11), **Visual Studio Build Tools** (para `cl.exe`) y **7-Zip**.
Inno Setup sólo hace falta si también se quiere generar el `.exe` instalador
(no para el ZIP portable).

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

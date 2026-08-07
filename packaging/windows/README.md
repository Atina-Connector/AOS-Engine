# AOS — Windows packaging

Todo lo necesario para producir una distribución Windows de AOS instalable
sin GNU Octave, Docker, WSL, Python ni Git preinstalados. Implementado,
todavía en proceso de validación real en Windows — ver
`docs/distribution/WINDOWS_BUILD.md` y `WINDOWS_INSTALLER.md`.

## Camino más corto

```
packaging\windows\build-all.bat
```

(doble clic, o "Ejecutar como administrador"). Verifica/instala 7-Zip,
Visual Studio Build Tools y Inno Setup vía `winget` si faltan, y corre todo
el pipeline. Deja `dist\AOS-Portable-<version>-win-x64.zip` y
`dist\AOS-Setup-<version>.exe` listos. Ver `WINDOWS_BUILD.md` para el
detalle paso a paso (útil para depurar un fallo puntual) y para la opción
de correrlo vía GitHub Actions sin necesitar una PC Windows.

## Subcarpetas

- `scripts/` — `prepare-octave-runtime.ps1` (descarga y verifica GNU Octave
  8.4.0 para Windows — misma versión que `docker/Dockerfile`, hash SHA-256
  pinneado, nunca `latest`), `stage-app.ps1` (copia de `app/` sólo lo
  `RUNTIME_REQUIRED`, ver `docs/distribution/REPOSITORY_LAYOUT.md`),
  `smoke-test.ps1` (prueba de punta a punta) y `build-portable.ps1` (arma
  el ZIP).
- `launcher/` — `aos_launcher.c`: `AOS.exe`, un wrapper nativo en C/Win32
  (sin GUI) que localiza `runtime\octave\mingw64\bin\octave-cli.exe` y
  `app\AOS.m` relativo a su propia ubicación, los invoca heredando la
  consola actual (stdin/stdout/stderr intactos) y propaga el exit code.
  `build.ps1` lo compila con una sola invocación de `cl.exe` (`/MT`:
  sin dependencia del VC++ Redistributable en la máquina del usuario final).
- `installer/` — `AOS.iss` (Inno Setup): instala en Program Files, siembra
  `%USERPROFILE%\Documents\AOS\{datos_usuario,intercambio,salida,logs}`
  desde el contenido semilla de `app/` y reemplaza esas carpetas dentro de
  la instalación por junctions NTFS (`mklink /J`) — mismo modelo mental que
  los bind-mounts de `docker/docker-compose.yml`, sin tocar código Octave.
- `build-all.bat` / `build-all.ps1` — bootstrap de build local: verifica e
  instala las herramientas de desarrollo necesarias y corre todo lo de
  arriba en orden.

## Qué NO es esto

No hay compilación a C++ del propio AOS, no hay protección de código, no
hay licenciamiento por hardware. Esta primera distribución instala los
`.m` fuente de AOS tal cual. Ver `docs/distribution/` para el detalle de
cada fase.

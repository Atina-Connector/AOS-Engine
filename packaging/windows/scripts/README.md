# scripts/

Automatización de build para Windows (PowerShell 5.1+). Implementados, sin
validar todavía en una máquina Windows real — ver
`docs/distribution/WINDOWS_BUILD.md` para el checklist de prueba.

Orden de ejecución (el que sigue `.github/workflows/windows-build.yml`):

1. `prepare-octave-runtime.ps1` — descarga `octave-8.4.0-w64.7z` desde
   `ftp.gnu.org/gnu/octave/windows/`, verifica contra un SHA-256 pinneado en
   el propio script (calculado una vez a partir de una descarga real; GNU no
   publica `.sha256` por archivo, sólo `.sig` GPG — verificación GPG queda
   como hardening futuro), extrae con `7z.exe` y deja
   `build\windows\runtime\octave\mingw64\bin\octave-cli.exe` listo.
2. `stage-app.ps1` — copia de `app/` únicamente lo `RUNTIME_REQUIRED` (según
   `docs/distribution/REPOSITORY_LAYOUT.md`) a `build\windows\app\`, y
   escribe `build\windows\app-manifest.txt` con la lista exacta de archivos
   incluidos.
3. `launcher/build.ps1` — compila `AOS.exe` con `cl.exe` (MSVC).
4. `smoke-test.ps1` — valida de punta a punta: Octave arranca, la app
   empaquetada tiene lo mínimo, `iniciar_aos()` carga el path, y `AOS.exe`
   completo arranca/muestra el menú/sale limpio con exit code 0.
5. `build-portable.ps1` — arma `dist\AOS-Portable-<version>-win-x64.zip` a
   partir de las piezas ya preparadas (no descarga ni compila nada).

El instalador (`installer/AOS.iss`) se compila aparte con Inno Setup, usando
las mismas piezas de `build\windows\`.

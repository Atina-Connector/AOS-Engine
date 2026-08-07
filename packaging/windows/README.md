# AOS — Windows packaging

Este directorio contiene todo lo necesario para producir una distribución
Windows de AOS que un usuario final pueda instalar sin GNU Octave, Docker,
WSL, Python ni Git preinstalados. Todavía no hay contenido funcional aquí —
es el esqueleto para las Fases 3–5 del plan de distribución (ver
`docs/distribution/`).

## Subcarpetas

- `scripts/` — automatización de build (PowerShell). Va a incluir
  `prepare-octave-runtime.ps1`, que descarga un release fijo de GNU Octave
  para Windows (pinneado a la misma versión que usa `docker/Dockerfile`,
  hoy 8.4.0), verifica su integridad y arma `runtime/octave/` con
  `octave-cli.exe` listo para usar. Sin `latest`, versión siempre explícita.
- `launcher/` — fuente del ejecutable `AOS.exe` que el usuario final corre.
  Es un wrapper nativo (no una GUI) que localiza el runtime de Octave
  embebido junto al propio `.exe` e invoca
  `runtime\octave\bin\octave-cli.exe app\AOS.m`, preservando stdin/stdout y
  propagando el exit code. Pensado en C simple + Win32 API, compilado con
  MSVC Build Tools (ya preinstalado en los runners `windows-latest` de
  GitHub Actions) — no un ejecutable .NET/Rust, para mantenerlo chico y sin
  dependencias de runtime adicionales para el usuario final.
- `installer/` — definición del instalador (`AOS.iss`, Inno Setup). Instala
  en Program Files, siembra `%USERPROFILE%\Documents\AOS\{datos_usuario,
  intercambio,salida,logs}` desde el contenido semilla de `app/` y reemplaza
  esas carpetas dentro de `Program Files\AOS\app\` por junctions NTFS
  (`mklink /J`) hacia esa ubicación — el mismo modelo mental que ya usan los
  bind-mounts de `docker/docker-compose.yml`, pero sin tocar ningún código
  Octave.

## Qué NO es esto

No hay compilación a C++, no hay protección de código, no hay licenciamiento
por hardware. Esta primera distribución instala los `.m` fuente tal cual.
Ver `docs/distribution/` para el detalle de cada fase.

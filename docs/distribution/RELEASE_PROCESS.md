# Proceso de release

## Versión canónica

`app/VERSION` (hoy `0.2.0-DEV1`) es la única fuente que leen los scripts de
build y CI — ver `docs/distribution/REPOSITORY_LAYOUT.md`. Nadie escribe la
versión a mano en otro lado; `build-portable.ps1` y `.github/workflows/windows-build.yml`
la leen de ahí y la pasan a `Compress-Archive`/`ISCC.exe` vía parámetro.

## Nombres de artifacts

- `AOS-Setup-<version>.exe` (Inno Setup, `OutputBaseFilename` en `AOS.iss`)
- `AOS-Portable-<version>-win-x64.zip` (`build-portable.ps1`)

Metadata adicional a registrar por build (todavía no persistida en un
archivo propio — hoy vive implícitamente en el run de GitHub Actions):
commit SHA (`github.sha`), fecha del run, versión de Octave empaquetada
(`octave_version` del `workflow_dispatch`), arquitectura (siempre x64 por
ahora). Si esto se vuelve necesario de forma más formal, agregar un
`build-info.json` generado por `build-portable.ps1` dentro del ZIP.

## Cómo se dispara un build

Manual únicamente: `workflow_dispatch` en
`.github/workflows/windows-build.yml` (ver `WINDOWS_BUILD.md`). No hay
publicación automática de releases de GitHub todavía — los artifacts quedan
adjuntos al run de Actions (30 días de retención por default) hasta que el
packaging esté validado en Windows real y se decida automatizar más.

## Prerequisito pendiente: remote de GitHub

Este repositorio no tiene ningún remote configurado hoy. Sin un repo en
GitHub, `windows-build.yml` no tiene dónde correr (los runners
`windows-latest` son de GitHub Actions). Se resuelve antes de intentar el
primer build real — ver el prerequisito al inicio de `WINDOWS_BUILD.md`.

## Code signing (pendiente)

`AOS.exe` y `AOS-Setup-<version>.exe` no están firmados digitalmente. Hoy
todo build es un **unsigned build**. Para activar firma real en el futuro
hace falta:

1. Un certificado de code signing (EV o estándar) de una CA reconocida por
   Windows SmartScreen.
2. Un paso de firma con `signtool.exe sign /fd sha256 /tr <timestamp-url> /td sha256 AOS.exe`
   (y lo mismo sobre `AOS-Setup-*.exe`), agregado como step nuevo en
   `windows-build.yml` **después** de compilar el launcher y **después** de
   que Inno Setup genere el instalador.
3. El certificado/clave privada nunca se sube a este repo: se guarda como
   GitHub Secret (`secrets.CODE_SIGNING_CERT`, `secrets.CODE_SIGNING_PASSWORD`
   o similar) y se decodifica en memoria durante el run.

Hasta que eso exista, cualquier build sigue siendo explícitamente un
**unsigned release** — Windows SmartScreen probablemente va a advertir al
usuario de prueba al instalar/ejecutar, y hay que avisarle de antemano que
es esperado en esta etapa piloto.

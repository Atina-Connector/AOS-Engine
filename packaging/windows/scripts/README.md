# scripts/

Automatización de build para Windows (PowerShell). Pendiente de Fase 3:

- `prepare-octave-runtime.ps1` — descarga `octave-8.4.0-w64.7z` desde
  `ftp.gnu.org/gnu/octave/windows/` (o un mirror de `ftpmirror.gnu.org`),
  verifica el SHA-256 contra un hash fijado en este repo la primera vez que
  se pinnea la versión (GNU no publica `.sha256` por archivo, sólo `.sig`
  GPG — verificación GPG queda como hardening futuro, no bloqueante para el
  piloto), extrae con `7z.exe` (preinstalado en runners `windows-latest`) y
  deja el runtime listo en `runtime/octave/`.
- Smoke test corto post-armado: confirma que `octave-cli.exe --version`
  responde y que puede ejecutar un `.m` mínimo.

Nada de esto está implementado todavía.

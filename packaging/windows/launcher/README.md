# launcher/

Fuente del ejecutable `AOS.exe`. Pendiente de Fase 3.

Responsabilidades del launcher (ver `docs/distribution/WINDOWS_BUILD.md`
cuando exista contenido):

- Localizar `runtime\octave\bin\octave-cli.exe` en forma relativa a su
  propia ubicación (funciona bajo `Program Files` sin variables de entorno
  globales ni tocar el `PATH` del usuario).
- Invocar `octave-cli.exe app\AOS.m` con la ruta absoluta de `AOS.m`.
- Preservar stdin/stdout/stderr y propagar el exit code del proceso hijo.
- No requiere fijar el working directory: `AOS.m` ya hace `cd(root_dir)` con
  `root_dir` resuelto vía `mfilename('fullpath')`, independiente del cwd de
  quien invoca Octave.
- Sin GUI. Es un shim de consola, pensado en C simple (Win32
  `CreateProcessW`) para mantenerlo chico y sin runtime adicional que
  instalar (se prefiere sobre C#/.NET self-contained o Rust).

Nada de esto está implementado todavía.

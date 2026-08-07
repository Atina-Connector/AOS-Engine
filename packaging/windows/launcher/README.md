# launcher/

Fuente de `AOS.exe` (`aos_launcher.c` + `build.ps1`). Implementado, sin
validar todavía en una máquina Windows real.

Qué hace (Win32 puro, sin dependencias externas, sin GUI):

- Localiza `runtime\octave\mingw64\bin\octave-cli.exe` y `app\AOS.m` en
  forma relativa a su propia ubicación (`GetModuleFileNameW`) — funciona
  bajo `Program Files` sin variables de entorno globales ni tocar el `PATH`
  del usuario.
- Invoca `octave-cli.exe --quiet --no-history --no-init-file app\AOS.m` vía
  `CreateProcessW`, sin `STARTF_USESTDHANDLES` ni `CREATE_NEW_CONSOLE`: el
  proceso hijo hereda directamente la consola del launcher, así que
  stdin/stdout/stderr quedan intactos y la interacción es idéntica a correr
  Octave a mano.
- No fija el working directory a nada especial más que la carpeta de
  instalación: `AOS.m` ya hace `cd(root_dir)` con `root_dir` resuelto vía
  `mfilename('fullpath')`, independiente del cwd de quien invoca Octave.
- Espera a que el proceso termine y propaga su exit code tal cual
  (`GetExitCodeProcess` + `return`).
- Si no encuentra el runtime o `AOS.m`, imprime un mensaje claro por stderr
  y sale con código 1 en lugar de fallar de forma críptica.

`build.ps1` lo compila con una sola invocación de `cl.exe` (requiere MSVC
Build Tools en el PATH — `ilammy/msvc-dev-cmd` en CI, o "Developer
PowerShell for VS" en local). Se eligió C simple sobre C#/.NET
self-contained o Rust para mantenerlo chico y sin runtime adicional que
distribuir junto al de Octave.

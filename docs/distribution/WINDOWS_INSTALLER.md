# Instalador Windows (pendiente)

Este documento va a cubrir, una vez implementada la Fase 4:

- estructura de `packaging/windows/installer/AOS.iss` (Inno Setup);
- qué queda en `Program Files\AOS\` vs. qué se siembra en
  `%USERPROFILE%\Documents\AOS\` y por qué (ver
  `docs/distribution/REPOSITORY_LAYOUT.md`, sección de datos base vs.
  mutables);
- cómo probar instalación/desinstalación en una VM Windows 10/11 limpia;
- checklist de aceptación (arranca sin Octave/Docker/WSL/Python
  preinstalados, `Documents\AOS` sobrevive a la desinstalación, etc.);
- qué falta para activar la firma digital (code signing) de `AOS.exe` y
  `AOS-Setup.exe` — separación explícita entre build sin firmar y release
  firmado, sin certificados ni claves privadas en este repositorio.

Se redacta con contenido real cuando exista el `.iss` correspondiente.

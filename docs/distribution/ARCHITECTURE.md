# Arquitectura de distribución AOS (pendiente)

Este documento va a explicar, una vez implementadas las Fases 3–5, cómo
encajan entre sí:

- el runtime portable de GNU Octave (`packaging/windows/scripts/prepare-octave-runtime.ps1`),
- el launcher nativo `AOS.exe` (`packaging/windows/launcher/`),
- el instalador Inno Setup (`packaging/windows/installer/AOS.iss`),
- la separación entre datos base (`app/config`, `app/datos`, `app/ejemplos`)
  y datos mutables del usuario (`%USERPROFILE%\Documents\AOS\`, vía
  junctions NTFS),
- y cómo todo esto se relaciona con el flujo de desarrollo en Docker
  (`docker/`), que sigue siendo el entorno de referencia y no cambia para
  el usuario final de Windows.

Se redacta con contenido real cuando exista el código correspondiente — ver
`docs/distribution/REPOSITORY_LAYOUT.md` para el estado actual del repo y el
plan de Fases 3–5 para el diseño ya acordado.

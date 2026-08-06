# AOSCAD 0.0.1 DEV1 R6 — lanzadores reales Flatpak

## Evidencia recibida

- FreeCAD: Flatpak `org.freecad.FreeCAD`, comando interno `FreeCAD`.
- LibreCAD: Flatpak `org.librecad.librecad`, comando interno `librecad`.
- Open CASCADE: ejecutable `occt-draw` en el sistema anfitrion.
- GNU Octave: Flatpak, ejecutable `/app/bin/octave-cli`.

## Correcciones

- Se corrige el ID de LibreCAD a `org.librecad.librecad`.
- Se conserva el ID anterior solo como compatibilidad secundaria.
- Se usan `--branch=stable`, `--arch=x86_64` y el comando interno correcto.
- Se implementa `--file-forwarding` con `@@ ruta @@` al abrir DXF o STEP.
- FreeCAD usa `--single-instance`, igual que el lanzador del escritorio.
- Se detecta `occt-draw` dentro del entorno actual o mediante `flatpak-spawn --host`.
- El diagnostico informa el lanzador del sistema, el comando AOSCAD y el metodo de deteccion.

## Sin cambios

No se modifican el formato `.aoscad`, la geometria, los parsers DXF/STEP, la topologia, los modelos de fluidos ni los solvers.

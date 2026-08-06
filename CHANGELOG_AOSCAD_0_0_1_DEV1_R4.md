# AOSCAD 0.0.1 DEV1 R4

## Detectores CAD Linux

- Corrige la deteccion de FreeCAD y LibreCAD instalados y funcionales fuera del PATH heredado por GNU Octave.
- Agrega deteccion por PATH, rutas absolutas, Flatpak, Snap, AppImage y archivos .desktop.
- Registra el metodo y el comando real encontrado.
- Permite abrir DXF/STEP mediante launchers compuestos, incluido `flatpak run`.
- Permite intentar FreeCADCmd dentro de Flatpak para exportaciones STEP revisadas.
- Agrega `DIAGNOSTICAR_EDITORES_AOSCAD`.
- Mantiene FreeCAD y LibreCAD como herramientas graficas externas; GNU Octave sigue siendo el unico motor de AOS.
- No modifica el formato .aoscad, topologia, solvers ni ecuaciones.

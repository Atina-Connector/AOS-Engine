# Changelog AOS Suite 0.1.9

Fecha: 2026-07-25  
Edicion: Puerta de entrada a AOS 0.2.0  
Plataforma: GNU Octave

## Arquitectura de la Suite

AOS 0.1.9 presenta todos los bancos de trabajo actuales y planificados como categorias independientes. El orden constituye el contrato inicial para la futura cinta del frame AOS 0.2.0:

1. AOS SLA
2. AOS Wells
3. AOS CAD
4. AOS Networks
5. AOS Electrical
6. AOS Facilities
7. AOS Geology
8. AOS Fluids
9. AOS SCADA
10. AOS Maintenance
11. AOS Data
12. AOS Solvers
13. AOS Global
14. AOS Viewer, siempre ultimo

Roadmap y configuracion permanecen como funciones de plataforma, no como bancos de ingenieria.

## Cambios principales

- AOS Fluids pasa a tener un espacio propio y transversal.
- AOS Solvers se separa en disciplinas hidraulica, electrica, mecanica, termica, geologica, reservorio, produccion, multifisica, redes/grafos, optimizacion, economia, confiabilidad y fluidos.
- AOS 3D Core queda definido como servicio transversal para Wells, CAD, Networks, Electrical, Facilities, Geology y Global.
- Los modulos en roadmap permanecen visibles y muestran alcance, estado y siguiente hito.
- Se incorporan manifiestos JSON para alimentar el futuro frame con cinta.
- Se conserva el menu historico como compatibilidad.

## AOS CAD

- AOSCAD 0.0.1 DEV1 R9.1 integrado.
- Lanzadores LibreCAD y FreeCAD compatibles con Octave dentro de Flatpak.
- Simulacion hidraulica DXF.
- Dominio hidraulico por nodo inicial, nodo final y camino.
- Persistencia `SELECTED_PATH` y `LOOP_SUBNETWORK` en `.aoscad`.
- Solver general de anillos tipo Kirchhoff registrado como roadmap, sin inventar distribuciones de caudal.

## Compatibilidad fisica

La reorganizacion no modifica intencionalmente las ecuaciones de GL/JGL, BES, BM/Gibbs, CGF, EGF ni las correlaciones hidraulicas existentes.

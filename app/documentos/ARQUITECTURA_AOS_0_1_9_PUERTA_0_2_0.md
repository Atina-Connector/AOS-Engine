# AOS 0.1.9 - Puerta de entrada a AOS 0.2.0

## Regla de arquitectura

AOS Suite contiene bancos de trabajo independientes. Los servicios transversales proveen capacidades compartidas. AOS Solvers concentra los motores cientificos por disciplina. AOS Global orquestara esas capas sin duplicar ecuaciones.

## Bancos visibles en la futura cinta

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

Los bancos planificados permanecen visibles y muestran estado, alcance, dependencias y siguiente hito.

## AOS Fluids

AOS Fluids es la fuente oficial de PVT, composiciones y propiedades en funcion de presion y temperatura. Los otros bancos deben referenciar un `fluid_id` persistente en lugar de duplicar propiedades.

## AOS Solvers

Los solvers se organizan en hidraulicos, electricos, mecanicos, termicos, geologicos, reservorio, produccion, multifisicos, redes/grafos, optimizacion, economia, confiabilidad y fluidos. El workbench define el problema; el solver resuelve el sistema; el servicio 3D representa el resultado.

## AOS 3D Core

AOS 3D Core es transversal. A partir de survey, DXF y STEP debe representar estado mecanico de pozos, redes hidraulicas y electricas, instalaciones de superficie, geologia y resultados. Cada objeto se identifica por `asset_id` y se vincula a tablas, topologia, SCADA, mantenimiento y reportes.

## Transicion a 0.2.0

El frame 0.2.0 utilizara los manifiestos JSON incluidos en `src/roadmap` para construir la cinta, el arbol de proyecto, las propiedades, la escena compartida y los accesos a solvers.

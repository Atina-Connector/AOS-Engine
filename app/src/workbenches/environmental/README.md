# AOS ENVIRONMENTAL workbench

Estado: `ROADMAP_RUNTIME_SHELL`  
Decision: `ADR-AOS-2026-001`  
Revision: `ENV-02`

AOS Environmental es un banco independiente. Su ambito incluye fuentes y eventos ambientales, emisiones fugitivas y directas, derrames, H2S, actividad energetica, emisiones indirectas, riesgo, mitigacion, cumplimiento y reporting.

## Fronteras

- AOSCAD / AOS 3D Core: identidad, geometria, ubicacion y topologia.
- AOS Environmental: evento, medicion, calculo, inventario, riesgo y cierre ambiental.
- AOS Maintenance: orden, reparacion e intervencion.
- AOS Fluids: composicion y propiedades.
- AOS SCADA: mediciones, historicos y alarmas.

No se debe duplicar geometria, fisica de fluidos, datos SCADA ni logica de mantenimiento dentro de este workbench.

## Runtime ENV-02

`AOS_menu_environmental` esta disponible como entrypoint independiente y aparece entre SCADA y Maintenance. El shell permite navegar hacia gestion de caso, AOSCAD, integridad, SCADA, Maintenance, Reporting y AOS Data. Las funciones cientificas permanecen pendientes.

`AOS_menu_gestion_ambiental` y `AMBIENTAL` se conservan como aliases historicos.

## Proximo entregable

Diseno y aprobacion de contratos de identidad espacial, fuentes, eventos, mediciones, actividad energetica, factores, resultados, riesgo y acciones antes de implementar calculos.

# Resumen de la enmienda ENV-01

## Decisión

AOS Environmental queda formalmente incorporado como banco de trabajo independiente y transversal de AOS 0.2.0.

## Cambios incluidos

- ADR-AOS-2026-001 aceptado.
- Workbench Environmental agregado a los manifests 0.2.0.
- Orden objetivo de cinta: SCADA -> Environmental -> Maintenance.
- AOSCAD definido como autoridad de identidad y ubicación física.
- Frontera Environmental/Maintenance corregida.
- Actividad energética separada del cálculo de emisiones indirectas.
- Roadmap y documentación actualizados.
- Alias históricos preservados.

## Cambios no incluidos

- No se modificó código `.m`.
- No se creó el entrypoint `AOS_menu_environmental`.
- No se diseñaron schemas detallados.
- No se implementaron cálculos, factores, importadores ni reportes ambientales.
- No se promocionó el módulo a BETA.

## Próxima etapa

Diseño de contratos: identidad espacial, fuentes, eventos, mediciones, energía, factores, resultados, riesgo y acciones.

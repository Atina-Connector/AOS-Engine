# AOS 0.1.9 R2 HF3.4

## Objetivo
Cerrar dos defectos detectados por la campaña dinámica posterior a HF3.3:

1. una geología reconfirmada sin cambios era marcada como modificada cuando contenía `NaN`;
2. GF3 producía `espaciamiento.valido`, pero validadores y reportes exigían `valido_calculo`.

## Cambios

- `aos_geologia_commit` compara estructuras con `isequaln`, por lo que `NaN` en la misma posición no genera un cambio ficticio.
- Una reconfirmación idéntica conserva las corridas vigentes y no vuelve a invalidar resultados.
- GF3 publica simultáneamente `valido` y `valido_calculo`.
- GF3 publica simultáneamente `validacion` y `mensaje_validacion`.
- `gibbs3_upgrade_result_schema` migra resultados anteriores al contrato `GF3_SPACING_RESULT_1_1`.
- `gibbs3_report_context` admite tanto el contrato histórico como el vigente.
- `gibbs3_selftest` informa la condición exacta que falla y valida expresamente el contrato de espaciamiento.
- Se agregan regresiones de idempotencia geológica y contrato de espaciamiento.

## Física
No se modifican ecuaciones, cargas, cinemática, correlaciones, parámetros de bomba ni resultados físicos. HF3.4 corrige comparación de estado y nombres de campos públicos.

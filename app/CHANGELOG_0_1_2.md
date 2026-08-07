# AOS 0.1.2 - Hito Bombeo Mecanico

## Cambios funcionales

- Se incorpora **Gibbs Foundation 2** de forma nativa y se congela el caso `BM_GF2_GOLDEN_CASE_001`.
- Se incorpora **Gibbs Foundation 3** como solver BETA, separado de GF2.
- El menu de Bombeo Mecanico deja de editarse con cadenas `elseif` para cada solver.
- Se agrega `bm_registro_modulos.m`, que registra nombre, funcion, estado, version y descripcion.
- El flujo BM operativo anterior se conserva sin cambios fisicos en `BM_operativo_menu.m`.
- Se incorpora el acceso visible a survey, punzados y completacion dentro de Importar / Exportar.

## Estados de BM

| Modulo | Estado |
|---|---|
| BM operativo | OPERATIVO |
| Laboratorio Gibbs | EXPERIMENTAL |
| Foundation v18 | LEGADO |
| Gibbs Foundation 2 | BENCHMARK |
| Gibbs Foundation 3 | BETA |

## Politica de validacion

GF2 es un testigo congelado. GF3 no reemplaza a GF2 hasta superar pruebas de:

- periodicidad;
- convergencia temporal;
- convergencia de malla;
- sensibilidad a SPM, carrera y profundidad;
- sensibilidad a sarta y llenado;
- comparacion con casos de campo y herramientas de referencia.

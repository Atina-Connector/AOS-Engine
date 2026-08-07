# AOS 0.1.3R1.1

Fecha: 2026-07-23

## Correccion de consolidacion BES3

Se restituyeron los siguientes componentes omitidos en R1:

- `README_BES3.md`
- `bes3_capillary_fit.m`
- `bes3_capillary_flow.m`
- `bes3_capillary_loss.m`
- `bes3_comparar_v1_v2_v3.m`
- `bes3_completion_geometry.m`
- `bes3_presion_intake.m`
- `bes3_servicios_transversales.m`
- `bes3_stage_performance.m`
- `AOS_0_1_3_BES3_RECIRCULACION_CAPILAR.aosdat`

## Verificacion

- El verificador exige ahora los 44 archivos activos de BES3.
- Se comprueban marcadores de dependencia entre solver, geometria, intake, capilar, secciones de bomba y servicios transversales.
- La prueba numerica opcional ejecuta `bes3_selftest` y el caso sintetico completo.

## Fisica

No se modificaron ecuaciones ni criterios fisicos. BES3 permanece en `DESARROLLO_NO_VALIDADO`.

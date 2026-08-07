# Regresiones AOS 0.1.9 R2 HF3.4

## GEO-HF34-001 - Reconfirmación idempotente
- Confirmar una geología con punzados que contienen `NaN`.
- Confirmar nuevamente la misma estructura.
- La segunda operación debe devolver `cambio=false`.
- Los resultados vigentes no deben invalidarse.

## GF3-HF34-001 - Contrato de espaciamiento
- El productor debe publicar `valido` y `valido_calculo` con el mismo significado.
- Debe publicar `validacion` y `mensaje_validacion`.
- El migrador debe reconstruir aliases faltantes en resultados residentes.
- El selftest integral GF3 debe aprobar los casos convencional, LPP, aparato, tubing libre y tubing anclado.

## Criterio de liberación
`VERIFICAR_AOS_0_1_9_R2_HF3_4(true)` debe finalizar con resultado aprobado.

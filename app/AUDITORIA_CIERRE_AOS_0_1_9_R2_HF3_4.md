# Auditoría de cierre AOS 0.1.9 R2 HF3.4

## Hallazgos confirmados

### Geología
El commit utilizaba `isequal`. Los intervalos normalizados contienen campos opcionales `NaN`; en GNU Octave, `isequal(NaN,NaN)` es falso. Por eso una reconfirmación idéntica se interpretaba como modificación y volvía a invalidar resultados.

### GF3
El productor de espaciamiento publicaba `e.valido` y `e.validacion`, mientras el validador y el adaptador de reportes exigían `e.valido_calculo` y `e.mensaje_validacion`. El cálculo estaba presente, pero el contrato público era inconsistente y el selftest integral se rechazaba.

## Corrección
- comparación `isequaln` para estado físico con valores faltantes;
- aliases simétricos de espaciamiento;
- migración de resultados anteriores;
- regresiones específicas y diagnóstico detallado.

## Alcance
No se cambió la física de GF3 ni la gestión numérica de geología/punzados.

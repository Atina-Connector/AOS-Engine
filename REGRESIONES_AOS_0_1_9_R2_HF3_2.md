# Regresiones AOS 0.1.9 R2 HF3.2

## AUD-EMPTY-001

Una auditoria sin hallazgos debe devolver:

- `ok = true`
- `errores = 0`
- `avisos = 0`
- `hallazgos` presente y vacio

No debe producir `structure has no member 'severidad'`.

## GEO-CONTRACT-001

`aos_geologia_resolver_punzados` debe devolver simultaneamente:

- `info.n_salida`
- `info.n_finales`

Ambos deben ser iguales al numero de intervalos finales.

## Aceptacion

```octave
VERIFICAR_AOS_0_1_9_R2_HF3_2(false)
VERIFICAR_AOS_0_1_9_R2_HF3_2(true)
```

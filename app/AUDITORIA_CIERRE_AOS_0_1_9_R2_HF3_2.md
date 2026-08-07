# Auditoria de cierre AOS 0.1.9 R2 HF3.2

## Evidencia de origen

La campana dinamica de HF3.1 aprobo el gestor de punzados, los contratos
`.aosdat`, catalogos, galeria de mandriles, AOSCAD, dominio hidraulico, AOSBCK y
BES3. El rechazo final se debio exclusivamente a dos excepciones de contrato:

- `structure has no member 'severidad'` en la auditoria transversal sin
  hallazgos.
- `structure has no member 'n_salida'` en el selftest transaccional de
  geologia.

## Causa raiz 1: estructura vacia sin esquema

`aos_auditar_interacciones` inicializaba `hallazgos` como `struct([])`. Cuando
no habia hallazgos, el acceso `{hallazgos.severidad}` intentaba consultar un
campo inexistente.

### Correccion

- Estructura vacia tipada con los campos del contrato.
- Rama explicita para el conjunto vacio antes de extraer severidades.

## Causa raiz 2: cambio de nombre de campo

`aos_geologia_resolver_punzados` publicaba `n_finales`, mientras el contrato
historico y el selftest utilizaban `n_salida`.

### Correccion

La funcion devuelve ambos campos como aliases compatibles:

```text
n_salida = numero de intervalos finales
n_finales = n_salida
```

## Regresiones agregadas

- Auditoria sin hallazgos.
- Presencia del esquema de `hallazgos`.
- Compatibilidad simultanea de `n_salida` y `n_finales`.
- Conservacion, uso de nuevos punzados y fusion de intervalos.

## Alcance

HF3.2 no modifica ecuaciones, correlaciones, solvers, parametros fisicos ni
resultados numericos. Es un cierre de contratos y verificadores.

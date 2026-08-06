# AOS 0.1.9 R2 HF3.2

## Cierre de auditoria transversal

HF3.2 corrige dos defectos detectados por la campana dinamica de HF3.1:

1. `aos_auditar_interacciones` fallaba cuando la auditoria no encontraba ningun
   hallazgo, porque intentaba acceder al campo `severidad` de un `struct([])` sin
   esquema de campos.
2. `aos_geologia_resolver_punzados` devolvia `n_finales`, mientras el contrato y
   los selftests historicos esperaban `n_salida`.

## Correcciones

- La coleccion de hallazgos se inicializa con un esquema tipado y la extraccion
  de severidades contempla explicitamente el conjunto vacio.
- La informacion de resolucion de punzados publica ambos campos:
  `n_salida` y `n_finales`, con el mismo valor.
- Se fortalecen los selftests de auditoria y geologia.
- Se agrega `test_aos_contratos_estructuras_hf3_2`.
- Los verificadores HF3 y HF3.1 redirigen a HF3.2.

No se modifican ecuaciones, correlaciones, solvers ni resultados fisicos.

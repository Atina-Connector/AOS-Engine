# Auditoría estática SENS-GLJGL-01

## Resultado

**`PASS_STATIC`**

La validación dinámica no fue ejecutada porque GNU Octave no está disponible en el entorno de construcción. El estado dinámico permanece **`NOT_RUN_GNU_OCTAVE_UNAVAILABLE`**.

## Alcance

Revisión de la capa de sensibilidades GL/JGL sobre AOS 0.2.0 DEV1 ENV-02. El hotfix corrige orquestación, paridad puntual-barrido, política de cálculo, publicación y trazabilidad; no reescribe los núcleos físicos puntuales.

## Inventario respecto de ENV-02

- Archivos nuevos: **21**.
- Archivos modificados: **16**.
- Archivos eliminados: **0**.
- Archivos `.m` nuevos o modificados: **24**.
- Archivos totales en la distribución: **1290**.

El inventario nominal completo se conserva en `PATCH_FILE_LIST_SENS01.txt` y el inventario estructurado en `AUDITORIA_ESTATICA_SENS_GLJGL_01.json`.

## Controles aprobados

- Balance léxico de delimitadores y bloques Octave en los **24** archivos `.m` nuevos o modificados.
- Coincidencia entre nombre de archivo y primera función declarada: sin discrepancias.
- **34** archivos JSON parseados correctamente.
- Ningún archivo `.mat`.
- Ningún nombre `.m` duplicado dentro de `src`.
- Estado GL real propagado; no existe `estado_gl{i} = 'OK'` forzado.
- Fallback IPR coherente con GL puntual: `linear`.
- Curva JGL con método y resolución uniformes.
- Contrato raw/publicado y máscaras independientes para curva y óptimo.
- Registro de `SENS-GLJGL-01` en release y registro científico.
- Aplicar el inventario del parche sobre una copia limpia de ENV-02 reproduce byte por byte la distribución corregida.

## Núcleos puntuales protegidos

| Archivo | SHA-256 | Sin cambios |
|---|---|---|
| `src/core/GL/GL_sim.m` | `e4ebbe948b8d41b7d2a64a55224a144fd7096ca6d6c30960c2c51758f0709f86` | Sí |
| `src/utilidades/nodal/aos_nodal_balance_gl.m` | `c8cd8a616f8a225c716c131caadb4aa87720b660f403503f78b517bb49c06d0f` | Sí |
| `src/utilidades/nodal/aos_buscar_cruce_nodal.m` | `038fae7cc180e50af0f226fb2a63d3a48f47aa4e9d94b7fecd071a8f00d80451` | Sí |
| `src/core/JGL/jgl_solver_directo.m` | `f6c8cabeefd272722a8a9cce382be5459c8a5dae5e71cb10fcf05fd9c0e6654a` | Sí |
| `src/core/JGL/jgl_solver_iterativo.m` | `d212c3d067ee45c16169a5122cac8a4fb1872425329153d6c130f217ed64c9c8` | Sí |

## Condición de aceptación dinámica

En GNU Octave deben aprobarse:

```octave
VERIFICAR_SENS_GLJGL_01(false)
VERIFICAR_AOS_0_2_0_DEV1(false)
VERIFICAR_SENS_GLJGL_01(true)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

Además, el caso real debe demostrar paridad entre cada punto GL individual y el mismo `Qiny` dentro del barrido, sin ceros falsos, caudales negativos publicados ni mezcla silenciosa de métodos.

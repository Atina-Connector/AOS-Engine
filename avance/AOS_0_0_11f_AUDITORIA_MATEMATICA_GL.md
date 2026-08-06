# AOS 0.0.11f — Corrección de auditoría matemática GL

## Objetivo

Dejar el modelo GL activo para benchmark, corrigiendo los problemas detectados en la auditoría matemática previa a AOS 0.0.12.

## Cambios principales

1. **Vogel compuesto corregido**
   - La rama bajo presión de burbuja ahora invierte el caudal incremental debajo de `P_b`.
   - La presión se escala con `P_b`, no con `P_res`.

2. **Solver nodal robusto**
   - Nuevo buscador de cruces con barrido auditable y bisección.
   - Detecta todos los cambios de signo.
   - Evita devolver `Ql = 0` cuando existe un cruce visible.
   - Conserva tabla de residuos para auditoría.

3. **Solver y gráfico usan el mismo balance**
   - `aos_nodal_balance_gl()` calcula una sola vez la física común.
   - `GL_puro_core`, `GL_sim`, `plot_nodal` y `error_gl` se apoyan en el mismo balance.

4. **Tramo reservorio–inyección corregido**
   - Hidrostática calculada con `Delta TVD`, no con `Delta MD`.
   - Densidad de gas local a presión y temperatura del tramo.
   - Gas libre de formación descuenta gas disuelto mediante `Rs`.

5. **Gas libre en VLP**
   - El gas inyectado se mantiene como gas libre.
   - El gas de formación se reduce por `Rs` antes de convertir a condiciones locales.

6. **Profundidad canónica GL/JGL**
   - Se prioriza `D_iny_m` / `D_iny`.
   - `D_bomba` queda como alias histórico, no como fuente principal para GL.

## Importante

No se aplican factores de ajuste contra PROSPER. Las diferencias remanentes deben atribuirse a datos, PVT, correlaciones simplificadas o configuración del caso.

## Archivos clave

- `src/core/common/ipr/ipr.m`
- `src/core/GL/GL_puro_core.m`
- `src/core/GL/GL_sim.m`
- `src/utilidades/nodal/aos_nodal_balance_gl.m`
- `src/utilidades/nodal/aos_buscar_cruce_nodal.m`
- `src/utilidades/nodal/calcular_columna_succion.m`
- `src/utilidades/nodal/plot_nodal.m`
- `src/core/common/vlp/aos_vlp_propiedades_locales.m`

## Criterio de validación

Para MX01, el objetivo inmediato es que AOS detecte el cruce que el gráfico muestra. Luego se compara el nuevo caudal contra PROSPER para determinar si el desvío restante proviene de datos reconstruidos o de VLP/PVT.

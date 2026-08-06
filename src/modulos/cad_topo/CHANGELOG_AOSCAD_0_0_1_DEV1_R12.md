# CHANGELOG AOSCAD 0.0.1 DEV1 R12 — Sprint 3

Fecha: 2026-07-28
Estado: DEV1 (PROTOTIPO_NO_VALIDADO). Sin promocion de madurez.

## Resumen

Sprint 3: red ramificada verificable y auditable, equipos activos con curva
head–caudal (metadato DXF + catalogo JSON), condiciones de dominio P–P / Q–P
con validacion de suficiencia, y campana multifasica en red. Schema
`info.schema` permanece `AOSCAD-0.0.1-DEV1` (crecimiento aditivo).

## Cambios

### A — Red ramificada verificable
- Fixture `demo_aos_red_ramificada.dxf` (1 fuente P, 3 demandas, 2 bifurcaciones).
- `aos_cad_hidraulica_diagnosticar_topologia`: items estructurados sin `error`
  como primer contacto (`HID_LAZO_NO_SOPORTADO_DEV1`, bifurcaciones, etc.).
- Balance nodal expuesto en nodos (`balance_nodal_m3s`, `grado`,
  `es_bifurcacion`) y resumen (`residual_balance_max_m3s`, `n_bifurcaciones`,
  `topologia_resuelta`); item `HID_BALANCE_NODAL` si se excede la tolerancia.
- Visibilidad en `validar_red` / `mostrar_resultados`.

### B — Curva head–caudal de equipos activos
- Contrato DXF: `CURVA_Q=` / `CURVA_H=` (separador `|`), `BOMBA_MODELO=`,
  `BOMBA_ESTADO=`. Precedencia: inline > catalogo > sin curva.
- `aos_cad_hidraulica_curva_bomba` (interpolacion lineal, saturacion,
  advertencias `CURVA_*`).
- Catalogo `datos/catalogos/aos_bombas_catalogo_0_0_1.json` +
  `aos_cad_hidraulica_catalogo_bombas`.
- `evaluar_tramo`: `dp_equipo_Pa` / `head_equipo_m` fuera de `dp_menores_Pa`;
  identidad `dp_total = dp_fric + dp_grav + dp_menores + dp_equipo`.
  Valvula cerrada sigue ganando sobre bomba.

### C — Condiciones de dominio
- Modos `P_INICIO_Q_FIN` (default, sin cambio de comportamiento),
  `Q_INICIO_P_FIN` (directo) y `P_INICIO_P_FIN` (biseccion externa sobre Q,
  solo `SELECTED_PATH` sin bifurcaciones).
- `dominio_validar`: `HID_BC_INSUFICIENTE`, `HID_BC_SOBREDETERMINADA`,
  `HID_MODO_NO_SOPORTADO_EN_LAZO`, `HID_MODO_PP_REQUIERE_CAMINO_SIMPLE`,
  `HID_MODO_CONDICION_OK`.
- `aos_cad_hidraulica_dominio_resolver_pp` + menu de seleccion de modo.

### D — Campana en red y documentacion
- `test_aos_cad_benchmark_red.m`: rama a rama vs nucleo; HB/DR pasan a
  `VALIDADO_EN_RED_DEV1` en el registro de modelos.
- `LEEME_RED_RAMIFICADA_Y_BOMBAS.md`; identidad extendida en
  `LEEME_BENCHMARK_TRAMO.md`.

### Testing y registro
- Nuevos: `test_aos_cad_red_ramificada`, `test_aos_cad_equipo_activo_curva`,
  `test_aos_cad_dominio_condiciones`; fixture `demo_aos_bomba_curva.dxf`.
- Ampliados: `test_aos_cad_benchmark_tramo` (`dp_equipo`), 
  `test_aos_cad_dominio_hidraulico` (modos + bloqueo anillo).
- `VERIFICAR_CAD_TOPO`: 4 tests nuevos + `test_aos_cad_hidraulica_dxf` (deuda),
  fixtures, funciones y LEEME.
- `VERIFICAR_AOSCAD_HIDRAULICA_0_0_1_DEV1`: curva/catalogo/diagnostico/tests red.

## Limitaciones remanentes
- Solver de lazos Kirchhoff (`HYD_LOOP`), multiples fuentes y flujo reverso:
  Sprint 4. `rechazar_lazos` sigue en `true`.
- `P_INICIO_P_FIN` sobre arbol ramificado: no soportado (reparto no unico).
- Curvas de eficiencia/potencia, NPSH, afinidad por frecuencia: fuera de alcance.
- Interpolacion de curva: solo lineal (sin splines).
- Visor 3D / placement STEP / interferencias: Sprints 5–6.
- `cad_topo` permanece en `src/modulos` (workbenches: 0.2.0).

## Estado DEV1
Se mantiene `PROTOTIPO_NO_VALIDADO`. No hay promocion de madurez en R12
(la promocion a BETA es Sprint 7).

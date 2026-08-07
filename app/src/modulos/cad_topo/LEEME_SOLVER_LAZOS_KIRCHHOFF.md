# LEEME — Solver de lazos Kirchhoff (HYD_LOOP) AOSCAD DEV1 R13

## Formulación

Con `E` tramos activos, `N` nodos activos y `F` fuentes de `PRESION`:

- Continuidad en `N − F` nodos.
- Energía: `E − (N − F) = (E − N + 1)` lazos reales + `(F − 1)` pseudolazos.

Procedimiento:

1. Árbol de expansión BFS; cuerdas = lazos fundamentales; pseudolazos = caminos en el árbol entre fuentes.
2. Inicialización con agregación bottom-up del árbol + circulación `q_init_lazo_m3s` (continuidad exacta).
3. Newton sobre circulaciones; residual = Σ signo·ΔP orientado (− ΔP impuestos en pseudolazos).
4. Jacobiano por diferencia central regularizada; line search con backtracking.
5. Recuperación de presiones por BFS con caudales convergidos.

`ΣQ=0` se preserva en toda iteración (correcciones = circulaciones).

## Flujo reverso

- `Q > 0`: sentido geométrico `nodo_o → nodo_d`.
- `Q < 0`: se invierten extremos, se evalúa `|Q|`, `dp_orientado = −dp_total`.
- Accesorios/válvulas en el nodo aguas abajo real.
- Válvula `CERRADA`: se excluyen de la base **todas** las aristas incidentes
  al nodo (`nodo_o` o `nodo_d`), porque Newton/FD exploran ambos signos de `Q`
  y `perdidas_menores` se aplican en el `nodo_out` real. Código:
  `HID_LAZO_VALVULA_CERRADA_REDUCE_BASE`.
- Bomba solo aporta head en sentido geométrico; en reverso head=0 y
  `EQUIPO_FLUJO_REVERSO_NO_APORTA_HEAD` vía `cfg.sentido_flujo_reverso`.

## Restricción monofásica

Lazos solo `MONOFASICO_DARCY`. En multifásico ΔP depende de `P_in` y ΣΔP=0
deja de ser exacto. Código: `HID_LAZO_MULTIFASICO_NO_SOPORTADO_DEV1`.

## Parámetros `cfg` (defaults)

| Campo | Default |
|-------|---------|
| `max_iter_lazo` | 60 |
| `tol_lazo_Pa` | 10 |
| `tol_dq_m3s` | 1e-9 |
| `q_init_lazo_m3s` | 1e-4 |
| `dq_derivada_m3s` | 1e-7 |
| `metodo_lazo` | NEWTON |
| `amortiguamiento_lazo_min` | 0.05 |
| `rechazar_lazos` | false |

## Catálogo de items nuevos

- `HID_LAZO_RESUELTO_KIRCHHOFF` (INFO)
- `HID_LAZO_NO_CONVERGE` (ERROR) — conserva último iterado y residuales
- `HID_LAZO_RESIDUAL_CIERRE` (ERROR)
- `HID_LAZO_MULTIFASICO_NO_SOPORTADO_DEV1` (ERROR)
- `HID_LAZO_JACOBIANO_SINGULAR` (ERROR)
- `HID_LAZO_VALVULA_CERRADA_REDUCE_BASE` (ADVERTENCIA)
- `HID_LAZOS_DETECTADOS` (INFO)
- `HID_FLUJO_REVERSO_DETECTADO` (INFO)
- `HID_INYECCION_NODAL` (INFO)
- `HID_LAZO_MODO_CONDICION_OK` (INFO)
- `HID_MODO_PP_NATIVO_LAZO` (INFO)
- `HID_LAZO_BASE_INCONSISTENTE` (ERROR)

## Entrypoints

- Árbol: `aos_cad_hidraulica_resolver` (`HYD_TREE`) — despacha a lazos si hace falta.
- Lazos: `aos_cad_hidraulica_resolver_lazos` (`HYD_LOOP`).
- Cruzado (tests): `aos_cad_hidraulica_lazos_hardy_cross`.

## Limitaciones

Ver `CHANGELOG_AOSCAD_0_0_1_DEV1_R13.md`. Sin promoción a BETA.

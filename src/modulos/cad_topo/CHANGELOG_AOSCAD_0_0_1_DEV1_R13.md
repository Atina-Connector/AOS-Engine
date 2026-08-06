# CHANGELOG AOSCAD 0.0.1 DEV1 R13

## Resumen

Sprint 4: solver de lazos `HYD_LOOP` por Kirchhoff (Newton sobre circulaciones),
multiples fuentes de presion, flujo reverso orientado y desbloqueo de
`LOOP_SUBNETWORK`. Estado AOSCAD permanece **DEV1 / PROTOTIPO_NO_VALIDADO**.
**No hay promocion a BETA.**

## Cambios

- Nuevo motor: `aos_cad_hidraulica_lazos_base`, `dp_orientado`,
  `resolver_lazos` (entrypoint `HYD_LOOP`), `lazos_hardy_cross` (verificador cruzado).
- `preparar` admite lazos, multifuente e inyecciones; `rechazar_lazos` default `false`.
- Camino arbol intacto cuando `requiere_solver_lazos=false`.
- Dominio `LOOP_SUBNETWORK` ejecutable (`LISTO_LAZO_KIRCHHOFF`);
  `P_INICIO_P_FIN` nativo en lazo (pseudolazo, sin biseccion).
- Diagnostico: `HID_LAZOS_DETECTADOS` (INFO), multifuente e inyeccion a INFO.
- Fixtures `demo_aos_anillo.dxf`, `demo_aos_dos_lazos.dxf`.
- Tests: `test_hyd_loop_selftest` (L1–L9), `test_aos_cad_red_lazos`.
- Registro: `HYD_LOOP` → DESARROLLO en `aos_solvers_0_1_9.json`.
- Fix R7: válvula `CERRADA` excluye aristas incidentes por `nodo_o` **y**
  `nodo_d` (antes solo `nodo_d`), para que Newton/FD no inyecten `Inf`.
  L8 ampliado: caudal cero en T1 (nodo_d) y T2 (nodo_o).

## Asserts invertidos

1. `test_aos_cad_dominio_hidraulico`: anillo valida y converge.
2. `test_aos_cad_dominio_condiciones`: `HID_LAZO_MODO_CONDICION_OK` + PP nativo.
3. `test_aos_cad_red_ramificada`: `HID_LAZOS_DETECTADOS` (INFO).

## Limitaciones remanentes (explicitas)

- Lazos solo `MONOFASICO_DARCY` (`HID_LAZO_MULTIFASICO_NO_SOPORTADO_DEV1`).
- Sin inyeccion con gas / multifasico reverso.
- Sin valvulas de retencion/control activo, tanques ni bombas de velocidad variable.
- `P_INICIO_P_FIN` en arbol ramificado monofuente sigue rechazado.
- Base de lazos = BFS (sin optimizacion de condicionamiento).
- Sistema denso; no escalado a redes grandes.
- Promocion BETA: Sprint 7.

## Schema

`info.schema` permanece exactamente `AOSCAD-0.0.1-DEV1`.

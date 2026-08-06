# CHANGELOG AOSCAD 0.0.1 DEV1 R10 — Sprint 1 baseline

Fecha: 2026-07-27
Estado: DEV1 (PROTOTIPO_NO_VALIDADO). Sin promocion de madurez.

## Resumen

Sprint 1 (baseline): benchmark de tramo vs nucleo VLP, unidades DXF reales
y round-trip de capas/bloques en exportacion `*_AOS_REV`.

## Cambios

### A — Benchmark de tramo
- Nuevo `test_aos_cad_benchmark_tramo.m` (casos M1–M3, F1–F4, A3 perdidas menores).
- Documento de tolerancias `LEEME_BENCHMARK_TRAMO.md`.
- El nucleo `src/core/common/vlp/*` no se modifica.

### B — Unidades DXF
- Nuevo `aos_cad_unidades_dxf.m` (prioridad: `AOS UNIDADES=` > `$INSUNITS` > preferencia > default m).
- `aos_cad_mapear_objetos.m` escala geometria a metros SI una sola vez.
- `aos_cad_meta_aplicar.m`: claves `UNIDADES=`, `D_M=`, `D_MM=`, `D_IN=`;
  heuristica `D>1` agrega `META_UNIDAD_HEURISTICA`.
- Export REV escribe `$INSUNITS=6` y `AOS UNIDADES=m`.
- Fixture `demo_aos_unidades_mm.dxf` + `test_aos_cad_unidades_dxf.m`.

### C — Capas y bloques
- `aos_dxf_leer.m` parsea seccion `BLOCKS` → `modelo.bloques`.
- `aos_cad_exportar_dxf_rev.m` preserva capas de usuario, reescribe BLOCKS e INSERT.
- `aos_cad_merge_ids_reimport.m`: clave estable `INSERT:bloque:x:y`.
- `aos_cad_importar_dxf.m` conserva `id_index` al reabrir `*_AOS_REV`.
- Fixture `demo_aos_bloques.dxf` + `test_aos_cad_bloques_capas.m`.

## Limitaciones remanentes
- Geometria interna de bloques no se expande a tablas (solo inventario/reexport).
- Equipos activos sin curva: solo advertencia (head=0); Sprint 3.
- Solver de lazos Kirchhoff: roadmap (`HYD_LOOP`).
- Visor 3D integrado: roadmap.

## Verificacion
Registrar en `VERIFICAR_CAD_TOPO`:
- `test_aos_cad_benchmark_tramo`
- `test_aos_cad_unidades_dxf`
- `test_aos_cad_bloques_capas`

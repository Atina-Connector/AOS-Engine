# CHANGELOG AOSCAD 0.0.1 DEV1 R11 — Sprint 2

Fecha: 2026-07-27
Estado: DEV1 (PROTOTIPO_NO_VALIDADO). Sin promocion de madurez.

## Resumen

Sprint 2: contrato `asset_id` deterministico y persistente, primera migracion
real a `src/services` (geometry_3d y units) con wrappers de compatibilidad, y
contrato de puertos solo-datos.

## Cambios

### A — Servicio de identidad asset_id
- `aos_asset_clave_estable`, `aos_asset_hash`, `aos_asset_id_generar`,
  `aos_asset_registro`, `aos_asset_identity_validar` en `src/services/geometry_3d`.
- Formato `AOS-<TIPO>-<hash8>`; clave sin handle DXF (IDEST > INSERT > STEP >
  geometria cuantizada > id local).
- Deteccion de colisiones `ASSET_ID_COLISION` con desambiguacion determinista.

### B — Asignacion, STEP y persistencia
- `aos_cad_asignar_asset_ids` integrado tras merge de IDs en mapear.
- Identidad STEP unificada via servicio (`aos_cad_build_id_index_step`).
- Persistencia `modelo.activos` e `info.asset_identity_schema` (schema aditivo;
  `info.schema` sigue `AOSCAD-0.0.1-DEV1`).
- Menu 3D opcion 6: registro de activos tabular (solo lectura).

### C — Migracion a services
- `aos_geom_punto_mas_cercano`, `aos_geom_fusionar_por_tolerancia`, `aos_geom_bbox`.
- `aos_units_factor_a_metros`; `aos_cad_unidades_dxf` delega conversion.
- Wrappers CAD (`aos_cad_meta_cercana`); helpers locales duplicados eliminados.
- README reales de geometry_3d/units; rutas unicidad extendidas.

### D — Contrato de puertos (solo datos)
- `aos_cad_puertos_derivar`: 2 puertos/tramo (`ENTRADA`/`SALIDA`), posiciones SI,
  `asset_id_componente`, sin logica 3D.
- Documentacion `LEEME_ASSET_ID_Y_PUERTOS.md`.

### Testing
- Nuevos: `test_aos_asset_identity`, `test_aos_geom_servicios`,
  `test_aos_cad_asset_roundtrip`, `test_aos_cad_puertos_contrato`.
- Fixture `demo_legacy_sin_asset.aoscad` (DEV1 sin activos/asset_id).
- Ampliados: `test_aos_cad_roundtrip_ids`, `test_aos_cad_step`.
- Registro en `VERIFICAR_AOSCAD_0_0_1_DEV1` (servicios) y `VERIFICAR_CAD_TOPO`
  (CAD + archivos requeridos).

## Limitaciones remanentes
- Sin logica 3D de puertos, conexiones ni interferencias (Sprint 6).
- Visor 3D / placement STEP / indice geometrico real (Sprint 5).
- Geometria interna de bloques aun no expandida a tablas.
- Equipos activos sin curva: solo advertencia (Sprint 3).
- Solver de lazos Kirchhoff: roadmap (Sprint 4 / HYD_LOOP).
- `cad_topo` permanece en `src/modulos` (movimiento a workbenches: 0.2.0).
- El export `*_AOS_REV` reescribe meta `ID=` en tramos, pero el TEXT `ID=`
  cercano a INSERT de equipo puede no reexportarse; la identidad estable del
  bloque ante REV sin memoria de `id_index` se apoya en `INSERT:bloque:x:y`.

## Estado DEV1
Se mantiene `PROTOTIPO_NO_VALIDADO`. No hay promocion de madurez en R11.

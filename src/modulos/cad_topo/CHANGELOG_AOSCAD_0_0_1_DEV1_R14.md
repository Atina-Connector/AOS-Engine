# CHANGELOG AOSCAD 0.0.1 DEV1 R14

## Resumen

Sprint 5: indice geometrico STEP nativo (tabla de entidades, unidades SI por
contexto, jerarquia NAUO, placement, bbox por cierre de referencias), escena 3D
como dato puro, visor 3D headless, vinculo bidireccional `asset_id` ↔
`geometry_id`, y verificador cruzado opcional por FreeCADCmd.

Estado AOSCAD permanece **DEV1 / PROTOTIPO_NO_VALIDADO**.
**No hay promocion a BETA.** Opciones 8–10 del menu 3D siguen `[ROADMAP]`
(Sprint 6). `info.schema` sigue exactamente `AOSCAD-0.0.1-DEV1`.
`result_overlay` queda pendiente de Sprint 6 en `aos_services_0_1_9.json`.

## Cambios

### Indice STEP (Linea A)

- `aos_step_tabla_entidades` — lexico `#id` → tipo/args/refs (multilinea,
  entidades complejas, strings con `#`).
- `aos_step_unidades` — factor a metros por contexto.
- `aos_step_indice_geometrico` — productos, NAUO, placement, bbox, `geometry_id`.
- `aos_geom_axis2_matriz`, `aos_geom_transformar_bbox` en `services/geometry_3d`.
- `aos_step_leer` / `aos_cad_importar_step` ampliados de forma **aditiva**
  (inventario y `asset_id` intactos).

### Escena y visor (Linea B)

- `aos_cad_escena_3d` — dato puro (red, pozo, cajas STEP); sin graficos.
- `aos_cad_visor_3d` — render separado, invisible + PNG.
- `aos_cad_escena_seleccionar` — seleccion por criterio → datos.
- `aos_step_indice_freecad` + `herramientas/aos_step_indice_freecad_export.py`
  (solo tests; AVISO si FreeCAD falta).

### Vinculo y menu (Linea C)

- `aos_cad_vincular_asset_3d` — mapa bidireccional persistido.
- Opcion 7 del menu 3D: vinculo real + escena/visor.
- Opcion 5 del menu 3D / CAD sync 3: traer STEP exportado desde FreeCAD.
- Editar STEP abre copia en `intercambio/cad/edicion/` (no pisa fixtures);
  FreeCAD debe **Exportar STEP** sobre esa copia para que mtime dispare recarga.
- Invalidacion de escena por edicion de tablas, mtime DXF/STEP y traer export
  (`ESCENA_3D_INVALIDADA_POR_EDICION`).
- `aos_cad_step_copia_edicion`, `aos_cad_traer_step_exportado`,
  `aos_cad_invalidar_escena_3d`.

### Fixtures y tests (Linea D)

- Fixtures: `demo_aos_sin_ensamble.step`, `demo_aos_ensamble_repetido.step`
  (`demo_aos_equipment.step` dorado de ensamble, sin tocar).
- Tests nuevos: `test_aos_cad_step_indice`, `test_aos_cad_visor_3d`,
  `test_aos_cad_vinculo_asset_3d`.
- `test_aos_cad_step` ampliado aditivamente (asserts congelados intactos).

### Registro y documentacion (Linea E)

- Registro en `VERIFICAR_CAD_TOPO`, `VERIFICAR_AOSCAD_0_0_1_DEV1`,
  `aos_cad_verificar_rutas_unicas`, `aos_services_0_1_9.json`.
- `DIAGNOSTICAR_EDITORES_AOSCAD`: FreeCAD = edicion STEP + CLI real;
  ausencia de `occt-draw` en Windows esperada.
- Capability contract: indice STEP nativo vs OCCT futuro.
- Este LEEME, extension R14 de `CONTRATO_VIEWER_AOSCAD.txt`,
  `VERSION_AOSCAD.txt` R14, README `geometry_3d`.

## Items nuevos

Ver catalogo completo en `LEEME_INDICE_STEP_Y_VISOR_3D.md`
(`STEP_*`, `AXIS2_*`, `ESCENA_*`, `VINCULO_3D_*`).

## Limitaciones remanentes (explicitas)

- Sin BRep, superficies, tessellation, booleanas ni medicion exacta.
- Open CASCADE como motor interno de AOS: **no adoptado**; FreeCAD es el
  editor y el cruzado opcional. `occt-draw` suelto no es requisito.
- Sin result_overlay / coloreo fisico 3D (Sprint 6).
- Sin interferencias, puertos 3D ni escena federada (Sprint 6).
- Sin sincronizacion 2D/3D completa ni promocion BETA (Sprint 7).
- Sin escritura de jerarquia/placements hacia STEP.
- Ensambles multiarchivo no soportados.
- Visor sin picking interactivo.

## Schema

`info.schema` permanece exactamente `AOSCAD-0.0.1-DEV1`.
Indice, escena y `geometry_id` entran por puertas aditivas del schema.
`.aoscad` legacy (p. ej. `demo_legacy_sin_asset.aoscad`) abren sin error.

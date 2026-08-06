# CHANGELOG AOSCAD 0.0.1 DEV1 R16

> **NO BETA — pendiente revision y aprobacion del jefe**

## Resumen

Sprint 7: sincronizacion 2D/3D completa (DXF/STEP), edicion DXF segura
simetrica a STEP, invalidacion atomica de simulacion y derivados,
recursos visuales reales para perfil ENRIQUECIDO, contrato Viewer
actualizado, hardening/auditoria estatica y etiqueta de candidato a
revision del jefe.

Estado AOSCAD permanece **DEV1 / PROTOTIPO_NO_VALIDADO**.
**No hay promocion a BETA.** Etiqueta: `CANDIDATO_REVISION_JEFE` /
`PROMOCION=PENDIENTE_APROBACION_JEFE`.
`info.schema` sigue exactamente `AOSCAD-0.0.1-DEV1`.
`sync_2d_3d` y `visual_resources` = `DELIVERED_SPRINT7` en
`aos_services_0_1_9.json`.
`promotion` = `NO_BETA_CANDIDATO_R16`.
Workbench CAD: version R16 candidato, `state` = `DEV1`.
Solvers HYD_TREE/HYD_DOMAIN = `DEV1`; HYD_LOOP = `DESARROLLO` (sin cambio).

## Cambios

### Invalidacion unica (T2)

- `aos_cad_invalidar_simulacion` — helper atomico: estado
  `INVALIDADA_POR_EDICION`, limpia resultados vigentes, marca escena /
  vinculo / overlay / recursos no vigentes, item trazable.
- Integrado en editar campo, recarga mtime, traer STEP, import DXF/STEP
  e hidraulica/configuracion.
- `aos_aoscad_leer` respeta estado persistido; no fuerza `EJECUTADA`
  solo porque exista `motor`.

### Sincronizacion 2D/3D (T3)

- `aos_cad_sincronizar_2d_3d` — orquestador con orden fijo (mtime →
  reimport → invalidar → topologia/vinculo → escena → reporte).
- Menu: "Sincronizar representaciones 2D y 3D" pasa a `[ACTIVO]`.
- Idempotencia: segunda sync sin cambios no altera ids ni mtimes.

### Edicion DXF segura (T4)

- `aos_cad_dxf_copia_edicion` — copia bajo `intercambio/cad/edicion`;
  nunca usa fixtures de `datos/ejemplos/cad` como destino editable.
- LibreCAD y FreeCAD comparten el mismo modelo de seguridad.

### Recursos visuales ENRIQUECIDO (T5–T6)

- `aos_aoscad_generar_recursos_visuales` — PNG regenerables
  (`PLANO_2D_RED`, `VISTA_3D_ESCENA`, `VISTA_3D_OVERLAY`); SIMPLE sin
  payload visual.
- Persistencia en escritura ENRIQUECIDO; rutas relativas; vigencia e
  invalidacion; contrato Viewer actualizado.
- Tablas y resultados siguen siendo fuente primaria; PNG son secundarios.

### Tests y hardening (T7–T8)

- Nuevos: `test_aos_cad_sincronizacion_2d_3d`,
  `test_aos_aoscad_recursos_visuales`, `test_aos_cad_dxf_edicion_externa`,
  `test_aos_cad_auditoria_estatica`.
- Regresion R10–R15 extendida aditivamente; fixtures inmutables.
- Auditoria: sombras, ausencia de binarios legacy de persistencia, `rand` en ids, estados schema, cleanup.

### Version y manifests (T9)

- `VERSION_AOSCAD.txt` = R16 + `REVISION` / `PROMOCION` / `SPRINT7`.
- `AOS_VERSION.txt`: AOSCAD integrado R16 candidato (sigue DEV1).
- Este changelog y `LEEME_SINCRONIZACION_Y_RECURSOS_R16.md`.

## Limitaciones remanentes (explicitas)

- **Sin promocion a BETA** — requiere aprobacion escrita del jefe
  (fuera de este sprint).
- Interferencia solo AABB (conservadora); sin BRep/OCCT.
- Overlay monofasico; sin picking interactivo.
- Recursos visuales dependen de gnuplot/visores headless; fallo de PNG
  no corrompe `.aoscad` pero puede dejar item informativo.
- Sin escritura de placements/jerarquia hacia STEP; ensambles
  multiarchivo no soportados.
- Migracion de `cad_topo` a `src/workbenches/cad` (contrato 0.2.0):
  fuera de alcance.
- HYD_LOOP permanece `DESARROLLO` (no BETA, no DEV1 maduro).

## Schema

`info.schema` permanece exactamente `AOSCAD-0.0.1-DEV1`.
Extensiones Sprint 7 son aditivas y compatibles con `.aoscad` legacy.

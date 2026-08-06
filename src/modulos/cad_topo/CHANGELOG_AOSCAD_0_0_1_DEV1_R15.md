# CHANGELOG AOSCAD 0.0.1 DEV1 R15

## Resumen

Sprint 6: puertos y conexiones 3D (materializacion del contrato Sprint 2),
deteccion de interferencias por AABB, escena federada pozo-red-instalaciones
y overlay de resultados fisicos sobre la escena 3D. Opciones 8-10 del menu
3D pasan a `[ACTIVO]`.

Estado AOSCAD permanece **DEV1 / PROTOTIPO_NO_VALIDADO**.
**No hay promocion a BETA** (queda para Sprint 7).
`info.schema` sigue exactamente `AOSCAD-0.0.1-DEV1`.
`result_overlay` = `DELIVERED_SPRINT6` en `aos_services_0_1_9.json`,
junto con `ports_3d`, `interference` y `federated_scene`.
`promotion` = `NO_BETA_SPRINT6`.

## Cambios

### Puertos y conexiones 3D (Linea A)

- `aos_cad_puertos_3d` — materializa `tablas_entrada.puertos` con posicion 3D
  finita (z del nodo, `geometry_id` del vinculo). Item
  `PUERTO_3D_SIN_POSICION` si queda indeterminada; nunca se fuerza a 0.
- `aos_cad_conexiones_3d` — emparejamiento por `nodo_ref` / proximidad;
  estados `CONECTADA` / `INFERIDA_POR_PROXIMIDAD` / `ABIERTA`; claves `CNX_*`.
- `aos_cad_validar_conectividad_3d` — contraste contra `topologia.aristas`
  (items `CONEXION_3D_INCONSISTENTE_2D`, `PUERTO_3D_HUERFANO`,
  `CONEXION_3D_DUPLICADA`). No modifica la topologia 2D.
- `aos_cad_escena_3d`: opcion aditiva `incluir_puertos` (default `false`)
  para tipos `PUERTO` / `CONEXION` sin alterar `n_objetos` por defecto.

### Interferencias AABB (Linea B)

- `aos_geom_bbox_solape` — servicio puro (solape, volumen, distancia minima).
- `aos_cad_interferencias` — pares en conflicto; exclusion de mismo
  `geometry_id` y pares NODO-TRAMO conectados; umbral y tope `max_pares`.
- `aos_cad_interferencias_mostrar` — tabla como salida primaria.
- Fixture `demo_aos_interferencia.step` (solape verificable a mano).
- **Explicitamente conservador**: la bbox sobreestima; no es colision BRep
  ni medicion exacta.

### Escena federada (Linea C)

- `aos_escena_federada` (services/geometry_3d) — compone red + pozo +
  instalaciones con `fuente_federada`, namespacing de ids e items
  `FEDERACION_*`. Criterio de seleccion aditivo por fuente.

### Overlay de resultados (Linea D)

- `aos_cad_overlay_resultados` — mapea `tablas_resultados` a
  `overlay.valor` / magnitud / unidad / clase / `color_rgb`.
  Sin recalcular fisica. Objetos sin dato: `SIN_DATO` (nunca como 0).
- `aos_cad_visor_3d` usa `color_rgb` si existe; sin overlay el render
  permanece identico a R14.

### Menu, registro y version (Linea E)

- Menu 3D opciones 8 / 9 / 10: `[ACTIVO]` con submenus; se elimina
  `aos_modulo_no_disponible` del case `{8,9,10}`.
- Registro en `VERIFICAR_CAD_TOPO`, `VERIFICAR_AOSCAD_0_0_1_DEV1`,
  `aos_cad_verificar_rutas_unicas`.
- `VERSION_AOSCAD.txt` = R15 + `SPRINT6=...`.
- `AOS_VERSION.txt`: AOSCAD integrado actualizado de R9.1 a R15.
- Este changelog y `LEEME_PUERTOS_INTERFERENCIAS_Y_OVERLAY_3D.md`.

### Tests (Linea T)

- Nuevos: `test_aos_cad_puertos_conexiones`, `test_aos_cad_interferencias`,
  `test_aos_escena_federada`, `test_aos_cad_overlay_3d`.
- Ampliados aditivamente: `test_aos_cad_visor_3d`,
  `test_aos_cad_puertos_contrato` (asserts congelados intactos).

## Items nuevos

Ver catalogo completo en `LEEME_PUERTOS_INTERFERENCIAS_Y_OVERLAY_3D.md`
(`PUERTO_3D_*`, `CONEXION_3D_*`, `INTERFERENCIA_*`, `FEDERACION_*`,
`OVERLAY_*`).

## Limitaciones remanentes (explicitas)

- **Sin promocion a BETA** (Sprint 7).
- Interferencia solo AABB: conservadora; sin BRep/OCCT, superficies,
  tessellation ni booleanas.
- Overlay monofasico: sin multifasico por fases ni overlay sobre geometria
  STEP interna (solo bbox/ancla).
- Sin sincronizacion 2D/3D completa ni recursos visuales del `.aoscad`
  (Sprint 7).
- Sin picking interactivo en el visor; seleccion por criterio de datos.
- Sin escritura de placements/jerarquia hacia STEP; ensambles multiarchivo
  no soportados.
- Migracion de `cad_topo` a `src/workbenches/cad` (contrato 0.2.0): fuera
  de alcance.

## Schema

`info.schema` permanece exactamente `AOSCAD-0.0.1-DEV1`.
Puertos 3D, interferencias, federacion y overlay entran por puertas
aditivas. `.aoscad` legacy (p. ej. `demo_legacy_sin_asset.aoscad`) abren
sin error y sin advertencias nuevas.

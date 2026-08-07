# LEEME — Indice geometrico STEP y visor 3D (Sprint 5 / R14)

Documentacion del indice geometrico STEP nativo, la escena 3D como dato puro,
el visor headless y el vinculo `asset_id` ↔ `geometry_id` en AOS CAD
(`cad_topo`). Plataforma: GNU Octave. `info.schema` = `AOSCAD-0.0.1-DEV1`.

## Que se interpreta (y que no)

**Si (cierre de referencias, sin BRep):**

| Cadena | Entidades |
|--------|-----------|
| Producto → forma | `PRODUCT`, `PRODUCT_DEFINITION_FORMATION`, `PRODUCT_DEFINITION`, `PRODUCT_DEFINITION_SHAPE`, `SHAPE_DEFINITION_REPRESENTATION` |
| Representaciones | `SHAPE_REPRESENTATION`, `ADVANCED_BREP_SHAPE_REPRESENTATION`, `MANIFOLD_SURFACE_SHAPE_REPRESENTATION`, `GEOMETRICALLY_BOUNDED_*` (desconocidas: se registran sin abortar) |
| Jerarquia | `NEXT_ASSEMBLY_USAGE_OCCURRENCE` (NAUO) |
| Placement | `CONTEXT_DEPENDENT_SHAPE_REPRESENTATION` → `ITEM_DEFINED_TRANSFORMATION` → `AXIS2_PLACEMENT_3D` → `CARTESIAN_POINT` / direcciones |
| Unidades | `LENGTH_UNIT` / `SI_UNIT` / `NAMED_UNIT` / `CONVERSION_BASED_UNIT` por contexto |
| BBox | `CARTESIAN_POINT` alcanzables por DFS desde la representacion |

**No (fuera de alcance):** caras, aristas, superficies, tessellation, booleanas,
secciones, medicion exacta, BRep completo. Curvas acotadas por puntos de
control → bbox **conservadora** (aproximacion documentada).

Parser lexico: `aos_step_tabla_entidades` (sentencias `;`, multilinea, entidades
complejas `( TIPO_A(...) TIPO_B(...) )`, `#` dentro de strings ignorado).

## Cadena de ejemplo (`demo_aos_equipment.step`)

1. Raiz `#7 PRODUCT('Unnamed',...)` → formacion → definicion `#5` → forma →
   `SHAPE_REPRESENTATION` `#10`.
2. Dos NAUO: `#196` y `#268` (padre `#5`).
3. Placement ligado a cada NAUO via `CONTEXT_DEPENDENT_SHAPE_REPRESENTATION` +
   `ITEM_DEFINED_TRANSFORMATION`.
4. Unidades: `SI_UNIT(.MILLI.,.METRE.)` → factor `1e-3`.
5. Ocurrencia 1: origen absoluto `(0.003, 0, 0)` m; ocurrencia 2: origen.
6. Inventario congelado: `n_entidades=277`, `n_productos=3`, `n_solidos=2`.

## Unidades a SI

- Factor **por contexto de representacion**, no global silencioso.
- `MILLI` → `1e-3`, `CENTI` → `1e-2`, sin prefijo → `1`.
- Items: `STEP_UNIDADES` (INFO), `STEP_UNIDADES_AUSENTES` /
  `STEP_UNIDADES_INCONSISTENTES` (ADVERTENCIA).
- Todo placement/bbox del indice esta en metros.

## `geometry_id` vs `asset_id`

- `asset_id` de producto STEP: clave estable `STEP:<product_name>` (Sprint 2).
  **No se toca.** Dos ocurrencias del mismo producto comparten `asset_id`.
- `geometry_id` (campo opcional del contrato de identidad): ruta de ensamble
  determinista `STEPOCC:<nombre_archivo>:<ruta_de_nauo>`.
- Relacion **uno a muchos**: un `asset_id` → varios `geometry_id`.
- Vinculo: `aos_cad_vincular_asset_3d` → `modelo.vinculo_3d` +
  `geometry_id` / `geometry_ids` en `activos`.

## Escena y render (separados)

| Funcion | Rol |
|---------|-----|
| `aos_cad_escena_3d` | Dato puro: red (NODO/TRAMO), pozo (POZO), STEP (EQUIPO_3D). Sin graficos. Determinista. |
| `aos_cad_visor_3d` | Solo dibuja; modo invisible + export PNG; sin unidades ni fisica. |
| `aos_cad_escena_seleccionar` | Seleccion por `asset_id` / `geometry_id` / tipo → datos. |

Tests nuevos **no** usan `AOS_CAD_SKIP_VISOR` (solo el flujo 2D heredado).

## FreeCAD / OCCT

- Camino de produccion del indice: parser Octave.
- FreeCAD: editor externo STEP + `FreeCADCmd` verificador cruzado opcional
  (`aos_step_indice_freecad`, solo tests; AVISO si falta).
- **Edicion FreeCAD**: AOS abre una **copia de trabajo** en
  `intercambio/cad/edicion/` (no pisa `datos/ejemplos`). FreeCAD no modifica
  el `.step` al guardar el documento: hay que **Exportar STEP** sobrescribiendo
  esa copia. Luego `CAD -> 6 -> 1 Recargar si cambio`. Si el export uso otro
  nombre: `aos_cad_traer_step_exportado` (menu `6 -> 3` o `3D Core -> 5`).
- `occt-draw` suelto: ausente en Windows por construccion; no es requisito.

## Catalogo de items nuevos

| Codigo | Severidad | Origen |
|--------|-----------|--------|
| `STEP_UNIDADES` | INFO | unidades |
| `STEP_UNIDADES_AUSENTES` | ADVERTENCIA | unidades |
| `STEP_UNIDADES_INCONSISTENTES` | ADVERTENCIA | indice |
| `STEP_SIN_PRODUCTOS` | ADVERTENCIA | indice |
| `STEP_SIN_ENSAMBLE` | INFO | indice (pieza unica) |
| `STEP_ENSAMBLE_CICLICO` | ADVERTENCIA | indice |
| `STEP_REFERENCIA_COLGADA` | ADVERTENCIA | tabla |
| `STEP_INDICE_PARCIAL` | ADVERTENCIA | leer/indice |
| `STEP_BBOX_INDETERMINADA` | ADVERTENCIA | indice (sin ceros falsos) |
| `STEP_ARCHIVO_GRANDE_INDICE_OMITIDO` | ADVERTENCIA | leer |
| `AXIS2_NO_ORTOGONAL` / `AXIS2_DEGENERADO` | adv. geom | `aos_geom_axis2_matriz` |
| `ESCENA_SELECCION_VACIA` | INFO | seleccionar |
| `ESCENA_3D_INVALIDADA_POR_EDICION` | ADVERTENCIA | edicion/mtime/traer export |
| `VINCULO_3D_ASSET_SIN_GEOMETRIA` | ADVERTENCIA | vinculo |
| `VINCULO_3D_GEOMETRIA_SIN_ASSET` | ADVERTENCIA | vinculo |

API edicion FreeCAD: `aos_cad_step_copia_edicion`, `aos_cad_traer_step_exportado`,
`aos_cad_invalidar_escena_3d`.

## Limitaciones remanentes

- Sin BRep, interferencias, puertos 3D, result_overlay (Sprint 6).
- Sin sincronizacion 2D/3D completa ni promocion BETA (Sprint 7).
- Sin escritura de placements/jerarquia hacia STEP.
- Ensambles multiarchivo / referencias externas: no soportados.
- Visor sin picking interactivo; seleccion solo por criterio de datos.
- Opciones menu 3D 7–9 siguen `[ROADMAP]` (Sprint 6).

## Fixtures

- `demo_aos_equipment.step` — dorado de ensamble / placement / unidades.
- `demo_aos_sin_ensamble.step` — pieza unica, factor 1.
- `demo_aos_ensamble_repetido.step` — dos ocurrencias, mismo `asset_id`.

## API principal

```text
aos_step_tabla_entidades / aos_step_unidades / aos_step_indice_geometrico
aos_step_leer (aditivo: modelo.indice_geometrico)
aos_geom_axis2_matriz / aos_geom_transformar_bbox
aos_cad_escena_3d / aos_cad_visor_3d / aos_cad_escena_seleccionar
aos_cad_vincular_asset_3d
aos_step_indice_freecad  (+ herramientas/aos_step_indice_freecad_export.py)
```

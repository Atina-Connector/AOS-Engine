# AOS Geometry 3D service

Servicio compartido de primitivas geometricas 2D/3D para AOS 0.1.9 / 0.2.0.
Consumido por `cad_topo` via wrappers delgados (`aos_cad_*`); los nombres de
archivo del servicio (`aos_geom_*`) son distintos para respetar el namespace plano
de `addpath(genpath(src))`.

## API

### `aos_geom_punto_mas_cercano(puntos, x, y, tol)`

- **Entrada**: `puntos` = cell de structs con `.x`/`.y`, o matriz Nx2/Nx3; punto consulta `(x,y)`; `tol` opcional.
- **Salida**: `[idx, dmin]` — indice 1-based del punto mas cercano y distancia.
- Si `tol` esta vacio o es `Inf`, no filtra. Si `dmin > tol`, `idx = []`.
- Empates: gana el primero (`d < dmin`).

### `aos_geom_fusionar_por_tolerancia(nodos, tol)`

- **Entrada**: cell de nodos con `.id`, `.x`, `.y` (y opcional `.estado_conexion`, `.tipo`); tolerancia en metros.
- **Salida**: `[nodos_out, mapa]` — nodos fusionados y mapa de remapeo `mapa.(id_orig) = id_canonico`.
- Preferir `CONFIRMADA`; propagar `tipo` distinto de `JUNCTION`.

### `aos_geom_bbox(puntos)`

- **Entrada**: cell de structs (`.x`/`.y`/[`.z`]) o matriz Nx2/Nx3.
- **Salida**: `[bbox, centroide]` — `bbox` con `xmin`/`xmax`/`ymin`/`ymax` (y `zmin`/`zmax` si hay Z); `centroide` = `[cx cy]` o `[cx cy cz]`.

### `aos_geom_axis2_matriz(origen_xyz, eje_z, dir_x)` (Sprint 5)

- **Entrada**: origen y dos direcciones de un `AXIS2_PLACEMENT_3D` (defaults `z=[0 0 1]`, `x=[1 0 0]`).
- **Salida**: `[T, adv]` — matriz homogenea 4x4 ortonormal (Gram-Schmidt), determinante positivo; `adv` cell con `AXIS2_NO_ORTOGONAL` y/o `AXIS2_DEGENERADO`.
- **Independiente de STEP**: no parsea archivos; solo geometria.

### `aos_geom_transformar_bbox(bbox_in, T)` (Sprint 5)

- **Entrada**: AABB (`xmin`/`xmax`/`ymin`/`ymax` y opcional Z) y matriz 4x4.
- **Salida**: nueva AABB alineada a ejes tras transformar los ocho vertices.
- Correcto bajo rotacion (no transforma solo dos esquinas).

## Contrato de identidad (referencia)

Ver `aos_asset_identity_0_2_0.json` en este directorio (campos requeridos de activo).
Las funciones `aos_asset_*` viven aqui cuando estan implementadas (Linea A).
Campo opcional `geometry_id`: identidad de ocurrencia 3D (Sprint 5); no altera
los `required` del contrato.

## Notas

- Solo GNU Octave. Sin literales de motor no-objetivo.
- No mueve solvers; es geometria pura + soporte de identidad.
- El parseo STEP vive en `cad_topo`; este servicio solo aporta primitivas reutilizables.

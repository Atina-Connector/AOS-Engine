# LEEME — Puertos, interferencias, escena federada y overlay 3D (Sprint 6 / R15)

Documentacion de puertos/conexiones 3D, deteccion de interferencias por AABB,
escena federada multi-fuente y overlay de resultados fisicos sobre 3D en
AOS CAD (`cad_topo` + `services/geometry_3d`). Plataforma: GNU Octave.
`info.schema` = `AOSCAD-0.0.1-DEV1`.

Estado: **DEV1 / PROTOTIPO_NO_VALIDADO**. **No hay promocion a BETA**
(Sprint 7). Menu 3D opciones 8-10: `[ACTIVO]`.

## Que hace (y que no)

**Si:**

| Capacidad | Rol |
|-----------|-----|
| Puertos 3D | Materializa el contrato Sprint 2 (`tablas_entrada.puertos`) con posicion 3D finita |
| Conexiones 3D | Empareja puertos por `nodo_ref` / proximidad; valida vs topologia 2D |
| Interferencias | Solape AABB y distancia minima entre bbox de la escena |
| Escena federada | Compone red + pozo + instalaciones con namespacing de ids |
| Overlay | Mapea `tablas_resultados` a `overlay` / `color_rgb` (sin fisica) |

**No:**

- BRep, OCCT, superficies, tessellation, booleanas ni colision geometrica exacta.
- Recalculo de presiones/caudales ni interpolacion entre nodos.
- Promocion DEV1 -> BETA; sincronizacion 2D/3D completa (Sprint 7).
- Picking interactivo; overlay multifasico; escritura de placements STEP.

## Puertos y conexiones 3D

1. `aos_cad_puertos_3d(modelo)` — hereda `z` del nodo referido y
   `geometry_id` del vinculo 3D. Claves `PTO_*`. Item
   `PUERTO_3D_SIN_POSICION` (ADVERTENCIA) si la posicion queda
   indeterminada; **nunca se fuerza a 0**.
2. `aos_cad_conexiones_3d(puertos_3d)` — estados
   `CONECTADA` / `INFERIDA_POR_PROXIMIDAD` / `ABIERTA`. Claves `CNX_*`.
   Orden estable por indice de puerto. Tolerancia default `0.05 m`.
3. `aos_cad_validar_conectividad_3d(tabla, modelo)` — solo reporta;
   no modifica `topologia.aristas`.
4. Escena: `opciones.incluir_puertos` (default `false`) agrega tipos
   `PUERTO` / `CONEXION` sin alterar `n_objetos` del caso Sprint 5.

El contrato solo-datos del Sprint 2 (`tablas_entrada.puertos`) permanece
intacto.

## Interferencias AABB (conservadoras)

```text
aos_geom_bbox_solape(bbox_a, bbox_b)
  -> hay_solape, volumen_solape_m3, distancia_m

aos_cad_interferencias(escena, opciones)
  -> tabla_interferencias, items

aos_cad_interferencias_mostrar(tabla, items)   % tabla = salida primaria
```

Reglas:

- Excluye mismo `geometry_id` y pares NODO-TRAMO conectados por `nodo_ref`.
- Bbox indeterminada -> item `INTERFERENCIA_BBOX_INDETERMINADA`, no se asume 0.
- `distancia_minima_m` (default 0): solo solape, o tambien PROXIMIDAD.
- `max_pares`: tope O(n^2) con item `INTERFERENCIAS_TRUNCADAS`.
- Orden estable por `(indice_a, indice_b)`.

**Limitacion explicita:** la AABB sobreestima. Un par reportado como
`SOLAPE` puede no colisionar en geometria real. No es medicion exacta.

## Escena federada

```text
aos_escena_federada(fuentes, opciones)
  fuentes.red / .pozo / .instalaciones  (cada una opcional)
  orden fijo: red -> pozo -> instalaciones
```

Cada objeto lleva `fuente_federada` en `{RED, POZO, INSTALACIONES}` e `id`
namespaced `FUENTE:id_local`. `asset_id` presente en mas de una fuente se
reporta (`FEDERACION_ASSET_DUPLICADO`); **no se fusiona en silencio**.
`aos_cad_escena_seleccionar` sigue funcionando; criterio aditivo
`fuente_federada` disponible.

## Overlay de resultados

```text
aos_cad_overlay_resultados(escena, tablas_resultados, opciones)
```

Mapeo por identidad:

| Tipo escena | Fuente | Magnitud | Unidad |
|-------------|--------|----------|--------|
| NODO | `tablas_resultados.nodos.presion_Pa` | PRESION | Pa |
| TRAMO | `tablas_resultados.tramos.caudal_liquido_m3s` | CAUDAL | m3/s |

- Valor almacenado **identico** al de la tabla (sin reescala).
- Sin resultado: `overlay.estado='SIN_DATO'`, color neutro (nunca como 0).
- Escala de color: min/max de la tabla + `n_bins` fijo (default 8).
- Visor: si el objeto trae `color_rgb`, se usa; si no, colores por tipo
  identicos a R14.

## Catalogo de items nuevos

| Codigo | Severidad | Origen |
|--------|-----------|--------|
| `PUERTO_3D_SIN_POSICION` | ADVERTENCIA | puertos_3d |
| `CONEXION_3D_INCONSISTENTE_2D` | ADVERTENCIA | validar_conectividad |
| `PUERTO_3D_HUERFANO` | ADVERTENCIA | validar_conectividad |
| `CONEXION_3D_DUPLICADA` | ADVERTENCIA | validar_conectividad |
| `INTERFERENCIA_BBOX_INDETERMINADA` | ADVERTENCIA | interferencias |
| `INTERFERENCIAS_TRUNCADAS` | ADVERTENCIA | interferencias |
| `FEDERACION_FUENTE_AUSENTE` | INFO | escena_federada |
| `FEDERACION_ASSET_DUPLICADO` | ADVERTENCIA | escena_federada |
| `FEDERACION_ASSET_INCONSISTENTE` | ADVERTENCIA | escena_federada |
| `OVERLAY_SIN_DATO` | INFO | overlay_resultados |

## Fixtures

- `demo_aos_red_ramificada.dxf` — puertos/conexiones (2 puertos por tramo).
- `demo_aos_interferencia.step` — solape AABB conocido / verificable a mano.
- `demo_aos_sin_ensamble.step` — caso limpio de interferencias (0 pares).
- Fixtures Sprint 5 de escena/vinculo reutilizados para federacion y overlay.

## Menu 3D Core

| Opcion | Estado | Submenu |
|--------|--------|---------|
| 8 | `[ACTIVO]` | Puertos 3D / conexiones / validacion / interferencias / mostrar tabla |
| 9 | `[ACTIVO]` | Construir / ver / visor de escena federada |
| 10 | `[ACTIVO]` | Aplicar overlay / visor con `color_rgb` |

## API principal

```text
aos_cad_puertos_3d / aos_cad_conexiones_3d / aos_cad_validar_conectividad_3d
aos_geom_bbox_solape / aos_cad_interferencias / aos_cad_interferencias_mostrar
aos_escena_federada
aos_cad_overlay_resultados
aos_cad_escena_3d (opcion incluir_puertos, default false)
aos_cad_visor_3d (usa color_rgb si existe)
```

## Limitaciones remanentes (Sprint 7 y mas adelante)

- Sin promocion BETA ni paquete de entrega.
- Sin interferencia geometrica exacta (BRep/OCCT).
- Sin sincronizacion 2D/3D completa ni recursos visuales del `.aoscad`.
- Sin picking interactivo; seleccion solo por criterio de datos.
- Overlay multifasico / overlay sobre geometria STEP interna: fuera de alcance.
- Ensambles multiarchivo y escritura de placements hacia STEP: no soportados.
- Migracion `cad_topo` -> `src/workbenches/cad` (contrato 0.2.0): pendiente.

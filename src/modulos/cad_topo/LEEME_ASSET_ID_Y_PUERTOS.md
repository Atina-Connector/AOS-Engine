# Identidad asset_id y contrato de puertos (Sprint 2)

Documentacion de la identidad estable de activos y del contrato de puertos
solo-datos en AOS CAD (`cad_topo`). Plataforma objetivo: GNU Octave.

## Prioridad de clave estable

La clave que alimenta `asset_id` **no** usa el handle DXF. Prioridad:

| Prioridad | Origen | Forma de clave |
|-----------|--------|----------------|
| 1 | `id_estable` (metadato `ID=` en DXF) | `IDEST:<id_estable>` |
| 2 | Bloque INSERT (equipos) | `INSERT:<block_name>:<x>:<y>` |
| 3 | Producto STEP | `STEP:<product_name>` |
| 4 | Geometria canonica cuantizada (1e-3 m) | `NODO:<x>:<y>:<z>` / `TRAMO:<x1>:<y1>:<x2>:<y2>` (extremos ordenados) |
| 5 | Fallback auditable | `ID:<id_local>` + advertencia `ASSET_CLAVE_NO_ESTABLE` |

Formato del identificador: `AOS-<TIPO>-<hash8>`, con `TIPO` en
`NODO|TRAMO|EQUIPO|VALVULA|ACCESORIO|BC|CAMARA|RAMAL|ACCESO|STEP_PRODUCT`.

Servicio: `src/services/geometry_3d/aos_asset_*.m`.
Asignacion en tablas: `aos_cad_asignar_asset_ids` (tras merge de IDs en mapear).

## Advertencia: handle DXF NO participa

El `handle` DXF **no** entra en la clave estable ni en el `asset_id`.

Motivo: al exportar revision (`*_AOS_REV`) los handles se regeneran desde un
contador fijo. Si la identidad dependiera del handle, el ciclo
import → export → reimport romperia la continuidad de activos.

Usar siempre `id_estable`, bloque+posicion, nombre STEP o geometria cuantizada.

## Contrato de puertos (solo datos)

Tabla opcional:

```text
modelo.tablas_entrada.puertos
```

Derivacion: `aos_cad_puertos_derivar.m` — **dos puertos por tramo**
(origen = `ENTRADA`, destino = `SALIDA`).

Campos por puerto:

| Campo | Contenido |
|-------|-----------|
| `id` | `<tramo_id>_ENTRADA` / `<tramo_id>_SALIDA` |
| `tipo` | `ENTRADA` \| `SALIDA` |
| `posicion` | struct `x`, `y`, `z` (SI, metros) |
| `asset_id_componente` | `asset_id` del tramo |
| `nodo_ref` | `nodo_o` o `nodo_d` |
| `estado_conexion` | de `topologia.aristas` si existe; si no, `INFERIDA_POR_PROXIMIDAD` |

### Fuera de alcance (Sprint 6)

- Logica 3D de puertos y conexiones puerto–puerto
- Interferencias / bounding box entre componentes
- Validador de conectividad 3D

Este sprint solo fija la forma del dato y su trazabilidad con `asset_id`.

## Flujo de invocacion

1. Mapear objetos → merge IDs → asignar `asset_id` → derivar puertos
2. Construir topologia → re-derivar puertos (actualiza `estado_conexion`)

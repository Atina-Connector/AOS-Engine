# LEEME — Sincronizacion 2D/3D y recursos visuales (Sprint 7 / R16)

> **NO BETA — pendiente revision y aprobacion del jefe**

Documentacion de sincronizacion DXF/STEP 2D-3D, edicion DXF segura,
invalidacion atomica y recursos visuales ENRIQUECIDO en AOS CAD
(`cad_topo`). Plataforma: GNU Octave.
`info.schema` = `AOSCAD-0.0.1-DEV1`.

Estado: **DEV1 / PROTOTIPO_NO_VALIDADO**.
Revision: **CANDIDATO_REVISION_JEFE**.
Promocion: **PENDIENTE_APROBACION_JEFE** (no ejecutada).
**No hay promocion a BETA.**

## Que hace (y que no)

**Si:**

| Capacidad | Rol |
|-----------|-----|
| Invalidacion unica | Estado, resultados, escena, vinculo, overlay y recursos en un solo paso |
| Sync 2D/3D | Detecta mtime DXF/STEP, reimporta, invalida y reconstruye en orden fijo |
| Copia DXF | Edicion externa sobre copia bajo `intercambio/cad/edicion` |
| Recursos visuales | PNG regenerables en perfil ENRIQUECIDO; SIMPLE sin payload |
| Vigencia | Recursos/escena marcados obsoletos tras edicion; no se presentan como vigentes |

**No:**

- Promocion DEV1 → BETA (requiere aprobacion del jefe, tarea separada).
- BRep, OCCT, picking interactivo, escritura de placements STEP.
- Sustituir tablas/resultados por PNG (los recursos son secundarios).
- Cambiar `info.schema` ni estados de solvers HYD_* a BETA.

## Invalidacion atomica

```text
[modelo, items] = aos_cad_invalidar_simulacion(modelo, motivo, opciones)
% opciones.codigo = 'INVALIDADA_POR_EDICION'
% opciones.invalidar_escena / limpiar_resultados / invalidar_recursos
```

- Estado siempre schema-allowed (`INVALIDADA_POR_EDICION`).
- Motivos especificos (p.ej. configuracion) van en historial/item.
- Idempotente: reaplicar sobre ya invalidado no inventa resultados.

## Sincronizacion 2D/3D

```text
[ok, reporte] = aos_cad_sincronizar_2d_3d(opciones)
% opciones.forzar / reconstruir_topologia / reconstruir_vinculo
%        reconstruir_escena / incluir_puertos / silencioso
```

Orden fijo:

1. detectar mtime;
2. reimportar fuente cambiada;
3. invalidar simulacion y derivados;
4. reconstruir tablas/topologia si cambio DXF;
5. reconstruir indice/vinculo si cambio STEP;
6. reconstruir escena;
7. registrar mtime nuevo;
8. devolver reporte (`fuentes_cambiadas`, `acciones`, `items`,
   `requiere_recalculo`, `escena_vigente`, conteos).

Menu: opcion "Sincronizar representaciones 2D y 3D" = `[ACTIVO]`.

## Edicion DXF segura

```text
[copia, info] = aos_cad_dxf_copia_edicion(origen, opciones)
```

- Destino bajo `intercambio/cad/edicion`; nunca el fixture.
- Origen, copia y mtime se registran por separado.
- Copia ausente/truncada/ilegible → item; no destruye la sesion.

## Recursos visuales ENRIQUECIDO

```text
[recursos, items] = aos_aoscad_generar_recursos_visuales(modelo, opciones)
% opciones.incluir_2d / incluir_3d / incluir_overlay / visible / directorio
```

Ids deterministas (orden fijo):

- `PLANO_2D_RED`
- `VISTA_3D_ESCENA`
- `VISTA_3D_OVERLAY` (solo si hay resultados vigentes)

Contrato minimo por recurso: `id`, `tipo`, `titulo`, `formato=PNG`,
`unidades`, `origen=REGENERABLE_AOSCAD`, `ruta_relativa`, `vigente`,
`asset_scope`.

Prioridad Viewer: tablas > validaciones > geometria > recursos.
Edicion invalida recursos persistidos (`vigente=false` / `obsoletos=true`).

## Tests focalizados

- `test_aos_cad_sincronizacion_2d_3d`
- `test_aos_aoscad_recursos_visuales`
- `test_aos_cad_dxf_edicion_externa`
- `test_aos_cad_auditoria_estatica`

## Limitaciones remanentes (explicitas)

- **NO BETA** — etiqueta candidato; madurez sigue `PROTOTIPO_NO_VALIDADO`.
- Interferencias AABB conservadoras (Sprint 6); sin colision BRep.
- Overlay monofasico; sin picking 3D.
- PNG requieren entorno headless (gnuplot/visores); fallo no corrompe
  `.aoscad`.
- HYD_LOOP sigue `DESARROLLO`.
- Paquete de evidencia y puertas finales: tareas posteriores del sprint
  (fuera de esta etiqueta).

## Schema

`info.schema` = `AOSCAD-0.0.1-DEV1` (sin cambio).
`.aoscad` legacy sin `recursos_visuales` abren sin error ni advertencias
nuevas.

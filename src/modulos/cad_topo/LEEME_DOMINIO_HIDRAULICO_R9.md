# Modulo de dominio hidraulico selectivo R9

## Uso rapido

1. Importe el DXF y prepare el modelo hidraulico.
2. Entre en `SIMULACION HIDRAULICA`.
3. Seleccione `SELECCIONAR DOMINIO`.
4. Toque el nodo inicial y luego el nodo final, o escriba sus IDs.
5. Si hay varios caminos, elija uno o conserve todos como anillo/subred.
6. Para un camino simple, defina presion de entrada y caudal de salida.
7. Valide y ejecute la simulacion.
8. Guarde el `.aoscad` simple o enriquecido.

## Contrato de datos

La seleccion se almacena en:

```text
tablas_entrada.dominios_hidraulicos
```

Cada fila contiene como minimo:

```text
id
tipo = SELECTED_PATH | LOOP_SUBNETWORK
nodo_inicio
nodo_fin
nodos_seleccionados
tramos_seleccionados
caminos
longitud_total_m
condicion_extremos
activo
estado
```

Las condiciones de borde generadas incluyen `dominio_id`. Cuando existe un
dominio activo, el solver usa primero las condiciones asociadas a ese dominio.

## Regla no destructiva

Seleccionar un dominio no borra tramos, nodos ni metadatos del DXF. Se crea una
vista local filtrada para el solver. La red completa sigue disponible para otra
seleccion y queda guardada dentro del `.aoscad`.

## Preparacion para anillos

Cuando existen varios caminos entre los extremos, se puede elegir `TODOS`.
AOSCAD guarda una `LOOP_SUBNETWORK` con los caminos detectados y la union de sus
tramos. R9 no la ejecuta: la deja lista para el solver futuro que debera cumplir:

```text
Balance nodal: suma Q = 0
Balance de lazo: suma deltaP = 0
```

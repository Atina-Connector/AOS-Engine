# AOSCAD 0.0.1 DEV1 R9 - Dominio hidraulico selectivo

Fecha: 2026-07-25
Motor objetivo: GNU Octave
Estado: desarrollo no validado

## Objetivo

Permitir que el usuario seleccione sobre el DXF un nodo inicial y un nodo final,
aisle el camino o subred de interes y ejecute el solver hidraulico solamente sobre
ese dominio. La red completa se conserva como dato primario dentro del `.aoscad`.

## Implementado

- Seleccion grafica de dos nodos mediante el visor 2D y `ginput`.
- Seleccion alternativa mediante IDs de nodo.
- Busqueda de caminos simples entre ambos extremos.
- Eleccion de un camino cuando existen recorridos alternativos.
- Persistencia de `SELECTED_PATH` en `tablas_entrada.dominios_hidraulicos`.
- Persistencia de `LOOP_SUBNETWORK` cuando se incluyen todos los caminos.
- Condicion DEV1 de extremos: presion en inicio y demanda de caudal en fin.
- Filtrado no destructivo: el solver ve solo el dominio; el `.aoscad` conserva toda la red.
- Invalidacion de resultados al cambiar dominio o condiciones de borde.
- Resultados con ID, tipo y nodos extremos del dominio efectivo.
- Visualizacion de la red completa en gris y del dominio seleccionado resaltado.
- Selftest de red con dos caminos alternativos.

## Limites de R9

- `SELECTED_PATH` es ejecutable con el solver de red abierta actual.
- `LOOP_SUBNETWORK` se guarda y visualiza, pero su ejecucion se bloquea hasta
  incorporar balance simultaneo de masa y presion tipo Kirchhoff.
- La condicion automatizada de extremos es `P_INICIO_Q_FIN`.
- Presion-presion, caudal-presion, varias fuentes y flujo reverso quedan para
  revisiones posteriores.

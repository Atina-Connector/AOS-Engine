# AOS BM Gibbs Foundation v18.1 - Ciclos configurables

## Cambio

Se agrega al menu de Gibbs Foundation una opcion para elegir la cantidad de ciclos a simular.

Default: 5 ciclos.

Uso de diagnostico:

- 1 ciclo: ver respuesta inicial sin regimen periodico.
- 2 ciclos: comparar efecto de superposicion / transitorio.
- 5 ciclos: criterio normal actual, descartar el primero y promediar los restantes.

## Regla

Si se simula un solo ciclo, no se descarta ningun ciclo.

Si se simulan dos o mas ciclos, el usuario puede elegir cuantos ciclos iniciales descartar. El valor se limita para que siempre quede al menos un ciclo valido.

## Objetivo

Permitir inspeccionar visualmente por que la carta v18 original mostraba varios lazos superpuestos: eran ciclos estables dibujados casi uno encima del otro, no una curva abierta.

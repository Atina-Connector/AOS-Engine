# Modulo BM / Gibbs - AOS v13

## Objetivo

Conservar la visualizacion BM/Gibbs estable, pero corregir un criterio fisico importante: la carrera de fondo no debe quedar limitada artificialmente por la carrera de superficie.

La sarta de varillas se comporta como un sistema oscilatorio con frecuencia y amplitud forzada. En determinadas condiciones de rigidez, masa, amortiguamiento y frecuencia, la amplitud en fondo puede ser menor o mayor que la amplitud superficial.

## Cambios BM/Gibbs v13

- Se mantiene la vista de transmision de carrera.
- Se mantiene la vista de transmision de carga.
- Se mantienen cartas superficie/fondo apaisadas.
- Se mantiene la lectura por semaforos.
- Se elimina el limite superior artificial `S_fondo <= S_superficie`.
- Se agrega una ganancia dinamica aproximada para permitir amplificacion o atenuacion de carrera.
- Se conserva un limite inferior numerico de seguridad para evitar soluciones degeneradas, pero no se impone un limite superior fisico falso.

## Importante

El modo estable v13 sigue siendo operativo/orientativo. El camino final de BM continua siendo una implementacion completa y validada de Gibbs comparable contra cartas reales, QROD o SROD.

# AOS - Laboratorio Gibbs v17 auditado

Este laboratorio es experimental y no reemplaza el calculo operativo de Bombeo Mecanico.

## Auditoria de v16

La v16 produjo una forma visualmente razonable, pero contenia una oscilacion/reflexion heuristica en superficie:

- `gibbs_lab_oscilacion_reflexion(...)`
- amplitud controlada por `gibbs_lab_osc_frac_Wf`

Eso no era una solucion directa de la ecuacion de onda. En v17 queda declarado como **benchmark visual** y la amplitud queda en `0.0` por defecto. Solo se activa si el usuario lo solicita explicitamente.

## Modo recomendado v17

`Gibbs Solver Lab v17` parte desde el movimiento impuesto por el polished rod:

```text
u(0,t) = movimiento superficie
```

y resuelve experimentalmente la ecuacion de onda amortiguada:

```text
u_tt = vs^2 u_xx - c u_t
```

Luego calcula cargas por deformacion elastica:

```text
F = E A du/dx
```

Si aparecen oscilaciones o reflexiones, salen del solver, de la condicion inferior y del amortiguamiento, no de una senoide agregada.

## Condiciones inferiores disponibles

- extremo libre
- extremo fijo
- carga de fluido constante
- bomba ideal llena: carga en subida / descarga en bajada

## Estado

Experimental. El objetivo es validar primero la propagacion de onda y las condiciones de borde antes de integrar un modelo BM definitivo comparable con QROD/SROD.

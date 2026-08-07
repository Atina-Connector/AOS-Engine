# AOS - Laboratorio Gibbs v15

## Objetivo

Agregar un banco de pruebas interno para desarrollar el modelo Gibbs sin alterar el modulo BM operativo.

El primer objetivo del laboratorio es controlado:

```text
carta de fondo impuesta -> carta de superficie estimada
```

Esto permite verificar la propagacion de carga y movimiento en la sarta antes de intentar el sensado automatico de valvulas.

## Uso

Desde AOS:

```text
4 - Simular Bombeo Mecanico
2 - Laboratorio Gibbs experimental
```

O desde Octave, con AOS cargado:

```octave
gibbs_lab_menu
```

## Advertencia

Este laboratorio es experimental. No debe usarse como resultado operativo ni como equivalente a QROD/SROD.

## Base fisica

El laboratorio queda orientado al articulo de S. G. Gibbs, donde el sistema de bombeo mecanico se plantea como un problema de valor de borde que combina:

- ecuacion de onda axial en la sarta;
- movimiento impuesto del polished rod;
- condicion de bomba de fondo variable;
- calculo por diferencias parciales.

## Estado v15

Todavia no resuelve el ciclo completo de valvulas por sensado automatico. En esta etapa se impone una carta de fondo y se estima la respuesta de superficie por retardo, amortiguamiento y dinamica distribuida simplificada.

## Motivo de esta etapa

El intento v14 mostro un problema claro: resolver la ecuacion de onda sin una condicion de bomba suficientemente fisica produjo una carta de resorte con fondo inactivo. Por eso v15 separa el problema:

1. Validar propagacion con carta de fondo conocida.
2. Luego implementar sensado de valvulas.
3. Luego integrar al BM operativo.

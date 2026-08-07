# AOS BM/Gibbs v11 - Vista operativa con transmision de carrera y carga

## Objetivo

Este parche es acumulativo respecto de la linea BM/Gibbs previa. No requiere instalar el parche 10 antes.

La idea central es mantener el modo Gibbs estable por defecto y mejorar la lectura operativa del modulo BM.

## Cambios principales

- Se conservan los semaforos operativos como lectura rapida de campo.
- Se mantiene la carta dinamometrica de superficie.
- Se mantiene la carta dinamometrica de fondo.
- Se agrega una grafica explicita de transmision de carrera: posicion de superficie y posicion de fondo versus tiempo/fase.
- Se agrega una grafica equivalente de transmision de carga: carga de superficie y carga de fondo versus tiempo/fase.

## Filosofia

La carta clasica sigue siendo necesaria porque muchos usuarios estan acostumbrados a leer carga contra posicion. Sin embargo, para AOS se incorpora una lectura mecanica mas directa:

- la transmision de carrera muestra amplitud, desfase, retardo y deformacion de onda;
- la transmision de carga muestra como se transmite el esfuerzo entre superficie y fondo.

Entre ambas curvas se obtiene una lectura rapida de la dinamica de la sarta y de la bomba.

## Vista grafica v11

El grafico BM/Gibbs queda organizado en seis paneles:

1. Semaforos operativos.
2. Transmision de carrera.
3. Transmision de carga.
4. Carta superficie.
5. Carta fondo.
6. Resumen numerico y notas.

## Nota de validacion

El modo Gibbs estable es una etapa de prevalidacion. El camino final sigue siendo desarrollar y validar un solver de onda comparable con herramientas como QROD/SROD mediante casos de referencia y cartas reales.

# PARCHE v18.3 - BM Gibbs estabilizacion cuasiestatica

Parche instalable para AOS / GNU Octave.

## Objetivo

Corregir el comportamiento observado en v18.2 donde un caso lento, de 3 spm, 1500 m, carrera 2.5 m y bomba llena generaba una carta serruchada no esperable.

## Cambios

- Mantiene el promedio punto a punto descartando los ciclos iniciales configurados.
- Agrega modo de solver `automatico`.
- En baja velocidad usa modo `cuasiestatico`, que debe entregar una carta de superficie tipo paralelogramo para bomba llena.
- Conserva el modo `dinamico_foundation` para seguir probando propagacion de onda.
- Mantiene menu de diametro de bomba.
- Mantiene cargas de superficie operativas positivas sin ocultar la carga dinamica relativa.

## Uso recomendado para validar

Parametros:

- Carrera PR: 2.5 m
- Velocidad: 3 spm
- Profundidad bomba: 1500 m
- Diametro bomba: 32 mm
- Llenado: 1.0
- Ciclos: 5
- Descartar: 1
- Modo solver: automatico o cuasiestatico

Resultado esperado: carta de superficie estable, limpia, casi paralelogramo; carta de fondo rectangular.

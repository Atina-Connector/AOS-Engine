# BM_GF2_GOLDEN_CASE_001

Primer caso de Gibbs Foundation 2 considerado fisicamente coherente en AOS.

## Contenido

- `entrada/ejemplo_bm.aosdat`: configuracion que genero el resultado.
- `codigo/gibbs_foundation2/`: codigo exacto conservado de GF2.
- `evidencia/GF2_PRIMER_RESULTADO_CORRECTO.png`: grafica observada.
- `origen/gibbs_foundation2_original.zip`: paquete fuente recibido.
- `MANIFIESTO_BENCHMARK.txt`: identificacion y criterios de preservacion.
- `SHA256SUMS.txt`: huellas de todos los archivos.

## Estado

Este paquete es un testigo congelado. No debe editarse. Toda evolucion debe hacerse
en un modulo paralelo (GF3 o posterior) y compararse contra este caso.

## Limitacion

La imagen permite definir rangos visuales preliminares, pero el resultado numerico
exacto de Octave no fue guardado en un archivo estructurado abierto o CSV. Por eso las metricas del
manifiesto son bandas de aceptacion iniciales y no valores de regresion exactos.

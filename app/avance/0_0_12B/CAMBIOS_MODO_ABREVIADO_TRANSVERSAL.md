# AOS 0.0.12B - Modo abreviado transversal

- Opcion 4 en sensibilidades JGL/GL.
- Malla directa liviana (61 puntos nodales internos).
- Ajuste polinomico grado 4/5 solo para seleccionar verificaciones.
- Verificacion iterativa de extremos, optimos, residuos y curvaturas.
- El polinomio nunca sustituye los resultados del solver.
- Solver GL configurable: preciso 1201 puntos, simple/hibrido 121, abreviado 61.
- Eliminada una resolucion GL duplicada por punto en comparaciones JGL/GL.
- GNU Octave es la plataforma objetivo.

# Gibbs Foundation 3 v1.8 integral

Modulo activo de desarrollo para BM Operativo II en GNU Octave.

Incluye:

- seleccion del aparato de bombeo;
- catalogo AOS, seleccion manual o automatica;
- perfiles cinematicos representativos;
- geometria explicita simplificada para unidad convencional;
- posicion, velocidad y aceleracion del polished rod;
- solver axial GF3;
- bomba convencional o LPP AESIR;
- tubing anclado o libre;
- diseno automatico, manual o uniforme de sarta;
- Goodman modificado;
- barras de peso;
- espaciamiento convencional y LPP;
- torque por trabajo virtual, potencia y contrabalanceo recomendado;
- tres ventanas de graficas;
- exportacion CSV, TXT y MAT.

Los perfiles denominados `representativo` son aproximaciones cinematicas por tipo.
Para una evaluacion geometrica especifica debe usarse `linkage_conventional` con
las dimensiones reales del aparato o incorporarse el perfil certificado del
fabricante.


## Correccion GF3 v1.8 - signo de tubing libre

GF3 usa desplazamiento axial positivo hacia arriba. La elongacion de una
columna de tubing libre es una magnitud positiva, pero el extremo inferior y
el barril se desplazan hacia abajo. Por lo tanto:

```text
elongacion_tubing >= 0
u_barril = -elongacion_tubing
u_piston_barril = u_varilla_fondo - u_barril
```

Esta separacion corrige la pendiente invertida de la rama de transferencia de
carga sin modificar las cargas del solver axial ni la carta de superficie. El
calculo de espaciamiento continua usando la magnitud positiva de elongacion
para evitar errores de signo o doble conteo.

Los resultados residentes creados con la convencion anterior pueden repararse
mediante `gibbs3_repair_tubing_sign_result`; las cargas calculadas no cambian.

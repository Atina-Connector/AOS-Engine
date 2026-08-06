# Regresiones obligatorias SENS-GLJGL-02

## Gate rapido

```octave
VERIFICAR_SENS_GLJGL_02(false)
```

Debe comprobar:

1. El menu de tratamiento siempre es visible.
2. El modo discreto no contiene ni ejecuta una llamada directa a `polyfit`.
3. `polyfit` queda confinado al helper explicito `sens_ajuste_polinomico`.
4. El modo informativo no cambia la recomendacion discreta.
5. El grado 5 historico puede seleccionarse y localizar un maximo interior.
6. El modo automatico elige un grado entre 2 y 5.
7. Una discontinuidad bloquea la optimizacion polinomica global.
8. Las mascaras `valido_para_curva` y `valido_para_optimo` permanecen separadas: una curva preliminar puede mostrarse sin fabricar un optimo.
9. Los puntos fisicos `Ql/Qo` permanecen byte a byte sin cambios en memoria.
10. Las regresiones rapidas SENS-GLJGL-01 continúan aprobadas.

## Gate profundo

```octave
VERIFICAR_SENS_GLJGL_02(true)
```

Agrega la campaña profunda SENS-GLJGL-01 para verificar paridad del punto GL,
metodo uniforme JGL, publicacion estricta y rechazo de puntos preliminares.

## Benchmark real obligatorio

Para el caso que presentaba caudales cero, negativos o curvas quebradas:

1. Ejecutar SENS01/SENS02 en modo `DISCRETO` y confirmar paridad punto-barrido.
2. Ejecutar `POLINOMICO_INFORMATIVO`, primero con grado 5 y luego en AUTO.
3. Verificar que los marcadores del solver no cambian y que la curva ajustada
   se identifica por separado.
4. Ejecutar `POLINOMICO_VERIFICADO`.
5. Confirmar que el `Qiny` estimado se recalcula mediante el solver canonico.
6. Comparar `Qo estimado`, `Qo solver`, residuo, estado y diferencia relativa.
7. Forzar un caso no convergente y comprobar que la recomendacion vuelve al
   optimo discreto.
8. Confirmar que no hay extrapolacion ni union de ramas separadas.
9. Exportar `.aosrpt` y revisar las secciones `CURVE_TREATMENT`,
   `POLYNOMIAL_FIT`, `POLYNOMIAL_CURVE` y
   `POLYNOMIAL_OPTIMUM_VERIFICATION`.

La armonizacion no convierte un punto `NO_CONVERGE` en un punto valido.

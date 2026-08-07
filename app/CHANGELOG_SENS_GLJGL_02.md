# Changelog SENS-GLJGL-02

## Objetivo

SENS-GLJGL-02 recupera la armonizacion polinomica historica de AOS, incluido el
polinomio quintico, y la convierte en una decision visible del usuario. Se
construye sobre SENS-GLJGL-01 y no modifica los solvers fisicos GL/JGL.

## Menu incorporado

Despues de elegir el metodo numerico aparece:

```text
--- TRATAMIENTO DE LA CURVA ---
1 - Discreto, sin armonizacion
2 - Armonizacion polinomica informativa
3 - Armonizacion polinomica con optimo verificado
0 - Cancelar
```

Cuando se elige una modalidad polinomica:

```text
0 - Automatico controlado
2 - Cuadratico
3 - Cubico
4 - Cuartico
5 - Quintico [HISTORICO AOS]
```

## Reglas funcionales

1. **Modo discreto predeterminado**
   - No ejecuta `polyfit`.
   - Calcula maximos y pendientes con los puntos aceptados por SENS01.
   - Conserva la recomendacion discreta.

2. **Modo polinomico informativo**
   - Superpone una curva derivada a los puntos fisicos.
   - Calcula derivadas y estacionarios para diagnostico.
   - No reemplaza la recomendacion oficial.

3. **Modo polinomico verificado**
   - Estima un maximo interior de `Qo` por derivada cero.
   - Ejecuta nuevamente el evaluador canonico GL o JGL en ese `Qiny`.
   - Publica el optimo polinomico solo si el punto fisico converge, es valido
     para optimizacion y coincide con el ajuste dentro de tolerancia.
   - Si falla, restaura la recomendacion discreta y conserva el diagnostico.

4. **Controles de ajuste**
   - La curva y el ajuste solo usan puntos `valido_para_curva=true`.
   - La recomendacion discreta y la verificacion solo usan puntos `valido_para_optimo=true`.
   - No une ramas separadas por `NaN` o puntos rechazados.
   - No extrapola fuera del dominio resuelto.
   - Normaliza la variable independiente para reducir condicionamiento.
   - Rechaza caudales negativos, `Qo > Ql`, sobreoscilacion y exceso sobre IPR.
   - El modo automatico selecciona un grado entre 2 y 5 mediante un criterio
     penalizado de error, complejidad, extremos y condicion numerica.

5. **Trazabilidad**
   - La tabla fisica del solver nunca se sobrescribe.
   - El `.aosrpt` distingue tratamiento, ajustes Ql/Qo/rendimiento, curva
     derivada y verificacion del optimo.
   - Se registra grado solicitado y efectivo, coeficientes normalizados, R2,
     RMSE, dominio, discontinuidad y estado.

## Archivos principales

- `sens_menu_tratamiento_curva.m`
- `sens_seleccionar_grado_polinomio.m`
- `sens_ajuste_polinomico.m`
- `sens_validar_ajuste_polinomico.m`
- `sens_verificar_optimo_polinomico.m`
- `sens_optimo_inyeccion.m`
- `sens_exportar_resultados.m`

## Nucleos protegidos sin cambios

- `GL_sim.m`
- `aos_nodal_balance_gl.m`
- `aos_buscar_cruce_nodal.m`
- `jgl_solver_directo.m`
- `jgl_solver_iterativo.m`

## Estado

La entrega requiere validacion dinamica en GNU Octave y comparacion contra el
caso real GL/JGL que produjo la regresion de sensibilidad.

# Regresiones obligatorias SENS-GLJGL-01

## Gate rapido

```octave
VERIFICAR_SENS_GLJGL_01(false)
```

Debe aprobar:

1. Contrato estatico del hotfix.
2. Rechazo de WC fuera de dominio, caudales negativos y estados no convergidos.
3. Paridad entre `GL_sim(p,Qiny)` y `sens_gl_evaluar_punto(p,Qiny)`.
4. Inmutabilidad de la firma cuando solo cambian Qiny o la resolucion numerica.

## Gate profundo

```octave
VERIFICAR_SENS_GLJGL_01(true)
```

Agrega una corrida JGL de dos puntos y comprueba que:

- todos los puntos usan el mismo metodo;
- el modo abreviado queda marcado preliminar;
- ningun punto preliminar entra al optimizador;
- un punto rechazado conserva raw y publica `NaN`.

## Benchmark real obligatorio

Conservar el caso `.aosdat` que presentaba la regresion y evaluar, como minimo:

- Qiny puntual bajo;
- Qiny puntual medio;
- Qiny puntual alto;
- los mismos tres valores dentro del barrido;
- igualdad de Ql, Qo, estado, Qiny efectivo, IPR, VLP y firma;
- ausencia de caudales negativos publicados;
- ausencia de caidas falsas a cero;
- continuidad fisica sin suavizado artificial;
- residuos dentro de tolerancia en puntos convergidos.

La tabla raw no debe borrarse aunque un punto sea rechazado.

# Auditoria GF3 - signo de tuberia libre

## Hallazgo

`gibbs3_tubing_motion` producia `x_tuberia_m` como magnitud positiva de
elongacion, pero `gibbs3_postprocess` la restaba como si fuera una posicion
axial positiva del barril. Durante la transferencia de carga esto invertia la
pendiente de la carta de fondo.

## Convencion fisica

GF3 adopta desplazamiento axial positivo hacia arriba:

```text
elongacion_tubing >= 0
u_barril = -elongacion_tubing
u_piston_barril = u_varilla_fondo - u_barril
```

En una prueba elastica aislada:

```text
dF / d(u_piston_barril) = E*A/L > 0
```

## Alcance

La correccion se limita a la cinematica relativa del tubing y a sus derivados.
No cambia las cargas del solver axial, la carta de superficie ni la logica de
bomba y valvulas.

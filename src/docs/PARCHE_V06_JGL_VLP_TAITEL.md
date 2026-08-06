# AOS - Parche v06 JGL/VLP/Taitel

## Objetivo

Este parche corrige dos puntos detectados durante la corrida del pozo MB01:

1. Inconsistencia entre el solver JGL y el grafico nodal VLP.
2. Clasificacion Taitel demasiado plana/conservadora, que tendia a mostrar slug en toda la tuberia.

## Cambio JGL/VLP

Antes, una version intermedia del modelo pasaba la presion VLP requerida como base interna del eductor. Eso hacia dificil auditar el sistema porque el solver y el grafico podian terminar comparando curvas distintas.

Desde v06 se usa un unico balance:

```text
residuo = P_d_eductor - P_req_VLP
```

Donde:

- `P_d_eductor` se calcula con el eductor JGL desde la presion de succion.
- `P_req_VLP` se calcula con `compute_P_req` usando el modelo VLP seleccionado.
- El mismo calculo se usa en `JGL_core` y en `plot_nodal` mediante `jgl_nodal_presiones.m`.

La ecuacion empirica del eductor vuelve a ser:

```text
(P_d - P_s) / (P_m - P_s) = a - b * M
```

Si `a_eductor` y `b_eductor` no estan definidos, se estiman desde la geometria:

```text
a = 0.0020  * (A_t / A_n)
b = 0.00010 * (A_t / A_n)
```

Esto coincide con la documentacion interna de calibracion JGL.

En el menu `corrida`, si el caso importado no trae `a_eductor` y `b_eductor`, tambien se calculan desde la geometria antes de mostrar los parametros al usuario. Esto evita que queden los defaults heredados `0.01` y `0.005` cuando se importa un `.aosdat` sin coeficientes JGL.

## Cambio Taitel

El clasificador sigue siendo diagnostico/orientativo. No reemplaza las correlaciones VLP HB/DR.

La version v06 separa mejor:

- burbuja,
- slug,
- slug severo,
- transicion,
- niebla.

Tambien mantiene la convencion de survey petrolero usada por AOS:

```text
0 grados  = vertical
90 grados = horizontal
```

## Archivos modificados

```text
src/menu/JGL_menu.m
src/core/GL/JGL_core.m
src/utilidades/nodal/plot_nodal.m
src/utilidades/nodal/eductor_jgl.m
src/utilidades/nodal/jgl_nodal_presiones.m
src/utilidades/nodal/acople_eductor_vlp.m
src/utilidades/nodal/error_presion_JGL.m
src/core/common/vlp/calcular_regimen.m
src/utilidades/diagnostico/calcular_perfil_tuberia_produccion.m
src/utilidades/diagnostico/diagnostico_tuberia_produccion.m
src/utilidades/graficos/plot_erosion_taitel.m
```

## Que revisar despues de instalar

Al correr JGL/corrida:

- El diagnostico nodal debe mostrar `Margen = P_entrega - P_req`.
- Ya no deberia aparecer la advertencia heredada que decia que el solver encontro produccion pero la VLP del grafico era mayor.
- Si el margen es positivo, el grafico debe decir que el sistema queda limitado por IPR/garganta/configuracion.
- Si el margen es cercano a cero, es un cruce nodal exacto.
- Si el margen es negativo, hay que revisar parametros, VLP o capacidad del eductor.

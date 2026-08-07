# Aplicacion de SENS-GLJGL-02

## Opcion recomendada: distribucion completa

1. Extraer `AOS_0_2_0_DEV1_ENV02_SENS02_COMPLETO.zip` en una carpeta nueva.
2. Conservar SENS01 como baseline de comparacion.
3. Abrir GNU Octave y ejecutar:

```octave
cd('/ruta/AOS_0_2_0_DEV1_ENV02_SENS02')
clear functions
rehash
VERIFICAR_SENS_GLJGL_02(false)
VERIFICAR_AOS_0_2_0_DEV1(false)
AOS
```

Antes de aceptar o distribuir la correccion:

```octave
VERIFICAR_SENS_GLJGL_02(true)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

## Opcion parche

Aplicar `PARCHE_AOS_SENS_GLJGL_02_POLINOMIO_EXPLICITO.zip` sobre una copia
limpia de `AOS_0_2_0_DEV1_ENV02_SENS01`. El parche no esta diseñado para
ENV-02 sin SENS01.

## Uso

1. Elegir el metodo numerico GL/JGL.
2. Elegir de forma separada el tratamiento de la curva.
3. Para reproducir exactamente SENS01, seleccionar `Discreto`.
4. Para visualizar la armonizacion sin alterar la recomendacion, seleccionar
   `Polinomico informativo`.
5. Para estimar el maximo por derivada cero y recalcularlo fisicamente,
   seleccionar `Polinomico verificado`.
6. Elegir grado AUTO, 2, 3, 4 o 5. El grado 5 es la opcion historica.

## Lectura de resultados

- Marcadores: puntos fisicos del solver.
- Linea polinomica: serie derivada, nunca fuente primaria.
- `OPTIMO_POLINOMICO_ESTIMADO`: maximo matematico pendiente de verificacion.
- `OPTIMO_POLINOMICO_VERIFICADO`: punto recalculado y aceptado por el solver.
- `OPTIMO_DISCRETO_*`: fallback cuando el ajuste o la verificacion fallan.

No utilizar el polinomio para cubrir puntos no convergidos. Los `NaN`, estados
y motivos de rechazo deben permanecer visibles.

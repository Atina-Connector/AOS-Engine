# Aplicacion de SENS-GLJGL-03

## Opcion recomendada: distribucion completa

Extraer `AOS_0_2_0_DEV1_ENV02_SENS03_COMPLETO.zip` en una carpeta nueva. Esta distribucion ya incluye SENS01, SENS02 y SENS03; no es necesario instalar SENS02 por separado.

```octave
cd('/ruta/AOS_0_2_0_DEV1_ENV02_SENS03')
clear functions
rehash
which sens_menu_condicion_motriz_jgl -all
which jgl_condicion_motriz -all
which sens_jgl_graficar_presiones -all
VERIFICAR_SENS_GLJGL_03(false)
VERIFICAR_AOS_0_2_0_DEV1(false)
AOS
```

## Parche acumulativo desde SENS01

Aplicar `PARCHE_AOS_SENS_GLJGL_03_DESDE_SENS01.zip` solamente sobre una copia limpia de `AOS_0_2_0_DEV1_ENV02_SENS01`. El parche incluye todos los cambios de SENS02 y SENS03.

Tambien se entrega un parche incremental desde SENS02 para auditoria, pero no es necesario en tu caso.

No aplicar sobre una carpeta con modificaciones locales sin conservar primero una copia y un inventario de diferencias.

## Seleccion para el caso MDM-2064

Cuando AOS detecte `P_iny_sup = 0` y un barrido con `Qiny` forzado, seleccionar:

```text
1 - Derivar la presion minima requerida desde Qiny y la tobera
```

El valor cero importado permanece en la auditoria; no se sustituye por una presion arbitraria. AOS calcula y reporta la presion minima requerida por punto.

La misma seleccion aparece en una simulacion puntual JGL cuando se fuerza un `Qiny > 0`.

## Campana completa

```octave
VERIFICAR_SENS_GLJGL_03(true)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

Conservar salida de consola, `.aosdat`, `.aosrpt` o CSV, graficas, limites del barrido, tratamiento de curva y tiempo de ejecucion.

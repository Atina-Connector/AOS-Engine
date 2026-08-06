# Aplicacion de SENS-GLJGL-01

## Opcion recomendada: distribucion completa

1. Extraer `AOS_0_2_0_DEV1_ENV02_SENS01_COMPLETO.zip` en una carpeta nueva.
2. No sobrescribir la copia ENV-02 que se utiliza como baseline.
3. Abrir GNU Octave y ejecutar:

```octave
cd('/ruta/AOS_0_2_0_DEV1_ENV02_SENS01')
clear functions
rehash
VERIFICAR_SENS_GLJGL_01(false)
VERIFICAR_AOS_0_2_0_DEV1(false)
AOS
```

Antes de distribuir o aceptar la correccion:

```octave
VERIFICAR_SENS_GLJGL_01(true)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

## Opcion parche

Aplicar el contenido de `PARCHE_AOS_SENS_GLJGL_01.zip` sobre una copia limpia de
`AOS_0_2_0_DEV1_ENV02`. La estructura de carpetas del parche comienza en la
raiz de AOS. Luego ejecutar `clear functions`, `rehash` y los verificadores.

## Uso de la sensibilidad corregida

1. Ejecutar primero una simulacion puntual GL o JGL representativa.
2. Ingresar a la sensibilidad correspondiente.
3. Aceptar la fuente recomendada `ultima simulacion ejecutada (GL/JGL)`.
4. Verificar en pantalla IPR, VLP, IP, WC, GLR, Pwh y profundidad.
5. Para un resultado tecnico final utilizar:
   - GL: `Preciso uniforme` o `Hibrido seguro`;
   - JGL: `Preciso iterativo` o `Automatico seguro`.
6. Utilizar `Simple/directo` o `Abreviado` solo como exploracion preliminar.
7. Exportar el `.aosrpt` para conservar raw, publicado, estado, residuo y motivo.

## Interpretacion

- `Ql raw` / `Qo raw`: valor devuelto por el solver, incluso si no converge.
- `Ql pub` / `Qo pub`: valor habilitado para curva; es `NaN` si el punto falla.
- `Aceptado`: pasa validacion numerica y fisica.
- `Valido curva`: puede dibujarse como resultado tecnico.
- `Valido optimo`: puede participar en optimizacion.
- Un punto de frontera IPR puede mostrarse, pero no constituye una raiz interior.

## Caso que se esta recalculando

Conservar sin descartar:

- archivo `.aosdat`;
- salida completa de consola;
- tabla exportada `.aosrpt` o CSV;
- modo de calculo;
- limites y cantidad de puntos;
- IPR y VLP efectivos;
- tiempo total de ejecucion.

Ese material sera el benchmark dorado de la regresion.

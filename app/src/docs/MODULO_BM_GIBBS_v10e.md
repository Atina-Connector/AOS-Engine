# AOS - Modulo BM/Gibbs v10e

## Objetivo

Convertir el bloque de Bombeo Mecanico de AOS en un modulo basado en la ecuacion de onda de Gibbs, para que el caudal no dependa solo del desplazamiento geometrico superficial.

La meta final es poder calcular con buena precision:

- carrera real de fondo;
- carta dinamometrica de fondo;
- llenado de bomba;
- desplazamiento efectivo;
- espaciamiento;
- cargas maximas y minimas;
- diagnostico mecanico de la sarta y de la bomba.

## Filosofia mecanica

El modulo se organiza como un conjunto mecanico:

```text
Unidad de superficie
        ↓
Cinematica del punto pulido
        ↓
Sarta de varillas discretizada
        ↓
Ecuacion de onda de Gibbs
        ↓
Bomba de fondo
        ↓
Carrera real de fondo
        ↓
Llenado / desplazamiento efectivo
        ↓
Caudal BM
```

## Archivos nuevos

```text
src/core/BM/gibbs/gibbs_bm_resolver.m
src/core/BM/gibbs/gibbs_param_defaults.m
src/core/BM/gibbs/gibbs_construir_malla_sarta.m
src/core/BM/gibbs/gibbs_resolver_forward.m
src/core/BM/gibbs/gibbs_resolver_inverso.m
src/core/BM/gibbs/gibbs_modelo_bomba.m
src/core/BM/gibbs/gibbs_carga_fluido.m
src/core/BM/gibbs/gibbs_calcular_metricas_bomba.m
src/core/BM/gibbs/gibbs_estimacion_espaciamiento.m
src/core/BM/gibbs/gibbs_resumen_texto.m
```

## Modo forward

Usado para diseno o simulacion cuando no hay carta medida.

Entradas principales:

- carrera superficial;
- golpes por minuto;
- tipo de unidad;
- profundidad de bomba;
- diametro de bomba;
- sarta de varillas;
- material;
- fluido;
- IPR;
- presion minima de intake.

Salida principal:

- carta superficie;
- carta fondo;
- carrera de fondo;
- llenado;
- caudal efectivo;
- espaciamiento preliminar.

## Modo inverso

Preparado para el camino de diagnostico con carta dinamometrica medida.

Requiere:

```text
opciones.carta_superficie = [posicion_m, carga_N]
```

La carta debe estar ordenada temporalmente. Una nube de puntos posicion-carga sin orden de muestreo no alcanza para resolver correctamente la propagacion de onda.

## Estado de desarrollo

Esta version es una base fisica mas fuerte que la aproximacion anterior, pero todavia no debe presentarse como equivalente validado a QROD/SROD.

Para acercarse a ese nivel faltan etapas:

1. Validar contra casos simples.
2. Validar contra cartas dinamometricas reales.
3. Ajustar amortiguamiento.
4. Agregar friccion por desviacion.
5. Mejorar valvulas, gas/interferencia y golpe de fluido.
6. Comparar carrera de fondo, PPRL, MPRL y torque contra QROD/SROD.

## Principio importante

Gibbs no debe ser solo un grafico. En BM, Gibbs debe ser el motor fisico que calcula el desplazamiento real del piston.

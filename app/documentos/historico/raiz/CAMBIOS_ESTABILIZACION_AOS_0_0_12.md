# AOS 0.0.12 - Estabilizacion transversal GNU Octave

Esta integracion reemplaza la cadena de hotfixes previos y corrige la causa comun detectada: los aliases importados desde `.aosdat` no pueden volver a sobrescribir valores canonicos modificados durante una corrida o sensibilidad.

## Alcance

- Configuracion runtime y aliases: precedencia canonica unica.
- GL: Qiny solicitado, efectivo dentro de VLP y balance de gas auditables.
- JGL: modos directo, iterativo y automatico/hibrido; CFD fuera del runtime.
- BES: corrida principal y cinco sensibilidades con valores solicitados/efectivos.
- BM: corrida principal con profundidad, carrera y velocidad auditables.
- Sensibilidades JGL: menu de aproximacion presente y modo realmente propagado en todas las mallas.
- Profundidades: `D_iny` separada de `D_bomba`.
- Reportes: snapshot inmutable de la corrida, sin releer aliases del `.aosdat`.
- Importacion/exportacion: pozos independientes y profundidades SLA separadas.
- Octave: se eliminaron implementaciones duplicadas dependientes del orden del `path`.

## Verificadores incluidos

```octave
VERIFICAR_ESTABILIZACION_AOS_0_0_12
VERIFICAR_QINY_HIDRAULICA_GL
VERIFICAR_SENSIBILIDADES_AOS_0_0_12
```

`VERIFICAR_QINY_HIDRAULICA_GL` prueba 0, 8000, el caudal de referencia y 30000 Sm3/d, e imprime el Qiny que entra realmente en la VLP, gas de formacion, gas total, Ql, Ps y P_req. Si Ql queda plano pero Qiny llega correctamente, la causa queda clasificada como insensibilidad del modelo/VLP y no como sobrescritura de configuracion.

## Limite de esta entrega

La revision estructural y de flujo de datos fue realizada sobre todo el arbol. GNU Octave no esta instalado en el entorno de construccion; por eso los tres verificadores deben ejecutarse en la instalacion objetivo antes de usar resultados para benchmark. La formulacion numerica JGL continua siendo una primera version calibrable; la tabla CFD gas-gas no participa en AOS.

# Registro de regresiones integrado en AOS 0.1.3R1

## GF3

- Signo incorrecto de la deformacion relativa con tuberia libre.

## BES3

- Vectores AOSDAT preservados como texto sin normalizacion.
- Seleccion nodal y modelos IPR/VLP incompletos.
- Frecuencia cero tratada como bomba operativa.
- Equilibrio en Q=0 informado como flujo natural convergido.
- Recirculacion evaluada contra produccion, sin referencia al caudal nominal efectivo.
- BEP unico que no diferenciaba etapas inferiores y superiores.
- Falta de cantidad total de etapas y etapa de sangrado en sensibilidad/reporte.
- Error de sintaxis por comentario incompleto en `bes3_defaults.m`.
- Error de dimensiones en actualizacion automatica de leyenda de Octave.
- Ausencia de cierre AOSRPT en sensibilidades BES3.

## Sensibilidades y reportes

- Conteo de puntos sin produccion basado en igualdad exacta a cero.
- Falta de diagnostico ejecutivo global.
- Valores NaN presentados al usuario sin estado explicito.
- Origen ambiguo `aosdat/manual/default` en lugar de origen efectivo.
- Secciones vacias extensas en el Viewer.
- Falta de contrato explicito para tablas nativas embebidas.
- Duplicacion de prefijos en nombres de reportes.

## Pruebas minimas recomendadas

1. Ejecutar `VERIFICAR_AOS_0_1_3_R1`.
2. Ejecutar `bes3_selftest`.
3. Repetir sensibilidad BES3 de frecuencia, incluyendo 0 Hz.
4. Repetir sensibilidad BES3 de cantidad de etapas.
5. Exportar reporte comun y enriquecido a carpeta estandar y carpeta seleccionada.
6. Abrir ambos reportes en AOS Viewer y verificar tablas, diagnosticos y graficos.
7. Ejecutar benchmark GF2 y selftest GF3 cuando corresponda.

## Consolidacion R1: menu y roadmap

- Primera compilacion R1 generada desde una base anterior al parche de capacidades 0.1.3-R2.
- Menu principal reducido incorrectamente de seis a cuatro opciones.
- Omision de los menus y contratos de roadmap, CAD, ambiente, integridad, mantenimiento y economia.
- Corregido mediante reintegracion del payload de capacidades y verificacion explicita del menu completo.

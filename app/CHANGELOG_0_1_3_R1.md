# AOS 0.1.3R1

Fecha: 2026-07-23

## Consolidacion

- Integracion limpia del estado final de AOS 0.1.3 posterior a DEV5.4.
- Eliminacion de instaladores ya aplicados, backups y reportes de prueba.
- Actualizacion de identificadores visibles y generadores AOSRPT a `AOS_0_1_3_R1`.
- Nuevo verificador R1 con controles de BES3, GF3 y la infraestructura transversal de reportes.

## Correcciones integradas

- GF3: signo de deformacion para tuberia libre.
- BES3: normalizacion de vectores AOSDAT y seleccion de modelos nodales.
- BES3: estado de bomba apagada, frecuencia cero y flujo natural.
- BES3: evaluacion de recirculacion respecto del caudal nominal efectivo.
- BES3: cantidad total de etapas, etapa de toma y caudales/BEP por seccion.
- BES3: correcciones de comentario y leyenda grafica.
- Exportacion AOSRPT simple/enriquecida con carpeta estandar, navegador o ruta manual.
- Diagnostico transversal de sensibilidades y deteccion de puntos sin produccion por tolerancia/estado.
- Tablas nativas embebidas y manifiesto de capacidades del reporte.

## Compatibilidad

- Se conserva el formato AOSDAT/AOSRPT existente.
- Los modulos en desarrollo conservan su advertencia de validacion.

## Correccion de consolidacion del menu principal

- Restaurado el menu principal completo de seis opciones: operacion, intercambio, configuracion, Viewer/reportes, roadmap y salida.
- Integrada la envolvente de capacidades del parche documental 0.1.3-R2 que habia quedado fuera de la primera compilacion R1.
- Restaurados los accesos a CAD/topografia/topologia, ambiente, integridad, mantenimiento/Pulling, economia y roadmap como modulos planificados o de arquitectura.
- El identificador del producto permanece `AOS 0.1.3R1`; los nombres de archivos `0_1_3_R2` se conservan solo como revision historica del roadmap.

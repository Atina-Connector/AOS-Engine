# AOS 0.1.0 — Sensibilidades: tablas y ganancias transversales

Fecha: 2026-07-15

## Problema corregido

Los reportes enriquecidos de sensibilidad podían conservar las gráficas y el survey, pero no mostrar una tabla punto a punto utilizable. En la sensibilidad de Qiny GL/JGL también se había perdido el porcentaje de ganancia que existía en versiones anteriores.

## Corrección transversal

La salida de todas las sensibilidades que utilizan `sens_exportar_resultados` queda normalizada mediante un contrato único:

- `[SENSITIVITY_TABLE]`: matriz canónica punto a punto, con nombres y unidades;
- `[SENSITIVITY_DATA]`: vectores de compatibilidad para Viewers anteriores;
- `[SENSITIVITY_TABLE_TEXT]`: tabla legible de respaldo;
- `[SENSITIVITY_GAIN_SUMMARY]`: referencia, valor base y ganancia máxima;
- CSV con encabezado, unidades y todos los puntos;
- tabla PNG paginada dentro del reporte enriquecido para Viewers que todavía no interpreten la tabla estructurada.

## Ganancias

Para Qiny, la prioridad de referencia es `Qiny = 0`. Si no existe ese punto o no es válido, se usa el primer punto válido y se declara explícitamente.

Se incluyen, para líquido y petróleo cuando están disponibles:

- ganancia absoluta respecto de la referencia;
- ganancia porcentual respecto de la referencia;
- ganancia incremental respecto del punto válido anterior;
- máximo de ganancia y variable donde ocurre.

Si el valor base es cero, el porcentaje se marca como no calculable en lugar de dividir por cero.

## Alcance revisado

El exportador central es utilizado por:

- Qiny JGL vs GL;
- Qiny GL;
- Qiny JGL;
- presión de inyección;
- presión de cabeza;
- profundidad de inyección/levantamiento;
- área de tobera JGL;
- diámetro de garganta JGL;
- balance energético;
- frecuencia, etapas, presión de cabeza, sumergencia y Run Life BES.

## Importación

`importar_aosrpt` muestra la tabla formateada en consola y evita que datos de resultados, gráficas o sensibilidad se carguen accidentalmente como parámetros de `CONFIG_ACTIVA`.

## Física

Este parche no modifica los solvers ni recalcula resultados físicos. Corrige persistencia, trazabilidad, presentación y cálculo de indicadores derivados.

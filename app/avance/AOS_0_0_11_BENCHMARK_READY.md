# AOS 0.0.11 — Benchmark Ready

**Estado:** compilación completa previa al benchmark Supati X1 ST  
**Fecha:** 2026-07-10  
**Plataforma:** GNU Octave

## Decisiones cerradas

### Unidades

AOS usa unidades métricas como convención de usuario y de los nuevos `.aosdat`:

- bar;
- m;
- m³/d;
- Sm³/d;
- °C;
- mm cuando corresponde.

Las unidades imperiales son referencias entre paréntesis. El núcleo conserva SI interno cuando una ecuación lo requiere.

### `.aosdat` como caso integral

Un `.aosdat` puede contener configuración, survey, geología, punzados, estado mecánico, parámetros de SLA, calibraciones y benchmarks. La importación no debe requerir pasos manuales adicionales para activar información ya presente en el archivo.

### Geología y punzados

- `[GEOLOGIA]` se carga automáticamente.
- `[PUNZADOS]` se carga automáticamente.
- Los intervalos quedan disponibles para geología, reportes y visualización.
- Si solo existen punzados, AOS no fabrica propiedades geológicas.

### Visualización

El survey incorpora un track explícito de punzados, además de su representación en MD–TVD y 3D.

## Regresión incluida

- importación del benchmark Supati;
- round-trip `.aosdat`;
- convención y conversiones de unidades;
- compatibilidad con archivos históricos;
- smoke test del plot survey/punzados.

## Congelamiento funcional

La física de JGL no se modifica en esta compilación. El benchmark GL debe realizarse primero. El desarrollo de AOS 0.0.12 comenzará después con el solver acoplado continuo GL–eductor.

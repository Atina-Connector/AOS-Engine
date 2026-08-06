# AOS 0.0.12B — Versión final para archivo

**Proyecto:** AOS — AESIR Oilfield Simulation  
**Entorno objetivo:** GNU Octave  
**Fecha de cierre:** 15 de julio de 2026  
**Estado:** congelada para archivo, benchmark y recuperación  
**Siguiente rama:** AOS 0.1.0

## Alcance consolidado

Esta copia integra directamente en el árbol base los cambios validados durante 0.0.12B, sin requerir la instalación posterior de parches. Incluye:

- simulación GL y JGL;
- modos JGL iterativo, directo y automático/híbrido;
- sensibilidades GL/JGL y BES;
- simulación BES;
- módulo BM/Gibbs en su estado 0.0.12B;
- diseño automático de mandriles con secuencia de unloading;
- perfiles compresibles de casing y tubing usados por el cálculo y la gráfica;
- galería de mandriles y válvulas embebible en `.aosdat`;
- selección automática de cantidad, profundidad, válvula y puerto;
- inferencia trazable del nivel inicial cuando no está medido;
- reportes `.aosrpt` ligeros y enriquecidos;
- contexto geométrico para AOS Viewer;
- exportación de sensibilidades y protección crypto transversal;
- modos abreviados de salida para análisis extensos;
- survey, punzados, geología e intercambio `.aosdat`/`.aosrpt`.

## Hito de cierre

El Diseño de Mandriles V2 fue probado en GNU Octave y se comportó de acuerdo con la lógica esperada de descarga secuencial. Los perfiles de presión compresibles intervienen en el cálculo del espaciamiento, no solamente en la presentación gráfica.

## Política de congelamiento

Esta versión no debe recibir nuevas funciones. Solo se admitirían correcciones críticas que impidan reproducir una corrida archivada. Toda evolución de arquitectura, menús y catálogos corresponde a AOS 0.1.0.

## Límites conocidos

- Los catálogos permanentes de usuario todavía no están implementados; 0.0.12B utiliza archivos base y catálogos opcionales embebidos en `.aosdat`.
- El módulo BM continúa en etapa de evolución física respecto de un solver Gibbs completo.
- Las correlaciones hidráulicas simplificadas deben seguir mostrando su modelo efectivo y nivel de confianza.
- La validación de campo depende de datos PVT, survey, completación y catálogos reales.

## Inicio de AOS 0.1.0

La rama 0.1.0 comienza con:

- menú principal jerárquico por sistema de levantamiento;
- funciones transversales separadas;
- base para administración permanente de catálogos;
- separación más estricta entre configuración del pozo y resultados de cada sistema.

# AOS 0.1.0 — Inicio de rama

**Fecha:** 15 de julio de 2026  
**Base:** AOS 0.0.12B Final Archivo  
**Entorno:** GNU Octave

## Objetivo del hito

AOS 0.1.0 comienza reorganizando la aplicación por sistemas de levantamiento sin reescribir los solvers validados en 0.0.12B.

## Nuevo menú principal

1. Gas Lift / Jet Gas Lift
2. Bombeo Electrosumergible
3. Bombeo Mecánico
4. Otros sistemas de levantamiento
5. Datos y geometría del pozo
6. Importar / Exportar
7. Administración de catálogos
8. Reportes y AOS Viewer
9. Configuración general

Los módulos específicos quedan dentro del sistema correspondiente. Survey, geología, intercambio, reportes y configuración permanecen como funciones transversales.

## Catálogos

Esta primera entrega incorpora el punto de entrada y el listado no destructivo de los catálogos base existentes. La infraestructura permanente prevista para 0.1.0 tendrá tres capas:

1. catálogos base de AOS;
2. catálogos permanentes del usuario;
3. catálogos opcionales embebidos en `.aosdat`.

La importación, fusión, activación y versionado se implementarán durante la rama 0.1.0. No se modifican los archivos base de 0.0.12B.

## Compatibilidad

Los nuevos menús llaman a las mismas funciones físicas de 0.0.12B. Esta etapa cambia la navegación y la separación conceptual, no los resultados de los solvers.

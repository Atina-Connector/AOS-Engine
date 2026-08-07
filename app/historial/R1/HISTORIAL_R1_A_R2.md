# Transición AOS 0.1.9 R1 a AOS 0.1.9 R2

## Baseline R1

R1 consolidó la arquitectura de workbenches, AOSCAD DEV1 R9.1 y AOSBCK R1.
La verificación dinámica aportada por el usuario confirmó la operación de:

- AOSCAD DEV1;
- dominio hidráulico selectivo R9;
- BES3 DEV5;
- AOSBCK R1, con una observación sobre limpieza interactiva de temporales.

## Causas de R2

R2 se genera para corregir regresiones de integración sin alterar las ecuaciones
físicas existentes:

1. restaurar apertura/importación universal desde AOS Suite;
2. agregar apertura contextual en bancos y módulos de simulación;
3. restaurar la prioridad del `.aosdat` activo sobre los defaults;
4. formalizar el contrato simétrico `AOS_CATALOGO_R2`;
5. recuperar galerías de mandriles y galerías CAD;
6. reconectar BES3 al menú BES;
7. reemplazar verificaciones rígidas por controles semánticos;
8. eliminar preguntas al limpiar temporales AOSBCK;
9. controlar el path operativo y retirar una copia pública duplicada, cuyo
   contenido se conserva en el historial como texto no ejecutable.

## Regla de conservación

R2 debe conservar todas las funciones únicas de R1. La única ruta ejecutable
retirada corresponde a una copia duplicada de
`aos_verificar_requisitos_plataforma.m`; la interfaz pública equivalente sigue
activa y el contenido retirado se archivó en
`historial/codigo_retirado_R2/`.

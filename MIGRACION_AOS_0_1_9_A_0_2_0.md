# Migracion de AOS 0.1.9 a AOS 0.2.0 DEV1

## Baseline

La baseline exacta utilizada fue el ZIP auditado de AOS 0.1.9 R2 HF3.4-CAD-R16 con SHA-256:

`addcee6e609aac769794fada358f9d8246539378a806e69a1b035818949ac421`

## Politica

- No se eliminaron archivos activos de `src/`.
- Los instaladores historicos extraidos se retiraron del arbol ejecutable y sus archivos comprimidos se conservaron en `historial/0_1_9_R2_HF3_4_CAD_R16/instaladores/`.
- Se integraron los 74 archivos funcionales y documentales de HF3.5, con fusion manual del unico conflicto funcional: `aos_aoscad_escribir.m`.
- La fusion conserva simultaneamente la composicion de tablas HF3.5 y la generacion de recursos visuales AOSCAD R16.
- La fisica de los solvers no fue modificada por esta migracion.

## Inicio recomendado

Extraer AOS 0.2.0 DEV1 en una carpeta nueva. No sobrescribir la instalacion 0.1.9.

## Enmienda de arquitectura ENV-01

La revisión ENV-01 no modifica la física ni el runtime. Corrige la arquitectura objetivo para reconocer AOS Environmental como banco independiente.

Migración planificada:

```text
src/menu/AOS_menu_gestion_ambiental.m
        -> alias de compatibilidad
src/workbenches/environmental/
        -> banco objetivo
AOS_menu_environmental
        -> entrypoint futuro
```

La migración deberá conservar `AMBIENTAL`, las secciones históricas de datos y el acceso desde Maintenance durante una etapa de transición.

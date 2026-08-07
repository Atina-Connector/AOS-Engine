# Arquitectura AOS Suite 0.1.9

## Proposito

AOS 0.1.9 es la puerta de entrada a AOS 0.2.0. Establece la separacion entre bancos de trabajo, servicios transversales, solvers cientificos y la futura orquestacion de AOS Global.

## Capas

```text
BANCOS DE TRABAJO
SLA | Wells | CAD | Networks | Electrical | Facilities | Geology |
Fluids | SCADA | Maintenance | Data | Solvers | Global | Viewer

SERVICIOS TRANSVERSALES
AOS 3D Core | Fluids Service | Unidades | Catalogos | Validacion | Reportes

SOLVERS
Hidraulicos | Electricos | Mecanicos | Termicos | Geologicos |
Reservorio | Produccion | Multfisicos | Grafos | Optimizacion | Riesgo

AOS GLOBAL
Orquestacion futura sin duplicar ecuaciones ni datos maestros.
```

## Reglas

- Viewer queda ultimo en la cinta.
- Los bancos en roadmap siguen visibles.
- AOS Fluids es la fuente oficial de propiedades mediante `fluid_id`.
- AOS 3D Core administra geometria y representacion, no fisica.
- AOS Solvers resuelve problemas matematicos y no contiene menus de dominio.
- Los activos comparten un `asset_id` persistente entre tablas, 3D, topologia, SCADA, mantenimiento y reportes.
- GNU Octave es el motor cientifico oficial.

## Contratos para el frame 0.2.0

Los manifiestos se encuentran en `src/roadmap` y definen workbenches, servicios, solvers, roadmap, orden de cinta y contexto compartido.

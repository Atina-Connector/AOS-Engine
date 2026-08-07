# AOS 0.1.3-R2 - Roadmap integral de capacidades

Este archivo define la envolvente funcional completa de AOS. La presencia de un menu no implica que el solver fisico correspondiente este publicado.

## Fases

1. **0.1.3 - Estabilizacion:** GL/JGL, BM, formatos y servicios comunes.
2. **0.1.4 - BES3 y consolidacion:** frecuencia cero, flujo natural, recirculacion y cierre funcional.
3. **0.2.x - Infraestructura y SCADA:** CAD-TOP, inyectores, mallas, baterias, fluidos, electricidad, arranque y SCADA.
4. **0.3.x - Inteligencia operativa:** ambiente, integridad, mantenimiento, Pulling Intelligence y economia.
5. **1.0 - Plataforma integral:** orquestacion del yacimiento y motor CAD interno basado en Open CASCADE.

## Dependencias de plataforma

- Motor cientifico unico: GNU Octave.
- CAD 2D inicial: LibreCAD y DXF.
- CAD 3D inicial: FreeCAD y STEP.
- Motor CAD futuro: Open CASCADE Technology integrado internamente.

## Regla de madurez

- OPERATIVO: capacidad disponible para el alcance declarado.
- BETA: capacidad disponible con validacion ampliada pendiente.
- DESARROLLO: interfaz o solver en construccion.
- PLANIFICADO: contrato, menu y datos definidos; solver no publicado.
- LEGADO: conservado como testigo o compatibilidad.

La interfaz debe exponer siempre el estado real y no presentar funciones planificadas como resultados fisicos disponibles.

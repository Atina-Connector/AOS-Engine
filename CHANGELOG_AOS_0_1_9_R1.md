# AOS 0.1.9 R1 - Componentes AOSBCK y visualizacion 3D bajo demanda

AOS 0.1.9 R1 conserva la totalidad de AOS 0.1.9 y agrega la primera implementacion transversal de componentes 3D reutilizables.

## Contrato AOSBCK

- STEP permanece como geometria neutral de origen.
- `.aosbck` es un contenedor ZIP abierto con `manifest.json`, una geometria STEP, metadatos y previsualizacion.
- Un `component_id` representa la definicion de catalogo.
- Un `part_number` representa el modelo comercial.
- Cada `instance_id` representa una ocurrencia fisica.
- Una sola geometria puede tener cientos de instancias sin duplicar el STEP.

## Ubicaciones

- `WELL_SURVEY`: posicion y orientacion calculadas por MD, survey, inclinacion y azimut.
- `AOSCAD_NODE`: posicion vinculada a un nodo de la instalacion.
- `XYZ_MANUAL`: coordenadas y orientacion ingresadas por el usuario.

## Alcance R1

- Crear AOSBCK desde STEP.
- Abrir, validar y actualizar paquetes.
- Agregar multiples instancias.
- Vincular instancias a Survey y nodos AOSCAD.
- Guardar referencias en `CONFIG_ACTIVA` y, para superficie, en tablas `.aoscad`.
- Visualizar una pieza seleccionada en FreeCAD bajo demanda.
- Definir metadatos de puertos para futuras conexiones.

## Fuera del alcance actual

- Ensamblaje 3D completo.
- Restricciones geometricas entre componentes.
- Interferencias y contactos.
- Carga simultanea de toda una instalacion.

Estas capacidades permanecen en el roadmap de AOS 3D Core y AOS Global.

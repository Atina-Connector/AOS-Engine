# AOSBCK R1 - Manual de componentes 3D reutilizables

## Objetivo

AOSBCK permite convertir una geometria STEP en un componente AOS identificado y reutilizable. Una sola geometria puede representar muchas ocurrencias fisicas. Cada ocurrencia conserva su propio `instance_id`, ubicacion, orientacion, estado, lote, serie e historial.

## Accesos

- AOS CAD > CAD 3D / STEP > Administrar componentes AOSBCK.
- AOS Wells > Componentes de completacion AOSBCK por Survey.
- AOS Networks, Electrical y Facilities > Componentes AOSBCK.
- AOS Data > Componentes `.aosbck`, partes e instancias.
- AOS 3D Core > Componentes AOSBCK.

## Crear un componente

1. Seleccionar `Crear .aosbck desde STEP`.
2. Elegir el archivo STEP.
3. Completar numero de parte, tipo, descripcion, fabricante, proveedor, material y unidades.
4. AOS genera un contenedor abierto `.aosbck`.

Contenido:

```text
componente.aosbck
  manifest.json
  geometry/pieza.step
  metadata/properties.json
  preview/README.txt
```

## Instancias en pozos

1. Cargar un `.aosdat` con survey.
2. Abrir AOS Wells > Componentes AOSBCK.
3. Abrir el componente.
4. Seleccionar `Agregar instancia por Survey / MD`.
5. Ingresar MD y rotacion axial.

AOS calcula X, Y, TVD, inclinacion, azimut y quaternion. La referencia al survey se conserva para recalcular la posicion si cambia la trayectoria.

## Instancias en superficie

1. Importar y normalizar el DXF en AOS CAD.
2. Abrir el AOSBCK.
3. Seleccionar `Tocar nodo AOSCAD y vincular instancia`.
4. Tocar el nodo en el plano; si no hay visor grafico, ingresar el ID.
5. Completar datos particulares de la pieza.

La instancia se guarda en `CONFIG_ACTIVA.componentes_3d` y en las tablas `componentes_3d` e `instancias_3d` del modelo `.aoscad`. El nodo recibe `asset_instance_id`, `component_id` y `part_number`.

## Visualizacion

La opcion `Visualizar componente o instancia en FreeCAD` extrae y abre solamente el STEP maestro. La ficha muestra numero de parte, proveedor, material, ubicacion y estado de la instancia seleccionada. R1 no carga un ensamblaje completo.

## Puertos

R1 permite declarar puertos de tipo `FLUID`, `ELECTRICAL` o `MECHANICAL`, con tamano nominal, norma de conexion, posicion local y direccion local. El apareamiento automatico y la validacion de interferencias permanecen en roadmap.

## Identidades

- `part_number`: identidad comercial.
- `component_id`: definicion reutilizable del catalogo AOS.
- `instance_id`: pieza fisica ubicada en un proyecto.

## Limites de R1

- No construye una escena completa.
- No resuelve restricciones de ensamblaje.
- No calcula interferencias.
- No duplica geometria para componentes repetidos.
- La visualizacion se realiza bajo demanda mediante FreeCAD.

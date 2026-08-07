# Auditoria transversal de punzados - AOS 0.1.9 R2 HF3

## Dictamen

La capacidad historica de crear y editar punzados habia quedado reducida a un
cargador dependiente de Geologia. HF3 restaura un gestor transversal,
transaccional e independiente de Survey y Geologia.

## Alcance auditado

- Menus de Suite, Wells, Geology, Data y herramientas comunes SLA.
- Importacion y exportacion `.aosdat`.
- Sincronizacion entre `CONFIG_ACTIVA.punzados` y Geologia.
- Visualizaciones 2D/3D y tablas del pozo.
- Distribucion de produccion y calculo de erosion por punzados.
- Invalidacion de resultados cuando cambia la completacion.
- Compatibilidad con el bloque historico `[PUNZADOS]`.

## Hallazgos corregidos

1. No existia CRUD de intervalos individuales.
2. No era posible configurar punzados sin Geologia activa.
3. La ausencia de Survey bloqueaba o degradaba el flujo manual.
4. El contrato legacy solo preservaba cuatro valores por intervalo.
5. Los tramos desactivados no tenian persistencia completa.
6. Metadatos como ID, zona, fase, penetracion, permeabilidad, skin,
   validacion y observaciones podian perderse.
7. Algunos consumidores no filtraban de manera uniforme los tramos activos.
8. Los cambios no invalidaban todos los resultados transversales.
9. Campos adicionales agregados por API podian romper la homogeneidad de un
   arreglo de estructuras GNU Octave.

## Solucion HF3

- Gestor CRUD transaccional con crear, agregar, editar, duplicar, activar,
  desactivar, eliminar, ordenar, fusionar e importar.
- Generacion regular de varios intervalos por rango MD, longitud, separacion,
  densidad y diametro.
- Edicion manual en MD sin Survey; TVD se calcula cuando el Survey existe.
- `[PUNZADOS]` mantiene compatibilidad historica.
- `[PUNZADOS_META]` conserva la ficha tecnica completa.
- Campos desconocidos se preservan en `extras`.
- Los caracteres reservados de `.aosdat`, incluidos `#` y `%`, se protegen
  mediante codificacion porcentual reversible en metadatos JSON.
- Geologia se sincroniza solo cuando existe una seccion geologica real.
- Los solvers y diagnosticos reciben unicamente intervalos activos.
- El commit invalida resultados, sensibilidades y reportes anteriores.

## Limites

HF3 no inventa Survey, TVD ni propiedades geologicas. Los intervalos fuera del
rango del Survey generan advertencias por defecto; pueden configurarse como
error estricto mediante la API de validacion.

La auditoria dinamica final debe ejecutarse con GNU Octave mediante:

```octave
VERIFICAR_AOS_0_1_9_R2_HF3(true)
```

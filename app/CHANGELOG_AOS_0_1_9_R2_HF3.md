# AOS 0.1.9 R2 HF3

## Restauracion del gestor transversal de punzados

HF3 recupera y amplia la capacidad historica de crear, editar y completar
intervalos de punzados manualmente. La funcion deja de depender de que exista
una geologia o un Survey cargado.

### Funciones incorporadas

- Gestor CRUD transaccional de intervalos.
- Creacion desde cero, agregado, edicion, duplicacion y eliminacion.
- Activacion y desactivacion sin borrar la ficha tecnica.
- Generacion regular de varios intervalos.
- Campos editables: ID, nombre, MD, densidad, diametro, fase, penetracion,
  tipo de disparo, formacion, permeabilidad, skin, validacion, observaciones,
  origen y campos adicionales.
- Validacion MD/TVD; la ausencia de Survey es un aviso, no un bloqueo.
- Sincronizacion con geologia solo cuando existe una geologia real.
- Invalidacion transversal de resultados al confirmar cambios.
- Importacion/exportacion con compatibilidad historica.

### Contrato .aosdat

- `[PUNZADOS]` conserva las cuatro columnas historicas.
- `[PUNZADOS_META]` agrega metadatos completos por intervalo.
- Los lectores anteriores pueden seguir leyendo el bloque legacy.
- HF3 recupera intervalos inactivos, densidad original y campos extendidos.

### Consumidores corregidos

- Distribucion de produccion por tiros.
- Calculo de erosion por punzados.
- Visualizaciones y tablas de geometria.
- Geologia y configuracion activa.

No se modificaron ecuaciones de los solvers SLA, BES3, Gibbs ni AOSCAD.

### Robustez adicional

- Los campos no canonicos editados por API se guardan en `extras` sin romper
  la homogeneidad de los arreglos de estructuras GNU Octave.
- Los metadatos `extras` protegen caracteres reservados del formato `.aosdat`
  (incluido `#`) mediante codificacion porcentual reversible.
- La fusion y limpieza de intervalos preservan los metadatos generales del
  conjunto de punzados.

# Regresiones y criterios de aceptacion HF3

1. Crear punzados sin Survey ni geologia.
2. Editar MD, densidad y diametro de un intervalo existente.
3. Agregar un tramo faltante y duplicar otro.
4. Desactivar un tramo sin eliminarlo.
5. Cancelar una edicion sin modificar el caso activo.
6. Generar varios intervalos regulares.
7. Calcular TVD cuando existe Survey.
8. Conservar MD y emitir aviso cuando no existe Survey.
9. Round-trip `.aosdat` de ID, nombre, activo, fase, penetracion,
   permeabilidad, skin, observaciones y extras.
10. Compatibilidad con `[PUNZADOS]` historico.
11. Sincronizacion con geologia solo si existe.
12. Invalidacion de resultados al confirmar cambios.
13. Exclusion de intervalos inactivos en erosion y distribucion productiva.
14. Acceso visible desde AOS Wells, AOS Data, Geology, SLA y BES3 mediante
    el menu transversal de datos del pozo.
15. Preservar campos adicionales agregados durante una edicion programatica.
16. Preservar caracteres `#` y `%` dentro de metadatos `extras` en el
    round-trip `.aosdat`.

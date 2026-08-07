# AOSCAD 0.0.1 DEV1 R8

## Menu jerarquico y nucleo hidraulico visible

- El menu principal AOSCAD se reduce a siete categorias.
- La simulacion hidraulica pasa a tener un submenu propio y visible.
- Se separan CAD 2D/DXF, CAD 3D/STEP, topologia, reportes y diagnosticos.
- Se incorporan pantallas para preparar, configurar, validar, ejecutar y revisar la red hidraulica.
- Las tablas nodales y por tramo quedan accesibles directamente desde el submenu hidraulico.
- Se incorporan guardados independientes `.aoscad` simple y enriquecido.
- Se agrega un flujo completo: simular, validar y guardar ambos perfiles.
- Se elimina la copia duplicada de `AOS_menu_cad_topologia.m` dentro del modulo.
- El punto publico unico queda en `src/menu` y llama a una implementacion con nombre unico.
- El visor 2D reconoce tanto `caudal_liquido_m3s` como el campo heredado `caudal_m3s`.
- La configuracion hidraulica puede editarse desde AOS Suite; cualquier cambio invalida resultados previos.

No se modifican las correlaciones, ecuaciones ni restricciones fisicas del solver DEV1.

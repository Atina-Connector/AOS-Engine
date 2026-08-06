# AOSCAD Hidráulica 0.0.1 DEV1

## Incorporado

- solver hidráulico de redes abiertas obtenidas desde DXF;
- balance de caudal en topologías de árbol;
- propagación de presión desde un BC de presión;
- Darcy-Weisbach monofásico;
- adaptadores a HB, Duns–Ros y VLP simplificado existentes en AOS;
- gravedad mediante coordenada Z;
- pérdidas menores de accesorios;
- válvulas con Kv;
- tablas nodales y por tramo en `.aoscad`;
- registro de modelos y parámetros efectivos;
- metadatos hidráulicos opcionales en AOS_META;
- ejemplo DXF y selftest end-to-end;
- integración con el menú AOSCAD.

## Limitaciones

Redes sin lazos, una presión de referencia, demandas positivas y sin curvas activas
de bombas/compresores. Los modelos multifásicos se reutilizan desde AOS pero todavía
no fueron validados como solver de redes.

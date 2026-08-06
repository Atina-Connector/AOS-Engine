# AOS 0.1.9 R1.1 - Restauracion transversal

Esta revision corrige una regresion de navegacion introducida durante la separacion de AOS en bancos de trabajo.

## Restaurado

- Gestion universal del caso desde el menu principal.
- Importacion directa de `.aosdat` y `.aosrpt`.
- Exportacion de la configuracion activa a `.aosdat`.
- Configuracion efectiva del caso desde el menu general.
- Accesos contextuales de apertura/importacion en todos los bancos operativos, beta y en desarrollo.
- Catalogos embebidos en `.aosdat` como fuente de verdad.
- Registro permanente de catalogos `.aosdat` en `datos_usuario/catalogos/aosdat`.
- Fusion de catalogos y galerias con un caso activo sin reemplazar sus datos de pozo.
- Galeria completa de mandriles y seleccion por el solver GL.
- Galerias CAD/DXF: camaras, ramales y accesos.
- Menu de compatibilidad con la numeracion de AOS 0.1.9 R1.

## Regla preservada

`config/` aporta defaults. Cuando existe un `.aosdat` activo, el archivo importado conserva prioridad y no debe ser pisado silenciosamente.

No se modificaron las ecuaciones de los solvers ni se incorporaron archivos `.mat`.

# Historial de desarrollo - AOS 0.1.9 R1

AOS 0.1.9 R1 es la baseline inmediatamente anterior a R2 y queda preservada
como entrega historica inmutable.

## Identificacion

- Archivo: `AOS_0_1_9_R1_HISTORICO.zip`
- Nombre original: `AOS_0_1_9_R1_COMPLETO.zip`
- SHA-256: `7032b765346828bb26dc8ceada580dbe3fc6166ff879db427b361d5fc6637cb3`
- Motor objetivo: GNU Octave

## Hito principal de R1

R1 incorporo AOSBCK como servicio transversal: una geometria STEP reutilizable,
metadatos de componente e instancias ubicables mediante Survey, nodos AOSCAD o
coordenadas XYZ.

## Motivo de R2

R2 conserva el contenido de R1 y corrige regresiones de navegacion y contratos
introducidas durante la reorganizacion por bancos de trabajo:

- importacion universal y contextual;
- configuracion y prioridad por `.aosdat`;
- catalogos y galerias;
- acceso a BES3;
- verificadores dependientes de numeracion visual;
- limpieza temporal AOSBCK;
- funciones sombreadas y path indiscriminado.

La baseline R1 no debe modificarse. Cualquier desarrollo posterior debe partir
de R2 o declarar explicitamente la dependencia historica utilizada.

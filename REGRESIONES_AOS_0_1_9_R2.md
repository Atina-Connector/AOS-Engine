# Regresiones y criterios de aceptación - AOS 0.1.9 R2

R2 no modifica ecuaciones físicas. Su objetivo es recuperar la gestión de casos
y estabilizar la arquitectura modular antes de distribuir los bancos de trabajo.

## Obligatorios

- Menú principal con apertura/importación transversal.
- Catorce workbenches registrados, visibles y despachados; Viewer último.
- Apertura contextual desde bancos y sistemas SLA.
- `.aosdat` activo con prioridad sobre defaults.
- Catálogos `AOS_CATALOGO_R2` importables y exportables sin pérdida.
- Catálogo puro o galería no reemplaza el caso activo.
- Galería `[MANDRILES_GALERIA]` y galerías CAD disponibles.
- BES3 accesible desde BES con estado no validado explícito.
- AOSBCK sin preguntas al borrar temporales.
- Sin archivos `.mat`, sin funciones públicas duplicadas y sin `genpath`
  indiscriminado en la ejecución normal.
- AOSCAD, dominio hidráulico R9, AOSBCK y BES3 deben conservar sus selftests.

## Comandos

```octave
clear functions
rehash
VERIFICAR_AOS_0_1_9_R2(false)
VERIFICAR_AOS_0_1_9_R2(true)
```

La aprobación dinámica oficial debe registrarse con la salida completa de GNU
Octave, versión del sistema operativo y hash de la distribución probada.

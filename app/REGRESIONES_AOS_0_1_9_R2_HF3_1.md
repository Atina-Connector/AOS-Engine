# Regresiones AOS 0.1.9 R2 HF3.1

## Criterios obligatorios

1. Las cinco utilidades transversales de conversion deben existir en la raiz
   activa y ser resueltas por `which` dentro de esa misma raiz.
2. `aos_logico_seguro('si', false)` debe devolver verdadero y estado valido.
3. `aos_logico_seguro('no', true)` debe devolver falso y estado valido.
4. Un punzado con `activo='no'` debe normalizarse sin excepciones y permanecer
   inactivo.
5. Los cinco selftests HF3 deben ejecutarse despues del control de dependencias.
6. El hotfix aplicado sobre la instalacion HF2 resultante de los ZIP publicados
   debe producir el mismo arbol que la distribucion completa HF3.1.
7. Ante cualquier falla, el instalador debe restaurar todos los archivos
   reemplazados y retirados.

## No regresion

- Sin archivos `.mat`.
- Sin funciones publicas duplicadas por nombre dentro de `src`.
- Sin cambios en los nucleos fisicos.
- Compatibilidad con `[PUNZADOS]` y `[PUNZADOS_META]`.

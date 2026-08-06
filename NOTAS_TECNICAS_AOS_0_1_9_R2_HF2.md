# Notas tecnicas HF2

- Instalar sobre AOS 0.1.9 R2, con o sin HF1.
- El instalador crea respaldo fuera de la raiz AOS.
- La instalacion no toca ecuaciones ni solvers.
- La geologia activa se actualiza mediante commit atomico.
- Las listas en `.aosdat` ya no se evalúan; los consumidores especializados
  usan `aos_vector_seguro`.
- Las preguntas binarias deben expresan una sola accion. Cuando existen varias
  acciones validas se utiliza un menu numerado.

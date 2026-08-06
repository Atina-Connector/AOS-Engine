# AOS 0.1.9 R2 HF3.1

Fecha: 2026-07-29
Motor oficial: GNU Octave

## Motivo

HF3.1 corrige una falla de empaquetado detectada durante la instalacion de HF3.
El gestor de punzados utilizaba `aos_logico_seguro`, pero el hotfix HF3 original
presuponia que esa dependencia habia sido instalada por HF2. El ZIP operativo de
HF2 no la habia transportado, aunque los manifiestos de la distribucion completa
si la declaraban.

La instalacion de HF3 se detuvo correctamente y restauro HF2. No se modificaron
el caso activo, los solvers ni los resultados del usuario.

## Correcciones

- El hotfix HF3.1 es autocontenido respecto de las dependencias transversales:
  - `aos_texto_seguro`
  - `aos_numero_seguro`
  - `aos_vector_seguro`
  - `aos_logico_seguro`
  - `aos_preguntar_sn`
- El instalador comprueba la existencia y la ruta efectiva de esas funciones
  antes de ejecutar cualquier selftest.
- Se retira la copia obsoleta de `aos_vector_seguro` ubicada en
  `src/utilidades/intercambio`, evitando sombreado con la version canonica de
  `src/utilidades/config`.
- Se agrego `test_aos_punzados_dependencias_hf3_1`.
- El verificador HF3.1 falla con un diagnostico explicito si una dependencia no
  pertenece a la raiz AOS activa.
- El payload se genero contra la instalacion real producida por los hotfixes
  distribuidos, no solamente contra la distribucion completa de laboratorio.

## Alcance fisico

No se modificaron ecuaciones, correlaciones, solvers, parametros de pozo,
Survey, geologia, resultados ni contratos de archivos. La correccion es de
empaquetado, carga de dependencias y verificacion.

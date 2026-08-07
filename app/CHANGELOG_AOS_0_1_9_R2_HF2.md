# AOS 0.1.9 R2 HF2 - Auditoria transversal de interacciones y datos

Fecha: 2026-07-29  
Motor oficial: GNU Octave  
Base: AOS 0.1.9 R2 + HF1

## Objetivo

HF2 corrige de manera transversal la familia de fallas observada al administrar
geologia y al convertir valores provenientes de configuraciones, catalogos,
reportes y componentes. El alcance incluye interfaz, parseo seguro,
transacciones, galerias y estabilidad de la campana de pruebas.

## Correcciones

- Reemplaza el dialogo ambiguo `Reemplazar o editar? (s/n)` por un administrador
  de geologia con acciones numeradas y explicitamente separadas.
- Edicion de geologia basada en una copia de la geologia activa; no recarga
  defaults ni modifica globals antes de confirmar.
- Reemplazo transaccional con comparacion previa, confirmacion destructiva por
  defecto NO y rollback ante errores.
- Gestion explicita de punzados: conservar, usar nuevos, fusionar o cancelar.
- Invalida resultados solo cuando cambian datos fisicos.
- Incorpora `aos_numero_seguro`, `aos_vector_seguro`, `aos_logico_seguro` y
  estandariza las preguntas binarias mediante `aos_preguntar_sn`.
- Elimina preguntas s/n directas del codigo activo; respuestas invalidas ya no
  se interpretan silenciosamente como NO.
- El parser `.aosdat` distingue escalares de listas y elimina el uso de
  `str2num`/evaluacion de expresiones.
- Corrige el round-trip de vectores de catalogos (Q, head, potencia).
- La galeria de mandriles conserva elementos deshabilitados o sin stock; el
  selector fisico realiza el filtrado.
- Restaura el path de tests antes y despues de cada selftest.
- Endurece importacion `.aosrpt`, AOSBCK, GF3, semaforos y resumentes de menu
  frente a tipos inesperados.
- Agrega auditoria automatica de interacciones y regresiones HF2.

## Sin cambios fisicos

HF2 no modifica ecuaciones, correlaciones, solvers, resultados numericos ni los
contratos `.aoscad`/`.aosbck`. Los cambios se limitan a interfaz, parseo,
persistencia, catalogos, galerias, reportes y QA.

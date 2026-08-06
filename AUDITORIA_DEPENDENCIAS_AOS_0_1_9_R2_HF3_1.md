# Auditoría de dependencias - AOS 0.1.9 R2 HF3.1

## Hallazgo

La instalación de HF3 original se detuvo en los selftests porque
`aos_punzados_normalizar` llamó a `aos_logico_seguro` y la función no estaba
disponible en la instalación HF2 activa.

La causa no estaba en el gestor de punzados ni en GNU Octave. Fue una
inconsistencia de empaquetado: la distribución completa HF2 contenía la
utilidad, pero el ZIP autoinstalable publicado de HF2 no la transportó. HF3
presuponía la instalación completa de HF2 y no incluía nuevamente la
dependencia.

## Medida correctiva

HF3.1 se construye contra el árbol real producido por los ZIP distribuidos y
transporta todas las dependencias transversales necesarias. El instalador
comprueba antes de los selftests que `which` resuelva cada función dentro de la
raíz AOS activa.

## Dependencias obligatorias

- `aos_texto_seguro`
- `aos_numero_seguro`
- `aos_vector_seguro`
- `aos_logico_seguro`
- `aos_preguntar_sn`

## Prevención

- El payload se deriva por comparación de árboles y no por una lista manual
  parcial.
- Cada archivo del payload tiene SHA-256.
- La aplicación simulada del hotfix debe producir el mismo árbol que la
  distribución completa HF3.1.
- Las funciones duplicadas u obsoletas se respaldan y retiran antes de validar.

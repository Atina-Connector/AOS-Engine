# AOSCAD 0.0.1 DEV1

Primera version de desarrollo identificada formalmente.

## Cambios de arquitectura

- GNU Octave queda como unico motor objetivo.
- `.aoscad` JSON UTF-8 es la unica fuente persistente.
- Eliminadas las representaciones binarias paralelas del modelo, preferencias, mapa de menús y exportación GF3.
- El lector acepta solo `.aoscad` y puede migrar en memoria el JSON del mockup previo.
- Escritura atomica con decodificacion y control de cantidades antes de confirmar.
- Las tablas de una sola fila se normalizan correctamente al reabrir.
- Toda edicion invalida y elimina resultados anteriores.
- El contrato deja de presentarse como 1.0 y pasa a `AOSCAD-0.0.1-DEV1`.
- Incorporado JSON Schema formal y verificador global de arquitectura Octave-only.

## Estado

El modulo sigue siendo `PROTOTIPO_NO_VALIDADO`. El solver hidraulico es una
demostracion y no un solver oficial de red.

## Revisión de empaquetado REV2

- Corregido falso positivo de `.mat` sobre campos `.material`.
- Agregadas autopruebas del detector.
- El instalador limpia la función anterior de la memoria de Octave antes de verificar.
- No se modificó física, formato `.aoscad` ni lógica de simulación.

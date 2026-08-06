# Regresiones obligatorias AOS 0.1.9 R2 HF2

## Conversiones seguras

- Escalares con notacion E/D se convierten sin evaluar codigo.
- Estructuras, vectores o expresiones se rechazan como escalares.
- Listas `10,20,30`, `10;20;30` y `[10 20 30]` se conservan/parsean como
  vectores segun el contrato consumidor.
- No existe uso activo de `str2num`.

## Geologia

- Editar parte de la geologia activa.
- Cancelar no cambia geologia, punzados ni resultados.
- Reemplazar no confirma por defecto.
- Punzados se conservan, reemplazan o fusionan solo por opcion explicita.
- Un fallo durante commit restaura el estado anterior.

## Catalogos y galerias

- Round-trip de bomba conserva `Q=[10 20 30]`, `head=[100 90 70]` y etapas.
- Galeria completa contiene 24 elementos, 23 habilitados y la reserva
  `AOS_SPARE_DISABLED` preservada con stock cero.

## Campana de tests

- Cada selftest vuelve a disponer de `src/tests`.
- `test_aosdat_roundtrip_001` permanece visible despues de un test legacy.
- La auditoria transversal encuentra cero preguntas binarias directas, cero
  acciones binarias ambiguas y cero conversiones evaluadas.

## Criterio de liberacion

```octave
VERIFICAR_AOS_0_1_9_R2_HF2(true)
```

debe devolver `ans = 1` en GNU Octave.

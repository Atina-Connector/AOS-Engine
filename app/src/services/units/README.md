# AOS Units service

Servicio compartido de conversion de unidades hacia SI (metros) para AOS 0.1.9 / 0.2.0.
Primer codigo real del namespace `units` (declarado ACTIVE en el mapa de servicios).

## API

### `aos_units_factor_a_metros(nom)`

- **Entrada**: nombre de unidad (string), p.ej. `'m'`, `'mm'`, `'cm'`, `'in'`, `'ft'` y sinonimos.
- **Salida**: `[factor, nombre, ok]`
  - `factor`: multiplicador para convertir a metros
  - `nombre`: nombre canonico (`m`/`mm`/`cm`/`in`/`ft`)
  - `ok`: `false` si el nombre no se reconoce (entonces `factor=1`, `nombre='m'`)

Tabla reconocida:

| Nombre(s) | Factor a m |
|-----------|------------|
| m, metro(s), meter(s) | 1 |
| mm, milimetro(s), millimeter(s) | 0.001 |
| cm, centimetro(s), centimeter(s) | 0.01 |
| in, inch(es), pulgada(s) | 0.0254 |
| ft, foot/feet, pie(s) | 0.3048 |

## Consumidor CAD

`aos_cad_unidades_dxf` conserva la prioridad DXF:

1. Metadato `AOS UNIDADES=`
2. `$INSUNITS` del HEADER
3. Preferencia de modulo
4. Default metros

y delega solo la conversion nombre→factor a este servicio.

## Notas

- Namespace distinto de wrappers CAD (`aos_units_*` vs `aos_cad_*`).
- Solo GNU Octave.

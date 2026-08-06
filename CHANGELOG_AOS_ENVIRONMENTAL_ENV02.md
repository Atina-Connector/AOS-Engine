# Changelog AOS Environmental ENV-02

## Alcance

Implementacion del runtime shell aprobado por ADR-AOS-2026-001 sobre AOS 0.2.0 DEV1 ENV-01.

## Cambios

- AOS Environmental visible en el menu principal entre SCADA y Maintenance.
- Nuevo entrypoint independiente `AOS_menu_environmental`.
- Registro runtime de quince workbenches.
- Maintenance conserva solo un acceso cruzado; no posee el modelo ambiental.
- `AOS_menu_gestion_ambiental` se conserva como alias historico.
- Se agrego selftest de orden, visibilidad, despacho y compatibilidad.
- Manifests actualizados a `ENV-02` y `runtime_available=true`.

## Limite deliberado

ENV-02 no implementa ecuaciones, schemas detallados, factores de emision, cuantificacion de derrames, dispersion de H2S, importadores LDAR ni reportes ambientales especializados. Esos elementos requieren contratos y benchmarks antes de su implementacion.

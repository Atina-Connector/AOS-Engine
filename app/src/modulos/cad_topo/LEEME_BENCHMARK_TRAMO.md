# Benchmark de tramo AOSCAD vs núcleo AOS

Documento de tolerancias formales del Sprint 1 (baseline), extendido en Sprint 3
con identidad de balance que incluye `dp_equipo_Pa`.
Selftest: `test_aos_cad_benchmark_tramo.m`

## Principio

AOSCAD no duplica física. El monofásico usa Darcy-Weisbach con
`aos_vlp_friccion` cuando está en path. El multifásico resuelve `P_out`
por bisección y valida contra `aos_vlp_integrar` / `vlp_simplified_corregida`.

El núcleo VLP (`src/core/common/vlp/*`) es referencia: no se modifica para
hacer pasar el benchmark.

## Tolerancias

| Magnitud | Criterio | Valor |
|---|---|---|
| Presión (bisección / cierre) | absoluto | config `tol_presion_Pa` (default 10 Pa); techo de aceptación multifásico 2e3 Pa |
| Monofásico vs fórmula Swamee-Jain idéntica | relativo | ≤ 1e-9 (f, Re, ΔP) |
| Multifásico vs núcleo directo | absoluto | \|P_req − P_in\| ≤ max(tol_presion, 2e3 Pa) |
| Holdup líquido | absoluto | ± 0.01 |
| Régimen | literal | igualdad de string |
| Balance interno | relativo | `dp_total = dp_fric + dp_grav + dp_menores + dp_equipo` ≤ 1e-6 |

## Identidad de balance (Sprint 3)

```
dp_total_Pa = dp_fric_Pa + dp_grav_Pa + dp_menores_Pa + dp_equipo_Pa
```

- `dp_equipo_Pa` es el aporte de equipos activos (bomba/compresor). Negativo =
  ganancia de presión. No se mezcla con `dp_menores_Pa` (accesorios/válvulas).
- En M1–M3 y F1–F4 (sin equipo activo) se exige `dp_equipo_Pa == 0`.
- Los números monofásicos/multifásicos del Sprint 1 se conservan (misma física
  de tramo; solo se añade el término nulo de equipo).

## Casos

- **M1** monofásico horizontal (ΔP fricción)
- **M2** monofásico con desnivel ±50 m (gravedad + ERROR por P_min)
- **M3** laminar Re<2000 y transición Re≈3000 (exige `aos_vlp_friccion`)
- **F1/F2/F3** multifásico HB / DR / simplificado (cierre contra núcleo)
- **F4** no convergencia controlada (advertencia presente, nunca silenciosa)
- **A3** pérdidas menores: Kv, CODO, válvula cerrada, bomba sin curva
  (`EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1`, `dp_equipo=0`)

## Limitaciones

- Equipos activos sin curva: solo advertencia
  `EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1` (head=0). Con curva válida el
  head se calcula (ver `test_aos_cad_equipo_activo_curva` / Sprint 3).
- Sin lazos Kirchhoff (`HYD_LOOP` roadmap).

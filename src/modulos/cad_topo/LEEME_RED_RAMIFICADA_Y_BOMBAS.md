# Red ramificada, bombas con curva y condiciones de dominio (Sprint 3)

Documento de contrato y limitaciones DEV1. Selftest de campana en red:
`test_aos_cad_benchmark_red.m` sobre `datos/ejemplos/cad/demo_aos_red_ramificada.dxf`.

## Topologia soportada

- Arbol conectado sin lazos (`rechazar_lazos = true`).
- Exactamente **una** fuente de presion (BC `PRESION`).
- Una o mas demandas de caudal positivas en hojas o nodos.
- Bifurcaciones (nodos de grado >= 3) permitidas y auditables:
  - cada nodo expone `grado`, `es_bifurcacion`, `balance_nodal_m3s`;
  - el resumen expone `n_bifurcaciones`, `topologia_resuelta`
    (`CADENA_SERIE` | `ARBOL_RAMIFICADO`) y `residual_balance_max_m3s`.
- Fixture de referencia: `N1(P) —T1— N2` con bifurcacion a `T2→N3(Q)` y
  `T3→N4`; en `N4` bifurcacion a `T4→N5(Q)` y `T5→N6(Q)`.

Fuera de alcance (Sprint 4+): lazos Kirchhoff, multiples fuentes de presion,
flujo reverso.

## Contrato de curva head–caudal (separador `|`)

Las listas en metadatos DXF **no pueden usar coma** (`parse_keys_local` parte
por espacio / `;` / `,`). Separador obligatorio: `|`.

| Clave | Significado |
|---|---|
| `CURVA_Q=0\|50\|100\|150` | Caudales (default m3/d) |
| `CURVA_H=120\|110\|85\|40` | Head (m de columna de liquido) |
| `CURVA_Q_UNIDAD=m3/d` | Unidad de `CURVA_Q` (`m3/d` o `m3/s`) |
| `BOMBA_MODELO=AOS_B_100_40` | Resuelve curva desde catalogo JSON |
| `BOMBA_ESTADO=ENCENDIDA\|APAGADA` | Apagada ⇒ head 0 sin aviso de falta de curva |

Precedencia:

1. curva inline `CURVA_Q` + `CURVA_H`
2. `BOMBA_MODELO` (catalogo `datos/catalogos/aos_bombas_catalogo_0_0_1.json`)
3. sin curva ⇒ advertencia `EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1`

Evaluacion: interpolacion lineal, saturacion en extremos (`CURVA_EXTRAPOLADA`),
sin splines. Identidad de tramo:

```text
dp_total = dp_fric + dp_grav + dp_menores + dp_equipo
```

con `dp_equipo_Pa` aparte (negativo = ganancia). `VALVULA_CERRADA` gana sobre
cualquier bomba (`dp_menores = Inf`).

Detalle de claves: `LEEME_METADATOS_DXF.txt`.

## Modos de condicion de dominio

Campo `dominio.condicion_extremos`:

| Modo | Incognita | Notas |
|---|---|---|
| `P_INICIO_Q_FIN` | presiones a lo largo del camino | Default; comportamiento historico |
| `Q_INICIO_P_FIN` | caudal de entrada conocido, P en fin | Directo (raiz BFS en el otro extremo) |
| `P_INICIO_P_FIN` | caudal | Biseccion externa en Q; solo `SELECTED_PATH` |

Rechazos estructurados (cuando la Linea C esta activa):

- `HID_MODO_PP_REQUIERE_CAMINO_SIMPLE` — P–P sobre arbol ramificado
- `HID_MODO_NO_SOPORTADO_EN_LAZO` — cualquier modo sobre `LOOP_SUBNETWORK`
- `HID_BC_INSUFICIENTE` / `HID_BC_SOBREDETERMINADA` — suficiencia de BC

`LOOP_SUBNETWORK` sigue sin ejecutarse en DEV1.

## Rangos y campana multifasica en red

Tolerancias formales (Sprint 1, `LEEME_BENCHMARK_TRAMO.md`):

| Magnitud | Criterio |
|---|---|
| Monofasico vs recalculo aislado | relativo <= 1e-9 |
| Multifasico \|P_out red − iso\| | absoluto max(tol_presion, 2e3) Pa |
| Holdup liquido | ± 0.01 |
| Regimen | igualdad literal |
| Balance interno monofasico | relativo <= 1e-6 (`dp_total = dp_fric+dp_grav+dp_menores+dp_equipo`) |

En multifasico, `dp_fric`/`dp_grav` son diagnosticos del VLP y no se exigen
contra `P_out` a 1e-6 (igual que F1–F3 del benchmark de tramo).

Modelos ejercidos en `test_aos_cad_benchmark_red`:

- `MONOFASICO_DARCY`
- `MULTIFASICO_HB`
- `MULTIFASICO_DR`
- `MULTIFASICO_SIMPLIFICADO`

La campana toma `ql_edge` / `qg_edge` y `P_in` del solver de red y recalcula
cada tramo con `aos_cad_hidraulica_evaluar_tramo`. No se modifica el nucleo VLP.

Fluidos de referencia multifasicos en la campana: API=35, WC=0.45, GLR=117,
gamma_g=0.70 (mismos ordenes que el benchmark de tramo).

## Estado de modelos en registro

Fuente: `aos_cad_hidraulica_registro_modelos.m`.

- `MONOFASICO_DARCY`: `DEV1`
- `MULTIFASICO_HB` / `MULTIFASICO_DR`: `VALIDADO_EN_RED_DEV1` tras campana D1
  (`test_aos_cad_benchmark_red` APROBADO: P_out red vs iso, holdup, regimen)
- `MULTIFASICO_SIMPLIFICADO`: `FALLBACK_FISICO` (no se promociona por esta campana)
- `AUTOMATICO`: `DEV1`

La promocion HB/DR es solo de estado DEV1 en red; el motor global sigue
`DESARROLLO_NO_VALIDADO` (sin promocion a BETA).

## Limitaciones remanentes

- Sin lazos Kirchhoff ni multiples fuentes de presion.
- `P_INICIO_P_FIN` no admite arbol ramificado (reparto de caudal no unico).
- Curvas: solo head–caudal a velocidad fija; sin eficiencia, NPSH ni afinidad.
- Interpolacion lineal (sin splines ni polinomios).
- Transitorios fuera de alcance.
- Equipo sin curva sigue sin aportar head (advertencia conservada).
- Estado global del motor: `DESARROLLO_NO_VALIDADO` (sin promocion a BETA).

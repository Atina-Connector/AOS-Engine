# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

AOS Suite is a GNU Octave application for artificial-lift and production-engineering
simulation in oil wells (Gas Lift/JGL, ESP/BES, Sucker-Rod Pumping/BM, PCP, CGF, EGF,
networks, CAD/topology, geology, environmental, etc.), developed by AESIR Oilfield
Systems. Current baseline: **AOS 0.2.0 DEV1** (architecture revision `ENV-02`,
science revision `SENS-GLJGL-03`). All code, identifiers, menus and comments are in
**Spanish**; keep new code consistent with that.

This directory (`app/`) is the Octave source tree. It is built into a Docker image
(`Dockerfile`/`docker-compose.yml` one level up, outside this repo) that copies this
whole tree to `/opt/aos` and runs it with `octave-cli`. There is no Node/Python
build — GNU Octave is the only runtime, and MATLAB is explicitly *not* a target
(no `.mat` files as a source of truth, no MATLAB-only syntax).

## Running AOS

From the parent `aos-docker` directory (outside this repo), the `aos` wrapper drives
the container:

```bash
docker compose up -d          # build/start the container
./aos run                     # launch AOS.m interactively
./aos verify                  # run VERIFICAR_AOS_0_2_0_DEV1.m
./aos octave <args>           # run arbitrary octave-cli commands
./aos shell                   # bash shell inside the container
```

Inside Octave (or via `octave-cli --quiet --no-history --no-init-file AOS.m` directly
in this directory), the canonical bootstrap is:

```octave
cd('/path/to/app')
clear functions
rehash
VERIFICAR_AOS_0_2_0_DEV1(false)   % quick static+contract verification
AOS                                 % launch the interactive menu (src/menu/AOS_app.m)
```

`AOS_HEADLESS=1` or `AOS_GRAPHICS_MODE=file` (env vars, see `AOS.m`) disable figure
display for headless/CI runs — the Docker image sets `AOS_GRAPHICS_MODE=off`.

## Verification / tests

There is no MOxUnit/xUnit-style runner. Tests are plain `.m` functions in
`src/tests/`, each named `test_*`, returning a boolean `ok` and printing
`RESULTADO: <name> APROBADO` on success. They mix static contract checks
(`fileread` + `strfind`/`assert` on source files) and dynamic execution checks.

Run the full campaign:

```octave
VERIFICAR_AOS_0_2_0_DEV1(false)   % static checks + HF3.5/SENS03 test list + legacy 0.1.9 core check
VERIFICAR_AOS_0_2_0_DEV1(true)    % same, plus deep legacy campaign + AOSCAD R16 full campaign
```

Feature-specific verifiers exist per hotfix/revision, e.g.:

```octave
VERIFICAR_SENS_GLJGL_03(false)    % quick
VERIFICAR_SENS_GLJGL_03(true)     % deep, includes benchmark MDM-2064
VERIFICAR_AOS_0_1_9_R2_HF3_4_AOSCAD_R16(...)
```

To run a **single test** manually, register the path (tests are excluded from the
path by default) and call the function directly:

```octave
iniciar_aos(true);   % true = include src/tests on the path
rehash;
ok = test_sens_gljgl03_contrato_estatico();
```

`GENERAR_MAPA_DEPENDENCIAS_MENUS()` (or `GENERAR_MAPA_DEPENDENCIAS_MENUS('salida','md')`
non-interactively) regenerates the navigable menu/dependency map used to audit menu
wiring — useful after adding or rewiring a menu.

## Architecture

### Path setup — no `genpath`

`src/iniciar_aos.m` builds the Octave path explicitly and deterministically instead
of using `genpath`: it walks `src/`, excludes `src/docs` always and `src/tests` /
`src/diagnosticos/legacy` unless `incluir_pruebas` is true, then orders directories
by a fixed weight (`core` → `services` → `solvers` → `utilidades` → `geologia`/
`sensibilidad` → `modulos` → `workbenches` → everything else → `menu` last-but-added-first).
`src/menu` and `src/` itself are then re-added with `-begin` so public menu
entrypoints can never be shadowed by an internal implementation file of the same
name. Duplicate `.m` basenames anywhere under `src/` are a hard verification
failure (`VERIFICAR_AOS_0_2_0_DEV1` checks for this) — check before adding a new
file whether the name is already used elsewhere.

### Global mutable state, not dependency injection

The Suite is a single long-lived Octave session driven by nested `while true` /
`switch` menu loops (entry: `AOS.m` → `iniciar_aos()` → `src/menu/AOS_app.m`).
Session state is carried in `global` variables declared at the top of each function
that needs them — there is no case object passed around:

- `CONFIG_ACTIVA` — struct holding the active well/case configuration (normalized
  via `aos_normalizar_config`).
- `AOSDAT_ACTIVO` — path/origin of the currently loaded `.aosdat`.
- `geologia` — active geology model.
- `ULTIMO_QL`, `ULTIMO_QO`, `ULTIMO_QINY`, `ULTIMO_TIPO`, `ULTIMO_PARAM` — last-run
  results, used to redisplay a summary at the top of every menu screen.

When touching menu code, redeclare the relevant `global`s at the top of the
function rather than threading parameters through — that's the existing
convention (see `src/menu/AOS_app.m`, `src/menu/AOS_menu_gestion_caso.m`).

### Directory layout and where physics actually lives

```
src/
├── core/          legacy-but-active physics engines: BES, BES2, BES3, BM, CGF,
│                  EGF, GL, JGL, common (PVT/IPR/VLP/redes), jet_core
├── menu/          public Octave entrypoints (AOS_app.m, AOS_menu_*.m, *_menu.m) —
│                  these are what the interactive session actually calls
├── modulos/       banks with their own implementation, e.g. cad_topo (AOSCAD),
│                  scada, comunes
├── sensibilidad/  cross-cutting sensitivity-analysis engine (GL/JGL/BES sweeps,
│                  curve fitting, polynomial validation) — large, actively developed
├── geologia/      geology + perforated-interval ("punzados") management
├── services/      aosbck, catalogs, fluids, geometry_3d, interoperability,
│                  reporting, units, validation — cross-cutting shared services
├── solvers/       solvers organized by discipline (hydraulic, electrical,
│                  mechanical, thermal, geological, reservoir, production,
│                  network_graph, optimization, economics, reliability, fluids) —
│                  target home for physics, migration from core/ is in progress
├── workbenches/   target structure for the 15 banks (sla, wells, cad, networks,
│                  electrical, facilities, geology, fluids, scada, environmental,
│                  maintenance, data, solvers, global, viewer) — currently mostly
│                  placeholder READMEs pointing back at menu/core/modulos; do not
│                  duplicate physics here, it's a migration target, not the
│                  current source of truth
├── utilidades/    unit conversions, formatting, config, plotting, reports, misc
├── roadmap/       JSON manifests describing workbenches/services/solvers/contracts
│                  per release (source of truth for "what's registered this version")
└── tests/         see Verification above
```

Root-level `VERIFICAR_*.m` and `CHANGELOG_*`/`AUDITORIA_*`/`REGRESIONES_*`/
`MANIFEST_*` files are per-release/per-hotfix historical records (one set per
revision: `0.1.3`, `0.1.9` + R1/R2/HF1-3.5, `SENS-GLJGL-01/02/03`, `ENV-01/02`...).
They're append-only audit trail, not something to edit retroactively. The current
architectural source of truth is `documentos/ARQUITECTURA_AOS_0_2_0_DEV1.md` (very
long — read the section you need, e.g. §16 for report composition, §27-28 for
per-system data contracts) plus `README.md` and `AOS_0_2_0_DEV1_CONTEXTO_COMPLETO.md`.

### Data lifecycle and file formats

- `.aosdat` — input model (well, Survey, geology, punzados, mechanical state,
  fluids, SLA params, catalogs, galleries). Loading one populates `CONFIG_ACTIVA`
  and takes priority over `config/` defaults — never silently overwritten.
- `.aosrpt` — reproducible report: effective inputs, results, tables, convergence,
  diagnostics, warnings, optionally embedded visuals.
- `.aoscad` — canonical JSON equivalent of `.aosrpt` for CAD/networks/facilities
  (geometry, topology, boundary conditions, tables, results, presentation).
- `.aosbck` — reusable component container derived from STEP (part number,
  manufacturer, ports, instances).

Governing principle (`full_data_policy = ALWAYS_PRESERVE`): computed data and full
tables are always retained even when a report's presentation profile
(`EXECUTIVE`/`TECHNICAL`/`AUDIT`/`CUSTOM`, per-table modes like `SUMMARY` or
`EXCLUDED_EXPORT`) chooses not to render them in a given output — never delete data
to satisfy a presentation choice. Similarly, `NaN`/`Inf`/`NO_CONVERGE`/
`FUERA_DE_RANGO`/`DATO_ASUMIDO`/`NO_VALIDADO` markers must never be hidden or
silently substituted.

### Module maturity is per-bank, not per-release

The Suite version does not imply every bank is validated. States you'll see
referenced in docs/comments: `OPERATIVO`, `BETA`, `DESARROLLO`, `ROADMAP`,
`ALPHA`, `CONCEPTUAL`, `PROTOTIPO_NO_VALIDADO`, `DESARROLLO_NO_VALIDADO`,
`ROADMAP_RUNTIME_SHELL`. Notably: AOSCAD is R16 and still `CANDIDATO_REVISION_JEFE`
(not promoted to beta), BES3 is `DESARROLLO_NO_VALIDADO`, AOS Environmental is a
navigation/contract shell only (no science implemented yet). Don't present a
result as validated just because the code runs — check the module's stated status
before describing it as reliable.

### Cross-module rules worth knowing before editing

- Core/solver code is shared across banks; a workbench-specific change must not
  fork or duplicate a shared solver's equations — raise the change at the shared
  level.
- Gas Lift/JGL: injection rate/pressure selection must distinguish "use default"
  from "force this value including zero" from "auto-determine" — a zero input is a
  real value, never silently replaced by a config default.
- BM/Gibbs GF3 free-tubing sign convention is load-bearing and has regressed
  before: `elongacion_tubing >= 0`, `u_fondo_tubing = -elongacion_tubing`,
  `u_piston_barril = u_varilla_fondo - u_fondo_tubing`; bottom-card apparent
  stiffness must stay positive and consistent with `E*A/L`.
- AOS Environmental attaches events/measurements to AOSCAD's `asset_id`/
  `component_id`/`instance_id` (or MD/TVD/node/tramo) rather than free text, and
  never computes indirect CO₂ independently per consuming module — factors are
  centralized to avoid double counting.

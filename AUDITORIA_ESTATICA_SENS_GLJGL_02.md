# Auditoria estatica SENS-GLJGL-02

**Resultado:** `PASS_STATIC`

## Alcance

- Base: `AOS_0_2_0_DEV1_ENV02_SENS01`.
- Candidato: `AOS_0_2_0_DEV1_ENV02_SENS02`.
- Hotfix: armonizacion polinomica explicita, grados AUTO/2/3/4/5 y optimo por derivada cero con verificacion fisica.

## Inventario

- Archivos base: 1290.
- Archivos candidato: 1315.
- Nuevos: 25.
- Modificados: 18.
- Eliminados: 0.
- JSON validados: 36.
- Archivos `.m` unicos dentro de `src`: 826.

## Controles

- `PASS` `baseline_exists` - /mnt/data/work_sens02/AOS_0_2_0_DEV1_ENV02_SENS01
- `PASS` `candidate_exists` - /mnt/data/work_sens02/AOS_0_2_0_DEV1_ENV02_SENS02
- `PASS` `no_removed_files` - removed=0
- `PASS` `all_json_valid` - count=36; errors=[]
- `PASS` `no_mat_files` - count=0
- `PASS` `no_duplicate_m_basenames_in_src` - m_count=826; duplicates={}
- `PASS` `protected_physical_cores_unchanged` - src/core/GL/GL_sim.m=True; src/utilidades/nodal/aos_nodal_balance_gl.m=True; src/utilidades/nodal/aos_buscar_cruce_nodal.m=True; src/core/JGL/jgl_solver_directo.m=True; src/core/JGL/jgl_solver_iterativo.m=True
- `PASS` `required_sens02_files_present` - missing=[]
- `PASS` `explicit_curve_treatment_in_all_main_paths` - missing=[]
- `PASS` `optimizer_integrated_in_all_main_paths` - bad=[]
- `PASS` `curve_and_optimum_masks_passed_separately` - missing=[]
- `PASS` `no_hidden_abbreviated_polynomial_in_main_paths` - found=[]
- `PASS` `historical_degree_5_visible`
- `PASS` `three_explicit_modes_visible`
- `PASS` `default_mode_discrete`
- `PASS` `polyfit_executable_confined_to_explicit_helper` - [{'path': 'src/sensibilidad/sens_ajuste_polinomico.m', 'line': 179}]
- `PASS` `discrete_optimizer_has_no_polyfit`
- `PASS` `balanced_delimiters_changed_m_files` - errors=[]
- `PASS` `explicit_block_balance_added_m_files` - errors=[]
- `PASS` `added_m_primary_names_match_files` - errors=[]
- `PASS` `verifier_registers_all_sens02_tests` - tests=8; missing=[]
- `PASS` `release_metadata_mentions_sens02`
- `PASS` `hotfix_metadata_default_discrete`

## Nucleos fisicos protegidos

- `src/core/GL/GL_sim.m` - sin cambios - `e4ebbe948b8d41b7d2a64a55224a144fd7096ca6d6c30960c2c51758f0709f86`
- `src/utilidades/nodal/aos_nodal_balance_gl.m` - sin cambios - `c8cd8a616f8a225c716c131caadb4aa87720b660f403503f78b517bb49c06d0f`
- `src/utilidades/nodal/aos_buscar_cruce_nodal.m` - sin cambios - `038fae7cc180e50af0f226fb2a63d3a48f47aa4e9d94b7fecd071a8f00d80451`
- `src/core/JGL/jgl_solver_directo.m` - sin cambios - `f6c8cabeefd272722a8a9cce382be5459c8a5dae5e71cb10fcf05fd9c0e6654a`
- `src/core/JGL/jgl_solver_iterativo.m` - sin cambios - `d212c3d067ee45c16169a5122cac8a4fb1872425329153d6c130f217ed64c9c8`

## Contrato polinomico

- El menu de tratamiento se presenta en las cuatro rutas GL/JGL de sensibilidad.
- El modo predeterminado es `DISCRETO`.
- La opcion `5 - Quintico [HISTORICO AOS]` esta visible.
- La unica llamada ejecutable nueva a `polyfit` esta en `sens_ajuste_polinomico.m`.
- `valido_para_curva` y `valido_para_optimo` se conservan como mascaras diferentes.
- Los puntos del solver no se sobrescriben; el ajuste es una serie derivada.
- El maximo polinomico solo se publica despues de una corrida canonica GL/JGL convergida.

## Validacion dinamica

`NOT_RUN_GNU_OCTAVE_UNAVAILABLE`

La auditoria estatica no sustituye la ejecucion de los verificadores ni el benchmark real en GNU Octave.

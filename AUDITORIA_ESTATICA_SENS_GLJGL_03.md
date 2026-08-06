# Auditoria estatica SENS-GLJGL-03

**Resultado:** `PASS_STATIC`

## Alcance

- Base comparada: `AOS_0_2_0_DEV1_ENV02_SENS02`.
- Candidato: `AOS_0_2_0_DEV1_ENV02_SENS03`.
- La validacion dinamica no fue ejecutada porque GNU Octave no esta disponible en este entorno.

## Inventario

- Archivos base: 1315.
- Archivos candidatos: 1342.
- Agregados respecto de SENS02: 27.
- Modificados respecto de SENS02: 26.
- Eliminados: 0.
- JSON validos: 38.
- Archivos `.m` unicos dentro de `src`: 841.
- Archivos `.m` nuevos o modificados revisados: 32.

## Controles

- `PASS` `candidate_exists` - /mnt/data/_sens03_release/AOS_0_2_0_DEV1_ENV02_SENS03
- `PASS` `no_removed_files_vs_sens02` - removed=0
- `PASS` `all_json_valid` - count=38; errors=[]
- `PASS` `no_mat_files` - count=0
- `PASS` `no_duplicate_m_basenames_in_src` - m_count=841; duplicates={}
- `PASS` `protected_physical_cores_unchanged` - src/core/GL/GL_sim.m=True; src/utilidades/nodal/aos_nodal_balance_gl.m=True; src/utilidades/nodal/aos_buscar_cruce_nodal.m=True; src/core/JGL/jgl_solver_directo.m=True; src/core/JGL/jgl_solver_iterativo.m=True
- `PASS` `required_sens03_files_present` - missing=[]
- `PASS` `changed_m_static_lexical_checks` - checked=32; issues=[]
- `PASS` `three_explicit_motive_modes_visible`
- `PASS` `point_jgl_uses_explicit_motive_menu`
- `PASS` `strict_default_no_hidden_derivation`
- `PASS` `required_pressure_formulas_present`
- `PASS` `imported_configured_available_required_effective_are_separate`
- `PASS` `derived_mode_does_not_overwrite_input_struct`
- `PASS` `motive_condition_precedes_block`
- `PASS` `pressure_graph_has_required_series`
- `PASS` `motive_pressure_reporting_present`
- `PASS` `menu_graph_reporting_sens_Qiny_JGL`
- `PASS` `menu_graph_reporting_sens_Qiny`
- `PASS` `sens02_polynomial_inherited`
- `PASS` `no_new_hidden_polyfit_in_sens03` - []
- `PASS` `deep_sweep_test_registered`
- `PASS` `independent_pressure_formula_check` - factor=1.13914232; dPbar=5.61012; Psupbar=75.1531; errPa=0
- `PASS` `independent_pressure_limit_check` - Qiny_limit=1500.0
- `PASS` `release_metadata_sens03`

## Nucleos fisicos preservados

- `src/core/GL/GL_sim.m` - SHA-256 `e4ebbe948b8d41b7d2a64a55224a144fd7096ca6d6c30960c2c51758f0709f86`
- `src/utilidades/nodal/aos_nodal_balance_gl.m` - SHA-256 `c8cd8a616f8a225c716c131caadb4aa87720b660f403503f78b517bb49c06d0f`
- `src/utilidades/nodal/aos_buscar_cruce_nodal.m` - SHA-256 `038fae7cc180e50af0f226fb2a63d3a48f47aa4e9d94b7fecd071a8f00d80451`
- `src/core/JGL/jgl_solver_directo.m` - SHA-256 `f6c8cabeefd272722a8a9cce382be5459c8a5dae5e71cb10fcf05fd9c0e6654a`
- `src/core/JGL/jgl_solver_iterativo.m` - SHA-256 `d212c3d067ee45c16169a5122cac8a4fb1872425329153d6c130f217ed64c9c8`

## Resultado de validacion dinamica

`NOT_RUN_GNU_OCTAVE_UNAVAILABLE`

La promocion requiere ejecutar `VERIFICAR_SENS_GLJGL_03(true)` y el benchmark real `MDM-2064` en GNU Octave.

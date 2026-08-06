# Auditoría estática AOS 0.1.1-alpha1

## Alcance

- Archivos `.m` revisados del bloque nuevo/modificado: **57**.
- Funciones primarias detectadas en todo el proyecto: **336**.
- Nombres de función duplicados: **0**.
- Dependencias críticas ausentes: **0**.

## Controles de funciones GNU Octave

- `src/core/BES2/BES_V2_menu.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_cargar_bomba.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/BES2/bes2_comparar_v1_v2.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_curva_bomba.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/BES2/bes2_defaults.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/BES2/bes2_evaluar_punto.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_exportar_reporte.m`: funciones=3, `endfunction`=3 — **OK**
- `src/core/BES2/bes2_imprimir_resultado.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/BES2/bes2_plot_resultado.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_presion_intake.m`: funciones=3, `endfunction`=3 — **OK**
- `src/core/BES2/bes2_pvt_intake.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_sensibilidad_ejecutar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_sensibilidad_menu.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/BES2/bes2_solver.m`: funciones=5, `endfunction`=5 — **OK**
- `src/core/CGF/CGF_menu.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/CGF/aos_comparar_gas_fondo.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/CGF/cgf_cargar_compresor.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/CGF/cgf_defaults.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/CGF/cgf_evaluar_punto.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/CGF/cgf_exportar_reporte.m`: funciones=3, `endfunction`=3 — **OK**
- `src/core/CGF/cgf_imprimir_resultado.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/CGF/cgf_mapa_evaluar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/CGF/cgf_plot_resultado.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/CGF/cgf_sensibilidad_ejecutar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/CGF/cgf_sensibilidad_menu.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/CGF/cgf_solver.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/EGF/EGF_menu.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/EGF/egf_cargar_eyector.m`: funciones=3, `endfunction`=3 — **OK**
- `src/core/EGF/egf_defaults.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/EGF/egf_evaluar_punto.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/EGF/egf_exportar_reporte.m`: funciones=3, `endfunction`=3 — **OK**
- `src/core/EGF/egf_imprimir_resultado.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/EGF/egf_plot_resultado.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/EGF/egf_sensibilidad_ejecutar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/EGF/egf_sensibilidad_menu.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/EGF/egf_solver.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/common/gas/aos_gas_flow_nozzle.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/common/gas/aos_gas_ipr.m`: funciones=4, `endfunction`=4 — **OK**
- `src/core/common/gas/aos_gas_profile.m`: funciones=3, `endfunction`=3 — **OK**
- `src/core/common/gas/aos_gas_props.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/common/gas/aos_gas_tvd_at_md.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/common/gas/aos_temperatura_at_md.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/common/electrico_fondo/aos_cable_evaluar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/common/electrico_fondo/aos_electrico_defaults.m`: funciones=2, `endfunction`=2 — **OK**
- `src/core/common/electrico_fondo/aos_electrico_fondo_evaluar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/common/electrico_fondo/aos_motor_pm_evaluar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/common/electrico_fondo/aos_termica_fondo.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/common/electrico_fondo/aos_vsd_evaluar.m`: funciones=1, `endfunction`=1 — **OK**
- `src/core/jet_core/jet_gas_gas_operar.m`: funciones=4, `endfunction`=4 — **OK**
- `src/menu/AOS_app.m`: funciones=1, `endfunction`=1 — **OK**
- `src/menu/AOS_menu_BES.m`: funciones=1, `endfunction`=1 — **OK**
- `src/menu/AOS_menu_gas_fondo.m`: funciones=1, `endfunction`=1 — **OK**
- `src/menu/AOS_menu_catalogos.m`: funciones=2, `endfunction`=2 — **OK**
- `src/iniciar_aos.m`: funciones=1, `endfunction`=1 — **OK**
- `src/utilidades/intercambio/aos011_exportar_sensibilidad.m`: funciones=4, `endfunction`=4 — **OK**
- `src/utilidades/intercambio/aos_exportar_contexto_viewer.m`: funciones=10, `endfunction`=10 — **OK**
- `VERIFICAR_AOS_0_1_1_ALPHA.m`: funciones=4, `endfunction`=4 — **OK**

## Duplicados

- No se detectaron nombres de función primarios duplicados.

## Dependencias críticas

- Todas las funciones críticas del verificador están presentes.

## Catálogos genéricos incluidos

- `config/BES_V2/catalogo/AOS_BES2_1500.txt` — OK
- `config/BES_V2/catalogo/AOS_BES2_3000.txt` — OK
- `config/CGF/catalogo/AOS_CGF_AXIAL_PM_01.txt` — OK
- `config/EGF/catalogo/AOS_EGF_GAS_GAS_01.txt` — OK
- `config/electrico_fondo/AOS_PM_150KW.txt` — OK

## Limitación de esta auditoría

GNU Octave no está instalado en el entorno de construcción. Esta auditoría comprueba estructura, cierres de funciones, nombres, dependencias y empaquetado; no sustituye la ejecución de `VERIFICAR_AOS_0_1_1_ALPHA` en la instalación del usuario.

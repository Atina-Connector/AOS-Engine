# AOS 0.0.11 Benchmark Ready — archivos clave

Esta distribución es un árbol completo, no un parche.

## Importación, configuración y unidades

- `src/utilidades/intercambio/importar_aosdat.m`
- `src/utilidades/intercambio/exportar_aosdat.m`
- `src/utilidades/intercambio/aos_parse_valor.m`
- `src/utilidades/intercambio/aos_sanitizar_campo.m`
- `src/utilidades/config/aos_aplicar_aliases_aosdat.m`
- `src/utilidades/config/aos_normalizar_config.m`
- `src/utilidades/config/aos_normalizar_geologia.m`
- `src/utilidades/config/aos_sincronizar_geologia_activa.m`
- `src/utilidades/config/aos_preparar_config_activa.m`
- `src/utilidades/aos_formato_presion.m`
- `src/utilidades/aos_formato_longitud.m`
- `src/utilidades/aos_formato_caudal_liquido.m`
- `src/utilidades/aos_formato_caudal_gas.m`
- `src/utilidades/aos_sm3d_a_m3s.m`
- `src/utilidades/aos_m3s_a_sm3d.m`

## Menú y módulos

- `src/menu/AOS_app.m`
- `src/menu/GL_puro_menu.m`
- `src/menu/JGL_menu.m`
- `src/menu/BES_app.m`
- `src/menu/BM_menu.m`

## Geología, survey y punzados

- `src/utilidades/graficos/plot_survey.m`
- `src/geologia/cargar_geologia_interactivo.m`
- `src/geologia/calcular_caudales_criticos.m`
- `src/geologia/preguntar_reporte.m`

## Reportes y diagnósticos métricos

- `src/utilidades/intercambio/exportar_aosrpt.m`
- `src/utilidades/intercambio/exportar_aosrpt_enriquecido.m`
- `src/utilidades/intercambio/importar_aosrpt.m`
- `src/utilidades/diagnostico/diagnostico_tuberia_produccion.m`
- `src/utilidades/graficos/plot_erosion_taitel.m`
- `src/utilidades/semaforos/aos_semaforo_operacion.m`

## Pruebas de regresión

- `VERIFICAR_AOS_0_0_11.m`
- `src/tests/test_aosdat_supati_001.m`
- `src/tests/test_aosdat_roundtrip_001.m`
- `src/tests/test_aosdat_legacy_compat_001.m`
- `src/tests/test_unidades_aos_001.m`
- `src/tests/test_plot_survey_punzados_001.m`

## Caso testigo

- `datos/ejemplos/benchmarks/SUPATI_X1_ST_BENCHMARK_AOS_001.aosdat`
- `CARGAR_BENCHMARK_SUPATI_001.m`

## Física preservada de 0.0.11

Los cambios Physics Guard de GL/JGL/BES/BM y sensibilidades siguen incluidos. El nuevo solver JGL acoplado no forma parte de este build y queda reservado para 0.0.12.

# Mapa de dependencias de menus AOS

- **Version AOS:** AOS 0.1.2 - Hito Bombeo Mecanico
AESIR Oilfield Simulation
Plataforma objetivo: GNU Octave
Fecha de consolidacion: 2026-07-18

Hito principal:
- Primer resultado fisicamente coherente de Bombeo Mecanico con Gibbs Foundation 2.
- GF2 congelado como benchmark dorado BM_GF2_GOLDEN_CASE_001.
- Gibbs Foundation 3 incorporado de forma nativa como linea BETA de desarrollo.
- Menu BM modular basado en registro, sin edicion manual para futuras Foundations.

Base heredada:
- AOS 0.1.1-R1 CLEAN como base funcional consolidada.
- GL/JGL, mandriles V2, BES, BM operativo, reportes, Viewer y utilidades.
- Importacion .aosdat unica, automatica e indiferenciada.
- Normalizacion Qiny, energia GL/JGL, economia y registro dinamico de graficos.
- Menu visible de survey, punzados y completacion.

Roadmap instalado:
- Los menus de inyectores, mallas, baterias, fluidos, red electrica, secuencia de arranque y SCADA representan arquitectura y contratos futuros.
- Los modulos BETA, DESARROLLO o PLANIFICADO no deben interpretarse como solvers validados.
- **Generado:** 2026-07-18T15:18:17
- **Menu raiz:** `AOS_app`
- **Menus detectados:** 39

## AOS - AESIR Oilfield Simulation 0.1.2 - Hito Bombeo Mecanico\n (`AOS_app`)

**Archivo:** `src/menu/AOS_app.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** iniciar_aos, aos_leer_opcion, AOS_menu_operacion_yacimiento, AOS_menu_importar_exportar, AOS_menu_configuracion, aos_normalizar_config, aos_sincronizar_geologia_activa, aos_menu_imprimir_resumen_config, aos_menu_imprimir_ultima_corrida

## aos leer opcion (`aos_leer_opcion`)

**Archivo:** `src/menu/aos_leer_opcion.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

## \n--- ANALISIS INTEGRAL DEL YACIMIENTO %s ---\n (`AOS_menu_analisis_integral`)

**Archivo:** `src/menu/AOS_menu_analisis_integral.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_modulo_no_disponible

## \n--- BATERIAS E INSTALACIONES %s ---\n (`AOS_menu_baterias`)

**Archivo:** `src/menu/AOS_menu_baterias.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_mostrar_seccion_activa, aos_modulo_no_disponible

## \n--- BOMBEO ELECTROSUMERGIBLE (BES) %s ---\n (`AOS_menu_BES`)

**Archivo:** `src/menu/AOS_menu_BES.m`  
**Grupo:** BES  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_preparar_config_activa, BES_V2_menu, aos_config_base, bes2_defaults, bes2_sensibilidad_menu, bes2_cargar_bomba, bes2_comparar_v1_v2, BES_app, AOS_catalogos_listar_tipo, AOS_menu_reportes

## \n--- BOMBEO MECANICO (BM) %s ---\n (`AOS_menu_BM`)

**Archivo:** `src/menu/AOS_menu_BM.m`  
**Grupo:** BM  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_preparar_config_activa, BM_menu, aos_modulo_no_disponible, AOS_catalogos_listar_tipo, AOS_menu_reportes, AOS_exportar_ultima_corrida

## \n--- ADMINISTRACION DE CATALOGOS ---\n (`AOS_menu_catalogos`)

**Archivo:** `src/menu/AOS_menu_catalogos.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, AOS_catalogos_listar_tipo, aos_mostrar_seccion_activa

## \n--- CGF - COMPRESION DE GAS EN FONDO %s ---\n (`AOS_menu_CGF`)

**Archivo:** `src/menu/AOS_menu_CGF.m`  
**Grupo:** CGF  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, CGF_menu, aos_config_base, cgf_defaults, cgf_sensibilidad_menu, aos_comparar_gas_fondo

## \n--- COMPARACION DE SISTEMAS SLA ---\n (`AOS_menu_comparacion_sla`)

**Archivo:** `src/menu/AOS_menu_comparacion_sla.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, sens_Qiny, sens_balance_energetico, aos_comparar_gas_fondo, aos_modulo_no_disponible

## \n--- CONFIGURACION GENERAL ---\n (`AOS_menu_configuracion`)

**Archivo:** `src/menu/AOS_menu_configuracion.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, aos_menu_imprimir_resumen_config, aos_preferencias_usuario, aos_scada_rutas, aos_registro_modulos, diagnosticar_rutas_archivos

## \n--- POZO: SURVEY, PUNZADOS Y COMPLETACION ---\n (`AOS_menu_datos_pozo`)

**Archivo:** `src/menu/AOS_menu_datos_pozo.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_obtener_geometria_activa, aos_leer_opcion, aos_visualizar_geometria_pozo, aos_validar_geometria_pozo, aos_exportar_geometria_pozo, cargar_geologia_interactivo, aos_normalizar_config, aos_sincronizar_geologia_activa

## \n--- EGF - EDUCTOR GAS-GAS DE FONDO %s ---\n (`AOS_menu_EGF`)

**Archivo:** `src/menu/AOS_menu_EGF.m`  
**Grupo:** EGF  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, EGF_menu, aos_config_base, egf_defaults, egf_sensibilidad_menu, aos_comparar_gas_fondo

## \n--- FLUIDOS Y ASEGURAMIENTO DE FLUJO %s ---\n (`AOS_menu_fluidos`)

**Archivo:** `src/menu/AOS_menu_fluidos.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_mostrar_seccion_activa, aos_modulo_no_disponible

## \n--- FORMATOS EXTERNOS Y PLANILLAS ---\n (`AOS_menu_formatos_externos`)

**Archivo:** `src/menu/AOS_menu_formatos_externos.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, importar_pozos

## \n--- PRODUCCION Y COMPRESION DE GAS EN FONDO ---\n (`AOS_menu_gas_fondo`)

**Archivo:** `src/menu/AOS_menu_gas_fondo.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** CGF_menu, aos_config_base, cgf_defaults, cgf_sensibilidad_menu, EGF_menu, egf_defaults, egf_sensibilidad_menu, aos_comparar_gas_fondo

## \n--- GAS LIFT / JET GAS LIFT %s ---\n (`AOS_menu_GL_JGL`)

**Archivo:** `src/menu/AOS_menu_GL_JGL.m`  
**Grupo:** JGL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_preparar_config_activa, JGL_menu, GL_puro_menu, menu_sensibilidad, diseno_mandriles, calibrar, sens_balance_energetico, sens_Qiny, AOS_menu_reportes, AOS_exportar_ultima_corrida

## \n--- HERRAMIENTAS Y UTILIDADES GENERALES ---\n (`AOS_menu_herramientas`)

**Archivo:** `src/menu/AOS_menu_herramientas.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, AOS_menu_datos_pozo, diagnosticar_rutas_archivos, generar_mapa_dependencias, aos_registro_modulos

## \n--- HERRAMIENTAS COMUNES DE SLA ---\n (`AOS_menu_herramientas_sla`)

**Archivo:** `src/menu/AOS_menu_herramientas_sla.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, AOS_menu_datos_pozo, aos_preparar_config_activa, calibrar, AOS_exportar_ultima_corrida, diagnosticar_rutas_archivos, aos_registro_modulos

## \n--- IMPORTAR / EXPORTAR ---\n (`AOS_menu_importar_exportar`)

**Archivo:** `src/menu/AOS_menu_importar_exportar.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, importar_aosdat, exportar_aosdat, AOS_menu_datos_pozo, AOS_menu_formatos_externos, AOS_menu_catalogos, AOS_menu_reportes, AOS_menu_scada, diagnosticar_rutas_archivos

## \n*** CONFIGURACION BASE IMPORTADA (.aosdat, no es la ultima corrida) ***\n (`aos_menu_imprimir_resumen_config`)

**Archivo:** `src/menu/aos_menu_imprimir_resumen_config.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_formato_presion, aos_formato_longitud, aos_formato_caudal_gas

## aos menu imprimir ultima corrida (`aos_menu_imprimir_ultima_corrida`)

**Archivo:** `src/menu/aos_menu_imprimir_ultima_corrida.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_formato_caudal_liquido, aos_formato_caudal_gas, aos_formato_presion, aos_formato_longitud

## AOS menu intercambio (`AOS_menu_intercambio`)

**Archivo:** `src/menu/AOS_menu_intercambio.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** AOS_menu_importar_exportar

## \n--- LDL - SISTEMA PROPIETARIO AESIR %s ---\n (`AOS_menu_LDL`)

**Archivo:** `src/menu/AOS_menu_LDL.m`  
**Grupo:** LDL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_modulo_no_disponible, AOS_menu_scada, AOS_exportar_ultima_corrida, aos_mostrar_seccion_activa

## \n--- MALLAS Y NIVELES %s ---\n (`AOS_menu_mallas_niveles`)

**Archivo:** `src/menu/AOS_menu_mallas_niveles.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_mostrar_seccion_activa, aos_modulo_no_disponible

## \n--- SIMULACION Y OPERACION DEL YACIMIENTO ---\n (`AOS_menu_operacion_yacimiento`)

**Archivo:** `src/menu/AOS_menu_operacion_yacimiento.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, AOS_menu_SLA, AOS_menu_pozos_inyectores, AOS_menu_mallas_niveles, AOS_menu_baterias, AOS_menu_fluidos, AOS_menu_redes_electricas, AOS_menu_secuencia_arranque, AOS_menu_scada, AOS_menu_analisis_integral, AOS_menu_herramientas

## \n--- OTROS SISTEMAS DE LEVANTAMIENTO ---\n (`AOS_menu_otros_sistemas`)

**Archivo:** `src/menu/AOS_menu_otros_sistemas.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

## \n--- PCP - BOMBEO POR CAVIDADES PROGRESIVAS %s ---\n (`AOS_menu_PCP`)

**Archivo:** `src/menu/AOS_menu_PCP.m`  
**Grupo:** PCP  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_modulo_no_disponible, AOS_menu_LDL, AOS_menu_reportes, aos_mostrar_seccion_activa

## \n--- POZOS INYECTORES %s ---\n (`AOS_menu_pozos_inyectores`)

**Archivo:** `src/menu/AOS_menu_pozos_inyectores.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_mostrar_seccion_activa, aos_modulo_no_disponible

## \n--- REDES ELECTRICAS %s ---\n (`AOS_menu_redes_electricas`)

**Archivo:** `src/menu/AOS_menu_redes_electricas.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_mostrar_seccion_activa, aos_modulo_no_disponible

## \n--- REPORTES Y AOS VIEWER ---\n (`AOS_menu_reportes`)

**Archivo:** `src/menu/AOS_menu_reportes.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_leer_opcion, importar_aosrpt, aos_preferencias_usuario, bes2_exportar_reporte, cgf_exportar_reporte, egf_exportar_reporte, AOS_exportar_ultima_corrida, aos_registro_graficos

## \n--- SCADA Y OPERACION EN TIEMPO REAL %s ---\n (`AOS_menu_scada`)

**Archivo:** `src/menu/AOS_menu_scada.m`  
**Grupo:** SCADA  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, importar_aosdat, aos_scada_procesar_bandeja, aos_scada_receptor_automatico, aos_scada_estado, aos_mostrar_seccion_activa, aos_modulo_no_disponible, aos_scada_rutas, AOS_menu_reportes

## \n--- SECUENCIA DE ARRANQUE DEL YACIMIENTO %s ---\n (`AOS_menu_secuencia_arranque`)

**Archivo:** `src/menu/AOS_menu_secuencia_arranque.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, aos_mostrar_seccion_activa, aos_modulo_no_disponible

## \n--- SISTEMAS DE LEVANTAMIENTO ARTIFICIAL - SLA ---\n (`AOS_menu_SLA`)

**Archivo:** `src/menu/AOS_menu_SLA.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** aos_etiqueta_modulo, aos_leer_opcion, AOS_menu_GL_JGL, AOS_menu_BES, AOS_menu_BM, AOS_menu_PCP, AOS_menu_CGF, AOS_menu_EGF, AOS_menu_comparacion_sla, AOS_menu_herramientas_sla

## \n--- CATÁLOGO DE BOMBAS BES ---\n (`BES_app`)

**Archivo:** `src/menu/BES_app.m`  
**Grupo:** BES  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** iniciar_aos, aos_config_base, aos_normalizar_config, validar_parametro, load_config, pvt_calcular, aos_formato_presion, aos_formato_longitud, aos_set_profundidad, aos_opcion_modelo_ipr, aos_opcion_modelo_vlp, aos_sincronizar_config, obtener_survey, BES_sim, aos_formato_caudal_liquido, aos_formato_caudal_gas, ipr, plot_nodal_BES, diagnostico_tuberia_produccion, preguntar_reporte, aos_semaforo_operacion, aos_imprimir_semaforos, preguntar_exportar_aosrpt

## AOS 0.1.2 - BOMBEO MECANICO\n (`BM_menu`)

**Archivo:** `src/menu/BM_menu.m`  
**Grupo:** BM  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** iniciar_aos, bm_registro_modulos

## \n--- BOMBEO MECANICO / GIBBS ---\n (`BM_operativo_menu`)

**Archivo:** `src/menu/BM_operativo_menu.m`  
**Grupo:** BM  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** iniciar_aos, gibbs_lab_menu, gibbs18_menu, aos_config_base, aos_normalizar_config, aos_bm_propiedades_fluido, cargar_materiales_varillas, cargar_catalogo_bm, aos_formato_presion, aos_formato_longitud, aos_set_profundidad, aos_opcion_modelo_ipr, aos_sincronizar_config, obtener_survey, BM_core, diseno_varillas, diagnostico_bm_gibbs, diagnostico_tuberia_produccion, aos_semaforo_operacion, aos_imprimir_semaforos, preguntar_exportar_aosrpt, aos_formato_caudal_liquido

## \n--- PARAMETROS ACTUALES ---\n (`GL_puro_menu`)

**Archivo:** `src/menu/GL_puro_menu.m`  
**Grupo:** GL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** iniciar_aos, aos_config_base, aos_normalizar_config, obtener_survey, aos_formato_presion, aos_formato_longitud, aos_qiny_configurada, aos_formato_caudal_gas, aos_set_profundidad, aos_sincronizar_config, aos_opcion_modelo_ipr, aos_opcion_modelo_vlp, diagnostico_vlp, aos_menu_qiny, GL_puro_core, aos_balance_energia_sla, aos_formato_caudal_liquido, aos_imprimir_balance_energia_sla, plot_nodal, diagnostico_tuberia_produccion, aos_semaforo_operacion, aos_imprimir_semaforos, preguntar_reporte, preguntar_exportar_aosrpt

## \n--- PARAMETROS ACTUALES ---\n (`JGL_menu`)

**Archivo:** `src/menu/JGL_menu.m`  
**Grupo:** JGL  
**Opciones:** 0

_No se detectaron opciones visibles._

**Dependencias detectadas:** iniciar_aos, aos_config_base, aos_normalizar_config, jgl_defaults, obtener_survey, aos_formato_presion, aos_formato_longitud, aos_qiny_configurada, aos_formato_caudal_gas, aos_set_profundidad, aos_sincronizar_config, aos_opcion_modelo_ipr, aos_opcion_modelo_vlp, diagnostico_vlp, aos_menu_qiny, JGL_core, aos_balance_energia_sla, aos_formato_caudal_liquido, aos_imprimir_balance_energia_sla, plot_nodal, diagnostico_tuberia_produccion, aos_semaforo_operacion, aos_imprimir_semaforos, preguntar_reporte, preguntar_exportar_aosrpt

## \n--- ANÁLISIS DE SENSIBILIDAD ---\n (`menu_sensibilidad`)

**Archivo:** `src/menu/menu_sensibilidad.m`  
**Grupo:** GENERAL  
**Opciones:** 0

_No se detectaron opciones visibles._


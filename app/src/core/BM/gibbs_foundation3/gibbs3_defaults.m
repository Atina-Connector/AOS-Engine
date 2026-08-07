function param = gibbs3_defaults(param)
% GIBBS3_DEFAULTS Parametros visibles de Gibbs Foundation 3 integral.

  if nargin < 1 || ~isstruct(param)
    param = struct();
  end

  % Identificacion. La version del solver describe el codigo que realmente
  % ejecuta la corrida y no debe heredarse de un archivo de entrada antiguo.
  param.gibbs3_version = ...
    'AOS_BM_Gibbs_Foundation3_v1_8_signo_tuberia_libre_Octave';
  param.gibbs3_modelo = ...
    'barra_axial_FE_aparato_sarta_bomba_tuberia_libre_signo_fisico_LPP_spacing';
  param.gibbs3_tubing_sign_schema = 'GF3_TUBING_SIGN_1_8';

  % Constantes fisicas y configuracion numerica.
  param = set_default(param, 'gibbs3_gravedad_m_s2', 9.80665);
  param = set_default(param, 'gibbs3_n_nodos', 41);
  param = set_default(param, 'gibbs3_n_ciclos', 5);
  param = set_default(param, 'gibbs3_descartar_ciclos', 1);
  param = set_default(param, 'gibbs3_puntos_por_ciclo', 720);
  param = set_default(param, 'gibbs3_oversampling', 2);
  param = set_default(param, 'gibbs3_cfl', 0.35);
  param = set_default(param, 'gibbs3_integrador', 'euler_simplectico');

  % Movimiento superficial y aparato de bombeo.
  param = set_default(param, 'S_carrera', 1.5);
  param = set_default(param, 'N_velocidad', 6.0);
  param = set_default(param, 'gibbs3_movimiento_superficie', 'aparato_bombeo');
  param = set_default(param, 'gibbs3_fase_inicial_rad', 0.0);
  param = set_default(param, 'pumping_unit_configured', 0);
  param = set_default(param, 'pumping_unit_config_confirmada', 0);
  param = set_default(param, 'pumping_unit_mode', 'no_configurado');
  param = set_default(param, 'pumping_unit_catalog_path', 'config/BM/unidades.txt');
  param = set_default(param, 'pumping_unit_catalog_source', 'config/BM/unidades.txt');
  param = set_default(param, 'pumping_unit_manufacturer', 'AOS');
  param = set_default(param, 'pumping_unit_model', 'GENERICO_SINUSOIDAL');
  param = set_default(param, 'pumping_unit_type', 'Generica');
  param = set_default(param, 'pumping_unit_kinematic_model', 'sinusoidal');
  param = set_default(param, 'pumping_unit_stroke_max_m', 6.0);
  param = set_default(param, 'pumping_unit_spm_min', 0.1);
  param = set_default(param, 'pumping_unit_spm_max', 20.0);
  param = set_default(param, 'pumping_unit_max_pr_load_kN', NaN);
  param = set_default(param, 'pumping_unit_gearbox_torque_kNm', NaN);
  param = set_default(param, 'pumping_unit_motor_power_kW', NaN);
  param = set_default(param, 'pumping_unit_mechanical_efficiency', 0.85);
  param = set_default(param, 'pumping_unit_counterbalance_torque_kNm', NaN);
  param = set_default(param, 'pumping_unit_counterbalance_phase_rad', 0.0);
  param = set_default(param, 'pumping_unit_crank_phase_rad', 0.0);
  param = set_default(param, 'pumping_unit_asymmetry', 0.10);
  param = set_default(param, 'pumping_unit_profile_shape', 1.5);
  param = set_default(param, 'pumping_unit_crank_radius_m', 0.60);
  param = set_default(param, 'pumping_unit_pitman_length_m', 3.20);
  param = set_default(param, 'pumping_unit_beam_rear_arm_m', 2.40);
  param = set_default(param, 'pumping_unit_beam_front_arm_m', 3.00);
  param = set_default(param, 'pumping_unit_crank_center_x_m', 2.80);
  param = set_default(param, 'pumping_unit_crank_center_y_m', -1.00);
  param = set_default(param, 'pumping_unit_linkage_branch', 1);

  % Sarta uniforme por compatibilidad.
  param = set_default(param, 'gibbs3_E_Pa', 207e9);
  param = set_default(param, 'gibbs3_rho_varilla_kg_m3', 7850.0);
  param = set_default(param, 'gibbs3_diam_varilla_mm', 22.2);
  param = set_default(param, 'gibbs3_secciones_varillas', []);
  param = set_default(param, 'gibbs3_delta_damping', 0.10);

  % Datos de fluido, bomba y tubing.
  param = set_default(param, 'D_bomba', 1500.0);
  param = set_default(param, 'D_bomba_TVD', NaN);
  param = set_default(param, 'D_bomba_mm', 32.0);
  param = set_default(param, 'WC', 0.50);
  param = set_default(param, 'rho_o', 850.0);
  param = set_default(param, 'rho_w', 1000.0);
  param = set_default(param, 'P_wh', 10e5);
  param = set_default(param, 'P_intake', NaN);
  param = set_default(param, 'P_intake_min', 1e5);
  param = set_default(param, 'eta_vol', 0.85);
  param = set_default(param, 'gibbs3_llenado_bomba', NaN);
  param = set_default(param, 'tuberia_anclada', 1);
  param = set_default(param, 'OD_tuberia_mm', 73.0);
  param = set_default(param, 'ID_tuberia_mm', 62.0);
  param = set_default(param, 'E_tuberia_Pa', 207e9);
  param = set_default(param, 'longitud_tuberia_m', NaN);
  param = set_default(param, 'longitud_piston_m', 1.20);
  param = set_default(param, 'holgura_radial_mm', 0.075);
  param = set_default(param, 'temperatura_fondo_C', 60.0);
  param = set_default(param, 'viscosidad_fluido_cP', NaN);

  % Bomba LPP AESIR. Por defecto desactivada y debe confirmarse.
  param = set_default(param, 'bomba_lpp', 0);
  param = set_default(param, 'gibbs3_config_lpp_confirmada', 0);
  param = set_default(param, 'lpp_longitud_piston_m', 1.20);
  param = set_default(param, 'lpp_id_piston_mm', 20.0);
  param = set_default(param, 'lpp_area_efectiva_m2', NaN);
  param = set_default(param, 'lpp_rugosidad_m', 4.5e-5);
  param = set_default(param, 'lpp_coef_perdidas_K', 0.0);
  param = set_default(param, 'lpp_modo_hidraulico', 'teorico');

  % Diseno de sarta.
  param = set_default(param, 'rod_design_mode', 'no_configurado');
  param = set_default(param, 'rod_design_configured', 0);
  param = set_default(param, 'rod_grade_name', 'Acero Grado D');
  param = set_default(param, 'rod_catalog_source', 'config/BM/materiales_varillas.txt');
  param = set_default(param, 'rod_Sut_MPa', 793.0);
  param = set_default(param, 'rod_Se_MPa', 280.0);
  param = set_default(param, 'rod_Sy_MPa', 550.0);
  param = set_default(param, 'rod_factor_seguridad', 1.25);
  param = set_default(param, 'rod_allowed_diameters_mm', ...
    [15.9, 19.1, 22.2, 25.4, 28.6]);
  param = set_default(param, 'rod_max_sections', 3);
  param = set_default(param, 'rod_auto_target_utilization', 0.85);
  param = set_default(param, 'rod_optimize_weight', 1);
  param = set_default(param, 'rod_longitud_comercial_m', 9.14);
  param = set_default(param, 'rod_ajuste_minimo_m', 0.05);
  param = set_default(param, 'rod_auto_prefer_tapered', 1);
  param = set_default(param, 'rod_auto_dynamic_verify', 1);
  param = set_default(param, 'rod_auto_max_candidates', 6);
  param = set_default(param, 'rod_design_candidate_name', 'NO_SELECCIONADA');
  param = set_default(param, 'rod_design_selection_reason', 'NO_DISPONIBLE');
  param = set_default(param, 'rod_design_candidates', []);
  param = set_default(param, 'gibbs3_secciones_varillas_base', []);

  % Barras de peso.
  param = set_default(param, 'barras_peso_habilitadas', 1);
  param = set_default(param, 'barras_peso_diametro_mm', 38.1);
  param = set_default(param, 'barras_peso_rho_kg_m3', 7850.0);
  param = set_default(param, 'barras_peso_margen', 1.20);
  param = set_default(param, 'barras_peso_tension_minima_N', 1000.0);
  param = set_default(param, 'barras_peso_longitud_unitaria_m', 7.62);
  param = set_default(param, 'barras_peso_E_Pa', 207e9);
  param = set_default(param, 'barras_peso_Sut_MPa', 793.0);
  param = set_default(param, 'barras_peso_Se_MPa', 280.0);
  param = set_default(param, 'barras_peso_Sy_MPa', 550.0);
  param = set_default(param, 'barras_peso_integrar_en_GF3', 1);
  param = set_default(param, 'barras_peso_aplicadas_cantidad', 0);
  param = set_default(param, 'barras_peso_aplicadas_longitud_m', 0.0);

  % Espaciamiento y expansion termica.
  param = set_default(param, 'spacing_mode', 'no_configurado');
  param = set_default(param, 'spacing_configured', 0);
  param = set_default(param, 'temperatura_superficie_C', 20.0);
  param = set_default(param, 'alpha_termica_varilla_1_C', 11.7e-6);
  param = set_default(param, 'alpha_termica_tuberia_1_C', 11.7e-6);
  param = set_default(param, 'spacing_margen_instalacion_m', 0.10);
  param = set_default(param, 'spacing_clearance_inferior_m', 0.05);
  param = set_default(param, 'spacing_clearance_superior_m', 0.05);
  param = set_default(param, 'spacing_offset_manual_m', NaN);
  param = set_default(param, 'spacing_tolerancia_ejecucion_m', 0.01);
  param = set_default(param, 'spacing_redondeo_mm', 5.0);
  param = set_default(param, 'longitud_barril_util_m', 1.80);
  % El espaciamiento se calcula entre dos estados: sensado e operacion.
  % La elongacion absoluta por peso propio queda solo como diagnostico.
  param = set_default(param, 'spacing_modelo', ...
    'diferencial_entre_sensado_y_operacion');
  param = set_default(param, 'spacing_condicion_termica_sensado', ...
    'estabilizada');
  param = set_default(param, 'spacing_perfil_termico', 'lineal');
  param = set_default(param, 'spacing_temperatura_sensado_superficie_C', ...
    param.temperatura_superficie_C);
  param = set_default(param, 'spacing_temperatura_sensado_fondo_C', ...
    param.temperatura_superficie_C);
  param = set_default(param, 'spacing_correccion_termica_manual_m', 0.0);
  % NaN significa que la capacidad de ajuste del vastago no fue informada.
  param = set_default(param, 'spacing_levantamiento_maximo_disponible_m', NaN);
  param = set_default(param, 'spacing_carga_sensado_N', NaN);
  param = set_default(param, 'spacing_exigir_capacidad_ajuste', 0);

  % Modelo de flotacion.
  param = set_default(param, 'gibbs3_modelo_flotacion', 'por_densidades');
  param = set_default(param, 'gibbs3_factor_flotacion_explicito', NaN);

  % Borde de bomba.
  param = set_default(param, 'gibbs3_friccion_ascenso_N', 0.0);
  param = set_default(param, 'gibbs3_friccion_descenso_N', 0.0);
  param = set_default(param, 'gibbs3_fraccion_referencia_carga', 0.50);
  param = set_default(param, 'gibbs3_velocidad_transicion_valvula_m_s', 0.01);
  param = set_default(param, 'gibbs3_constante_tiempo_valvula_s', 0.08);
  param = set_default(param, 'gibbs3_apertura_valvula_inicial', 0.50);

  % Validacion y presentacion.
  param = set_default(param, 'gibbs3_tolerancia_periodicidad_rel', 0.05);
  param = set_default(param, 'gibbs3_tolerancia_cierre_m', 1e-10);
  param = set_default(param, 'gibbs3_tolerancia_longitud_abs_m', 1e-4);
  param = set_default(param, 'gibbs3_tolerancia_longitud_rel', 1e-6);
  param = set_default(param, 'gibbs3_normalizar_posiciones_grafico', true);
  param = set_default(param, 'gibbs3_exportar_resultado', false);
  param = set_default(param, 'gibbs3_directorio_exportacion', pwd());
end

function s = set_default(s, nombre, valor)
  if ~isfield(s, nombre) || isempty(s.(nombre))
    s.(nombre) = valor;
  end
end

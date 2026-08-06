function gibbs3_validate_params(param)
% GIBBS3_VALIDATE_PARAMS Falla temprano ante entradas fisicas invalidas.

  require_positive(param, 'gibbs3_gravedad_m_s2');
  require_integer(param, 'gibbs3_n_nodos', 3);
  require_integer(param, 'gibbs3_n_ciclos', 1);
  require_integer(param, 'gibbs3_puntos_por_ciclo', 16);
  require_integer(param, 'gibbs3_oversampling', 1);
  require_positive(param, 'gibbs3_cfl');
  if param.gibbs3_cfl >= 1
    error('gibbs3_cfl debe ser menor que 1 para el integrador explicito.');
  end
  if param.gibbs3_descartar_ciclos < 0 || ...
      param.gibbs3_descartar_ciclos >= param.gibbs3_n_ciclos
    error('gibbs3_descartar_ciclos debe estar entre 0 y n_ciclos-1.');
  end

  require_positive(param, 'S_carrera');
  require_positive(param, 'N_velocidad');

  % Aparato de bombeo.
  require_boolean01(param, 'pumping_unit_configured');
  require_boolean01(param, 'pumping_unit_config_confirmada');
  if ~param.pumping_unit_configured || ~param.pumping_unit_config_confirmada
    error('Debe seleccionarse y confirmarse el aparato de bombeo antes de ejecutar GF3.');
  end
  require_positive(param, 'pumping_unit_stroke_max_m');
  require_positive(param, 'pumping_unit_spm_min');
  require_positive(param, 'pumping_unit_spm_max');
  if param.pumping_unit_spm_min > param.pumping_unit_spm_max
    error('pumping_unit_spm_min no puede superar pumping_unit_spm_max.');
  end
  if param.S_carrera > param.pumping_unit_stroke_max_m + 1e-9
    error('La carrera operativa excede la carrera maxima del aparato.');
  end
  if param.N_velocidad < param.pumping_unit_spm_min || ...
      param.N_velocidad > param.pumping_unit_spm_max
    error('La velocidad operativa esta fuera del rango del aparato.');
  end
  require_positive(param, 'pumping_unit_mechanical_efficiency');
  if param.pumping_unit_mechanical_efficiency > 1
    error('pumping_unit_mechanical_efficiency debe ser menor o igual a 1.');
  end
  validar_opcional_positivo(param, 'pumping_unit_max_pr_load_kN');
  validar_opcional_positivo(param, 'pumping_unit_gearbox_torque_kNm');
  validar_opcional_positivo(param, 'pumping_unit_motor_power_kW');
  validar_opcional_no_negativo(param, 'pumping_unit_counterbalance_torque_kNm');
  require_positive(param, 'pumping_unit_crank_radius_m');
  require_positive(param, 'pumping_unit_pitman_length_m');
  require_positive(param, 'pumping_unit_beam_rear_arm_m');
  require_positive(param, 'pumping_unit_beam_front_arm_m');
  if ~isscalar(param.pumping_unit_linkage_branch) || ...
      ~(param.pumping_unit_linkage_branch == 1 || param.pumping_unit_linkage_branch == -1)
    error('pumping_unit_linkage_branch debe ser +1 o -1.');
  end

  require_positive(param, 'D_bomba');
  require_positive(param, 'D_bomba_mm');
  require_positive(param, 'OD_tuberia_mm');
  require_positive(param, 'ID_tuberia_mm');
  require_positive(param, 'E_tuberia_Pa');
  if param.ID_tuberia_mm >= param.OD_tuberia_mm
    error('ID_tuberia_mm debe ser menor que OD_tuberia_mm.');
  end
  if ~isnan(param.longitud_tuberia_m) && param.longitud_tuberia_m <= 0
    error('longitud_tuberia_m debe ser positiva o NaN para usar D_bomba.');
  end
  require_boolean01(param, 'tuberia_anclada');
  require_boolean01(param, 'bomba_lpp');
  require_boolean01(param, 'gibbs3_config_lpp_confirmada');
  require_boolean01(param, 'rod_design_configured');
  require_boolean01(param, 'spacing_configured');
  require_boolean01(param, 'barras_peso_habilitadas');
  if ~param.gibbs3_config_lpp_confirmada
    error('Debe confirmarse bomba convencional o LPP antes de ejecutar GF3.');
  end
  if ~param.rod_design_configured
    error('Debe configurarse o disenarse la sarta antes de ejecutar GF3.');
  end
  if ~param.spacing_configured
    error('Debe configurarse el espaciamiento antes de ejecutar GF3.');
  end

  if param.bomba_lpp
    require_positive(param, 'lpp_longitud_piston_m');
    require_positive(param, 'lpp_id_piston_mm');
    if param.lpp_id_piston_mm >= param.D_bomba_mm
      error('lpp_id_piston_mm debe ser menor que D_bomba_mm.');
    end
    require_nonnegative(param, 'lpp_rugosidad_m');
    require_nonnegative(param, 'lpp_coef_perdidas_K');
    if ~isnan(param.lpp_area_efectiva_m2) && param.lpp_area_efectiva_m2 <= 0
      error('lpp_area_efectiva_m2 debe ser positiva o NaN.');
    end
    require_positive(param, 'viscosidad_fluido_cP');
  end

  require_positive(param, 'rod_Sut_MPa');
  require_positive(param, 'rod_Se_MPa');
  require_positive(param, 'rod_Sy_MPa');
  require_positive(param, 'rod_factor_seguridad');
  require_integer(param, 'rod_max_sections', 1);
  require_positive(param, 'rod_auto_target_utilization');
  if param.rod_auto_target_utilization > 1.0
    error('rod_auto_target_utilization no debe superar 1.0.');
  end
  if ~isnumeric(param.rod_allowed_diameters_mm) || ...
      isempty(param.rod_allowed_diameters_mm) || ...
      any(~isfinite(param.rod_allowed_diameters_mm(:))) || ...
      any(param.rod_allowed_diameters_mm(:) <= 0)
    error('rod_allowed_diameters_mm debe contener diametros positivos.');
  end

  require_positive(param, 'barras_peso_diametro_mm');
  require_positive(param, 'barras_peso_rho_kg_m3');
  require_positive(param, 'barras_peso_margen');
  require_nonnegative(param, 'barras_peso_tension_minima_N');

  require_positive(param, 'longitud_barril_util_m');
  require_nonnegative(param, 'spacing_margen_instalacion_m');
  require_nonnegative(param, 'spacing_clearance_inferior_m');
  require_nonnegative(param, 'spacing_clearance_superior_m');
  if ~isnan(param.spacing_offset_manual_m) && param.spacing_offset_manual_m < 0
    error('spacing_offset_manual_m debe ser no negativo o NaN.');
  end

  require_positive(param, 'rho_o');
  require_positive(param, 'rho_w');
  require_nonnegative(param, 'P_wh');
  if param.WC < 0 || param.WC > 1
    error('WC debe estar entre 0 y 1.');
  end
  if param.eta_vol <= 0 || param.eta_vol > 1.2
    error('eta_vol debe estar en (0,1.2].');
  end
  if ~isnan(param.gibbs3_llenado_bomba) && ...
      (param.gibbs3_llenado_bomba <= 0 || param.gibbs3_llenado_bomba > 1.2)
    error('gibbs3_llenado_bomba debe estar en (0,1.2] o ser NaN.');
  end

  require_nonnegative(param, 'gibbs3_delta_damping');
  require_nonnegative(param, 'gibbs3_friccion_ascenso_N');
  require_nonnegative(param, 'gibbs3_friccion_descenso_N');
  require_positive(param, 'gibbs3_velocidad_transicion_valvula_m_s');
  require_nonnegative(param, 'gibbs3_constante_tiempo_valvula_s');
  if param.gibbs3_apertura_valvula_inicial < 0 || ...
      param.gibbs3_apertura_valvula_inicial > 1
    error('gibbs3_apertura_valvula_inicial debe estar entre 0 y 1.');
  end
  if param.gibbs3_fraccion_referencia_carga < 0 || ...
      param.gibbs3_fraccion_referencia_carga > 1
    error('gibbs3_fraccion_referencia_carga debe estar entre 0 y 1.');
  end

  if isempty(param.gibbs3_secciones_varillas)
    require_positive(param, 'gibbs3_E_Pa');
    require_positive(param, 'gibbs3_rho_varilla_kg_m3');
    require_positive(param, 'gibbs3_diam_varilla_mm');
  else
    validar_secciones(param);
  end
end

function validar_secciones(param)
  sec = param.gibbs3_secciones_varillas;
  if ~isstruct(sec)
    error('gibbs3_secciones_varillas debe ser un arreglo de estructuras.');
  end
  campos = {'longitud_m', 'diametro_mm', 'E_Pa', 'rho_kg_m3'};
  for i = 1:numel(sec)
    for j = 1:numel(campos)
      c = campos{j};
      if ~isfield(sec(i), c) || ~finite_positive(sec(i).(c))
        error('Seccion %d: falta %s positivo.', i, c);
      end
    end
    if isfield(sec(i), 'Sut_MPa') && ~finite_positive(sec(i).Sut_MPa)
      error('Seccion %d: Sut_MPa invalido.', i);
    end
    if isfield(sec(i), 'Se_MPa') && ~finite_positive(sec(i).Se_MPa)
      error('Seccion %d: Se_MPa invalido.', i);
    end
  end
  Lsec = sum([sec.longitud_m]);
  tolL = max(param.gibbs3_tolerancia_longitud_abs_m, ...
    param.gibbs3_tolerancia_longitud_rel*param.D_bomba);
  if abs(Lsec-param.D_bomba) > tolL
    error(['La suma de longitudes de gibbs3_secciones_varillas (%.6g m) ' ...
      'debe coincidir con D_bomba (%.6g m).'], Lsec, param.D_bomba);
  end
end

function require_positive(s, n)
  if ~isfield(s, n) || ~finite_positive(s.(n))
    error('%s debe ser un escalar positivo.', n);
  end
end

function require_nonnegative(s, n)
  if ~isfield(s, n) || ~isnumeric(s.(n)) || ~isscalar(s.(n)) || ...
      ~isfinite(s.(n)) || s.(n) < 0
    error('%s debe ser un escalar no negativo.', n);
  end
end

function require_integer(s, n, minimo)
  if ~isfield(s, n) || ~isnumeric(s.(n)) || ~isscalar(s.(n)) || ...
      ~isfinite(s.(n)) || s.(n) < minimo || s.(n) ~= round(s.(n))
    error('%s debe ser un entero mayor o igual que %d.', n, minimo);
  end
end

function require_boolean01(s, n)
  if ~isfield(s, n) || ~isscalar(s.(n)) || ...
      ~(s.(n) == 0 || s.(n) == 1)
    error('%s debe ser 0 o 1.', n);
  end
end


function validar_opcional_positivo(s, n)
  if ~isfield(s,n) || isempty(s.(n)) || isnan(s.(n))
    return;
  end
  if ~isnumeric(s.(n)) || ~isscalar(s.(n)) || ~isfinite(s.(n)) || s.(n) <= 0
    error('%s debe ser positivo o NaN.', n);
  end
end

function validar_opcional_no_negativo(s, n)
  if ~isfield(s,n) || isempty(s.(n)) || isnan(s.(n))
    return;
  end
  if ~isnumeric(s.(n)) || ~isscalar(s.(n)) || ~isfinite(s.(n)) || s.(n) < 0
    error('%s debe ser no negativo o NaN.', n);
  end
end

function tf = finite_positive(x)
  tf = isnumeric(x) && isscalar(x) && isfinite(x) && x > 0;
end

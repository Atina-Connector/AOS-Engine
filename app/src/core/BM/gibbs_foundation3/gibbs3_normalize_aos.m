function param = gibbs3_normalize_aos(param)
% GIBBS3_NORMALIZE_AOS Convierte aliases AOS a campos canonicos GF3.

  if nargin < 1 || ~isstruct(param)
    param = struct();
  end

  param = copy_alias(param, 'D_bomba', ...
    {'D_bomba_m','prof_bomba_m','profundidad_bomba_m'});
  param = copy_alias(param, 'D_bomba_mm', ...
    {'diametro_bomba_mm','pump_diameter_mm'});
  param = copy_alias(param, 'S_carrera', ...
    {'carrera_m','stroke_m','pumping_unit_stroke_m'});
  param = copy_alias(param, 'N_velocidad', ...
    {'spm','golpes_min','pumping_unit_spm'});
  param = copy_alias(param, 'P_wh', ...
    {'P_wh_Pa','presion_cabeza_Pa'});
  param = copy_alias(param, 'P_intake', ...
    {'P_intake_Pa','presion_intake_Pa'});
  param = copy_alias(param, 'rho_o', ...
    {'rho_o_kg_m3','densidad_petroleo_kg_m3'});
  param = copy_alias(param, 'rho_w', ...
    {'rho_w_kg_m3','densidad_agua_kg_m3'});
  param = copy_alias(param, 'WC', ...
    {'WC_fraccion','water_cut'});
  param = copy_alias(param, 'eta_vol', ...
    {'eficiencia_volumetrica','eta_vol_BM'});
  param = copy_alias(param, 'temperatura_fondo_C', ...
    {'T_fondo_C','bottomhole_temperature_C'});
  param = copy_alias(param, 'viscosidad_fluido_cP', ...
    {'viscosidad_cP','mu_cP','fluid_viscosity_cP'});
  param = copy_alias(param, 'longitud_piston_m', ...
    {'largo_piston_m','plunger_length_m'});
  param = copy_alias(param, 'holgura_radial_mm', ...
    {'luz_radial_mm','plunger_radial_clearance_mm'});
  param = copy_alias(param, 'longitud_tuberia_m', ...
    {'L_tuberia_m','tubing_length_m','profundidad_tuberia_m'});

  % Aparato de bombeo.
  param = copy_alias(param, 'pumping_unit_manufacturer', ...
    {'fabricante_unidad_BM','fabricante_aparato'});
  param = copy_alias(param, 'pumping_unit_model', ...
    {'modelo_unidad_BM','modelo_aparato'});
  param = copy_alias(param, 'pumping_unit_type', ...
    {'tipo_unidad','tipo_aparato'});
  param = copy_alias(param, 'pumping_unit_stroke_max_m', ...
    {'carrera_max_unidad_m','pumping_unit_max_stroke_m'});
  param = copy_alias(param, 'pumping_unit_spm_min', ...
    {'spm_min_unidad'});
  param = copy_alias(param, 'pumping_unit_spm_max', ...
    {'spm_max_unidad','vel_max_gpm'});
  param = copy_alias(param, 'pumping_unit_max_pr_load_kN', ...
    {'carga_max_PR_kN','pumping_unit_max_load_kN'});
  param = copy_alias(param, 'pumping_unit_gearbox_torque_kNm', ...
    {'torque_reductor_kNm','pumping_unit_torque_kNm'});
  param = copy_alias(param, 'pumping_unit_motor_power_kW', ...
    {'potencia_motor_kW','pumping_unit_power_kW'});
  param = copy_alias(param, 'pumping_unit_kinematic_model', ...
    {'modelo_cinematico_unidad','pumping_unit_motion_model'});

  param = copy_alias(param, 'bomba_lpp', ...
    {'usa_bomba_lpp','lpp','pump_lpp'});
  param = copy_alias(param, 'lpp_longitud_piston_m', ...
    {'longitud_piston_lpp_m','largo_piston_lpp_m'});
  param = copy_alias(param, 'lpp_id_piston_mm', ...
    {'id_piston_lpp_mm','diametro_interno_lpp_mm'});

  param = copy_alias(param, 'rod_design_mode', ...
    {'modo_diseno_sarta','sarta_modo'});
  param = copy_alias(param, 'rod_grade_name', ...
    {'grado_varilla','material_varillas'});
  param = copy_alias(param, 'rod_factor_seguridad', ...
    {'factor_seguridad_varillas','sarta_factor_seguridad'});
  param = copy_alias(param, 'spacing_mode', ...
    {'modo_espaciamiento','espaciamiento_modo'});
  param = copy_alias(param, 'spacing_offset_manual_m', ...
    {'espaciamiento_superficie_m','spacing_superficie_m'});

  if (~isfield(param,'P_wh') || isempty(param.P_wh)) && ...
      isfield(param,'P_wh_bar') && isfinite_scalar(param.P_wh_bar)
    param.P_wh = param.P_wh_bar*1e5;
  end
  if (~isfield(param,'P_intake') || isempty(param.P_intake)) && ...
      isfield(param,'P_intake_min_bar') && isfinite_scalar(param.P_intake_min_bar)
    param.P_intake = param.P_intake_min_bar*1e5;
  end

  if isfield(param,'pumping_unit_type') && ...
      (~isfield(param,'pumping_unit_kinematic_model') || ...
       isempty(param.pumping_unit_kinematic_model))
    param.pumping_unit_kinematic_model = cinematica_por_tipo(param.pumping_unit_type);
  end
  if ~isfield(param,'pumping_unit_config_confirmada') || ...
      isempty(param.pumping_unit_config_confirmada)
    param.pumping_unit_config_confirmada = 0;
  end
  if ~isfield(param,'pumping_unit_configured') || ...
      isempty(param.pumping_unit_configured)
    param.pumping_unit_configured = 0;
  end

  if ~isfield(param, 'gibbs3_config_lpp_confirmada') || ...
      isempty(param.gibbs3_config_lpp_confirmada)
    param.gibbs3_config_lpp_confirmada = 0;
  end
  if isfield(param, 'gibbs3_secciones_varillas') && ...
      ~isempty(param.gibbs3_secciones_varillas)
    param.rod_design_configured = 1;
    if ~isfield(param, 'rod_design_mode') || isempty(param.rod_design_mode)
      param.rod_design_mode = 'aosdat_existente';
    end
  end
  if isfield(param, 'spacing_offset_manual_m') && ...
      isfinite_scalar(param.spacing_offset_manual_m)
    param.spacing_configured = 1;
    if ~isfield(param, 'spacing_mode') || isempty(param.spacing_mode)
      param.spacing_mode = 'manual';
    end
  elseif isfield(param, 'spacing_mode') && ...
      ~isempty(param.spacing_mode) && ~strcmpi(param.spacing_mode, 'no_configurado')
    param.spacing_configured = 1;
  end

  if (~isfield(param,'D_bomba_TVD') || ~isfinite_scalar(param.D_bomba_TVD)) && ...
      isfield(param,'survey') && isfinite_scalar_field(param,'D_bomba')
    tvd = survey_tvd_at_md(param.survey, param.D_bomba);
    if isfinite(tvd)
      param.D_bomba_TVD = tvd;
    end
  end

  try
    param = aos_bm_propiedades_fluido(param);
  catch
  end
end

function s = copy_alias(s, canonico, aliases)
  if isfield(s, canonico) && ~isempty(s.(canonico))
    return;
  end
  for k = 1:numel(aliases)
    a = aliases{k};
    if isfield(s, a) && ~isempty(s.(a))
      s.(canonico) = s.(a);
      return;
    end
  end
end

function modelo = cinematica_por_tipo(tipo)
  t = lower(strtrim(tipo));
  if ~isempty(strfind(t,'reverse')) || ~isempty(strfind(t,'revers'))
    modelo = 'perfil_reverse_mark_representativo';
  elseif ~isempty(strfind(t,'mark'))
    modelo = 'perfil_markii_representativo';
  elseif ~isempty(strfind(t,'rota')) || ~isempty(strfind(t,'carrera'))
    modelo = 'perfil_carrera_larga';
  elseif ~isempty(strfind(t,'hidrau'))
    modelo = 'perfil_hidraulico_suave';
  elseif ~isempty(strfind(t,'conv'))
    modelo = 'perfil_convencional_representativo';
  else
    modelo = 'sinusoidal';
  end
end

function tvd = survey_tvd_at_md(survey, md)
  tvd = NaN;
  if isnumeric(survey) && size(survey,2) >= 2 && size(survey,1) >= 2
    M = survey(:,1:2);
  elseif isstruct(survey) && isfield(survey,'MD_m') && isfield(survey,'TVD_m')
    M = [survey.MD_m(:), survey.TVD_m(:)];
  elseif isstruct(survey) && isfield(survey,'MD') && isfield(survey,'TVD')
    M = [survey.MD(:), survey.TVD(:)];
  else
    return;
  end
  mask = all(isfinite(M),2);
  M = M(mask,:);
  if size(M,1) < 2, return; end
  [mds, idx] = sort(M(:,1));
  tvds = M(idx,2);
  md_eval = min(max(md, mds(1)), mds(end));
  tvd = interp1(mds, tvds, md_eval, 'linear');
end

function tf = isfinite_scalar(x)
  tf = isnumeric(x) && isscalar(x) && isfinite(x);
end

function tf = isfinite_scalar_field(s, n)
  tf = isfield(s,n) && isfinite_scalar(s.(n));
end

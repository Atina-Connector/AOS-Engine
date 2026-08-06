function perfil = calcular_perfil_tuberia_produccion(param, survey, Ql, Qiny, opciones)
  % calcular_perfil_tuberia_produccion.m
  % Calcula el perfil comun de tuberia para erosion, carga y Taitel.
  % Esta funcion no grafica: solo calcula. El grafico se hace en
  % plot_erosion_taitel.m. Asi los sistemas futuros pueden reutilizarla.

  if nargin < 5 || isempty(opciones), opciones = struct(); end
  if nargin < 4 || isempty(Qiny), Qiny = 0; end
  if nargin < 3 || isempty(Ql), Ql = 0; end

  survey = completar_survey_local(survey, param);
  MD = survey.MD(:);
  TVD = survey.TVD(:);
  n = length(MD);

  ID = campo_vector(survey, 'ID_tubing', n, leer_num(param, {'diam_tbg'}, 0.062));
  inclinacion = campo_vector(survey, 'inclinacion', n, 0);
  azimut = campo_vector(survey, 'azimut', n, 0);
  rugosidad = campo_vector(survey, 'rugosidad', n, 4.57e-5);

  P_wh = leer_num(param, {'P_wh'}, 10e5);
  if P_wh <= 0, P_wh = 10e5; end
  T_sup = leer_num(param, {'T_sup'}, 298.15);
  T_fondo = leer_num(param, {'T_fondo'}, 358.15);
  if T_sup < 150, T_sup = T_sup + 273.15; end
  if T_fondo < 150, T_fondo = T_fondo + 273.15; end
  GLR = leer_num(param, {'GLR'}, 0);
  WC = leer_num(param, {'WC'}, 0);
  rho_o = leer_num(param, {'rho_o'}, 850);
  rho_w = leer_num(param, {'rho_w'}, 1000);
  rho_l = (1 - WC) * rho_o + WC * rho_w;
  if rho_l <= 0, rho_l = 900; end
  gamma_g = leer_num(param, {'gamma_g'}, 0.7);
  Z = leer_num(param, {'Z','z_factor'}, 0.85);
  if Z <= 0, Z = 0.85; end

  sigma = leer_num(param, {'sigma','tension_superficial','sigma_Nm'}, 0.030);
  mu_l = leer_num(param, {'mu_l','mu_o'}, 0.001);
  C_erosion = leer_num(opciones, {'C_erosion'}, leer_num(param, {'C_erosion'}, 100));

  P_std = 101325;
  T_std = 288.15;
  R = 8.314462618;
  M_air = 0.02897;
  M_g = max(gamma_g, 0.1) * M_air;

  tvd0 = min(TVD);
  dtvd = max(TVD) - tvd0;
  if abs(dtvd) < eps
      dtvd = max(MD) - min(MD);
      if abs(dtvd) < eps, dtvd = 1; end
      TVD_ref = MD - min(MD);
  else
      TVD_ref = TVD - tvd0;
  end
  T = T_sup + (T_fondo - T_sup) .* (TVD_ref ./ dtvd);
  T = max(T, 200);
  T_prom = max((T_sup + T) ./ 2, 200);
  P = P_wh .* exp(M_g * 9.81 .* TVD_ref ./ max(Z * R .* T_prom, eps));
  P = max(P, 101325);
  rho_g = P .* M_g ./ max(Z * R .* T, eps);
  rho_g = max(rho_g, 0.01);

  A = pi .* (ID ./ 2).^2;
  A = max(A, 1e-6);

  Ql = max(Ql, 0);
  Qiny = max(Qiny, 0);
  Qgas_total_std_opt = leer_num(opciones, {'Qgas_total_std','Qgas_total','Qg_total'}, NaN);
  Qgas_form_std_opt = leer_num(opciones, {'Qgas_form_std','Qgas_formacion_std'}, NaN);

  if ~isnan(Qgas_form_std_opt)
      Qgas_form_std = max(Qgas_form_std_opt, 0);
  elseif ~isnan(Qgas_total_std_opt) && Qgas_total_std_opt >= Qiny
      Qgas_form_std = max(Qgas_total_std_opt - Qiny, 0);
  else
      Qgas_form_std = max(Ql * max(GLR, 0), 0);
  end

  if ~isnan(Qgas_total_std_opt)
      Qgas_total_std = max(Qgas_total_std_opt, Qgas_form_std + Qiny);
  else
      Qgas_total_std = Qgas_form_std + Qiny;
  end

  D_inyeccion = leer_num(opciones, {'D_inyeccion','D_valvula','D_eductor','D_levantamiento'}, NaN);
  if isnan(D_inyeccion)
      D_inyeccion = profundidad_levantamiento(param);
  end

  Qgas_profile_std = Qgas_form_std * ones(n, 1);
  Qiny_profile_std = zeros(n, 1);
  if Qiny > 0
      if isfinite(D_inyeccion)
          mascara_inyeccion = (MD <= D_inyeccion + 1e-6);
      else
          mascara_inyeccion = ones(n, 1) > 0;
      end
      Qiny_profile_std(mascara_inyeccion) = Qiny;
      Qgas_profile_std = Qgas_profile_std + Qiny_profile_std;
  else
      mascara_inyeccion = zeros(n, 1) > 0;
  end

  Qgas_local = Qgas_profile_std .* (P_std ./ P) .* (T ./ T_std);
  Vsg = Qgas_local ./ A;
  Vsl = Ql ./ A;
  Vmix = Vsg + Vsl;
  Fr_g = Vsg ./ max(sqrt(9.81 .* ID), eps);
  Fr_m = Vmix ./ max(sqrt(9.81 .* ID), eps);
  fraccion_gas_superficial = Vsg ./ max(Vmix, eps);

  % API RP 14E simplificado. Para erosion se usa densidad de mezcla y velocidad
  % superficial de mezcla. Es un criterio practico/conservador para diagnostico.
  rho_mix = (rho_l .* Vsl + rho_g .* Vsg) ./ max(Vmix, eps);
  rho_mix = max(rho_mix, 1);
  rho_mix_lbm_ft3 = rho_mix ./ 16.0185;
  V_eros = 0.3048 .* C_erosion ./ sqrt(max(rho_mix_lbm_ft3, eps));

  % Turner simplificado para carga de liquido: compara velocidad superficial de gas.
  sigma_dyn_cm = max(sigma * 1000, 1); % 0.030 N/m = 30 dyn/cm
  rho_g_lbm_ft3 = rho_g ./ 16.0185;
  rho_l_lbm_ft3 = rho_l ./ 16.0185;
  V_carga_ft_s = 5.48 .* sqrt(sigma_dyn_cm .* max(rho_l_lbm_ft3 - rho_g_lbm_ft3, eps) ./ max(rho_g_lbm_ft3.^2, eps));
  V_carga = V_carga_ft_s .* 0.3048;

  ratio_erosion = Vmix ./ max(V_eros, eps);
  ratio_carga = Vsg ./ max(V_carga, eps);

  regimenes = cell(n, 1);
  for i = 1:n
      inc_rad = deg2rad(inclinacion(i));
      try
          regimenes{i} = calcular_regimen(Vsg(i), Vsl(i), ID(i), rho_g(i), rho_l, sigma, mu_l, inc_rad);
      catch
          regimenes{i} = regimen_simple(Vsg(i), Vsl(i));
      end
  end

  alerta = struct();
  alerta.erosion = find(ratio_erosion > 1.0);
  alerta.carga = find(ratio_carga < 1.0);
  alerta.slug = find(strcmp(regimenes, 'slug') | strcmp(regimenes, 'slug_severo'));
  alerta.transicion = find(strcmp(regimenes, 'transicion'));
  alerta.niebla = find(strcmp(regimenes, 'niebla'));

  perfil = struct();
  perfil.MD = MD;
  perfil.TVD = TVD;
  perfil.ID = ID;
  perfil.inclinacion = inclinacion;
  perfil.azimut = azimut;
  perfil.rugosidad = rugosidad;
  perfil.A = A;
  perfil.P = P;
  perfil.T = T;
  perfil.rho_g = rho_g;
  perfil.rho_l = rho_l;
  perfil.rho_mix = rho_mix;
  perfil.Ql = Ql;
  perfil.Qiny_std = Qiny;
  perfil.Qgas_form_std = Qgas_form_std;
  perfil.Qgas_total_std = Qgas_total_std;
  perfil.Qgas_profile_std = Qgas_profile_std;
  perfil.Qiny_profile_std = Qiny_profile_std;
  perfil.Qgas_local = Qgas_local;
  perfil.Vsg = Vsg;
  perfil.Vsl = Vsl;
  perfil.Vmix = Vmix;
  perfil.Fr_g = Fr_g;
  perfil.Fr_m = Fr_m;
  perfil.fraccion_gas_superficial = fraccion_gas_superficial;
  perfil.V_eros = V_eros;
  perfil.V_carga = V_carga;
  perfil.ratio_erosion = ratio_erosion;
  perfil.ratio_carga = ratio_carga;
  perfil.regimenes = regimenes;
  perfil.alerta = alerta;
  perfil.D_inyeccion = D_inyeccion;
  perfil.mascara_inyeccion = mascara_inyeccion;
  perfil.survey_simplificado = (n < 3);
  perfil.C_erosion = C_erosion;
  perfil.sigma = sigma;
  perfil.mu_l = mu_l;
  perfil.criterio_erosion = 'API14E_simplificado_mezcla';
  perfil.criterio_carga = 'Turner_simplificado';
  perfil.criterio_regimen = 'Taitel_Dukler_simplificado_AOS_v06_orientativo';
end

function survey = completar_survey_local(survey, param)
  if isempty(survey) || ~isstruct(survey)
      survey = struct();
  end
  if ~isfield(survey, 'MD') || isempty(survey.MD)
      D = leer_num(param, {'D_tubing','D_res'}, 3000);
      survey.MD = [0; D];
  end
  survey.MD = survey.MD(:);
  n = length(survey.MD);
  if ~isfield(survey, 'TVD') || isempty(survey.TVD)
      survey.TVD = survey.MD;
  end
  survey.TVD = ajustar_largo(survey.TVD(:), n, survey.MD);
  if ~isfield(survey, 'inclinacion') || isempty(survey.inclinacion)
      survey.inclinacion = zeros(n, 1);
  end
  survey.inclinacion = ajustar_largo(survey.inclinacion(:), n, zeros(n,1));
  if ~isfield(survey, 'ID_tubing') || isempty(survey.ID_tubing)
      survey.ID_tubing = leer_num(param, {'diam_tbg'}, 0.062) * ones(n,1);
  end
  survey.ID_tubing = ajustar_largo(survey.ID_tubing(:), n, leer_num(param, {'diam_tbg'}, 0.062) * ones(n,1));
end

function v = campo_vector(s, campo, n, defecto)
  if isfield(s, campo) && ~isempty(s.(campo))
      v = s.(campo)(:);
  else
      v = defecto * ones(n,1);
  end
  if length(v) == 1
      v = v * ones(n,1);
  elseif length(v) ~= n
      v = ajustar_largo(v, n, defecto * ones(n,1));
  end
end

function v = ajustar_largo(v, n, defecto)
  if length(v) == n
      return;
  elseif length(v) == 1
      v = v * ones(n,1);
  else
      x_old = linspace(0, 1, length(v));
      x_new = linspace(0, 1, n);
      try
          v = interp1(x_old, v(:), x_new, 'linear', 'extrap')(:);
      catch
          v = defecto(:);
          if length(v) ~= n
              v = v(1) * ones(n,1);
          end
      end
  end
end

function D = profundidad_levantamiento(param)
  D = NaN;
  if isfield(param, 'gl') && isstruct(param.gl) && isfield(param.gl, 'D_valvula')
      D = param.gl.D_valvula;
      return;
  end
  nombres = {'D_valvula','D_eductor','D_levantamiento','D_bomba'};
  for k = 1:length(nombres)
      if isfield(param, nombres{k}) && isnumeric(param.(nombres{k})) && ~isempty(param.(nombres{k}))
          D = param.(nombres{k})(1);
          return;
      end
  end
end

function reg = regimen_simple(vsg, vsl)
  if vsg < 0.25 * max(vsl, eps)
      reg = 'burbuja';
  elseif vsg > 8
      reg = 'niebla';
  elseif vsg > 3
      reg = 'transicion';
  else
      reg = 'slug';
  end
end

function v = leer_num(s, nombres, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  for k = 1:length(nombres)
      nombre = nombres{k};
      if isfield(s, nombre)
          tmp = s.(nombre);
          if isnumeric(tmp) && ~isempty(tmp)
              v = tmp(1);
              return;
          end
      end
  end
end

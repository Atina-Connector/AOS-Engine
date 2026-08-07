function [Ql, Qo, Qgas_total, Q_iny, Qiny_MMscfd, diagnostico, sol_gl] = GL_puro_core(param)
  % GL_puro_core.m - Motor Gas Lift convencional.
  % AOS 0.0.11f - Nodal Guard.
  % Usa un único balance nodal auditable para solver y gráfico.

  diagnostico = '';
  sol_gl = struct();
  if nargin < 1 || ~isstruct(param), param = struct(); end
  try
      param = aos_normalizar_config(param, 'GL');
  catch
  end
  if ~isfield(param, 'modelo_IPR'), param.modelo_IPR = 'linear'; end
  if ~isfield(param, 'modelo_VLP'), param.modelo_VLP = 'simplified'; end
  if ~isfield(param, 'P_b') || isempty(param.P_b), param.P_b = 100e5; end
  param.P_b = aos_normalizar_presion_burbuja(param.P_b, 100);

  P_wh      = getnum_glp(param, 'P_wh', 10e5);
  P_iny_sup = getnum_glp(param, 'P_iny_sup', 0);
  D_iny     = aos_profundidad_inyeccion(param, getnum_glp(param, 'D_bomba', 2000));
  try
      param = aos_set_profundidad(param, 'GL', D_iny);
  catch
      param.D_iny = D_iny; param.D_iny_m = D_iny;
  end
  if isfield(param, 'survey'), survey = param.survey; else, survey = []; end

  % --- Caudal de gas inyectado ---
  if isfield(param, 'Q_iny') && ~isempty(param.Q_iny)
      Q_iny = max(param.Q_iny, 0);
      if P_iny_sup <= P_wh && Q_iny > 0
          diagnostico = agregar_diag(diagnostico, 'Escenario hipotetico: Qiny impuesto sin margen evidente de presion de inyeccion en superficie.');
      end
  else
      Q_iny = calcular_qiny_auto(param, D_iny, survey);
  end
  param.Q_iny = Q_iny;

  % --- Resolver cruce nodal robusto ---
  [Ql, det_solver] = aos_resolver_gl(param, Q_iny);
  diagnostico = agregar_diag(diagnostico, det_solver.mensaje);
  if isfield(det_solver, 'estado')
      diagnostico = agregar_diag(diagnostico, sprintf('Estado solver nodal: %s.', det_solver.estado));
  end
  if isfield(det_solver, 'raices') && length(det_solver.raices) > 1
      diagnostico = agregar_diag(diagnostico, sprintf('Advertencia: se detectaron %d cruces nodales; se usa el primero estable.', length(det_solver.raices)));
  end

  % --- Diagnostico intake/reservorio ---
  if Ql > 0
      try
          [P_s_guard, det_guard] = calcular_columna_succion(Ql, param);
          guard = aos_sla_intake_guard('GL', Ql, P_s_guard, param, det_guard);
          if ~strcmp(guard.estado, 'OK')
              diagnostico = agregar_diag(diagnostico, guard.mensaje);
          end
      catch err_guard
          diagnostico = agregar_diag(diagnostico, sprintf('No se pudo evaluar intake guard GL: %s', err_guard.message));
      end
  end

  % --- Resultados ---
  WC = getnum_glp(param, 'WC', 0.5);
  GLR = getnum_glp(param, 'GLR', 0);
  if Ql > 0
      Qo = Ql * (1 - WC);
      Qgas_total = Ql * GLR + Q_iny;
  else
      Qo = 0;
      Qgas_total = Q_iny;
  end

  Qiny_MMscfd = Q_iny * 86400 / 0.0283168 / 1e6;
  sol_gl = struct('Ql',Ql,'Qo',Qo,'Qgas_total',Qgas_total,'Qiny',Q_iny, ...
      'D_iny',D_iny,'estado',det_solver.estado,'diagnostico',diagnostico, ...
      'solver',det_solver);
  sol_gl.audit = struct('Qiny_solicitado',Q_iny,'Qiny_efectivo',Q_iny, ...
      'IP_efectivo',getnum_glp(param,'IP',NaN), ...
      'P_res_efectiva',getnum_glp(param,'P_res',NaN), ...
      'P_wh_efectiva',getnum_glp(param,'P_wh',NaN), ...
      'P_iny_sup_efectiva',getnum_glp(param,'P_iny_sup',NaN), ...
      'D_iny_efectiva',D_iny,'GLR_efectivo',GLR);
  if isfield(det_solver,'balance_solucion')
      b = det_solver.balance_solucion;
      sol_gl.audit.balance = b;
      if isfield(b,'Qg_inyectado_std'), sol_gl.audit.Qiny_efectivo = b.Qg_inyectado_std; end
      if isfield(b,'Qg_formacion_std'), sol_gl.audit.Qg_formacion_std = b.Qg_formacion_std; end
      if isfield(b,'Qg_total_std'), sol_gl.audit.Qg_total_std = b.Qg_total_std; end
      if isfield(b,'P_s'), sol_gl.audit.P_s = b.P_s; end
      if isfield(b,'P_req'), sol_gl.audit.P_req = b.P_req; end
      if isfield(b,'residuo'), sol_gl.audit.residuo = b.residuo; end
  end
  diagnostico = agregar_diag(diagnostico, sprintf('VLP seleccionada: %s | VLP efectiva: %s.', param.modelo_VLP, aos_vlp_modelo_efectivo(param, D_iny)));
  diagnostico = agregar_diag(diagnostico, 'Tramo inferior: Intake AOS con TVD, gas libre por Rs y densidad local de gas.');
end

function Q_iny = calcular_qiny_auto(param, D_iny, survey)
  P_iny_sup = getnum_glp(param, 'P_iny_sup', 0);
  T_sup     = getnum_glp(param, 'T_sup', 298.15);
  T_fondo   = getnum_glp(param, 'T_fondo', 358.15);
  rho_g_std = getnum_glp(param, 'rho_g_std', 0.8);
  gamma_g   = getnum_glp(param, 'gamma_g', 0.7);
  d_orif = getnum_glp(param, 'd_orif', 0.012);
  C_d = getnum_glp(param, 'C_d_orif', 0.85);
  delta_P_ap = 5e5;
  Z = 0.85; R_gas = 8.314;
  M_g = max(gamma_g * 0.028967, 0.002);
  Ts = normalizar_TK_glp(T_sup); Tf = normalizar_TK_glp(T_fondo);
  T_prom = (Ts + Tf) / 2;
  TVD_iny = D_iny;
  if ~isempty(survey) && isstruct(survey), TVD_iny = aos_tvd_at_md(survey, D_iny); end
  P_valv = P_iny_sup * exp(M_g * 9.81 * TVD_iny / (Z * R_gas * max(T_prom,200)));
  if ~isempty(survey) && isstruct(survey) && isfield(survey, 'TVD') && ~isempty(survey.TVD)
      T_valv = Ts + (Tf - Ts) * TVD_iny / max(max(survey.TVD), 1);
  else
      T_valv = Tf;
  end
  P_down_est = max(P_valv - delta_P_ap, 1e5);
  kappa_TC = 1.30;
  try
      Q_iny_masico = thornhill_craver(P_valv, P_down_est, T_valv, d_orif, getnum_glp(param,'R_gas',519.6), kappa_TC, C_d);
      Q_iny = max(Q_iny_masico / max(rho_g_std, 1e-12), 0);
  catch
      Q_iny = 0;
  end
end

function T = normalizar_TK_glp(T)
  if ~isfinite(T) || T <= 0, T = 300; end
  if T < 150, T = T + 273.15; end
end

function out = agregar_diag(base, nuevo)
  if nargin < 1 || isempty(base)
      out = nuevo;
  elseif nargin < 2 || isempty(nuevo)
      out = base;
  else
      out = sprintf('%s\n%s', base, nuevo);
  end
end

function v = getnum_glp(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
          v = x(1);
      elseif ischar(x)
          y = str2double(x);
          if isfinite(y), v = y; end
      end
  end
end

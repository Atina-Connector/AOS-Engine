function [Ql, Qo, Qgas_total, Qiny, diagnostico, det_solver] = GL_sim(param, Qiny)
% GL_sim.m - Simulador de Gas Lift convencional.
% AOS 0.0.11f: usa solver nodal robusto común con plot_nodal.

  diagnostico = '';
  det_solver = struct();
  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || isempty(Qiny)
      if isfield(param, 'Q_iny'), Qiny = param.Q_iny; else, Qiny = 0; end
  end
  Qiny = max(Qiny, 0);

  try
      param = aos_normalizar_config(param, 'GL');
  catch
  end
  if ~isfield(param, 'modelo_IPR'), param.modelo_IPR = 'linear'; end
  if ~isfield(param, 'modelo_VLP'), param.modelo_VLP = 'simplified'; end
  if ~isfield(param, 'P_b') || isempty(param.P_b), param.P_b = 100e5; end
  param.P_b = aos_normalizar_presion_burbuja(param.P_b, 100);
  param.Q_iny = Qiny;

  [Ql, det_solver] = aos_resolver_gl(param, Qiny);
  diagnostico = det_solver.mensaje;
  if isfield(det_solver, 'estado')
      diagnostico = agregar_diag_glsim(diagnostico, ['Estado solver: ' det_solver.estado]);
  end

  if Ql > 0
      try
          [P_s_guard, det_guard] = calcular_columna_succion(Ql, param);
          guard = aos_sla_intake_guard('GL', Ql, P_s_guard, param, det_guard);
          if isfield(guard, 'estado') && ~strcmp(guard.estado, 'OK')
              diagnostico = agregar_diag_glsim(diagnostico, guard.mensaje);
          end
      catch err_guard
          diagnostico = agregar_diag_glsim(diagnostico, ['No se pudo evaluar intake guard GL: ', err_guard.message]);
      end
  end

  if Ql > 0
      try
          [v_sg, v_crit] = turner_gl(Ql, Qiny, param);
          if isfinite(v_sg) && isfinite(v_crit) && v_sg < v_crit
              diagnostico = agregar_diag_glsim(diagnostico, sprintf('[AMARILLO] Turner GL: Vsg %.2f m/s menor que Vcrit %.2f m/s. Riesgo de carga liquida; no se fuerza produccion cero.', v_sg, v_crit));
          end
      catch
          diagnostico = agregar_diag_glsim(diagnostico, 'No se pudo calcular diagnostico Turner GL.');
      end
  end

  WC = getnum_gls(param, 'WC', 0.5);
  GLR = getnum_gls(param, 'GLR', 0);
  Qo = Ql * (1 - WC);
  Qgas_total = Qiny + Ql * GLR;
end

function [v_sg, v_crit] = turner_gl(Ql, Qiny, param)
  WC = getnum_gls(param, 'WC', 0.5);
  rho_o = getnum_gls(param, 'rho_o', 850);
  rho_w = getnum_gls(param, 'rho_w', 1000);
  rho_l = rho_o*(1-WC) + rho_w*WC;
  D_valv = aos_profundidad_inyeccion(param, getnum_gls(param, 'D_bomba', getnum_gls(param,'D_res',0)));
  diam = aos_id_at_md(param, D_valv, getnum_gls(param, 'diam_tbg', 0.062));
  A_tbg = pi*(diam/2)^2;
  GLR = getnum_gls(param, 'GLR', 0);
  Qg_std = Qiny + Ql*GLR;
  P_punto = max(getnum_gls(param, 'P_res', 100e5)*0.9, 1e5);
  T_punto = getnum_gls(param, 'T_fondo', 358.15); if T_punto < 150, T_punto = T_punto + 273.15; end
  Qg_real = Qg_std*(101325/P_punto)*(T_punto/288.15);
  v_sg = Qg_real/max(A_tbg,1e-12);
  sigma = 0.03;
  gamma_g = getnum_gls(param, 'gamma_g', 0.7);
  M_g = max(gamma_g * 0.028967, 0.002);
  Z = aos_vlp_z_factor(P_punto, T_punto, gamma_g, NaN);
  rho_g_punto = max(P_punto * M_g / (max(Z,0.2)*8.314462618*T_punto), 0.01);
  v_crit = 5.48*sqrt(max(sigma*(rho_l - rho_g_punto)/(rho_g_punto^2),0))*0.3048;
end

function out = agregar_diag_glsim(base, nuevo)
  if nargin < 1 || isempty(base)
      out = nuevo;
  elseif nargin < 2 || isempty(nuevo)
      out = base;
  else
      out = [base char(10) nuevo];
  end
end

function v = getnum_gls(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); return; end
  end
end

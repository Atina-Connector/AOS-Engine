function [Ql, Qo, potencia, diagnostico, detalle] = BM_core(param)
  % BM_core.m - Motor de Bombeo Mecanico AOS v15.
  % El desplazamiento de bomba se calcula desde la carrera efectiva de fondo
  % obtenida por el modulo Gibbs/onda, no solo desde la carrera superficial.

  detalle = struct();
  diagnostico = '';
  param = bm_defaults_param(param);

  WC = min(max(param.WC, 0), 1);
  rho_l = param.rho_o * (1 - WC) + param.rho_w * WC;
  g = 9.81;

  % IPR y limite por presion minima de intake.
  [Ql_max_ipr, P_wf_func] = ipr(param, param.modelo_IPR);
  Ql_max_ipr = max(Ql_max_ipr, 0);
  P_intake_min = leer_campo_num(param, 'P_intake_min', 1e5);
  Q_ipr_intake_min = bm_q_para_pwf(P_wf_func, Ql_max_ipr, P_intake_min);
  Q_ipr_intake_min = max(Q_ipr_intake_min, 0);

  % Sarta.
  if isfield(param, 'varillas') && isstruct(param.varillas)
      varillas = param.varillas;
  else
      varillas = diseno_varillas(param, min(Ql_max_ipr, max(Q_ipr_intake_min, 0)));
  end

  % Gibbs forward. Si falla, se usa fallback geometrico para no dejar al usuario sin corrida.
  usar_gibbs = leer_campo_num(param, 'usar_gibbs_BM', 1) > 0.5;
  gibbs_ok = false;
  gibbs_msg = '';
  gibbs = [];

  if usar_gibbs && exist('gibbs_bm_resolver', 'file')
      opciones = struct();
      opciones.modo = 'forward';
      opciones.n_t = leer_campo_num(param, 'gibbs_n_t', leer_campo_num(param, 'gibbs_n_puntos', 720));
      opciones.n_ciclos = leer_campo_num(param, 'gibbs_n_ciclos', 8);
      opciones.n_nodos_objetivo = leer_campo_num(param, 'gibbs_n_nodos', 31);
      opciones.amortiguamiento = leer_campo_num(param, 'gibbs_amortiguamiento', 0.055);
      opciones.metodo_forward = leer_campo_txt(param, 'gibbs_metodo_forward', 'estable');
      opciones.imprimir = false;
      opciones.graficar = false;

      % Primera pasada con llenado inicial.
      param_g = param;
      param_g.P_intake = P_intake_min;
      param_g.llenado_bomba = min(max(leer_campo_num(param, 'eta_vol', 0.85), 0.02), 1.2);
      try
          gibbs1 = gibbs_bm_resolver(param_g, varillas, opciones);
          Qcap = max(gibbs1.metricas.Q_teorico_fondo_m3s, 0);
          llenado_real = bm_llenado_desde_ipr(Qcap, Q_ipr_intake_min, param.eta_vol, leer_campo_num(param,'slip_bomba',0));
          % Segunda pasada con llenado coherente con IPR.
          param_g.llenado_bomba = llenado_real;
          gibbs = gibbs_bm_resolver(param_g, varillas, opciones);
          gibbs_ok = true;
      catch err
          gibbs_msg = err.message;
          gibbs_ok = false;
      end
  end

  Dp = max(param.D_bomba_mm, 1) / 1000;
  A_bomba = pi * (Dp/2)^2;
  spm_s = max(param.N_velocidad, 0) / 60;
  S_sup = max(param.S_carrera, 0);

  if gibbs_ok
      Q_teorico_superficie = gibbs.metricas.Q_teorico_superficie_m3s;
      Q_teorico_fondo = gibbs.metricas.Q_teorico_fondo_m3s;
      llenado_real = bm_llenado_desde_ipr(Q_teorico_fondo, Q_ipr_intake_min, param.eta_vol, leer_campo_num(param,'slip_bomba',0));
      Q_bomba = Q_teorico_fondo * llenado_real * (1 - min(max(leer_campo_num(param,'slip_bomba',0),0),0.95));
      Ql = min(max(Q_bomba, 0), Q_ipr_intake_min);
      Qo = Ql * (1 - WC);
      if isfield(gibbs, 'modelo')
          modelo = gibbs.modelo;
      else
          modelo = 'BM_Gibbs_estable_AOS_v11';
      end
  else
      Q_teorico_superficie = A_bomba * S_sup * spm_s;
      Q_teorico_fondo = Q_teorico_superficie;
      llenado_real = min(max(param.eta_vol, 0), 1.2);
      Q_bomba = Q_teorico_fondo * llenado_real;
      Ql = min(max(Q_bomba, 0), Q_ipr_intake_min);
      Qo = Ql * (1 - WC);
      modelo = 'BM_fallback_geometrico_AOS_v11';
  end

  P_wf = P_wf_func(Ql);
  if isempty(P_wf) || ~isfinite(P_wf), P_wf = P_intake_min; end

  H = max(param.D_bomba, 0) + max(param.P_wh, 0) / max(rho_l * g, 1);
  eta_mec = min(max(leer_campo_num(param, 'eta_mecanica_BM', 0.75), 0.05), 1.0);
  potencia = rho_l * g * H * Ql / max(eta_mec, 1e-3);

  if gibbs_ok
      if Q_teorico_fondo * param.eta_vol > Q_ipr_intake_min * 1.001
          diagnostico = sprintf('BM/Gibbs limitado por IPR o llenado. Llenado %.2f, carrera fondo %.3f m.', llenado_real, gibbs.metricas.stroke_fondo_m);
      else
          diagnostico = sprintf('BM/Gibbs gobernado por desplazamiento de fondo. Llenado %.2f, carrera fondo %.3f m.', llenado_real, gibbs.metricas.stroke_fondo_m);
      end
  else
      diagnostico = sprintf('BM en fallback geometrico. Gibbs no disponible o fallo: %s', gibbs_msg);
  end

  detalle.modelo = modelo;
  detalle.varillas = varillas;
  detalle.Q_teorico = Q_teorico_superficie;
  detalle.Q_teorico_fondo = Q_teorico_fondo;
  detalle.Q_bomba = Ql;
  detalle.llenado_bomba = llenado_real;
  detalle.Ql_max_ipr = Ql_max_ipr;
  detalle.Q_ipr_intake_min = Q_ipr_intake_min;
  detalle.P_wf = P_wf;
  detalle.P_intake = max(P_wf, 0);
  detalle.P_intake_min = P_intake_min;
  detalle.A_bomba = A_bomba;
  detalle.rho_l = rho_l;
  detalle.eta_vol = param.eta_vol;
  detalle.eta_mecanica = eta_mec;
  detalle.gibbs_ok = gibbs_ok;
  if gibbs_ok
      detalle.gibbs = gibbs;
      detalle.S_superficie_m = gibbs.metricas.stroke_superficie_m;
      detalle.S_fondo_m = gibbs.metricas.stroke_fondo_m;
      detalle.carga_sup_max_N = gibbs.metricas.carga_sup_max_N;
      detalle.carga_sup_min_N = gibbs.metricas.carga_sup_min_N;
      detalle.carga_fondo_max_N = gibbs.metricas.carga_fondo_max_N;
      detalle.carga_fondo_min_N = gibbs.metricas.carga_fondo_min_N;
      detalle.espaciamiento = gibbs.espaciamiento;
  else
      detalle.S_superficie_m = S_sup;
      detalle.S_fondo_m = S_sup;
  end
  detalle.audit = struct('IP_efectivo',param.IP,'P_wh_efectiva',param.P_wh, ...
      'D_bomba_efectiva',param.D_bomba,'D_bomba_mm_efectivo',param.D_bomba_mm, ...
      'S_carrera_efectiva',param.S_carrera,'N_velocidad_efectiva',param.N_velocidad, ...
      'eta_vol_efectiva',param.eta_vol,'modelo_IPR',param.modelo_IPR);
end

function llenado = bm_llenado_desde_ipr(Qcap, Qipr, eta_usuario, slip)
  if nargin < 4, slip = 0; end
  Qcap = max(Qcap, 0);
  Qipr = max(Qipr, 0);
  eta_usuario = min(max(eta_usuario, 0), 1.2);
  slip = min(max(slip, 0), 0.95);
  if Qcap <= 0
      llenado = 0;
  else
      llenado = min(eta_usuario, Qipr / max(Qcap * (1 - slip), 1e-12));
      llenado = min(max(llenado, 0), 1.2);
  end
end

function param = bm_defaults_param(param)
  if nargin < 1 || ~isstruct(param), param = struct(); end
  if ~isfield(param, 'P_res'), param.P_res = 200e5; end
  if ~isfield(param, 'IP'), param.IP = 1e-11; end
  if ~isfield(param, 'WC'), param.WC = 0.5; end
  if ~isfield(param, 'P_wh'), param.P_wh = 10e5; end
  if ~isfield(param, 'D_bomba'), param.D_bomba = 1500; end
  if ~isfield(param, 'D_res'), param.D_res = param.D_bomba; end
  if ~isfield(param, 'rho_o'), param.rho_o = 850; end
  if ~isfield(param, 'rho_w'), param.rho_w = 1000; end
  if ~isfield(param, 'GLR'), param.GLR = 0; end
  if ~isfield(param, 'D_bomba_mm'), param.D_bomba_mm = 32; end
  if ~isfield(param, 'S_carrera'), param.S_carrera = 1.5; end
  if ~isfield(param, 'N_velocidad'), param.N_velocidad = 6; end
  if ~isfield(param, 'eta_vol'), param.eta_vol = 0.85; end
  if ~isfield(param, 'eta_mecanica_BM'), param.eta_mecanica_BM = 0.75; end
  if ~isfield(param, 'modelo_IPR'), param.modelo_IPR = 'linear'; end
  if ~isfield(param, 'tipo_unidad'), param.tipo_unidad = 'Convencional'; end
  if ~isfield(param, 'material_varillas'), param.material_varillas = 'Acero Grado D'; end
  if ~isfield(param, 'usar_gibbs_BM'), param.usar_gibbs_BM = 1; end
  if ~isfield(param, 'P_intake_min'), param.P_intake_min = 1e5; end
  if ~isfield(param, 'gibbs_metodo_forward'), param.gibbs_metodo_forward = 'estable'; end
end

function q = bm_q_para_pwf(P_wf_func, qmax, p_obj)
  qmax = max(qmax, 0);
  if qmax <= 0
      q = 0;
      return;
  end
  p0 = P_wf_func(0);
  if p0 <= p_obj
      q = 0;
      return;
  end
  pmax = P_wf_func(qmax);
  if isempty(pmax) || ~isfinite(pmax), pmax = 0; end
  if pmax >= p_obj
      q = qmax;
      return;
  end
  qa = 0; qb = qmax;
  for it = 1:60
      qm = 0.5*(qa+qb);
      pm = P_wf_func(qm);
      if isempty(pm) || ~isfinite(pm), pm = -Inf; end
      if pm >= p_obj
          qa = qm;
      else
          qb = qm;
      end
  end
  q = qa;
end

function v = leer_campo_num(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end

function v = leer_campo_txt(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if ischar(tmp)
          v = tmp;
      end
  end
end

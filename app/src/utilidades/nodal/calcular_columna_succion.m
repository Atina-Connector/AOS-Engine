function [P_s, detalle] = calcular_columna_succion(Ql, param)
% calcular_columna_succion.m
% Presion de succion/intake en el punto de levantamiento.
%
% AOS 0.0.11f:
%   - hidrostática del tramo reservorio-inyección usa Delta TVD, no Delta MD.
%   - fracción de gas libre descuenta gas disuelto Rs en petróleo.
%   - densidad de gas de mezcla usa densidad local, no rho_g_std.
%   - D_iny_m/D_iny es la profundidad canónica GL/JGL; D_bomba queda solo
%     como alias histórico.

  if nargin < 1 || isempty(Ql), Ql = 0; end
  if nargin < 2 || ~isstruct(param), param = struct(); end
  Ql = max(Ql, 0);

  [P_res, IP, D_res, D_valv, WC, GLR, rho_o, rho_w, rho_g_std, T_fondo, modelo_IPR, API, gamma_g, diam_tbg] = extraer_parametros_cs(param);

  WC = max(0, min(1, WC));
  diam_tbg = max(diam_tbg, 1e-4);
  IP = max(IP, 1e-20);
  T_fondo = normalizar_T_K(T_fondo);

  param_ipr.P_res = P_res;
  param_ipr.IP = IP;
  if isfield(param, 'P_b') && ~isempty(param.P_b)
      param_ipr.P_b = aos_normalizar_presion_burbuja(param.P_b, 100);
  elseif isfield(param, 'P_b_bar') && ~isempty(param.P_b_bar)
      param_ipr.P_b = aos_normalizar_presion_burbuja(param.P_b_bar, 100);
  end
  [~, P_wf_func] = ipr(param_ipr, modelo_IPR);
  P_wf = P_wf_func(Ql);

  % Geometria: hidrostática por TVD, fricción aproximada por MD (por ahora
  % la fricción inferior queda diagnóstica; el modelo mantiene solo peso de
  % columna para no inventar un VLP inferior completo).
  if isfield(param, 'survey') && ~isempty(param.survey)
      TVD_res = aos_tvd_at_md(param.survey, D_res);
      TVD_valv = aos_tvd_at_md(param.survey, D_valv);
  else
      TVD_res = D_res;
      TVD_valv = D_valv;
  end
  delta_TVD = max(TVD_res - TVD_valv, 0);
  delta_MD = max(D_res - D_valv, 0);

  P_pvt = max(P_wf, 1e5);
  T_pvt_C = T_fondo - 273.15;
  pvt_succ = pvt_calcular(P_pvt, T_pvt_C, API, gamma_g);
  rho_o_succ = rho_o / max(pvt_succ.Bo, 1e-12);
  rho_l = rho_o_succ * (1 - WC) + rho_w * WC;

  % Gas libre de formación en el tramo debajo del punto de levantamiento:
  % no hay gas inyectado debajo de la válvula/eductor.
  pgas = param;
  pgas.WC = WC; pgas.API = API; pgas.gamma_g = gamma_g; pgas.Q_iny = 0;
  Qg_total_form = Ql * GLR;
  [Qg_free_std, det_gas] = aos_gas_libre_std(Ql, Qg_total_form, pgas, P_pvt, T_fondo);

  Z = aos_vlp_z_factor(P_pvt, T_fondo, gamma_g, NaN);
  M_air = 0.028967;
  M_g = max(gamma_g * M_air, 0.002);
  R = 8.314462618;
  rho_g_local = max((P_pvt * M_g) / (max(Z,0.2) * R * max(T_fondo,250)), 0.01);
  Qg_fondo = Qg_free_std * (101325 / P_pvt) * (T_fondo / 288.15) * max(Z,0.2);

  A_tbg = pi * (diam_tbg/2)^2;
  v_sl = Ql / max(A_tbg, 1e-12);
  v_sg = Qg_fondo / max(A_tbg, 1e-12);
  C0 = 1.2; v_inf = 0.25;
  v_m = v_sl + v_sg;
  H_l = 1 - v_sg / (C0 * max(v_m, 1e-6) + v_inf);
  H_l = min(max(H_l, 0.01), 1);
  rho_mezcla = rho_l * H_l + rho_g_local * (1 - H_l);

  delta_P = rho_mezcla * 9.81 * delta_TVD;
  P_s_raw = P_wf - delta_P;

  detalle = struct();
  detalle.P_s_raw = P_s_raw;
  detalle.P_wf = P_wf;
  detalle.delta_P_succion = delta_P;
  detalle.H_l = H_l;
  detalle.rho_mezcla = rho_mezcla;
  detalle.rho_l = rho_l;
  detalle.rho_g_local = rho_g_local;
  detalle.v_sl = v_sl;
  detalle.v_sg = v_sg;
  detalle.D_res = D_res;
  detalle.D_intake = D_valv;
  detalle.TVD_res = TVD_res;
  detalle.TVD_intake = TVD_valv;
  detalle.delta_TVD = delta_TVD;
  detalle.delta_MD = delta_MD;
  detalle.gas = det_gas;
  detalle.modelo_tramo_inferior = 'Intake AOS: IPR + columna inferior simplificada con TVD y gas libre Rs';

  if ~isfinite(P_s_raw)
      P_s = 1e5;
      detalle.estado = 'NO_FISICO';
      detalle.mensaje = 'P_s_raw no finita; se usa minimo numerico 1 bar.';
  elseif P_s_raw < 1e5
      P_s = 1e5;
      detalle.estado = 'LIMITADO_POR_RESERVORIO';
      detalle.mensaje = 'El reservorio no puede sostener ese nivel de intake; se usa minimo numerico 1 bar.';
  else
      P_s = P_s_raw;
      detalle.estado = 'OK';
      detalle.mensaje = 'Intake dentro de rango fisico.';
  end
  detalle.P_s_usada = P_s;
end

function [P_res, IP, D_res, D_valv, WC, GLR, rho_o, rho_w, rho_g_std, T_fondo, modelo_IPR, API, gamma_g, diam_tbg] = extraer_parametros_cs(param)
  if isfield(param, 'int1') && isstruct(param.int1) && isfield(param.int1, 'P_res')
      P_res = leer_num_cs(param.int1, 'P_res', leer_num_cs(param, 'P_res', 200e5));
      IP = leer_num_cs(param.int1, 'IP', leer_num_cs(param, 'IP', 1.1574e-10));
      D_res = leer_num_cs(param.pozo, 'D_res', leer_num_cs(param, 'D_res', 3000));
      D_valv = aos_profundidad_inyeccion(param, leer_num_cs(param.gl, 'D_valvula', leer_num_cs(param, 'D_bomba', D_res)));
      WC = leer_num_cs(param.fluidos, 'WC', leer_num_cs(param, 'WC', 0.5));
      GLR = leer_num_cs(param.fluidos, 'GLR', leer_num_cs(param, 'GLR', 0));
      rho_o = leer_num_cs(param.fluidos, 'rho_o', leer_num_cs(param, 'rho_o', 850));
      rho_w = leer_num_cs(param.fluidos, 'rho_w', leer_num_cs(param, 'rho_w', 1000));
      rho_g_std = leer_num_cs(param.fluidos, 'rho_g_std', leer_num_cs(param, 'rho_g_std', 0.8));
      T_fondo = leer_num_cs(param, 'T_fondo', 358.15);
      modelo_IPR = leer_str_cs(param, 'modelo_IPR', 'linear');
      API = leer_num_cs(param, 'API', leer_num_cs(param.fluidos, 'API', 35));
      gamma_g = leer_num_cs(param, 'gamma_g', leer_num_cs(param.fluidos, 'gamma_g', 0.7));
      diam_tbg = aos_id_at_md(param, D_valv, leer_num_cs(param.tubing, 'ID', leer_num_cs(param, 'diam_tbg', 0.062)));
  else
      P_res = leer_num_cs(param, 'P_res', 200e5);
      IP = leer_num_cs(param, 'IP', 1.1574e-10);
      D_res = leer_num_cs(param, 'D_res', leer_num_cs(param, 'D_bomba', 3000));
      D_valv = aos_profundidad_inyeccion(param, leer_num_cs(param, 'D_bomba', D_res));
      WC = leer_num_cs(param, 'WC', 0.5);
      GLR = leer_num_cs(param, 'GLR', 0);
      rho_o = leer_num_cs(param, 'rho_o', 850);
      rho_w = leer_num_cs(param, 'rho_w', 1000);
      rho_g_std = leer_num_cs(param, 'rho_g_std', 0.8);
      T_fondo = leer_num_cs(param, 'T_fondo', 358.15);
      modelo_IPR = leer_str_cs(param, 'modelo_IPR', 'linear');
      API = leer_num_cs(param, 'API', 35);
      gamma_g = leer_num_cs(param, 'gamma_g', 0.7);
      diam_tbg = aos_id_at_md(param, D_valv, leer_num_cs(param, 'diam_tbg', 0.062));
  end
end

function T = normalizar_T_K(T)
  if ~isfinite(T) || T <= 0, T = 358.15; end
  if T < 150, T = T + 273.15; end
end

function v = leer_num_cs(s, campo, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  if isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
          v = x(1); return;
      elseif ischar(x)
          y = str2double(x);
          if isfinite(y), v = y; return; end
      end
  end
end

function v = leer_str_cs(s, campo, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  if isfield(s, campo) && ischar(s.(campo))
      v = s.(campo);
  end
end

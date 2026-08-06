function [Ql, Qo, Qg_total, P_intake, T_motor, Q_recirc, ...
          corriente, IR_actual, IR_estado, run_life, diagnostico_sla] = BES_sim(param)
  % Simulador de Bombeo Electrosumergible (BES) con diagnóstico completo.
  % Utiliza curva de bomba (Q, head, potencia) escalada por frecuencia,
  % número de etapas y corrección por viscosidad (ANSI/HI 9.6.7).
  % Calcula temperatura del motor, refrigeración, corriente, aislación y run life.
  % AOS 0.0.11: intake minimo se informa como diagnostico SLA; no recalcula caudal.
  %
  % Entradas (estructura param):
  %   Campos obligatorios: P_res, IP, D_bomba, P_wh, diam_tbg, WC, GLR,
  %                        rho_o, rho_w, rho_g_std, T_sup, T_fondo, survey
  %   Campos opcionales para BES: curva_bomba_file, frecuencia, frecuencia_base,
  %                               num_etapas, T_max_motor, eficiencia_motor,
  %                               cp_fluido, velocidad_min_refrig, voltaje_motor,
  %                               IR_base, factor_envejecimiento, mu_o
  %
  % Salidas adicionales:
  %   T_motor     : temperatura del motor (°C)
  %   Q_recirc    : caudal de recirculación recomendado (m³/s)
  %   corriente   : corriente estimada del motor (A)
  %   IR_actual   : resistencia de aislación a temperatura de operación (MΩ)
  %   IR_estado   : cadena 'BUENO', 'REGULAR' o 'MALO'
  %   run_life    : estimación de vida remanente (días)

  diagnostico_sla = '';

  % --- Cargar curva de bomba ---
  if isfield(param, 'curva_bomba_file')
      curva_file = param.curva_bomba_file;
  else
      curva_file = 'config/BES/curva_bomba.txt';
  end
  if ~exist(curva_file, 'file')
      error('No se encontró el archivo de curva de bomba: %s', curva_file);
  end
  curva = load_config(curva_file);
  Q_curva = curva.Q_bomba(:) / 86400;      % m³/d -> m³/s
  head_curva = curva.head_bomba(:);         % metros (por etapa)
  pot_curva = curva.potencia_bomba(:);      % kW (por etapa)

  % --- Escalar por número de etapas ---
  if isfield(param, 'num_etapas')
      num_etapas = param.num_etapas;
  elseif isfield(curva, 'num_etapas')
      num_etapas = curva.num_etapas;
  else
      num_etapas = 1;
  end
  head_curva = head_curva * num_etapas;
  pot_curva = pot_curva * num_etapas;

  % --- Escalar por frecuencia (leyes de afinidad) ---
  if isfield(param, 'frecuencia') && isfield(param, 'frecuencia_base')
      f_ratio = param.frecuencia / param.frecuencia_base;
      Q_curva = Q_curva * f_ratio;
      head_curva = head_curva * f_ratio^2;
      pot_curva = pot_curva * f_ratio^3;
  end

  % --- Corrección por viscosidad (ANSI/HI 9.6.7) ---
  nu_cSt = calcular_viscosidad_cinematica(param);
  [~, idx_bep] = max(pot_curva);
  if ~isempty(idx_bep) && idx_bep > 0
      Q_bep = Q_curva(idx_bep);
      H_bep = head_curva(idx_bep);
      [C_Q, C_H, C_eta] = corregir_curva_viscosidad(Q_bep, H_bep, nu_cSt);
      Q_curva    = Q_curva * C_Q;
      head_curva = head_curva * C_H;
      pot_curva  = pot_curva * (C_Q * C_H / C_eta);
  end

  % --- Parámetros básicos ---
  D_bomba = param.D_bomba;
  P_wh = param.P_wh;
  IP = param.IP;
  P_res = param.P_res;
  WC = param.WC;
  GLR_form = param.GLR;
  rho_o = param.rho_o;
  rho_w = param.rho_w;
  rho_l = rho_o * (1 - WC) + rho_w * WC;
  rho_g_std = param.rho_g_std;
  g = 9.81;

  % Modelo IPR seleccionado por el usuario (.aosdat/menu).
  if ~isfield(param, 'modelo_IPR'), param.modelo_IPR = 'linear'; end
  if isfield(param, 'P_b'), param.P_b = aos_normalizar_presion_burbuja(param.P_b, 100); else param.P_b = 100e5; end
  [Ql_max, P_wf_func] = ipr(param, param.modelo_IPR);

  % --- Función de error para fzero ---
  f = @(Ql) error_presion_BES(Ql, param, Q_curva, head_curva);

  % --- Buscar cambio de signo ---
  Ql_upper = Ql_max * 0.99;
  if Ql_upper <= 1e-6
      Ql_upper = Ql_max;
  end
  f_min = f(1e-6);
  f_max = f(Ql_upper);

  if f_min * f_max < 0
      [Ql, ~, info] = fzero(f, [1e-6, Ql_upper]);
      if info ~= 1
          Ql = 0; Qo = 0; Qg_total = 0; P_intake = NaN;
          T_motor = NaN; Q_recirc = 0; corriente = NaN; IR_actual = NaN;
          IR_estado = 'N/A'; run_life = NaN;
          diagnostico_sla = 'BES: fzero no convergio en el cruce de presion.';
          return;
      end
  else
      if f_min > 0
          % La bomba entrega más presión de la necesaria -> el yacimiento limita
          Ql = Ql_max;
      else
          Ql = 0; Qo = 0; Qg_total = 0; P_intake = NaN;
          T_motor = NaN; Q_recirc = 0; corriente = NaN; IR_actual = NaN;
          IR_estado = 'N/A'; run_life = NaN;
          diagnostico_sla = 'BES: no se encontro cruce de presion ni limite por yacimiento util.';
          return;
      end
  end

  % Calcular la presión de intake disponible para el caudal actual
  P_int_disp_actual = P_intake_disponible(Ql, param);

  % AOS 0.0.11: no recalcular ni limitar caudal por intake. Se informa
  % el estado del reservorio/SLA y se conserva el resultado hidraulico.
  P_intake = P_int_disp_actual;
  Qo = Ql * (1 - param.WC);
  Qg_total = Ql * param.GLR;
  try
      guard = aos_sla_intake_guard('BES', Ql, P_int_disp_actual, param);
      if isfield(guard, 'estado') && ~strcmp(guard.estado, 'OK')
          diagnostico_sla = guard.mensaje;
      end
      global AOS_ULTIMO_DIAGNOSTICO_BES;
      AOS_ULTIMO_DIAGNOSTICO_BES = guard.mensaje;
  catch err_guard
      diagnostico_sla = ['No se pudo evaluar intake guard BES: ', err_guard.message];
  end

  % --- Resultados hidráulicos ---
  % (Qo, Qg_total ya calculados arriba)

  % --- Potencia en el eje y corriente ---
  potencia_hidraulica = Ql * delta_P_bomba(Ql, param, Q_curva, head_curva);
  if isfield(param, 'eficiencia_motor')
      eta_m = param.eficiencia_motor;
  else
      eta_m = 0.85;
  end
  potencia_electrica = potencia_hidraulica / eta_m;
  if isfield(param, 'voltaje_motor')
      V = param.voltaje_motor;
  else
      V = 4000;
  end
  corriente = potencia_electrica / (V * sqrt(3));

  % --- Temperatura del motor ---
  T_fondo = param.T_fondo - 273.15;
  T_sup = param.T_sup - 273.15;
  if isfield(param, 'survey') && ~isempty(param.survey)
      TVD_bomba = param.survey.get_TVD(D_bomba);
  else
      TVD_bomba = D_bomba;
  end
  grad_T = (T_fondo - T_sup) / max(1, param.D_res);
  T_intake = T_sup + grad_T * TVD_bomba;

  if isfield(param, 'cp_fluido')
      cp = param.cp_fluido;
  else
      cp = 3500;
  end

  if Ql > 1e-6
      delta_T = (potencia_electrica * (1 - eta_m)) / (Ql * rho_l * cp);
      T_motor = T_intake + delta_T;
  else
      T_motor = T_intake;
  end

  % --- Refrigeración y recirculación ---
  if isfield(param, 'OD_motor')
      OD_motor = param.OD_motor;
  else
      OD_motor = 0.15;
  end
  if isfield(param, 'ID_casing')
      ID_casing = param.ID_casing;
  else
      ID_casing = 0.157;
  end
  A_anular = pi/4 * (ID_casing^2 - OD_motor^2);
  if isfield(param, 'velocidad_min_refrig')
      v_min = param.velocidad_min_refrig;
  else
      v_min = 0.3;
  end
  Q_min_refrig = A_anular * v_min;
  if Ql < Q_min_refrig
      Q_recirc = Q_min_refrig - Ql;
  else
      Q_recirc = 0;
  end

  % --- Resistencia de aislación y run life ---
  if isfield(param, 'IR_base')
      IR_base = param.IR_base;
  else
      IR_base = 1000;
  end
  IR_actual = IR_base * 2^((20 - T_motor) / 10);
  if IR_actual < 1
      IR_estado = 'MALO';
  elseif IR_actual < 10
      IR_estado = 'REGULAR';
  else
      IR_estado = 'BUENO';
  end

  if isfield(param, 'factor_envejecimiento')
      f_enve = param.factor_envejecimiento;
  else
      f_enve = 1.0;
  end
  IR_min = 0.5;
  if IR_actual > IR_min
      run_life = (IR_actual / IR_min) * 365 * f_enve;
  else
      run_life = 0;
  end
end

% ================================================================
% Subfunciones
% ================================================================
function err = error_presion_BES(Ql, param, Q_curva, head_curva)
  P_int_disp = P_intake_disponible(Ql, param);
  P_int_req  = P_intake_requerida(Ql, param, Q_curva, head_curva);
  err = P_int_disp - P_int_req;
end

function P_int = P_intake_disponible(Ql, param)
  if ~isfield(param, 'modelo_IPR'), param.modelo_IPR = 'linear'; end
  if isfield(param, 'P_b'), param.P_b = aos_normalizar_presion_burbuja(param.P_b, 100); else param.P_b = 100e5; end
  [~, P_wf_func] = ipr(param, param.modelo_IPR);
  P_wf = P_wf_func(Ql);
  rho_l = param.rho_o * (1-param.WC) + param.rho_w * param.WC;
  Qo = Ql * (1-param.WC);
  Qg_form = Ql * param.GLR;
  P_prom = max((P_wf + 0.8*P_wf)/2, 1e5);
  T_prom = max(param.T_fondo - 5, 250);
  Qg_fondo = Qg_form * (101325 / P_prom) * (T_prom / 288.15);
  A_tbg = max(pi * (param.diam_tbg/2)^2, 1e-12);
  v_sl = Ql / A_tbg;
  v_sg = Qg_fondo / A_tbg;
  C0 = 1.2; v_inf = 0.25;
  v_m = v_sl + v_sg;
  H_l = 1 - v_sg / (C0 * max(v_m,1e-6) + v_inf);
  H_l = min(max(H_l, 0.01), 1);
  rho_mezcla_succ = rho_l * H_l + param.rho_g_std * (1-H_l);
  delta_P_succ = rho_mezcla_succ * 9.81 * (param.D_res - param.D_bomba);
  P_int = P_wf - delta_P_succ;
end

function P_int = P_intake_requerida(Ql, param, Q_curva, head_curva)
  if Ql > max(Q_curva)
      head = min(head_curva);
  elseif Ql < min(Q_curva)
      head = max(head_curva);
  else
      head = interp1(Q_curva, head_curva, Ql, 'pchip');
  end
  rho_l = param.rho_o * (1-param.WC) + param.rho_w * param.WC;
  delta_P_bomba = rho_l * 9.81 * head;
  Qg_total = Ql * param.GLR;
  P_descarga_req = compute_P_req(param, Ql, Qg_total, param.D_bomba);
  P_int = P_descarga_req - delta_P_bomba;
end

function dP = delta_P_bomba(Ql, param, Q_curva, head_curva)
  if Ql > max(Q_curva)
      head = min(head_curva);
  elseif Ql < min(Q_curva)
      head = max(head_curva);
  else
      head = interp1(Q_curva, head_curva, Ql, 'pchip');
  end
  rho_l = param.rho_o * (1-param.WC) + param.rho_w * param.WC;
  dP = rho_l * 9.81 * head;
end

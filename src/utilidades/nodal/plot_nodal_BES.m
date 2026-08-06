function plot_nodal_BES(param, Ql_sol)
  % Grafica el análisis nodal para BES:
  %   P_intake_disponible (IPR - succión) vs P_intake_requerida (VLP descarga - ΔP_bomba)
  % Utiliza la función unificada calcular_columna_succion para la presión de intake disponible.

  % --- Extraer parámetros ---
  P_res = param.P_res;
  IP = param.IP;
  P_wh = param.P_wh;
  diam_tbg = param.diam_tbg;
  rho_o = param.rho_o;
  rho_w = param.rho_w;
  rho_g_std = param.rho_g_std;
  WC = param.WC;
  GLR = param.GLR;
  D_bomba = param.D_bomba;
  D_res = param.D_res;

  % --- Rango de caudales (hasta Qmax del IPR) ---
  [Ql_max, ~] = ipr(param, 'linear');
  Ql_vals = linspace(1e-6, Ql_max * 1.05, 100);  % en m³/s

  % --- Calcular P_intake_disponible (usando función unificada) ---
  P_int_disp_vals = zeros(size(Ql_vals));
  for i = 1:length(Ql_vals)
      P_int_disp_vals(i) = calcular_columna_succion(Ql_vals(i), param);
  end

  % --- Cargar curva de bomba y escalar ---
  curva_file = param.curva_bomba_file;
  if ~exist(curva_file, 'file')
      curva_file = 'config/BES/curva_bomba.txt';
  end
  curva = load_config(curva_file);
  Q_curva = curva.Q_bomba(:) / 86400;
  head_curva = curva.head_bomba(:);
  pot_curva = curva.potencia_bomba(:);
  if isfield(curva, 'num_etapas')
      num_etapas = curva.num_etapas;
  else
      num_etapas = 1;
  end
  if isfield(param, 'num_etapas')
      num_etapas = param.num_etapas;
  end
  head_curva = head_curva * num_etapas;
  pot_curva = pot_curva * num_etapas;
  if isfield(param, 'frecuencia') && isfield(param, 'frecuencia_base')
      f_ratio = param.frecuencia / param.frecuencia_base;
      Q_curva = Q_curva * f_ratio;
      head_curva = head_curva * f_ratio^2;
      pot_curva = pot_curva * f_ratio^3;
  end

  % --- Calcular P_intake_requerida (lógica específica de la bomba) ---
  P_int_req_vals = zeros(size(Ql_vals));
  for i = 1:length(Ql_vals)
      P_int_req_vals(i) = P_intake_requerida_local(Ql_vals(i), param, Q_curva, head_curva);
  end

  % --- Graficar ---
  figure;
  plot(Ql_vals * 86400, P_int_disp_vals / 1e5, 'b-', 'LineWidth', 2);
  hold on;
  plot(Ql_vals * 86400, P_int_req_vals / 1e5, 'r-', 'LineWidth', 2);

  % --- Punto de operación ---
  if ~isempty(Ql_sol) && Ql_sol > 1e-6
      P_int_sol = calcular_columna_succion(Ql_sol, param);
      P_req_sol = P_intake_requerida_local(Ql_sol, param, Q_curva, head_curva);
      tol = 0.01 * max(abs(P_int_sol), 1e5);

      if abs(P_int_sol - P_req_sol) < tol || Ql_sol < 0.99 * Ql_max
          % Cruce exacto
          plot(Ql_sol * 86400, P_int_sol / 1e5, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
          legend({'P_{intake} disponible', 'P_{intake} requerida', 'Punto de operación'}, 'Location', 'best');
          title(sprintf('Análisis Nodal BES – Ql = %.1f m³/d, P_intake = %.1f bar', Ql_sol*86400, P_int_sol/1e5));
      else
          % Limitado por yacimiento (bomba sobredimensionada)
          plot(Ql_sol * 86400, P_req_sol / 1e5, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
          legend({'P_{intake} disponible', 'P_{intake} requerida', 'Operación (Qmax yac.)'}, 'Location', 'best');
          title(sprintf('Análisis Nodal BES – Ql = %.1f m³/d (limitado por yacimiento)', Ql_sol*86400));
      end
  else
      legend({'P_{intake} disponible', 'P_{intake} requerida'}, 'Location', 'best');
      title('Análisis Nodal BES – Sin producción');
  end

  xlabel('Caudal de líquido (m³/d)');
  ylabel('Presión de intake (bar)');
  grid on;
end

% ================================================================
% Subfunción local: cálculo de P_intake_requerida (específico de la bomba)
% ================================================================
function P_int = P_intake_requerida_local(Ql, param, Q_curva, head_curva)
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
  % Límite físico: 1 bar absoluto
  if P_int < 1e5
      P_int = 1e5;
  end
end

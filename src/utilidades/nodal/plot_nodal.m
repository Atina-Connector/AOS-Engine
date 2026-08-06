function plot_nodal(param, Ql_sol, tipo, sol_jgl)
% PLOT_NODAL Grafico nodal comun y auditable para GNU Octave.
% Usa exclusivamente los campos canonicos activos y el resultado entregado
% por el solver. No recalcula JGL con un motor heredado ni usa defaults de
% gas ocultos.

  if nargin < 3 || isempty(tipo), tipo = 'AOS'; end
  if nargin < 4, sol_jgl = []; end
  es_jgl = strcmpi(tipo, 'JGL');

  modulo = 'GL';
  if es_jgl, modulo = 'JGL'; end
  try
    param = aos_sincronizar_config(param, modulo);
  catch
    try, param = aos_normalizar_config(param, modulo); catch, end
  end

  P_res = leer_num_plot(param, {'P_res'}, 0);
  IP = leer_num_plot(param, {'IP'}, 0);
  P_wh = leer_num_plot(param, {'P_wh'}, 0); %#ok<NASGU>
  GLR = leer_num_plot(param, {'GLR'}, 0);
  D_valv = aos_profundidad_inyeccion(param, ...
             leer_num_plot(param, {'D_iny','D_valvula','D_levantamiento'}, ...
               leer_num_plot(param, {'D_res'}, 0)));
  Q_iny = leer_num_plot(param, {'Q_iny','Qiny_plot','Qiny'}, 0);

  if es_jgl && isstruct(sol_jgl) && isfield(sol_jgl, 'Qiny') && ...
     isnumeric(sol_jgl.Qiny) && isscalar(sol_jgl.Qiny) && isfinite(sol_jgl.Qiny)
    Q_iny = max(sol_jgl.Qiny, 0);
  end

  param_ipr = struct('P_res', P_res, 'IP', IP);
  if isfield(param, 'P_b'), param_ipr.P_b = param.P_b; end
  modelo_ipr = 'linear';
  if isfield(param, 'modelo_IPR') && ischar(param.modelo_IPR)
    modelo_ipr = param.modelo_IPR;
  end
  [Ql_max_modelo, ~] = ipr(param_ipr, modelo_ipr);
  if ~isfinite(Ql_max_modelo) || Ql_max_modelo <= 0
    Ql_max_modelo = max(Ql_sol * 1.2, 1e-6);
  end
  Ql_vals = linspace(0, Ql_max_modelo * 1.2, 120);

  info_vlp = aos_vlp_info(param, D_valv);
  modelo_sel = 'simplified';
  if isfield(param, 'modelo_VLP') && ischar(param.modelo_VLP)
    modelo_sel = param.modelo_VLP;
  end
  fprintf('Modelo VLP seleccionado : %s\n', modelo_sel);
  fprintf('Modelo VLP efectivo     : %s\n', info_vlp.efectivo);
  fprintf('Qiny efectivo grafico   : %.0f Sm3/d\n', Q_iny * 86400);

  P_entrega_vals = NaN(size(Ql_vals));
  P_req_vals = NaN(size(Ql_vals));
  for i = 1:length(Ql_vals)
    ql = Ql_vals(i);
    qg_total = Q_iny + ql * GLR;
    try
      if es_jgl
        [ps_tmp, ~] = calcular_columna_succion(max(ql, 1e-12), param);
        e_tmp = jgl_eductor_comun(param, max(ql, 0), Q_iny, ps_tmp);
        P_entrega_vals(i) = e_tmp.Pd;
        [P_req_vals(i), ~] = compute_P_req(param, ql, qg_total, D_valv);
      else
        [~, detbal] = aos_nodal_balance_gl(ql, param, Q_iny, D_valv);
        P_entrega_vals(i) = detbal.P_s;
        P_req_vals(i) = detbal.P_req;
      end
    catch
      P_entrega_vals(i) = NaN;
      P_req_vals(i) = NaN;
    end
  end

  figure;
  plot(Ql_vals * 86400, P_entrega_vals / 1e5, 'b-', 'LineWidth', 2);
  hold on;
  plot(Ql_vals * 86400, P_req_vals / 1e5, 'r-', 'LineWidth', 2);

  if es_jgl
    leg1 = 'P_s + DeltaP eductor';
    ylabel('Presion de descarga del eductor / VLP (bar)');
  else
    leg1 = 'P_s disponible';
    ylabel('Presion disponible / VLP (bar)');
  end

  if ~isempty(Ql_sol) && isfinite(Ql_sol) && Ql_sol > 1e-9
    qg_total_sol = Q_iny + Ql_sol * GLR;
    [P_req_sol, ~] = compute_P_req(param, Ql_sol, qg_total_sol, D_valv);

    if es_jgl
      [P_s_sol, ~] = calcular_columna_succion(Ql_sol, param);
      deltaP_sol = 0;
      if isstruct(sol_jgl)
        if isfield(sol_jgl, 'eductor') && isstruct(sol_jgl.eductor)
          if isfield(sol_jgl.eductor, 'Ps') && isfinite(sol_jgl.eductor.Ps)
            P_s_sol = sol_jgl.eductor.Ps;
          end
          if isfield(sol_jgl.eductor, 'Pd') && isfinite(sol_jgl.eductor.Pd)
            P_entrega_sol = sol_jgl.eductor.Pd;
          else
            P_entrega_sol = P_s_sol;
          end
        else
          P_entrega_sol = P_s_sol;
        end
        if isfield(sol_jgl, 'deltaP') && isfinite(sol_jgl.deltaP)
          deltaP_sol = max(sol_jgl.deltaP, 0);
          P_entrega_sol = P_s_sol + deltaP_sol;
        end
      else
        e_sol = jgl_eductor_comun(param, Ql_sol, Q_iny, P_s_sol);
        deltaP_sol = e_sol.deltaP;
        P_entrega_sol = e_sol.Pd;
      end
    else
      [~, detbal_sol] = aos_nodal_balance_gl(Ql_sol, param, Q_iny, D_valv);
      P_s_sol = detbal_sol.P_s; %#ok<NASGU>
      P_entrega_sol = detbal_sol.P_s;
      P_req_sol = detbal_sol.P_req;
      deltaP_sol = 0; %#ok<NASGU>
    end

    residuo_sol = P_entrega_sol - P_req_sol;
    tol = max(1e5, 0.01 * max(abs(P_req_sol), 1e5));

    fprintf('\n--- Diagnostico de cruce ---\n');
    fprintf('Ql_sol        = %.4f m3/s (%.2f m3/d)\n', Ql_sol, Ql_sol * 86400);
    fprintf('Qiny_sol      = %.0f Sm3/d\n', Q_iny * 86400);
    if es_jgl, fprintf('P_succion_sol = %.2f bar\n', P_s_sol / 1e5); end
    fprintf('P_entrega_sol = %.2f bar\n', P_entrega_sol / 1e5);
    fprintf('P_req_sol     = %.2f bar\n', P_req_sol / 1e5);
    fprintf('Margen        = %.2f bar (P_entrega - P_req)\n', residuo_sol / 1e5);
    fprintf('Tolerancia    = %.2f bar\n', tol / 1e5);
    try
      info_modelo = aos_vlp_model_info(param, D_valv);
      fprintf('VLP seleccionado = %s | efectivo = %s | funcion = %s | fallback = %s\n', ...
        info_modelo.seleccionado, info_modelo.efectivo, info_modelo.funcion, ...
        texto_sn(info_modelo.fallback));
    catch
    end
    if es_jgl
      fprintf('Trabajo eductor = DeltaP %.3f bar [mismo resultado del solver]\n', deltaP_sol / 1e5);
    end

    if abs(residuo_sol) <= tol
      plot(Ql_sol * 86400, P_req_sol / 1e5, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
      legend({leg1, 'VLP', 'Punto de operacion'}, 'Location', 'best');
      title(sprintf('Analisis Nodal - %s (Ql = %.1f m3/d)', tipo, Ql_sol * 86400));
    elseif residuo_sol > tol
      plot(Ql_sol * 86400, P_req_sol / 1e5, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
      plot(Ql_sol * 86400, P_entrega_sol / 1e5, 'k^', 'MarkerSize', 8, 'LineWidth', 1.5);
      legend({leg1, 'VLP', 'Punto requerido', 'Capacidad disponible'}, 'Location', 'best');
      title(sprintf('Analisis Nodal - %s (Ql = %.1f m3/d, limitado)', tipo, Ql_sol * 86400));
      fprintf('Nota: existe margen positivo; revisar si el caudal esta limitado por IPR o por otro componente.\n');
    else
      plot(Ql_sol * 86400, P_entrega_sol / 1e5, 'ks', 'MarkerSize', 10, 'LineWidth', 2);
      legend({leg1, 'VLP', 'Punto solver (margen negativo)'}, 'Location', 'best');
      title(sprintf('Analisis Nodal - %s (Ql = %.1f m3/d, revisar)', tipo, Ql_sol * 86400));
      fprintf('ADVERTENCIA: margen negativo. El sistema no alcanza la VLP en ese caudal.\n');
    end
  else
    legend({leg1, 'VLP'}, 'Location', 'best');
    title(sprintf('Analisis Nodal - %s (sin produccion)', tipo));
  end

  xlabel('Caudal de liquido (m3/d)');
  grid on;
end

function v = leer_num_plot(s, nombres, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  for k = 1:length(nombres)
    nombre = nombres{k};
    if isfield(s, nombre)
      tmp = s.(nombre);
      if isnumeric(tmp) && isscalar(tmp) && isfinite(tmp)
        v = tmp;
        return;
      end
    end
  end
end

function txt = texto_sn(tf)
  if tf, txt = 'si'; else, txt = 'no'; end
end

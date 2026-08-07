function [modelo, resultados] = aos_cad_hidraulica_resolver_lazos(modelo, cfg, silencioso)
% AOS_CAD_HIDRAULICA_RESOLVER_LAZOS Entrypoint HYD_LOOP (Newton Kirchhoff).
% Solo MONOFASICO_DARCY. Continuidad exacta por circulaciones.
  if nargin < 3, silencioso = false; endif
  if nargin < 2 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(modelo); endif

  red = aos_cad_hidraulica_preparar(modelo, cfg);
  nN = numel(red.nodos); nE = numel(red.tramos);
  warnings = {};
  items_extra = {};
  estado_global = 'EJECUTADA';
  historial_residual = [];
  convergio = false;
  iteraciones = 0;
  residual_lazo_max = Inf;
  residual_fuente_max = 0;
  metodo = 'NEWTON';
  if isfield(cfg, 'metodo_lazo') && ~isempty(cfg.metodo_lazo)
    metodo = upper(char(cfg.metodo_lazo));
  endif

  % Validacion monofasica por tramo activo
  for e = 1:nE
    if ~red.active_edge(e), continue; endif
    mid = modelo_tramo_local(red.tramos{e}, cfg, red.qg_edge_std_m3s(e));
    if ~strcmp(mid, 'MONOFASICO_DARCY')
      items_extra{end+1} = item_local('HID_LAZO_MULTIFASICO_NO_SOPORTADO_DEV1', ...
        sprintf(['Tramo %s resuelve a %s; lazos DEV1 solo admiten MONOFASICO_DARCY ' ...
                 '(DeltaP depende de P_in en multifasico).'], ...
                id_local(red.tramos{e}, e), mid), 'ERROR'); %#ok<AGROW>
    endif
  endfor
  if ~isempty(items_extra)
    [modelo, resultados] = resultado_rechazo_local(modelo, red, cfg, items_extra, silencioso);
    return;
  endif

  [base, items_base] = aos_cad_hidraulica_lazos_base(red, cfg);
  for i = 1:numel(items_base)
    items_extra{end+1} = items_base{i}; %#ok<AGROW>
    if strcmpi(items_base{i}.severidad, 'ERROR')
      estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
    endif
  endfor
  if ~base.conectado
    [modelo, resultados] = resultado_rechazo_local(modelo, red, cfg, items_extra, silencioso);
    return;
  endif

  active = base.active_edge_efectivo;
  q = red.ql_edge_m3s;
  qg = red.qg_edge_std_m3s;
  % Forzar caudal cero en aristas excluidas (valvula cerrada)
  for i = 1:numel(base.aristas_excluidas)
    q(base.aristas_excluidas(i)) = 0;
    qg(base.aristas_excluidas(i)) = 0;
  endfor

  % Inicializacion: circulacion q_init sobre cada lazo fundamental
  q_init = 1e-4;
  if isfield(cfg, 'q_init_lazo_m3s') && isfinite(cfg.q_init_lazo_m3s)
    q_init = cfg.q_init_lazo_m3s;
  endif
  for i = 1:numel(base.lazos)
    if ~strcmp(base.lazos{i}.tipo, 'FUNDAMENTAL'), continue; endif
    for k = 1:numel(base.lazos{i}.aristas)
      ee = base.lazos{i}.aristas(k);
      q(ee) = q(ee) + q_init * base.lazos{i}.signos(k);
    endfor
  endfor

  nL = numel(base.lazos);
  max_iter = 60;
  if isfield(cfg, 'max_iter_lazo'), max_iter = cfg.max_iter_lazo; endif
  tol_lazo = 10;
  if isfield(cfg, 'tol_lazo_Pa'), tol_lazo = cfg.tol_lazo_Pa; endif
  tol_dq = 1e-9;
  if isfield(cfg, 'tol_dq_m3s'), tol_dq = cfg.tol_dq_m3s; endif
  dq_fd = 1e-7;
  if isfield(cfg, 'dq_derivada_m3s'), dq_fd = cfg.dq_derivada_m3s; endif
  alpha_min = 0.05;
  if isfield(cfg, 'amortiguamiento_lazo_min'), alpha_min = cfg.amortiguamiento_lazo_min; endif

  cfg_iter = cfg;
  cfg_iter.omitir_chequeo_P_min = true;
  P_ref = red.P_root_Pa;
  jacobiano_singular = false;
  cond_J = NaN;

  if nL == 0
    convergio = true;
    residual_lazo_max = 0;
  else
    for it = 1:max_iter
      iteraciones = it;
      R = residual_lazos_local(red, base, q, qg, P_ref, cfg_iter, modelo);
      residual_lazo_max = max(abs(R));
      historial_residual(end+1) = residual_lazo_max; %#ok<AGROW>
      if residual_lazo_max <= tol_lazo
        convergio = true;
        break;
      endif

      J = zeros(nL, nL);
      for j = 1:nL
        dq = max(dq_fd, abs(q_init) * 1e-3);
        q_p = q; q_m = q;
        for k = 1:numel(base.lazos{j}.aristas)
          ee = base.lazos{j}.aristas(k);
          q_p(ee) = q_p(ee) + dq * base.lazos{j}.signos(k);
          q_m(ee) = q_m(ee) - dq * base.lazos{j}.signos(k);
        endfor
        Rp = residual_lazos_local(red, base, q_p, qg, P_ref, cfg_iter, modelo);
        Rm = residual_lazos_local(red, base, q_m, qg, P_ref, cfg_iter, modelo);
        J(:, j) = (Rp - Rm) / (2 * dq);
      endfor

      cond_J = cond(J);
      if ~isfinite(cond_J) || cond_J > 1e14
        jacobiano_singular = true;
        items_extra{end+1} = item_local('HID_LAZO_JACOBIANO_SINGULAR', ...
          sprintf('Jacobiano mal condicionado (cond=%.3e).', cond_J), 'ERROR');
        break;
      endif

      delta = - (J \ R);
      if any(~isfinite(delta))
        jacobiano_singular = true;
        items_extra{end+1} = item_local('HID_LAZO_JACOBIANO_SINGULAR', ...
          'Resolucion del sistema de lazos produjo no-finitos.', 'ERROR');
        break;
      endif

      % Line search / backtracking
      norma0 = norm(R);
      alpha = 1.0;
      aceptado = false;
      while alpha >= alpha_min
        q_try = q;
        for j = 1:nL
          for k = 1:numel(base.lazos{j}.aristas)
            ee = base.lazos{j}.aristas(k);
            q_try(ee) = q_try(ee) + alpha * delta(j) * base.lazos{j}.signos(k);
          endfor
        endfor
        R_try = residual_lazos_local(red, base, q_try, qg, P_ref, cfg_iter, modelo);
        if norm(R_try) < norma0 || alpha <= alpha_min * 1.01
          q = q_try;
          aceptado = true;
          break;
        endif
        alpha = alpha * 0.5;
      endwhile
      if ~aceptado
        q = q_try;
      endif
      if max(abs(alpha * delta)) <= tol_dq && residual_lazo_max <= tol_lazo * 10
        R = residual_lazos_local(red, base, q, qg, P_ref, cfg_iter, modelo);
        residual_lazo_max = max(abs(R));
        historial_residual(end+1) = residual_lazo_max; %#ok<AGROW>
        if residual_lazo_max <= tol_lazo
          convergio = true;
        endif
        break;
      endif
    endfor
    if ~convergio && ~jacobiano_singular
      R = residual_lazos_local(red, base, q, qg, P_ref, cfg_iter, modelo);
      residual_lazo_max = max(abs(R));
    endif
  endif

  if ~convergio
    estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
    items_extra{end+1} = item_local('HID_LAZO_NO_CONVERGE', ...
      sprintf('Newton de lazos no convergio en %d iteraciones (res=%.6g Pa).', ...
              iteraciones, residual_lazo_max), 'ERROR');
  else
    items_extra{end+1} = item_local('HID_LAZO_RESUELTO_KIRCHHOFF', ...
      sprintf('Lazos resueltos por Newton Kirchhoff (%d lazos, %d iter).', ...
              nL, iteraciones), 'INFO');
  endif

  % Recuperacion de presiones (BFS) con chequeo P_min
  cfg_final = cfg;
  if isfield(cfg_final, 'omitir_chequeo_P_min')
    cfg_final = rmfield(cfg_final, 'omitir_chequeo_P_min');
  endif
  [P, res_edge, residual_fuente_max, residual_cierre, n_reverso, adv_rec] = ...
    recuperar_presiones_local(red, base, q, qg, cfg_final, modelo);
  for i = 1:numel(adv_rec), warnings{end+1} = adv_rec{i}; endfor %#ok<AGROW>
  if residual_cierre > tol_lazo && convergio
    items_extra{end+1} = item_local('HID_LAZO_RESIDUAL_CIERRE', ...
      sprintf('Residual de cierre de lazo %.6g Pa supera tol.', residual_cierre), 'ERROR');
    estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
  endif
  if n_reverso > 0
    items_extra{end+1} = item_local('HID_FLUJO_REVERSO_DETECTADO', ...
      sprintf('Flujo reverso en %d tramo(s).', n_reverso), 'INFO');
  endif
  if any(red.ql_inyeccion_m3s > cfg.tol_balance_m3s)
    items_extra{end+1} = item_local('HID_INYECCION_NODAL', ...
      'Se detectaron inyecciones nodales (caudal negativo de demanda).', 'INFO');
  endif

  % Completar tramos inactivos / excluidos
  for e = 1:nE
    if isempty(res_edge{e})
      tr = red.tramos{e};
      st = 'NO_RESUELTO';
      adv0 = {'TRAMO_FUERA_COMPONENTE_ACTIVO'};
      if any(base.aristas_excluidas == e)
        st = 'VALVULA_CERRADA';
        adv0 = {'VALVULA_CERRADA'};
        res_edge{e} = struct('id', id_local(tr, e), ...
          'nodo_entrada', char(tr.nodo_o), 'nodo_salida', char(tr.nodo_d), ...
          'estado', st, 'estado_convergencia', st, ...
          'caudal_liquido_m3s', 0, 'caudal_orientado_m3s', 0, ...
          'sentido_flujo', 'DIRECTO', ...
          'P_in_Pa', NaN, 'P_out_Pa', NaN, ...
          'advertencias', {adv0});
      else
        res_edge{e} = struct('id', id_local(tr, e), ...
          'nodo_entrada', char(tr.nodo_o), 'nodo_salida', char(tr.nodo_d), ...
          'estado', st, 'estado_convergencia', st, ...
          'advertencias', {adv0});
      endif
    endif
  endfor

  grado = zeros(1, nN);
  for e = 1:nE
    if ~active(e) && ~red.active_edge(e), continue; endif
    if red.active_edge(e)
      grado(red.e_o(e)) = grado(red.e_o(e)) + 1;
      grado(red.e_d(e)) = grado(red.e_d(e)) + 1;
    endif
  endfor
  n_bif = sum(grado >= 3);
  if red.tiene_lazos
    topologia_resuelta = 'CON_LAZOS';
  elseif n_bif > 0
    topologia_resuelta = 'ARBOL_RAMIFICADO';
  else
    topologia_resuelta = 'CADENA_SERIE';
  endif

  residual_balance_max = 0;
  res_nodes = cell(1, nN);
  fuentes = red.nodos_presion;
  for i = 1:nN
    n = red.nodos{i};
    q_in = 0; q_out = 0;
    for e = 1:nE
      if ~red.active_edge(e), continue; endif
      if any(base.aristas_excluidas == e), continue; endif
      if red.e_d(e) == i
        if q(e) >= 0, q_in = q_in + q(e); else q_out = q_out + abs(q(e)); endif
      endif
      if red.e_o(e) == i
        if q(e) >= 0, q_out = q_out + q(e); else q_in = q_in + abs(q(e)); endif
      endif
    endfor
    dem = red.ql_demanda_m3s(i);
    % Balance: inflow - outflow - demand = 0 (demand negativa = inyeccion)
    balance = q_in - q_out - dem;
    % En fuentes de presion el "suministro" equilibra
    if any(fuentes == i)
      suministro = q_out - q_in + dem;
      balance = q_in + suministro - q_out - dem;
    endif
    residual_balance_max = max(residual_balance_max, abs(balance));

    rn = struct();
    rn.id = char(n.id);
    rn.x_m = coord_local(n, 'x'); rn.y_m = coord_local(n, 'y'); rn.z_m = coord_local(n, 'z');
    rn.presion_Pa = P(i); rn.presion_bar = P(i) / 1e5;
    rn.demanda_liquido_m3s = dem;
    rn.demanda_gas_std_m3s = red.qg_demanda_std_m3s(i);
    rn.es_referencia_presion = (i == red.root);
    rn.es_fuente_presion = any(fuentes == i);
    rn.inyeccion_liquido_m3s = red.ql_inyeccion_m3s(i);
    rn.grado = grado(i);
    rn.es_bifurcacion = (grado(i) >= 3);
    rn.caudal_entrante_m3s = q_in;
    rn.caudal_saliente_m3s = q_out;
    rn.balance_nodal_m3s = balance;
    rn.estado = 'OK';
    if isnan(P(i)), rn.estado = 'NO_RESUELTO'; endif
    res_nodes{i} = rn;
  endfor

  if residual_balance_max > cfg.tol_balance_m3s
    estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
  endif
  for e = 1:nE
    if ~isempty(res_edge{e}) && isfield(res_edge{e}, 'estado')
      if strcmp(res_edge{e}.estado, 'ERROR')
        estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
      endif
    endif
  endfor

  dominio_id = ''; dominio_tipo = 'RED_COMPLETA'; dominio_inicio = ''; dominio_fin = '';
  if isfield(red, 'dominio_hidraulico') && ~isempty(red.dominio_hidraulico)
    dominio_id = char(red.dominio_hidraulico.id);
    dominio_tipo = char(red.dominio_hidraulico.tipo);
    dominio_inicio = char(red.dominio_hidraulico.nodo_inicio);
    dominio_fin = char(red.dominio_hidraulico.nodo_fin);
  endif

  ql_total = 0;
  for i = 1:nN
    if red.ql_demanda_m3s(i) > 0, ql_total = ql_total + red.ql_demanda_m3s(i); endif
  endfor

  resultados = struct();
  resultados.nodos = res_nodes;
  resultados.tramos = res_edge;
  resultados.resumen = {struct( ...
    'motor', cfg.version, ...
    'estado', estado_global, ...
    'n_nodos', nN, ...
    'n_tramos', nE, ...
    'dominio_hidraulico_id', dominio_id, ...
    'dominio_hidraulico_tipo', dominio_tipo, ...
    'nodo_inicio', dominio_inicio, ...
    'nodo_fin', dominio_fin, ...
    'caudal_liquido_total_m3s', ql_total, ...
    'caudal_liquido_total_m3d', ql_total * 86400, ...
    'caudal_gas_total_std_m3s', red.qg_total_std_m3s, ...
    'caudal_gas_total_std_m3d', red.qg_total_std_m3s * 86400, ...
    'residual_balance_max_m3s', residual_balance_max, ...
    'n_bifurcaciones', n_bif, ...
    'topologia_resuelta', topologia_resuelta, ...
    'n_lazos_independientes', base.n_lazos_reales, ...
    'n_pseudolazos', base.n_pseudolazos, ...
    'n_fuentes_presion', numel(fuentes), ...
    'metodo_lazo', metodo, ...
    'iteraciones_lazo', iteraciones, ...
    'convergio', convergio, ...
    'residual_lazo_max_Pa', residual_lazo_max, ...
    'residual_fuente_max_Pa', residual_fuente_max, ...
    'historial_residual_lazo', historial_residual, ...
    'n_tramos_flujo_reverso', n_reverso, ...
    'n_advertencias', numel(warnings))};

  modelo.tablas_entrada.fluidos = {cfg.fluido};
  modelo.tablas_resultados = resultados;
  modelo.simulacion.motor = cfg.version;
  modelo.simulacion.dominio = 'HIDRAULICO';
  modelo.simulacion.estado = estado_global;
  modelo.simulacion.configuracion_hidraulica = cfg;
  modelo.simulacion.parametros_efectivos = struct( ...
    'modelo', cfg.modelo, ...
    'modelo_multifasico', cfg.modelo_multifasico, ...
    'fluido', cfg.fluido, ...
    'topologia_soportada', 'LAZOS_KIRCHHOFF_MONOFASICO', ...
    'convencion_caudal', cfg.signo_bc_caudal, ...
    'dominio_hidraulico_id', dominio_id, ...
    'dominio_hidraulico_tipo', dominio_tipo, ...
    'nodo_inicio', dominio_inicio, ...
    'nodo_fin', dominio_fin, ...
    'metodo_lazo', metodo, ...
    'iteraciones_lazo', iteraciones);
  modelo.simulacion.advertencias = warnings;
  modelo.simulacion.corrida_id = sprintf('AOSCAD_HID_LOOP_%s', datestr(now, 'yyyymmdd_HHMMSS'));
  modelo.simulacion.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  modelo.simulacion.entradas_hash = hash_entradas_local(modelo);
  modelo.simulacion.solver_usado = 'HYD_LOOP';

  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  items = modelo.validaciones.items;
  if ~iscell(items), items = num2cell(items); endif
  items = limpiar_codigos_local(items, 'HID_');
  items{end+1} = struct('codigo', 'HID_SOLVER_DEV1', ...
    'mensaje', sprintf('Dominio %s resuelto por HYD_LOOP: %d nodos, %d tramos.', ...
                       dominio_tipo, nN, nE), ...
    'severidad', 'INFO');
  for i = 1:numel(items_extra), items{end+1} = items_extra{i}; endfor %#ok<AGROW>
  if residual_balance_max > cfg.tol_balance_m3s
    items{end+1} = struct('codigo', 'HID_BALANCE_NODAL', ...
      'mensaje', sprintf('Residual de balance nodal maximo %.3e m3/s supera tol %.3e.', ...
                         residual_balance_max, cfg.tol_balance_m3s), ...
      'severidad', 'ERROR');
  endif
  hay_err = false;
  for i = 1:numel(items)
    if isstruct(items{i}) && isfield(items{i}, 'severidad') && ...
        strcmpi(items{i}.severidad, 'ERROR')
      hay_err = true; break;
    endif
  endfor
  if hay_err || (~isempty(warnings) && ~convergio)
    modelo.validaciones.estado = 'ADVERTENCIA';
  elseif isempty(warnings) && residual_balance_max <= cfg.tol_balance_m3s
    modelo.validaciones.estado = 'OK';
  else
    modelo.validaciones.estado = 'ADVERTENCIA';
  endif
  modelo.validaciones.items = items;

  if ~silencioso
    aos_cad_hidraulica_imprimir(modelo, resultados);
  endif
endfunction

function R = residual_lazos_local(red, base, q, qg, P_ref, cfg, modelo)
  nL = numel(base.lazos);
  R = zeros(nL, 1);
  for i = 1:nL
    lazo = base.lazos{i};
    s = 0;
    for k = 1:numel(lazo.aristas)
      e = lazo.aristas(k);
      [dp, ~, ~] = aos_cad_hidraulica_dp_orientado( ...
        red.tramos{e}, red.nodos{red.e_o(e)}, red.nodos{red.e_d(e)}, ...
        P_ref, q(e), qg(e), cfg, modelo);
      s = s + lazo.signos(k) * dp;
    endfor
    if strcmp(lazo.tipo, 'PSEUDO')
      Pa = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_a, 1));
      Pb = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_b, 1));
      % Camino a->b: sum(sign*dp) debe igualar Pa - Pb
      s = s - (Pa - Pb);
    endif
    R(i) = s;
  endfor
endfunction

function [P, res_edge, residual_fuente_max, residual_cierre, n_reverso, warnings] = ...
    recuperar_presiones_local(red, base, q, qg, cfg, modelo)
  nN = numel(red.nodos); nE = numel(red.tramos);
  P = NaN(1, nN);
  P(red.root) = red.P_root_Pa;
  res_edge = cell(1, nE);
  warnings = {};
  n_reverso = 0;
  residual_cierre = 0;
  residual_fuente_max = 0;

  parent = base.parent;
  parent_edge = base.parent_edge;
  visited = base.visited;
  order = zeros(1, nN); n_order = 0;
  queue = zeros(1, nN); qh = 1; qt = 1;
  queue(1) = red.root;
  seen = false(1, nN); seen(red.root) = true;
  while qh <= qt
    u = queue(qh); qh = qh + 1;
    n_order = n_order + 1; order(n_order) = u;
    for e = 1:nE
      if ~base.active_edge_efectivo(e), continue; endif
      a = red.e_o(e); b = red.e_d(e);
      v = 0;
      if a == u && ~seen(b), v = b; endif
      if b == u && ~seen(a), v = a; endif
      if v == 0, continue; endif
      % Prefer tree edges for BFS recovery order
      if parent(v) == u || parent(u) == v || true
        seen(v) = true;
        qt = qt + 1; queue(qt) = v;
      endif
    endfor
  endwhile
  order = order(1:n_order);

  % Propagar por arbol de expansion primero
  for kk = 2:numel(order)
    child = order(kk);
    if parent(child) <= 0, continue; endif
    e = parent_edge(child);
    if e <= 0 || ~base.active_edge_efectivo(e), continue; endif
    parent_n = parent(child);
    if isnan(P(parent_n)), continue; endif
    [dp, r, adv] = aos_cad_hidraulica_dp_orientado( ...
      red.tramos{e}, red.nodos{red.e_o(e)}, red.nodos{red.e_d(e)}, ...
      P(parent_n), q(e), qg(e), cfg, modelo);
    % Presion del hijo segun orientacion del flujo relativo al parent
    if red.e_o(e) == parent_n
      % geometric parent -> child: si q>0, P_child = P_parent - dp_orientado
      P(child) = P(parent_n) - dp;
    else
      % geometric child -> parent (parent is e_d): dp_orientado = P_o - P_d = P_child - P_parent
      % => P_child = P_parent + dp
      P(child) = P(parent_n) + dp;
    endif
    r.id = id_local(red.tramos{e}, e);
    if q(e) >= 0
      r.nodo_entrada = char(red.nodos{red.e_o(e)}.id);
      r.nodo_salida = char(red.nodos{red.e_d(e)}.id);
    else
      r.nodo_entrada = char(red.nodos{red.e_d(e)}.id);
      r.nodo_salida = char(red.nodos{red.e_o(e)}.id);
    endif
    r.estado_convergencia = r.estado;
    r.caudal_liquido_m3s = abs(q(e));
    res_edge{e} = r;
    if strcmp(r.sentido_flujo, 'REVERSO'), n_reverso = n_reverso + 1; endif
    for j = 1:numel(adv), warnings{end+1} = sprintf('%s:%s', r.id, adv{j}); endfor %#ok<AGROW>
  endfor

  % Evaluar cuerdas / restantes con P conocida en extremo de entrada de flujo
  for e = 1:nE
    if ~isempty(res_edge{e}), continue; endif
    if ~base.active_edge_efectivo(e), continue; endif
    io = red.e_o(e); id = red.e_d(e);
    if q(e) >= 0
      if isnan(P(io)), continue; endif
      Pref = P(io);
    else
      if isnan(P(id)), continue; endif
      Pref = P(id);
    endif
    [dp, r, adv] = aos_cad_hidraulica_dp_orientado( ...
      red.tramos{e}, red.nodos{io}, red.nodos{id}, Pref, q(e), qg(e), cfg, modelo);
    r.id = id_local(red.tramos{e}, e);
    if q(e) >= 0
      r.nodo_entrada = char(red.nodos{io}.id);
      r.nodo_salida = char(red.nodos{id}.id);
      if isnan(P(id)), P(id) = Pref - dp; endif
    else
      r.nodo_entrada = char(red.nodos{id}.id);
      r.nodo_salida = char(red.nodos{io}.id);
      if isnan(P(io)), P(io) = Pref - abs(r.dp_total_Pa); endif
    endif
    r.estado_convergencia = r.estado;
    r.caudal_liquido_m3s = abs(q(e));
    res_edge{e} = r;
    if strcmp(r.sentido_flujo, 'REVERSO'), n_reverso = n_reverso + 1; endif
    for j = 1:numel(adv), warnings{end+1} = sprintf('%s:%s', r.id, adv{j}); endfor %#ok<AGROW>
  endfor

  % Residuales de cierre y fuentes
  for i = 1:numel(base.lazos)
    lazo = base.lazos{i};
    s = 0;
    for k = 1:numel(lazo.aristas)
      e = lazo.aristas(k);
      if isempty(res_edge{e}) || ~isfield(res_edge{e}, 'dp_total_Pa')
        [dp, ~, ~] = aos_cad_hidraulica_dp_orientado( ...
          red.tramos{e}, red.nodos{red.e_o(e)}, red.nodos{red.e_d(e)}, ...
          red.P_root_Pa, q(e), qg(e), cfg, modelo);
      else
        if q(e) >= 0
          dp = res_edge{e}.dp_total_Pa;
        else
          dp = -res_edge{e}.dp_total_Pa;
        endif
      endif
      s = s + lazo.signos(k) * dp;
    endfor
    if strcmp(lazo.tipo, 'PSEUDO')
      Pa = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_a, 1));
      Pb = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_b, 1));
      s = s - (Pa - Pb);
      if ~isnan(P(lazo.fuente_b))
        residual_fuente_max = max(residual_fuente_max, abs(P(lazo.fuente_b) - Pb));
      endif
    endif
    residual_cierre = max(residual_cierre, abs(s));
  endfor
endfunction

function [modelo, resultados] = resultado_rechazo_local(modelo, red, cfg, items_extra, silencioso)
  nN = numel(red.nodos); nE = numel(red.tramos);
  res_nodes = cell(1, nN);
  for i = 1:nN
    n = red.nodos{i};
    res_nodes{i} = struct('id', char(n.id), 'presion_Pa', NaN, 'presion_bar', NaN, ...
      'demanda_liquido_m3s', red.ql_demanda_m3s(i), ...
      'demanda_gas_std_m3s', red.qg_demanda_std_m3s(i), ...
      'es_referencia_presion', i == red.root, ...
      'es_fuente_presion', any(red.nodos_presion == i), ...
      'inyeccion_liquido_m3s', red.ql_inyeccion_m3s(i), ...
      'estado', 'NO_RESUELTO', 'balance_nodal_m3s', 0, ...
      'caudal_entrante_m3s', 0, 'caudal_saliente_m3s', 0, ...
      'grado', 0, 'es_bifurcacion', false, ...
      'x_m', 0, 'y_m', 0, 'z_m', 0);
  endfor
  res_edge = cell(1, nE);
  for e = 1:nE
    tr = red.tramos{e};
    res_edge{e} = struct('id', id_local(tr, e), ...
      'nodo_entrada', char(tr.nodo_o), 'nodo_salida', char(tr.nodo_d), ...
      'estado', 'NO_RESUELTO', 'estado_convergencia', 'NO_RESUELTO', ...
      'advertencias', {{'CORRIDA_NO_EJECUTADA'}});
  endfor
  resultados = struct();
  resultados.nodos = res_nodes;
  resultados.tramos = res_edge;
  resultados.resumen = {struct('motor', cfg.version, 'estado', 'NO_EJECUTADA', ...
    'n_nodos', nN, 'n_tramos', nE, 'convergio', false, ...
    'residual_lazo_max_Pa', NaN, 'iteraciones_lazo', 0, ...
    'n_lazos_independientes', 0, 'n_pseudolazos', 0, ...
    'n_fuentes_presion', numel(red.nodos_presion), ...
    'metodo_lazo', 'NEWTON', 'residual_balance_max_m3s', 0, ...
    'caudal_liquido_total_m3s', 0, 'caudal_liquido_total_m3d', 0, ...
    'caudal_gas_total_std_m3s', 0, 'caudal_gas_total_std_m3d', 0, ...
    'n_bifurcaciones', 0, 'topologia_resuelta', 'RECHAZADA', ...
    'n_tramos_flujo_reverso', 0, 'n_advertencias', 0, ...
    'dominio_hidraulico_id', '', 'dominio_hidraulico_tipo', 'RED_COMPLETA', ...
    'nodo_inicio', '', 'nodo_fin', '')};
  modelo.tablas_resultados = resultados;
  modelo.simulacion.estado = 'NO_EJECUTADA';
  modelo.simulacion.solver_usado = 'HYD_LOOP';
  modelo.simulacion.parametros_efectivos = struct( ...
    'topologia_soportada', 'LAZOS_KIRCHHOFF_MONOFASICO');
  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'ERROR', 'items', {{}});
  endif
  items = modelo.validaciones.items;
  if ~iscell(items), items = num2cell(items); endif
  items = limpiar_codigos_local(items, 'HID_');
  for i = 1:numel(items_extra), items{end+1} = items_extra{i}; endfor %#ok<AGROW>
  modelo.validaciones.items = items;
  modelo.validaciones.estado = 'ERROR';
  if ~silencioso
    fprintf('HYD_LOOP: corrida no ejecutada (%d items).\n', numel(items_extra));
  endif
endfunction

function it = item_local(codigo, mensaje, severidad)
  it = struct('codigo', codigo, 'mensaje', mensaje, 'severidad', severidad);
endfunction

function m = modelo_tramo_local(tr, cfg, Qg)
  m = cfg.modelo;
  campos = {'modelo_hidraulico','modelo_vlp','modelo'};
  for i = 1:numel(campos)
    if isstruct(tr) && isfield(tr, campos{i})
      x = tr.(campos{i});
      if isstruct(x), x = aos_aoscad_valor(x); endif
      if ischar(x) && ~isempty(strtrim(x)), m = x; break; endif
    endif
  endfor
  m = upper(strrep(strrep(strtrim(char(m)), '-', '_'), ' ', '_'));
  if any(strcmp(m, {'DARCY','DARCY_WEISBACH','MONOFASICO'})), m = 'MONOFASICO_DARCY'; endif
  if strcmp(m, 'AUTO'), m = 'AUTOMATICO'; endif
  if strcmp(m, 'AUTOMATICO')
    if abs(Qg) <= 1e-12, m = 'MONOFASICO_DARCY';
    else m = upper(char(cfg.modelo_multifasico)); endif
  endif
endfunction

function id = id_local(tr, e)
  id = sprintf('T%03d', e); if isstruct(tr) && isfield(tr, 'id'), id = char(tr.id); endif
endfunction
function v = coord_local(n, f)
  v = 0;
  if isstruct(n) && isfield(n, f) && isnumeric(n.(f)) && ~isempty(n.(f)), v = n.(f)(1);
  elseif strcmp(f, 'z') && isfield(n, 'cota'), x=aos_aoscad_valor(n.cota); if ~isempty(x), v=x(1); endif
  endif
endfunction
function items = limpiar_codigos_local(items, pref)
  keep = {};
  for i = 1:numel(items)
    it = items{i}; cod = '';
    if isstruct(it) && isfield(it, 'codigo'), cod = char(it.codigo); endif
    if ~strncmp(cod, pref, numel(pref)), keep{end+1} = it; endif %#ok<AGROW>
  endfor
  items = keep;
endfunction
function h = hash_entradas_local(modelo)
  h = '';
  try
    txt = jsonencode(modelo.tablas_entrada);
    if exist('hash', 'builtin') == 5 || exist('hash', 'file') == 2
      h = hash('sha256', txt);
    else
      h = sprintf('LEN_%d_SUM_%d', numel(txt), sum(double(txt)));
    endif
  catch
    h = sprintf('NO_HASH_%s', datestr(now, 'yyyymmddHHMMSS'));
  end_try_catch
endfunction

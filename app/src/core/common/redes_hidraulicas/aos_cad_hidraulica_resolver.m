function [modelo, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, silencioso)
% AOS_CAD_HIDRAULICA_RESOLVER Solver de red DXF abierta AOSCAD HID DEV1.
% Alcance: arbol conectado, un BC de presion, demandas nodales positivas.
  if nargin < 3, silencioso = false; endif
  if nargin < 2 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(modelo); endif

  red = aos_cad_hidraulica_preparar(modelo, cfg);
  if isfield(red, 'requiere_solver_lazos') && red.requiere_solver_lazos
    [modelo, resultados] = aos_cad_hidraulica_resolver_lazos(modelo, cfg, silencioso);
    return;
  endif
  nN = numel(red.nodos); nE = numel(red.tramos);
  P = NaN(1, nN); P(red.root) = red.P_root_Pa;
  res_edge = cell(1, nE);
  warnings = {};
  estado_global = 'EJECUTADA';

  for kk = 2:numel(red.order)
    child = red.order(kk); parent = red.parent(child); e = red.parent_edge(child);
    tr = red.tramos{e};
    ql = red.ql_edge_m3s(e); qg = red.qg_edge_std_m3s(e);
    if ql < -cfg.tol_balance_m3s || qg < -cfg.tol_balance_m3s
      error('AOSCAD HID DEV1: flujo reverso no soportado en tramo %s.', id_local(tr, e));
    endif
    r = aos_cad_hidraulica_evaluar_tramo(tr, red.nodos{parent}, red.nodos{child}, ...
                                          P(parent), ql, qg, cfg, modelo);
    r.id = id_local(tr, e);
    r.nodo_entrada = char(red.nodos{parent}.id);
    r.nodo_salida = char(red.nodos{child}.id);
    r.sentido_geometria = sentido_local(tr, red.nodos{parent}.id, red.nodos{child}.id);
    r.estado_convergencia = r.estado;
    res_edge{e} = r;
    P(child) = r.P_out_Pa;
    if strcmp(r.estado, 'ERROR')
      estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
    elseif strcmp(r.estado, 'ADVERTENCIA') && strcmp(estado_global, 'EJECUTADA')
      estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
    endif
    for j = 1:numel(r.advertencias)
      warnings{end+1} = sprintf('%s:%s', r.id, r.advertencias{j}); %#ok<AGROW>
    endfor
  endfor

  % Completar tramos inactivos (solo si se permitieron desconectados).
  for e = 1:nE
    if isempty(res_edge{e})
      tr = red.tramos{e};
      res_edge{e} = struct('id', id_local(tr, e), ...
                           'nodo_entrada', char(tr.nodo_o), ...
                           'nodo_salida', char(tr.nodo_d), ...
                           'estado', 'NO_RESUELTO', ...
                           'estado_convergencia', 'NO_RESUELTO', ...
                           'advertencias', {{'TRAMO_FUERA_COMPONENTE_ACTIVO'}});
    endif
  endfor

  grado = zeros(1, nN);
  for e = 1:nE
    if ~red.active_edge(e), continue; endif
    grado(red.e_o(e)) = grado(red.e_o(e)) + 1;
    grado(red.e_d(e)) = grado(red.e_d(e)) + 1;
  endfor
  n_bif = sum(grado >= 3);
  if n_bif > 0
    topologia_resuelta = 'ARBOL_RAMIFICADO';
  else
    topologia_resuelta = 'CADENA_SERIE';
  endif

  residual_balance_max = 0;
  res_nodes = cell(1, nN);
  for i = 1:nN
    n = red.nodos{i};
    q_in_edges = 0; q_out_edges = 0;
    for e = 1:nE
      if ~red.active_edge(e), continue; endif
      if red.edge_child(e) == i
        q_in_edges = q_in_edges + red.ql_edge_m3s(e);
      endif
      if red.edge_parent(e) == i
        q_out_edges = q_out_edges + red.ql_edge_m3s(e);
      endif
    endfor
    dem = red.ql_demanda_m3s(i);
    if i == red.root
      caudal_entrante = q_out_edges + dem;
    else
      caudal_entrante = q_in_edges;
    endif
    caudal_saliente = q_out_edges;
    balance = caudal_entrante - caudal_saliente - dem;
    residual_balance_max = max(residual_balance_max, abs(balance));

    rn = struct();
    rn.id = char(n.id);
    rn.x_m = coord_local(n, 'x'); rn.y_m = coord_local(n, 'y'); rn.z_m = coord_local(n, 'z');
    rn.presion_Pa = P(i); rn.presion_bar = P(i) / 1e5;
    rn.demanda_liquido_m3s = dem;
    rn.demanda_gas_std_m3s = red.qg_demanda_std_m3s(i);
    rn.es_referencia_presion = (i == red.root);
    rn.grado = grado(i);
    rn.es_bifurcacion = (grado(i) >= 3);
    rn.caudal_entrante_m3s = caudal_entrante;
    rn.caudal_saliente_m3s = caudal_saliente;
    rn.balance_nodal_m3s = balance;
    rn.estado = 'OK';
    if isnan(P(i)), rn.estado = 'NO_RESUELTO'; endif
    res_nodes{i} = rn;
  endfor

  if residual_balance_max > cfg.tol_balance_m3s
    estado_global = 'EJECUTADA_CON_ADVERTENCIAS';
  endif

  dominio_id = ''; dominio_tipo = 'RED_COMPLETA'; dominio_inicio = ''; dominio_fin = '';
  if isfield(red, 'dominio_hidraulico') && ~isempty(red.dominio_hidraulico)
    dominio_id = char(red.dominio_hidraulico.id);
    dominio_tipo = char(red.dominio_hidraulico.tipo);
    dominio_inicio = char(red.dominio_hidraulico.nodo_inicio);
    dominio_fin = char(red.dominio_hidraulico.nodo_fin);
  endif

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
    'caudal_liquido_total_m3s', red.ql_total_m3s, ...
    'caudal_liquido_total_m3d', red.ql_total_m3s * 86400, ...
    'caudal_gas_total_std_m3s', red.qg_total_std_m3s, ...
    'caudal_gas_total_std_m3d', red.qg_total_std_m3s * 86400, ...
    'residual_balance_max_m3s', residual_balance_max, ...
    'n_bifurcaciones', n_bif, ...
    'topologia_resuelta', topologia_resuelta, ...
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
    'topologia_soportada', 'ARBOL_SIN_LAZOS', ...
    'convencion_caudal', cfg.signo_bc_caudal, ...
    'dominio_hidraulico_id', dominio_id, ...
    'dominio_hidraulico_tipo', dominio_tipo, ...
    'nodo_inicio', dominio_inicio, ...
    'nodo_fin', dominio_fin);
  modelo.simulacion.advertencias = warnings;
  modelo.simulacion.corrida_id = sprintf('AOSCAD_HID_%s', datestr(now, 'yyyymmdd_HHMMSS'));
  modelo.simulacion.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  modelo.simulacion.entradas_hash = hash_entradas_local(modelo);
  modelo.simulacion.solver_usado = 'HYD_TREE';

  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  items = modelo.validaciones.items;
  if ~iscell(items), items = num2cell(items); endif
  items = limpiar_codigos_local(items, 'HID_');
  items{end+1} = struct('codigo', 'HID_SOLVER_DEV1', ...
    'mensaje', sprintf('Dominio %s resuelto: %d nodos, %d tramos.', dominio_tipo, nN, nE), ...
    'severidad', 'INFO');
  if residual_balance_max > cfg.tol_balance_m3s
    items{end+1} = struct('codigo', 'HID_BALANCE_NODAL', ...
      'mensaje', sprintf('Residual de balance nodal maximo %.3e m3/s supera tol %.3e.', ...
                         residual_balance_max, cfg.tol_balance_m3s), ...
      'severidad', 'ERROR');
  endif
  if isempty(warnings) && residual_balance_max <= cfg.tol_balance_m3s
    modelo.validaciones.estado = 'OK';
  else
    modelo.validaciones.estado = 'ADVERTENCIA';
    if ~isempty(warnings)
      items{end+1} = struct('codigo', 'HID_ADVERTENCIAS', ...
        'mensaje', sprintf('La corrida genero %d advertencias.', numel(warnings)), ...
        'severidad', 'ADVERTENCIA');
    endif
  endif
  modelo.validaciones.items = items;

  if ~silencioso
    aos_cad_hidraulica_imprimir(modelo, resultados);
  endif
endfunction

function id = id_local(tr, e)
  id = sprintf('T%03d', e); if isstruct(tr) && isfield(tr, 'id'), id = char(tr.id); endif
endfunction
function s = sentido_local(tr, p, c)
  if strcmp(char(tr.nodo_o), char(p)) && strcmp(char(tr.nodo_d), char(c))
    s = 'NODO_O_A_NODO_D';
  else
    s = 'NODO_D_A_NODO_O';
  endif
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

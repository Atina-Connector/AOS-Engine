function red = aos_cad_hidraulica_preparar(modelo, cfg)
% AOS_CAD_HIDRAULICA_PREPARAR Convierte tablas AOSCAD en una red solvable.
% Sprint 4: admite lazos, multifuente e inyecciones; el camino arbol
% permanece bit-identico cuando no se requiere solver de lazos.
  if nargin < 2 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(modelo); endif
  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada')
    error('AOSCAD HID: modelo sin tablas_entrada.');
  endif

  [modelo_red, dominio_activo] = aos_cad_hidraulica_dominio_filtrar_modelo(modelo);
  te = modelo_red.tablas_entrada;
  nodos = get_rows_local(te, 'nodos');
  tramos = get_rows_local(te, 'tramos');
  bcs = get_rows_local(te, 'condiciones_borde');
  if isempty(nodos), error('AOSCAD HID: no hay nodos.'); endif
  if isempty(tramos), error('AOSCAD HID: no hay tramos.'); endif

  nN = numel(nodos); nE = numel(tramos);
  ids = cell(1, nN);
  for i = 1:nN
    ids{i} = char(nodos{i}.id);
  endfor
  if numel(unique(ids)) ~= nN
    error('AOSCAD HID: existen IDs de nodo duplicados.');
  endif

  e_o = zeros(1, nE); e_d = zeros(1, nE);
  adj_n = cell(1, nN); adj_e = cell(1, nN);
  for i = 1:nN, adj_n{i} = []; adj_e{i} = []; endfor
  for e = 1:nE
    tr = tramos{e};
    io = buscar_id_local(ids, char(tr.nodo_o));
    id = buscar_id_local(ids, char(tr.nodo_d));
    if io == 0 || id == 0
      error('AOSCAD HID: tramo %s referencia nodo inexistente.', id_tramo_local(tr, e));
    endif
    if io == id
      error('AOSCAD HID: tramo %s conecta un nodo consigo mismo.', id_tramo_local(tr, e));
    endif
    e_o(e) = io; e_d(e) = id;
    adj_n{io}(end+1) = id; adj_e{io}(end+1) = e;
    adj_n{id}(end+1) = io; adj_e{id}(end+1) = e;
  endfor

  p_nodes = []; p_vals = [];
  ql_dem = zeros(1, nN); qg_dem = zeros(1, nN);
  qg_explicito = false;
  for i = 1:numel(bcs)
    bc = bcs{i};
    if ~isfield(bc, 'nodo_ref'), continue; endif
    ni = buscar_id_local(ids, char(bc.nodo_ref));
    if ni == 0
      error('AOSCAD HID: BC %d referencia nodo inexistente %s.', i, char(bc.nodo_ref));
    endif
    tipo = upper(strtrim(char(getf_local(bc, 'tipo_bc', ''))));
    valor = aos_aoscad_valor(getf_local(bc, 'valor', []));
    if isempty(valor), continue; endif
    unidad = char(getf_local(bc, 'unidad', ''));
    if strcmp(tipo, 'PRESION') || strcmp(tipo, 'PRESSURE')
      p_nodes(end+1) = ni; p_vals(end+1) = convertir_presion_local(valor, unidad);
    elseif any(strcmp(tipo, {'CAUDAL','CAUDAL_LIQUIDO','DEMANDA','FLOW','LIQUID_FLOW'}))
      ql_dem(ni) = ql_dem(ni) + convertir_caudal_local(valor, unidad);
    elseif any(strcmp(tipo, {'CAUDAL_GAS','CAUDAL_GAS_STD','QG','GAS_FLOW'}))
      qg_dem(ni) = qg_dem(ni) + convertir_caudal_local(valor, unidad);
      qg_explicito = true;
    endif
  endfor

  if isempty(p_nodes)
    error('AOSCAD HID: se requiere un BC de PRESION.');
  endif
  p_unique = unique(p_nodes);
  % Conservar orden de primera aparicion para root = primera fuente
  nodos_presion = [];
  P_nodos = [];
  for i = 1:numel(p_nodes)
    if ~any(nodos_presion == p_nodes(i))
      nodos_presion(end+1) = p_nodes(i); %#ok<AGROW>
      P_nodos(end+1) = p_vals(i); %#ok<AGROW>
    else
      idx = find(nodos_presion == p_nodes(i), 1, 'first');
      P_nodos(idx) = p_vals(i);
    endif
  endfor
  root = nodos_presion(1);
  P_root = P_nodos(1);
  if P_root <= 0, error('AOSCAD HID: presion de referencia invalida.'); endif
  for i = 1:numel(P_nodos)
    if P_nodos(i) <= 0
      error('AOSCAD HID: presion de referencia invalida en fuente %d.', i);
    endif
  endfor

  % BFS sobre el componente de la presion de referencia.
  visited = false(1, nN);
  parent = zeros(1, nN); parent_edge = zeros(1, nN);
  order = zeros(1, nN); n_order = 0;
  queue = zeros(1, nN); qh = 1; qt = 1; queue(1) = root; visited(root) = true;
  ciclo = false;
  while qh <= qt
    u = queue(qh); qh = qh + 1;
    n_order = n_order + 1; order(n_order) = u;
    for k = 1:numel(adj_n{u})
      v = adj_n{u}(k); e = adj_e{u}(k);
      if ~visited(v)
        visited(v) = true; parent(v) = u; parent_edge(v) = e;
        qt = qt + 1; queue(qt) = v;
      elseif parent(u) ~= v && parent(v) ~= u
        ciclo = true;
      endif
    endfor
  endwhile
  order = order(1:n_order);

  active_edge = false(1, nE);
  for e = 1:nE
    active_edge(e) = visited(e_o(e)) && visited(e_d(e));
  endfor
  if any((ql_dem ~= 0 | qg_dem ~= 0) & ~visited)
    error('AOSCAD HID: existe una demanda fuera del componente conectado al BC de presion.');
  endif
  if cfg.rechazar_desconectados && any(~active_edge)
    error('AOSCAD HID DEV1: la red contiene tramos desconectados del BC de presion.');
  endif
  if cfg.rechazar_lazos && ciclo
    error('AOSCAD HID DEV1: se detecto un lazo. Los lazos se incorporaran en una version posterior.');
  endif

  % La red recorrida debe ser un arbol: E_componente = N_componente - 1.
  n_comp_nodes = sum(visited); n_comp_edges = sum(active_edge);
  if cfg.rechazar_lazos && n_comp_edges ~= n_comp_nodes - 1
    error('AOSCAD HID DEV1: topologia no arborescente (nodos=%d, tramos=%d).', ...
          n_comp_nodes, n_comp_edges);
  endif

  hay_inyeccion = any(ql_dem < -cfg.tol_balance_m3s) || any(qg_dem < -cfg.tol_balance_m3s);
  if hay_inyeccion && cfg.rechazar_lazos
    error(['AOSCAD HID DEV1: caudales negativos (fuentes internas o flujo reverso) ' ...
           'todavia no estan soportados.']);
  endif
  if hay_inyeccion && (any(qg_dem < -cfg.tol_balance_m3s) || ...
      (~qg_explicito && cfg.fluido.GLR > 0 && any(ql_dem < -cfg.tol_balance_m3s)))
    error(['AOSCAD HID DEV1: inyeccion con gas / multifasico con flujo reverso ' ...
           'no soportada.']);
  endif
  if ~qg_explicito && cfg.fluido.GLR > 0
    qg_dem = ql_dem * cfg.fluido.GLR;
  endif

  ql_inyeccion = zeros(1, nN);
  for i = 1:nN
    if ql_dem(i) < -cfg.tol_balance_m3s
      ql_inyeccion(i) = -ql_dem(i);
    endif
  endfor

  n_fuentes = numel(nodos_presion);
  requiere_solver_lazos = ciclo || n_fuentes > 1 || hay_inyeccion;

  % Agregacion bottom-up sobre el arbol de expansion (init / camino arbol).
  ql_sub = ql_dem; qg_sub = qg_dem;
  ql_edge = zeros(1, nE); qg_edge = zeros(1, nE);
  edge_parent = zeros(1, nE); edge_child = zeros(1, nE);
  for kk = numel(order):-1:2
    v = order(kk); u = parent(v); e = parent_edge(v);
    ql_edge(e) = ql_sub(v); qg_edge(e) = qg_sub(v);
    edge_parent(e) = u; edge_child(e) = v;
    ql_sub(u) = ql_sub(u) + ql_sub(v);
    qg_sub(u) = qg_sub(u) + qg_sub(v);
  endfor

  % Clasificacion topologica
  grado = zeros(1, nN);
  for e = 1:nE
    if ~active_edge(e), continue; endif
    grado(e_o(e)) = grado(e_o(e)) + 1;
    grado(e_d(e)) = grado(e_d(e)) + 1;
  endfor
  n_bif = sum(grado >= 3);
  if ciclo && n_fuentes > 1
    clase = 'CON_LAZOS_MULTIFUENTE';
  elseif ciclo
    clase = 'CON_LAZOS';
  elseif n_fuentes > 1
    clase = 'ARBOL_MULTIFUENTE';
  elseif n_bif > 0
    clase = 'ARBOL_RAMIFICADO';
  else
    clase = 'CADENA_SERIE';
  endif

  n_lazos_indep = max(0, n_comp_edges - n_comp_nodes + 1);

  red = struct();
  red.nodos = nodos; red.tramos = tramos; red.bcs = bcs;
  red.ids_nodo = ids; red.e_o = e_o; red.e_d = e_d;
  red.root = root; red.P_root_Pa = P_root;
  red.nodos_presion = nodos_presion;
  red.P_nodos_Pa = P_nodos;
  red.visited = visited; red.active_edge = active_edge;
  red.parent = parent; red.parent_edge = parent_edge; red.order = order;
  red.edge_parent = edge_parent; red.edge_child = edge_child;
  red.ql_demanda_m3s = ql_dem; red.qg_demanda_std_m3s = qg_dem;
  red.ql_edge_m3s = ql_edge; red.qg_edge_std_m3s = qg_edge;
  red.ql_total_m3s = ql_sub(root); red.qg_total_std_m3s = qg_sub(root);
  red.ql_inyeccion_m3s = ql_inyeccion;
  red.tiene_lazos = ciclo;
  red.clase_topologia = clase;
  red.n_lazos_independientes = n_lazos_indep;
  red.requiere_solver_lazos = requiere_solver_lazos;
  red.valvulas = get_rows_local(te, 'valvulas');
  red.equipos = get_rows_local(te, 'equipos');
  red.dominio_hidraulico = dominio_activo;
  if isempty(dominio_activo), red.dominio_id = ''; else red.dominio_id = char(dominio_activo.id); endif

  if requiere_solver_lazos
    [base_lazos, ~] = aos_cad_hidraulica_lazos_base(red, cfg);
    red.aristas_cuerda = base_lazos.aristas_cuerda;
    red.lazos_fundamentales = base_lazos.lazos;
    red.n_lazos_independientes = base_lazos.n_lazos_reales;
  else
    red.aristas_cuerda = [];
    red.lazos_fundamentales = {};
  endif
endfunction

function rows = get_rows_local(s, campo)
  rows = {};
  if isstruct(s) && isfield(s, campo) && ~isempty(s.(campo))
    rows = s.(campo);
    if isstruct(rows), rows = num2cell(rows); endif
  endif
endfunction

function i = buscar_id_local(ids, id)
  i = 0;
  for k = 1:numel(ids)
    if strcmp(ids{k}, id), i = k; return; endif
  endfor
endfunction

function v = getf_local(s, f, d)
  if isstruct(s) && isfield(s, f), v = s.(f); else v = d; endif
endfunction

function id = id_tramo_local(tr, i)
  id = sprintf('T%03d', i);
  if isstruct(tr) && isfield(tr, 'id'), id = char(tr.id); endif
endfunction

function P = convertir_presion_local(v, u)
  P = v; u = upper(strtrim(u));
  if any(strcmp(u, {'BAR','BARA','BAR_A'})), P = v * 1e5;
  elseif any(strcmp(u, {'KPA'})), P = v * 1e3;
  elseif any(strcmp(u, {'MPA'})), P = v * 1e6;
  elseif any(strcmp(u, {'PSI','PSIA'})), P = v * 6894.757293;
  endif
endfunction

function Q = convertir_caudal_local(v, u)
  Q = v; u = upper(strrep(strtrim(u), ' ', ''));
  if any(strcmp(u, {'M3/D','M3D','M^3/D'})), Q = v / 86400;
  elseif any(strcmp(u, {'M3/H','M3H','M^3/H'})), Q = v / 3600;
  elseif any(strcmp(u, {'L/S','LPS'})), Q = v / 1000;
  elseif any(strcmp(u, {'SM3/D','SM3D'})), Q = v / 86400;
  elseif any(strcmp(u, {'SM3/H','SM3H'})), Q = v / 3600;
  endif
endfunction

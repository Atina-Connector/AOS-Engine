function [diag, items] = aos_cad_hidraulica_diagnosticar_topologia(modelo, cfg)
% AOS_CAD_HIDRAULICA_DIAGNOSTICAR_TOPOLOGIA Diagnostico estructurado DEV1/R13.
% No lanza error: reporta grado, bifurcaciones, lazos y fuentes en items.
  if nargin < 2 || isempty(cfg)
    cfg = aos_cad_hidraulica_defaults(modelo);
  endif
  items = {};
  diag = struct( ...
    'grado_por_nodo', [], ...
    'nodos_bifurcacion', {{}}, ...
    'n_bifurcaciones', 0, ...
    'tiene_lazos', false, ...
    'n_lazos_independientes', 0, ...
    'n_pseudolazos', 0, ...
    'n_fuentes_presion', 0, ...
    'nodos_desconectados', {{}}, ...
    'topologia', 'DESCONECTADA', ...
    'clase_topologia', 'DESCONECTADA', ...
    'solver_requerido', 'HYD_TREE', ...
    'ids_nodo', {{}}, ...
    'root', 0);

  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada')
    items{end+1} = item_local('HID_TRAMOS_DESCONECTADOS', ...
      'Modelo sin tablas_entrada; no se puede diagnosticar la red.', 'ERROR');
    return;
  endif

  try
    [modelo_red, ~] = aos_cad_hidraulica_dominio_filtrar_modelo(modelo);
  catch err
    items{end+1} = item_local('HID_TRAMOS_DESCONECTADOS', err.message, 'ERROR');
    return;
  end_try_catch

  te = modelo_red.tablas_entrada;
  nodos = get_rows_local(te, 'nodos');
  tramos = get_rows_local(te, 'tramos');
  bcs = get_rows_local(te, 'condiciones_borde');
  if isempty(nodos) || isempty(tramos)
    items{end+1} = item_local('HID_TRAMOS_DESCONECTADOS', ...
      'La red no tiene nodos o tramos suficientes.', 'ERROR');
    return;
  endif

  nN = numel(nodos); nE = numel(tramos);
  ids = cell(1, nN);
  for i = 1:nN
    ids{i} = char(nodos{i}.id);
  endfor
  diag.ids_nodo = ids;

  e_o = zeros(1, nE); e_d = zeros(1, nE);
  adj_n = cell(1, nN); adj_e = cell(1, nN);
  for i = 1:nN, adj_n{i} = []; adj_e{i} = []; endfor
  tramos_invalidos = 0;
  for e = 1:nE
    tr = tramos{e};
    io = buscar_id_local(ids, char(tr.nodo_o));
    id = buscar_id_local(ids, char(tr.nodo_d));
    if io == 0 || id == 0 || io == id
      tramos_invalidos = tramos_invalidos + 1;
      continue;
    endif
    e_o(e) = io; e_d(e) = id;
    adj_n{io}(end+1) = id; adj_e{io}(end+1) = e;
    adj_n{id}(end+1) = io; adj_e{id}(end+1) = e;
  endfor

  grado = zeros(1, nN);
  for i = 1:nN
    grado(i) = numel(adj_n{i});
  endfor
  diag.grado_por_nodo = grado;

  bif_idx = find(grado >= 3);
  diag.n_bifurcaciones = numel(bif_idx);
  nodos_bif = {};
  for k = 1:numel(bif_idx)
    nodos_bif{end+1} = ids{bif_idx(k)}; %#ok<AGROW>
    items{end+1} = item_local('HID_BIFURCACION_DETECTADA', ...
      sprintf('Nodo %s con grado %d.', ids{bif_idx(k)}, grado(bif_idx(k))), ...
      'INFO'); %#ok<AGROW>
  endfor
  diag.nodos_bifurcacion = nodos_bif;

  p_nodes = [];
  ql_dem = zeros(1, nN); qg_dem = zeros(1, nN);
  for i = 1:numel(bcs)
    bc = bcs{i};
    if ~isfield(bc, 'nodo_ref'), continue; endif
    ni = buscar_id_local(ids, char(bc.nodo_ref));
    if ni == 0, continue; endif
    tipo = upper(strtrim(char(getf_local(bc, 'tipo_bc', ''))));
    valor = aos_aoscad_valor(getf_local(bc, 'valor', []));
    if isempty(valor), continue; endif
    unidad = char(getf_local(bc, 'unidad', ''));
    if strcmp(tipo, 'PRESION') || strcmp(tipo, 'PRESSURE')
      p_nodes(end+1) = ni; %#ok<AGROW>
    elseif any(strcmp(tipo, {'CAUDAL','CAUDAL_LIQUIDO','DEMANDA','FLOW','LIQUID_FLOW'}))
      ql_dem(ni) = ql_dem(ni) + convertir_caudal_local(valor, unidad);
    elseif any(strcmp(tipo, {'CAUDAL_GAS','CAUDAL_GAS_STD','QG','GAS_FLOW'}))
      qg_dem(ni) = qg_dem(ni) + convertir_caudal_local(valor, unidad);
    endif
  endfor

  p_unique = unique(p_nodes);
  diag.n_fuentes_presion = numel(p_unique);
  hay_inyeccion = any(ql_dem < -cfg.tol_balance_m3s) || any(qg_dem < -cfg.tol_balance_m3s);
  if diag.n_fuentes_presion == 0
    items{end+1} = item_local('HID_SIN_FUENTE_PRESION', ...
      'No hay BC de PRESION en la red.', 'ERROR');
  elseif diag.n_fuentes_presion > 1
    items{end+1} = item_local('HID_MULTIPLES_FUENTES_PRESION', ...
      sprintf(['Se encontraron %d nodos con BC de PRESION; se resuelven ' ...
               'por HYD_LOOP (pseudolazos).'], diag.n_fuentes_presion), 'INFO');
  endif

  if hay_inyeccion
    items{end+1} = item_local('HID_CAUDAL_NEGATIVO_NO_SOPORTADO', ...
      ['Existen caudales negativos (inyecciones); se resuelven por HYD_LOOP ' ...
       'con convencion de flujo reverso.'], 'INFO');
  endif

  visited = false(1, nN);
  parent = zeros(1, nN);
  ciclo = false;
  root = 0;
  if diag.n_fuentes_presion >= 1
    root = p_unique(1);
    diag.root = root;
    queue = zeros(1, nN); qh = 1; qt = 1;
    queue(1) = root; visited(root) = true;
    while qh <= qt
      u = queue(qh); qh = qh + 1;
      for k = 1:numel(adj_n{u})
        v = adj_n{u}(k);
        if ~visited(v)
          visited(v) = true; parent(v) = u;
          qt = qt + 1; queue(qt) = v;
        elseif parent(u) ~= v && parent(v) ~= u
          ciclo = true;
        endif
      endfor
    endwhile
  endif
  diag.tiene_lazos = ciclo;

  descon = {};
  for i = 1:nN
    if ~visited(i)
      descon{end+1} = ids{i}; %#ok<AGROW>
    endif
  endfor
  diag.nodos_desconectados = descon;

  active_edge = false(1, nE);
  for e = 1:nE
    if e_o(e) > 0 && e_d(e) > 0
      active_edge(e) = visited(e_o(e)) && visited(e_d(e));
    endif
  endfor
  n_descon_edges = sum(~active_edge) + tramos_invalidos;
  if diag.n_fuentes_presion >= 1 && (n_descon_edges > 0 || ~isempty(descon))
    items{end+1} = item_local('HID_TRAMOS_DESCONECTADOS', ...
      sprintf('Hay %d tramo(s) o nodo(s) fuera del componente del BC de presion.', ...
              max(n_descon_edges, numel(descon))), 'ERROR');
  endif

  N_act = sum(visited);
  E_act = sum(active_edge);
  F = diag.n_fuentes_presion;
  n_lazos = max(0, E_act - N_act + 1);
  n_pseudo = max(0, F - 1);
  diag.n_lazos_independientes = n_lazos;
  diag.n_pseudolazos = n_pseudo;

  if ciclo
    items{end+1} = item_local('HID_LAZOS_DETECTADOS', ...
      sprintf('Se detectaron %d lazo(s) independiente(s); solver HYD_LOOP.', ...
              n_lazos), 'INFO');
  endif

  requiere_loop = ciclo || F > 1 || hay_inyeccion;
  if requiere_loop
    diag.solver_requerido = 'HYD_LOOP';
  else
    diag.solver_requerido = 'HYD_TREE';
  endif

  if ciclo && F > 1
    diag.topologia = 'CON_LAZOS_MULTIFUENTE';
  elseif ciclo
    diag.topologia = 'CON_LAZOS';
  elseif F > 1 && isempty(descon) && n_descon_edges == 0
    diag.topologia = 'ARBOL_MULTIFUENTE';
  elseif F < 1 || ~isempty(descon) || n_descon_edges > 0
    diag.topologia = 'DESCONECTADA';
  elseif diag.n_bifurcaciones > 0
    diag.topologia = 'ARBOL_RAMIFICADO';
    items{end+1} = item_local('HID_TOPOLOGIA_ARBOL_RAMIFICADO', ...
      sprintf('Arbol ramificado con %d bifurcacion(es).', diag.n_bifurcaciones), ...
      'INFO');
  else
    diag.topologia = 'CADENA_SERIE';
  endif
  diag.clase_topologia = diag.topologia;
endfunction

function it = item_local(codigo, mensaje, severidad)
  it = struct('codigo', codigo, 'mensaje', mensaje, 'severidad', severidad);
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

function Q = convertir_caudal_local(v, u)
  Q = v; u = upper(strrep(strtrim(u), ' ', ''));
  if any(strcmp(u, {'M3/D','M3D','M^3/D'})), Q = v / 86400;
  elseif any(strcmp(u, {'M3/H','M3H','M^3/H'})), Q = v / 3600;
  elseif any(strcmp(u, {'L/S','LPS'})), Q = v / 1000;
  elseif any(strcmp(u, {'SM3/D','SM3D'})), Q = v / 86400;
  elseif any(strcmp(u, {'SM3/H','SM3H'})), Q = v / 3600;
  endif
endfunction

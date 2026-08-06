function [base, items] = aos_cad_hidraulica_lazos_base(red, cfg)
% AOS_CAD_HIDRAULICA_LAZOS_BASE Topologia pura de lazos fundamentales y pseudolazos.
% Sin fisica y sin error(): reporta inconsistencias como items estructurados.
  if nargin < 2 || isempty(cfg), cfg = struct(); endif
  items = {};
  base = struct( ...
    'aristas_arbol', [], ...
    'aristas_cuerda', [], ...
    'n_lazos_reales', 0, ...
    'n_pseudolazos', 0, ...
    'lazos', {{}}, ...
    'matriz_signos', [], ...
    'aristas_excluidas', [], ...
    'grados_libertad', 0, ...
    'conectado', true);

  nN = numel(red.nodos); nE = numel(red.tramos);
  active = false(1, nE);
  if isfield(red, 'active_edge') && ~isempty(red.active_edge)
    active = logical(red.active_edge);
  else
    active = true(1, nE);
  endif

  % Valvulas cerradas: excluir aristas incidentes al nodo (nodo_o O nodo_d).
  % Motivo: perdidas_menores se evaluan en nodo_out real; en Q>=0 eso es nodo_d
  % y en Q<0 es nodo_o. Newton/FD exploran ambos signos, asi que dejar la arista
  % activa con valvula solo en nodo_o podria inyectar Inf en el residual.
  excluidas = [];
  valvulas = {};
  if isfield(red, 'valvulas') && ~isempty(red.valvulas)
    valvulas = red.valvulas;
    if isstruct(valvulas), valvulas = num2cell(valvulas); endif
  endif
  nodos_cerrados = {};
  for i = 1:numel(valvulas)
    v = valvulas{i};
    if ~isstruct(v) || ~isfield(v, 'nodo_ref'), continue; endif
    estado = 'ABIERTA';
    if isfield(v, 'estado'), estado = upper(char(valor_texto_local(v.estado))); endif
    if any(strcmp(estado, {'CERRADA', 'CLOSED'}))
      nodos_cerrados{end+1} = char(v.nodo_ref); %#ok<AGROW>
    endif
  endfor
  for e = 1:nE
    if ~active(e), continue; endif
    id_o = char(red.nodos{red.e_o(e)}.id);
    id_d = char(red.nodos{red.e_d(e)}.id);
    hit_o = any(strcmp(nodos_cerrados, id_o));
    hit_d = any(strcmp(nodos_cerrados, id_d));
    if hit_o || hit_d
      excluidas(end+1) = e; %#ok<AGROW>
      active(e) = false;
      if hit_o
        nid_hit = id_o;
      else
        nid_hit = id_d;
      endif
      items{end+1} = item_local('HID_LAZO_VALVULA_CERRADA_REDUCE_BASE', ...
        sprintf('Tramo %s excluido de la base por valvula cerrada en %s.', ...
                id_tramo_local(red.tramos{e}, e), nid_hit), 'ADVERTENCIA'); %#ok<AGROW>
    endif
  endfor
  base.aristas_excluidas = excluidas;

  % Fuentes de presion
  if isfield(red, 'nodos_presion') && ~isempty(red.nodos_presion)
    fuentes = red.nodos_presion(:)';
  else
    fuentes = red.root;
  endif
  F = numel(fuentes);
  root = fuentes(1);

  % BFS arbol de expansion sobre grafo reducido
  visited = false(1, nN);
  parent = zeros(1, nN); parent_edge = zeros(1, nN);
  adj_n = cell(1, nN); adj_e = cell(1, nN);
  for i = 1:nN, adj_n{i} = []; adj_e{i} = []; endfor
  for e = 1:nE
    if ~active(e), continue; endif
    io = red.e_o(e); id = red.e_d(e);
    adj_n{io}(end+1) = id; adj_e{io}(end+1) = e;
    adj_n{id}(end+1) = io; adj_e{id}(end+1) = e;
  endfor

  queue = zeros(1, nN); qh = 1; qt = 1;
  queue(1) = root; visited(root) = true;
  aristas_arbol = [];
  while qh <= qt
    u = queue(qh); qh = qh + 1;
    for k = 1:numel(adj_n{u})
      v = adj_n{u}(k); e = adj_e{u}(k);
      if ~visited(v)
        visited(v) = true; parent(v) = u; parent_edge(v) = e;
        aristas_arbol(end+1) = e; %#ok<AGROW>
        qt = qt + 1; queue(qt) = v;
      endif
    endfor
  endwhile

  % Conectividad del componente activo con demandas/fuentes
  for i = 1:nN
    if ~visited(i)
      dem = 0;
      if isfield(red, 'ql_demanda_m3s'), dem = red.ql_demanda_m3s(i); endif
      es_fuente = any(fuentes == i);
      if es_fuente || abs(dem) > 0
        base.conectado = false;
        items{end+1} = item_local('HID_LAZO_BASE_INCONSISTENTE', ...
          sprintf('Nodo activo %s queda desconectado tras retirar valvulas cerradas.', ...
                  char(red.ids_nodo{i})), 'ERROR'); %#ok<AGROW>
      endif
    endif
  endfor

  tree_edge = false(1, nE);
  tree_edge(aristas_arbol) = true;
  cuerdas = [];
  for e = 1:nE
    if active(e) && ~tree_edge(e)
      cuerdas(end+1) = e; %#ok<AGROW>
    endif
  endfor

  N_act = sum(visited);
  E_act = sum(active);
  n_lazos_reales = max(0, E_act - N_act + 1);
  n_pseudolazos = max(0, F - 1);
  grados_libertad = E_act - (N_act - F);

  lazos = {};
  % Lazos fundamentales (uno por cuerda)
  for ic = 1:numel(cuerdas)
    e = cuerdas(ic);
    [aristas, signos, nodos_ciclo] = ciclo_fundamental_local(red, e, parent, parent_edge);
    lazo = struct();
    lazo.tipo = 'FUNDAMENTAL';
    lazo.aristas = aristas;
    lazo.signos = signos;
    lazo.nodos = nodos_ciclo;
    lazo.fuente_a = 0;
    lazo.fuente_b = 0;
    lazo.cuerda = e;
    lazos{end+1} = lazo; %#ok<AGROW>
  endfor

  % Pseudolazos entre fuente de referencia y cada otra fuente
  for ifu = 2:F
    fb = fuentes(ifu);
    if ~visited(fb)
      continue;
    endif
    [aristas, signos, nodos_camino] = camino_arbol_local(red, root, fb, parent, parent_edge);
    lazo = struct();
    lazo.tipo = 'PSEUDO';
    lazo.aristas = aristas;
    lazo.signos = signos;
    lazo.nodos = nodos_camino;
    lazo.fuente_a = root;
    lazo.fuente_b = fb;
    lazo.cuerda = 0;
    lazos{end+1} = lazo; %#ok<AGROW>
  endfor

  nL = numel(lazos);
  matriz = zeros(nL, nE);
  for i = 1:nL
    for k = 1:numel(lazos{i}.aristas)
      ee = lazos{i}.aristas(k);
      matriz(i, ee) = lazos{i}.signos(k);
    endfor
  endfor

  if nL ~= grados_libertad && base.conectado
    items{end+1} = item_local('HID_LAZO_BASE_INCONSISTENTE', ...
      sprintf('Conteo de lazos inconsistente: nL=%d vs E-(N-F)=%d (E=%d,N=%d,F=%d).', ...
              nL, grados_libertad, E_act, N_act, F), 'ERROR');
  endif

  base.aristas_arbol = aristas_arbol;
  base.aristas_cuerda = cuerdas;
  base.n_lazos_reales = n_lazos_reales;
  base.n_pseudolazos = numel(lazos) - numel(cuerdas);
  base.lazos = lazos;
  base.matriz_signos = matriz;
  base.grados_libertad = grados_libertad;
  base.parent = parent;
  base.parent_edge = parent_edge;
  base.visited = visited;
  base.active_edge_efectivo = active;
endfunction

function [aristas, signos, nodos_ciclo] = ciclo_fundamental_local(red, e_chord, parent, parent_edge)
  a = red.e_o(e_chord); b = red.e_d(e_chord);
  [path_a, edges_a] = path_to_root_local(a, parent, parent_edge);
  [path_b, edges_b] = path_to_root_local(b, parent, parent_edge);
  % LCA
  mark = false(1, max(numel(parent), max(a, b)));
  for i = 1:numel(path_a), mark(path_a(i)) = true; endfor
  lca = b;
  for i = 1:numel(path_b)
    if mark(path_b(i)), lca = path_b(i); break; endif
  endfor
  % Camino a -> LCA -> b, luego cuerda b->a cierra (recorrido a->...->b->a)
  aristas = []; signos = [];
  u = a;
  while u ~= lca && parent(u) > 0
    e = parent_edge(u);
    p = parent(u);
    % recorrido u -> p (hacia la raiz)
    if red.e_o(e) == u && red.e_d(e) == p
      aristas(end+1) = e; signos(end+1) = 1; %#ok<AGROW>
    else
      aristas(end+1) = e; signos(end+1) = -1; %#ok<AGROW>
    endif
    u = p;
  endwhile
  % LCA -> b: invertir el tramo b->LCA
  stack_e = []; stack_s = [];
  u = b;
  while u ~= lca && parent(u) > 0
    e = parent_edge(u);
    p = parent(u);
    % recorrido p -> u (alejandose de la raiz)
    if red.e_o(e) == p && red.e_d(e) == u
      stack_e(end+1) = e; stack_s(end+1) = 1; %#ok<AGROW>
    else
      stack_e(end+1) = e; stack_s(end+1) = -1; %#ok<AGROW>
    endif
    u = p;
  endwhile
  for i = numel(stack_e):-1:1
    aristas(end+1) = stack_e(i); signos(end+1) = stack_s(i); %#ok<AGROW>
  endfor
  % Cuerda en sentido a -> b? Recorrido cierra b -> a, o a->...->b con cuerda b->a
  % Tras llegar a b, cerramos con cuerda de b hacia a:
  if red.e_o(e_chord) == b && red.e_d(e_chord) == a
    aristas(end+1) = e_chord; signos(end+1) = 1;
  else
    % geometric o=a,d=b: recorrer b->a es sentido inverso
    aristas(end+1) = e_chord; signos(end+1) = -1;
  endif
  nodos_ciclo = unique([path_a, path_b]);
endfunction

function [aristas, signos, nodos_camino] = camino_arbol_local(red, a, b, parent, parent_edge)
  [path_a, ~] = path_to_root_local(a, parent, parent_edge);
  [path_b, ~] = path_to_root_local(b, parent, parent_edge);
  mark = false(1, max(numel(parent), max(a, b)));
  for i = 1:numel(path_a), mark(path_a(i)) = true; endfor
  lca = b;
  for i = 1:numel(path_b)
    if mark(path_b(i)), lca = path_b(i); break; endif
  endfor
  aristas = []; signos = [];
  u = a;
  while u ~= lca && parent(u) > 0
    e = parent_edge(u); p = parent(u);
    if red.e_o(e) == u && red.e_d(e) == p
      aristas(end+1) = e; signos(end+1) = 1; %#ok<AGROW>
    else
      aristas(end+1) = e; signos(end+1) = -1; %#ok<AGROW>
    endif
    u = p;
  endwhile
  stack_e = []; stack_s = [];
  u = b;
  while u ~= lca && parent(u) > 0
    e = parent_edge(u); p = parent(u);
    if red.e_o(e) == p && red.e_d(e) == u
      stack_e(end+1) = e; stack_s(end+1) = 1; %#ok<AGROW>
    else
      stack_e(end+1) = e; stack_s(end+1) = -1; %#ok<AGROW>
    endif
    u = p;
  endwhile
  for i = numel(stack_e):-1:1
    aristas(end+1) = stack_e(i); signos(end+1) = stack_s(i); %#ok<AGROW>
  endfor
  nodos_camino = unique([path_a, path_b]);
endfunction

function [path, edges] = path_to_root_local(u, parent, parent_edge)
  path = u; edges = [];
  while parent(u) > 0
    edges(end+1) = parent_edge(u); %#ok<AGROW>
    u = parent(u);
    path(end+1) = u; %#ok<AGROW>
  endwhile
endfunction

function it = item_local(codigo, mensaje, severidad)
  it = struct('codigo', codigo, 'mensaje', mensaje, 'severidad', severidad);
endfunction

function id = id_tramo_local(tr, e)
  id = sprintf('T%03d', e);
  if isstruct(tr) && isfield(tr, 'id'), id = char(tr.id); endif
endfunction

function t = valor_texto_local(v)
  if isstruct(v), v = aos_aoscad_valor(v); endif
  if ischar(v), t = v; elseif isnumeric(v), t = num2str(v); else t = ''; endif
endfunction

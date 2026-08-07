function topologia = aos_cad_construir_topologia(tol_m, silencioso)
% AOS_CAD_CONSTRUIR_TOPOLOGIA Deriva topologia secundaria desde tablas (tol 0.05 m).
% Marca INFERIDA_POR_PROXIMIDAD vs CONFIRMADA. No escribe .aostopo como contrato.
  global CONFIG_ACTIVA;
  if nargin < 1 || isempty(tol_m), tol_m = 0.05; endif
  if nargin < 2, silencioso = false; endif

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOS CAD_TOPO: ejecute import/normalizacion antes de construir topologia.');
  endif

  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  nodos = modelo.tablas_entrada.nodos;
  tramos = modelo.tablas_entrada.tramos;

  % Fusionar nodos por proximidad (servicio geometry_3d)
  [nodos, mapa] = aos_geom_fusionar_por_tolerancia(nodos, tol_m);

  aristas = {};
  for i = 1:numel(tramos)
    tr = tramos{i};
    id_o = remap_local(mapa, tr.nodo_o);
    id_d = remap_local(mapa, tr.nodo_d);
    tramos{i}.nodo_o = id_o; %#ok<AGROW>
    tramos{i}.nodo_d = id_d; %#ok<AGROW>

    % Heuristica: endpoints dentro de tol respecto a nodos => CONFIRMADA
    estado = 'INFERIDA_POR_PROXIMIDAD';
    no = buscar_nodo_local(nodos, id_o);
    nd = buscar_nodo_local(nodos, id_d);
    if ~isempty(no) && ~isempty(nd) && isfield(tr, 'x1')
      d1 = hypot(tr.x1 - no.x, tr.y1 - no.y);
      d2 = hypot(tr.x2 - nd.x, tr.y2 - nd.y);
      if d1 <= tol_m && d2 <= tol_m
        estado = 'CONFIRMADA';
      endif
    endif

    a = struct();
    a.id = sprintf('E%03d', numel(aristas) + 1);
    a.tramo_ref = tr.id;
    a.nodo_o = id_o;
    a.nodo_d = id_d;
    a.estado_conexion = estado;
    aristas{end+1} = a; %#ok<AGROW>
  endfor

  topologia = struct();
  topologia.origen = 'DERIVADA_DE_TABLAS';
  topologia.tolerancia_m = tol_m;
  topologia.aristas = aristas;
  topologia.nodos_grafo = nodos;
  topologia.n_nodos = numel(nodos);
  topologia.n_aristas = numel(aristas);

  modelo.tablas_entrada.nodos = nodos;
  modelo.tablas_entrada.tramos = tramos;
  modelo.topologia = topologia;

  % Refrescar puertos con estado_conexion de aristas (contrato solo-datos)
  try
    [modelo, ~] = aos_cad_puertos_derivar(modelo);
  catch
  end_try_catch

  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.topologia = topologia; % representacion secundaria

  % Validaciones topologicas minimas (vuelcan a modelo.validaciones)
  try
    aos_cad_validar_topologia(true);
  catch
  end_try_catch

  if ~silencioso
    n_conf = 0; n_inf = 0;
    for i = 1:numel(aristas)
      if strcmp(aristas{i}.estado_conexion, 'CONFIRMADA')
        n_conf = n_conf + 1;
      else
        n_inf = n_inf + 1;
      endif
    endfor
    fprintf('\n--- TOPOLOGIA DERIVADA (secundaria) ---\n');
    fprintf('tolerancia  : %.3f m\n', tol_m);
    fprintf('nodos       : %d\n', numel(nodos));
    fprintf('aristas     : %d (CONFIRMADA=%d, INFERIDA=%d)\n', ...
      numel(aristas), n_conf, n_inf);
    fprintf('Nota: contrato Suite/Viewer es .aoscad (tablas), no .aostopo.\n');
  endif
endfunction

function id = remap_local(mapa, id0)
  id = id0;
  if isstruct(mapa) && isfield(mapa, id0)
    id = mapa.(id0);
  endif
endfunction

function n = buscar_nodo_local(nodos, id)
  n = [];
  for i = 1:numel(nodos)
    if strcmp(nodos{i}.id, id)
      n = nodos{i};
      return;
    endif
  endfor
endfunction

function [modelo, items] = aos_cad_puertos_derivar(modelo)
% AOS_CAD_PUERTOS_DERIVAR Deriva dos puertos por tramo (origen/destino).
% Contrato solo-datos: id, tipo ENTRADA|SALIDA, posicion, asset_id_componente,
% nodo_ref, estado_conexion. Persiste en modelo.tablas_entrada.puertos.
% Sin logica 3D, sin interferencias, sin validador de conectividad 3D.
%
% [modelo, items] = aos_cad_puertos_derivar(modelo)
%   Preferible despues de asignar asset_id; si hay topologia.aristas, hereda
%   estado_conexion por tramo_ref.

  items = {};
  if nargin < 1 || isempty(modelo) || ~isstruct(modelo)
    return;
  endif
  if ~isfield(modelo, 'tablas_entrada') || ~isstruct(modelo.tablas_entrada)
    return;
  endif

  tramos = {};
  if isfield(modelo.tablas_entrada, 'tramos')
    tramos = modelo.tablas_entrada.tramos;
  endif
  if isempty(tramos)
    modelo.tablas_entrada.puertos = {};
    return;
  endif
  if ~iscell(tramos), tramos = {tramos}; endif

  nodos = {};
  if isfield(modelo.tablas_entrada, 'nodos')
    nodos = modelo.tablas_entrada.nodos;
  endif
  if ~isempty(nodos) && ~iscell(nodos), nodos = {nodos}; endif

  % Mapa tramo_id -> estado_conexion desde topologia (si existe)
  estado_por_tramo = struct();
  if isfield(modelo, 'topologia') && isstruct(modelo.topologia) ...
      && isfield(modelo.topologia, 'aristas') ...
      && ~isempty(modelo.topologia.aristas)
    aristas = modelo.topologia.aristas;
    if ~iscell(aristas), aristas = {aristas}; endif
    for i = 1:numel(aristas)
      a = aristas{i};
      if isempty(a) || ~isstruct(a), continue; endif
      if ~isfield(a, 'tramo_ref') || isempty(a.tramo_ref), continue; endif
      est = 'INFERIDA_POR_PROXIMIDAD';
      if isfield(a, 'estado_conexion') && ~isempty(a.estado_conexion)
        est = char(a.estado_conexion);
      endif
      key = clave_campo_local(char(a.tramo_ref));
      estado_por_tramo.(key) = est;
    endfor
  endif

  puertos = {};
  for i = 1:numel(tramos)
    tr = tramos{i};
    if isempty(tr) || ~isstruct(tr), continue; endif

    tid = '';
    if isfield(tr, 'id') && ~isempty(tr.id)
      tid = char(tr.id);
    else
      tid = sprintf('T%03d', i);
    endif

    aid = '';
    if isfield(tr, 'asset_id') && ~isempty(tr.asset_id)
      aid = char(tr.asset_id);
    endif

    id_o = '';
    id_d = '';
    if isfield(tr, 'nodo_o') && ~isempty(tr.nodo_o)
      id_o = char(tr.nodo_o);
    endif
    if isfield(tr, 'nodo_d') && ~isempty(tr.nodo_d)
      id_d = char(tr.nodo_d);
    endif

    [x1, y1, z1] = pos_extremo_local(tr, nodos, id_o, 'o');
    [x2, y2, z2] = pos_extremo_local(tr, nodos, id_d, 'd');

    est = 'INFERIDA_POR_PROXIMIDAD';
    key = clave_campo_local(tid);
    if isfield(estado_por_tramo, key)
      est = estado_por_tramo.(key);
    endif

    % Origen del tramo = ENTRADA; destino = SALIDA (flujo dirigido o->d)
    p_ent = struct();
    p_ent.id = [tid '_ENTRADA'];
    p_ent.tipo = 'ENTRADA';
    p_ent.posicion = struct('x', x1, 'y', y1, 'z', z1);
    p_ent.asset_id_componente = aid;
    p_ent.nodo_ref = id_o;
    p_ent.estado_conexion = est;
    puertos{end+1} = p_ent; %#ok<AGROW>

    p_sal = struct();
    p_sal.id = [tid '_SALIDA'];
    p_sal.tipo = 'SALIDA';
    p_sal.posicion = struct('x', x2, 'y', y2, 'z', z2);
    p_sal.asset_id_componente = aid;
    p_sal.nodo_ref = id_d;
    p_sal.estado_conexion = est;
    puertos{end+1} = p_sal; %#ok<AGROW>
  endfor

  modelo.tablas_entrada.puertos = puertos;
endfunction

function [x, y, z] = pos_extremo_local(tr, nodos, nodo_id, extremo)
  x = 0; y = 0; z = 0;
  if strcmp(extremo, 'o')
    if isfield(tr, 'x1') && isnumeric(tr.x1), x = double(tr.x1(1)); endif
    if isfield(tr, 'y1') && isnumeric(tr.y1), y = double(tr.y1(1)); endif
    if isfield(tr, 'z1') && isnumeric(tr.z1), z = double(tr.z1(1)); endif
  else
    if isfield(tr, 'x2') && isnumeric(tr.x2), x = double(tr.x2(1)); endif
    if isfield(tr, 'y2') && isnumeric(tr.y2), y = double(tr.y2(1)); endif
    if isfield(tr, 'z2') && isnumeric(tr.z2), z = double(tr.z2(1)); endif
  endif

  % Completar Z (y fallback XY) desde el nodo referido
  n = buscar_nodo_local(nodos, nodo_id);
  if ~isempty(n)
    if ~(isfield(tr, 'x1') || isfield(tr, 'x2'))
      if isfield(n, 'x') && isnumeric(n.x), x = double(n.x(1)); endif
      if isfield(n, 'y') && isnumeric(n.y), y = double(n.y(1)); endif
    endif
    if (~isfield(tr, 'z1') && ~isfield(tr, 'z2')) ...
        || (strcmp(extremo, 'o') && (~isfield(tr, 'z1') || isempty(tr.z1))) ...
        || (strcmp(extremo, 'd') && (~isfield(tr, 'z2') || isempty(tr.z2)))
      if isfield(n, 'z') && isnumeric(n.z) && ~isempty(n.z)
        z = double(n.z(1));
      endif
    endif
  endif
endfunction

function n = buscar_nodo_local(nodos, id)
  n = [];
  if isempty(id) || isempty(nodos), return; endif
  id = char(id);
  for i = 1:numel(nodos)
    ni = nodos{i};
    if isempty(ni) || ~isstruct(ni), continue; endif
    if isfield(ni, 'id') && strcmp(char(ni.id), id)
      n = ni;
      return;
    endif
  endfor
endfunction

function key = clave_campo_local(id)
  % Clave segura para struct dinamico (ids tipo T001)
  key = regexprep(char(id), '[^A-Za-z0-9_]', '_');
  if isempty(key), key = 'X'; endif
  if key(1) >= '0' && key(1) <= '9'
    key = ['T_' key];
  endif
endfunction

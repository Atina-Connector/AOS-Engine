function [tabla_conexiones, items] = aos_cad_conexiones_3d(puertos_3d, opciones)
% AOS_CAD_CONEXIONES_3D Empareja puertos 3D por nodo_ref y proximidad.
% Estados: CONECTADA | INFERIDA_POR_PROXIMIDAD | ABIERTA.
% Orden estable por indice de puerto. Claves CNX_*. Solo datos, sin graficos.
%
% [tabla_conexiones, items] = aos_cad_conexiones_3d(puertos_3d, opciones)
%   puertos_3d: salida de aos_cad_puertos_3d, cell de puertos, o modelo .aoscad
%   opciones.tolerancia_m: metros (default 0.05)
%
% Cada fila: id, puerto_a, puerto_b, nodo_ref, distancia_m, estado.
  if nargin < 1 || isempty(puertos_3d), puertos_3d = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  items = {};
  tabla_conexiones = {};

  tol = 0.05;
  if isfield(opciones, 'tolerancia_m') && isnumeric(opciones.tolerancia_m) ...
      && ~isempty(opciones.tolerancia_m) && isfinite(opciones.tolerancia_m(1))
    tol = double(opciones.tolerancia_m(1));
  endif

  [lista, items_res] = normalizar_puertos_local(puertos_3d, opciones);
  for k = 1:numel(items_res)
    items{end+1} = items_res{k}; %#ok<AGROW>
  endfor
  n = numel(lista);
  if n < 1, return; endif

  emparejado = false(1, n);
  conexiones = {};

  % --- 1) Emparejamiento por nodo_ref compartido ---
  grupos = struct();
  orden_grupos = {};
  for i = 1:n
    p = lista{i};
    nr = '';
    if isfield(p, 'nodo_ref') && ~isempty(p.nodo_ref)
      nr = char(p.nodo_ref);
    endif
    if isempty(nr), continue; endif
    gk = safe_key_local(nr);
    if ~isfield(grupos, gk)
      grupos.(gk) = i;
      orden_grupos{end+1} = gk; %#ok<AGROW>
      grupos.(['N_' gk]) = nr;
    else
      grupos.(gk)(end+1) = i; %#ok<AGROW>
    endif
  endfor

  for ig = 1:numel(orden_grupos)
    gk = orden_grupos{ig};
    idxs = grupos.(gk);
    nr = grupos.(['N_' gk]);
    if numel(idxs) < 2, continue; endif
    % Pares (i<j) en orden de indice de puerto (idxs ya en orden de aparicion)
    for a = 1:numel(idxs)
      for b = (a + 1):numel(idxs)
        ia = idxs(a); ib = idxs(b);
        [dist, ok_d] = distancia_puertos_local(lista{ia}, lista{ib});
        c = conexion_base_local(lista{ia}, lista{ib}, nr, dist, ok_d, 'CONECTADA');
        conexiones{end+1} = c; %#ok<AGROW>
        emparejado(ia) = true;
        emparejado(ib) = true;
      endfor
    endfor
  endfor

  % --- 2) Proximidad entre no emparejados (tol explicita en m) ---
  libres = find(~emparejado);
  usados_prox = false(1, n);
  for ii = 1:numel(libres)
    ia = libres(ii);
    if usados_prox(ia) || emparejado(ia), continue; endif
    if ~posicion_ok_local(lista{ia}), continue; endif
    best_j = 0;
    best_d = Inf;
    for jj = (ii + 1):numel(libres)
      ib = libres(jj);
      if usados_prox(ib) || emparejado(ib), continue; endif
      if ~posicion_ok_local(lista{ib}), continue; endif
      [dist, ok_d] = distancia_puertos_local(lista{ia}, lista{ib});
      if ~ok_d, continue; endif
      if dist <= tol && dist < best_d
        best_d = dist;
        best_j = ib;
      endif
    endfor
    if best_j > 0
      nr = '';
      if isfield(lista{ia}, 'nodo_ref') && ~isempty(lista{ia}.nodo_ref)
        nr = char(lista{ia}.nodo_ref);
      elseif isfield(lista{best_j}, 'nodo_ref') && ~isempty(lista{best_j}.nodo_ref)
        nr = char(lista{best_j}.nodo_ref);
      endif
      c = conexion_base_local(lista{ia}, lista{best_j}, nr, best_d, true, ...
        'INFERIDA_POR_PROXIMIDAD');
      conexiones{end+1} = c; %#ok<AGROW>
      emparejado(ia) = true;
      emparejado(best_j) = true;
      usados_prox(ia) = true;
      usados_prox(best_j) = true;
    endif
  endfor

  % --- 3) Puertos restantes => ABIERTA (orden por indice) ---
  for i = 1:n
    if emparejado(i), continue; endif
    p = lista{i};
    c = struct();
    c.id = '';
    c.puerto_a = char(p.id);
    c.puerto_b = '';
    c.nodo_ref = '';
    if isfield(p, 'nodo_ref') && ~isempty(p.nodo_ref)
      c.nodo_ref = char(p.nodo_ref);
    endif
    c.distancia_m = [];
    c.estado = 'ABIERTA';
    c.unidades = 'm';
    conexiones{end+1} = c; %#ok<AGROW>
  endfor

  % Asignar ids CNX_### en orden estable final
  for i = 1:numel(conexiones)
    conexiones{i}.id = sprintf('CNX_%03d', i);
    conexiones{i}.clave = ['CNX_' safe_key_local(conexiones{i}.id)];
  endfor

  tabla_conexiones = conexiones;
endfunction

function [lista, items] = normalizar_puertos_local(puertos_3d, opciones)
  lista = {};
  items = {};
  if iscell(puertos_3d)
    lista = puertos_3d;
    return;
  endif
  if ~isstruct(puertos_3d), return; endif

  if isfield(puertos_3d, 'lista') && iscell(puertos_3d.lista)
    lista = puertos_3d.lista;
    return;
  endif

  % Modelo .aoscad: materializar primero
  if isfield(puertos_3d, 'tablas_entrada')
    [p3, items] = aos_cad_puertos_3d(puertos_3d, opciones);
    if isfield(p3, 'lista'), lista = p3.lista; endif
    return;
  endif

  % Struct unico de puerto
  if isfield(puertos_3d, 'id')
    lista = {puertos_3d};
  endif
endfunction

function c = conexion_base_local(pa, pb, nodo_ref, dist, ok_d, estado)
  c = struct();
  c.id = '';
  c.puerto_a = char(pa.id);
  c.puerto_b = char(pb.id);
  c.nodo_ref = char(nodo_ref);
  if ok_d
    c.distancia_m = dist;
  else
    c.distancia_m = [];
  endif
  c.estado = char(estado);
  c.unidades = 'm';
  c.clave = '';
endfunction

function [d, ok] = distancia_puertos_local(pa, pb)
  d = [];
  ok = false;
  if ~posicion_ok_local(pa) || ~posicion_ok_local(pb), return; endif
  a = [double(pa.posicion.x(1)), double(pa.posicion.y(1)), double(pa.posicion.z(1))];
  b = [double(pb.posicion.x(1)), double(pb.posicion.y(1)), double(pb.posicion.z(1))];
  d = sqrt(sum((a - b) .^ 2));
  ok = isfinite(d);
endfunction

function tf = posicion_ok_local(p)
  tf = false;
  if ~isstruct(p), return; endif
  if isfield(p, 'posicion_resuelta') && ~p.posicion_resuelta, return; endif
  if ~isfield(p, 'posicion') || ~isstruct(p.posicion), return; endif
  pos = p.posicion;
  if ~isfield(pos, 'x') || ~isfield(pos, 'y') || ~isfield(pos, 'z'), return; endif
  if isempty(pos.x) || isempty(pos.y) || isempty(pos.z), return; endif
  if ~isnumeric(pos.x) || ~isnumeric(pos.y) || ~isnumeric(pos.z), return; endif
  tf = isfinite(pos.x(1)) && isfinite(pos.y(1)) && isfinite(pos.z(1));
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction

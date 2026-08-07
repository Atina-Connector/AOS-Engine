function caminos = aos_cad_hidraulica_encontrar_caminos(modelo, nodo_inicio, nodo_fin, max_caminos)
% Encuentra caminos simples entre dos nodos de la red AOSCAD.
% Devuelve una celda de structs ordenada por longitud creciente.
  if nargin < 4 || isempty(max_caminos)
    max_caminos = 32;
  endif
  max_caminos = max(1, round(max_caminos));
  caminos = {};

  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada')
    error('AOSCAD DOMINIO: modelo sin tablas_entrada.');
  endif
  nodos = filas_local(modelo.tablas_entrada, 'nodos');
  tramos = filas_local(modelo.tablas_entrada, 'tramos');
  if isempty(nodos) || isempty(tramos)
    error('AOSCAD DOMINIO: se requieren nodos y tramos.');
  endif

  ids = cell(1, numel(nodos));
  for i = 1:numel(nodos)
    ids{i} = char(nodos{i}.id);
  endfor
  indice_inicio = buscar_id_local(ids, char(nodo_inicio));
  indice_fin = buscar_id_local(ids, char(nodo_fin));
  if indice_inicio == 0
    error('AOSCAD DOMINIO: nodo inicial inexistente: %s', char(nodo_inicio));
  endif
  if indice_fin == 0
    error('AOSCAD DOMINIO: nodo final inexistente: %s', char(nodo_fin));
  endif
  if indice_inicio == indice_fin
    error('AOSCAD DOMINIO: los nodos inicial y final deben ser distintos en DEV1.');
  endif

  ady_nodos = cell(1, numel(nodos));
  ady_tramos = cell(1, numel(nodos));
  for i = 1:numel(nodos)
    ady_nodos{i} = [];
    ady_tramos{i} = [];
  endfor
  for e = 1:numel(tramos)
    tramo = tramos{e};
    io = buscar_id_local(ids, char(tramo.nodo_o));
    id = buscar_id_local(ids, char(tramo.nodo_d));
    if io == 0 || id == 0
      continue;
    endif
    ady_nodos{io}(end+1) = id;
    ady_tramos{io}(end+1) = e;
    ady_nodos{id}(end+1) = io;
    ady_tramos{id}(end+1) = e;
  endfor

  visitado = false(1, numel(nodos));
  visitar_local(indice_inicio, visitado, indice_inicio, [], 0);

  if numel(caminos) > 1
    longitudes = zeros(1, numel(caminos));
    for i = 1:numel(caminos)
      longitudes(i) = caminos{i}.longitud_m;
    endfor
    [~, orden] = sort(longitudes);
    caminos = caminos(orden);
    for i = 1:numel(caminos)
      caminos{i}.indice = i;
    endfor
  endif

  function visitar_local(nodo_actual, visitado_local, ruta_nodos, ruta_tramos, longitud)
    if numel(caminos) >= max_caminos
      return;
    endif
    if nodo_actual == indice_fin
      camino = struct();
      camino.indice = numel(caminos) + 1;
      camino.nodos = ids(ruta_nodos);
      camino.tramos = cell(1, numel(ruta_tramos));
      for jj = 1:numel(ruta_tramos)
        e = ruta_tramos(jj);
        camino.tramos{jj} = id_tramo_local(tramos{e}, e);
      endfor
      camino.longitud_m = longitud;
      caminos{end+1} = camino;
      return;
    endif

    visitado_local(nodo_actual) = true;
    for kk = 1:numel(ady_nodos{nodo_actual})
      vecino = ady_nodos{nodo_actual}(kk);
      arista = ady_tramos{nodo_actual}(kk);
      if visitado_local(vecino)
        continue;
      endif
      nueva_longitud = longitud + longitud_tramo_local( ...
        tramos{arista}, nodos{nodo_actual}, nodos{vecino});
      visitar_local(vecino, visitado_local, ...
        [ruta_nodos vecino], [ruta_tramos arista], nueva_longitud);
      if numel(caminos) >= max_caminos
        return;
      endif
    endfor
  endfunction
endfunction

function rows = filas_local(tablas, campo)
  rows = {};
  if isstruct(tablas) && isfield(tablas, campo) && ...
      ~isempty(tablas.(campo))
    rows = tablas.(campo);
    if isstruct(rows)
      rows = num2cell(rows);
    endif
  endif
endfunction

function indice = buscar_id_local(ids, id)
  indice = 0;
  for k = 1:numel(ids)
    if strcmp(ids{k}, id)
      indice = k;
      return;
    endif
  endfor
endfunction

function id = id_tramo_local(tramo, indice)
  id = sprintf('T%03d', indice);
  if isstruct(tramo) && isfield(tramo, 'id') && ~isempty(tramo.id)
    id = char(tramo.id);
  endif
endfunction

function longitud = longitud_tramo_local(tramo, nodo1, nodo2)
  longitud = 0;
  if isstruct(tramo) && isfield(tramo, 'longitud_m')
    valor = aos_aoscad_valor(tramo.longitud_m);
    if isnumeric(valor) && ~isempty(valor)
      longitud = valor(1);
    endif
  endif
  if longitud <= 0
    dx = coord_local(nodo2, 'x') - coord_local(nodo1, 'x');
    dy = coord_local(nodo2, 'y') - coord_local(nodo1, 'y');
    dz = coord_local(nodo2, 'z') - coord_local(nodo1, 'z');
    longitud = sqrt(dx^2 + dy^2 + dz^2);
  endif
  longitud = max(longitud, 0);
endfunction

function v = coord_local(nodo, campo)
  v = 0;
  if isstruct(nodo) && isfield(nodo, campo) && ...
      isnumeric(nodo.(campo)) && ~isempty(nodo.(campo))
    v = nodo.(campo)(1);
  elseif strcmp(campo, 'z') && isstruct(nodo) && isfield(nodo, 'cota')
    valor = aos_aoscad_valor(nodo.cota);
    if isnumeric(valor) && ~isempty(valor)
      v = valor(1);
    endif
  endif
endfunction

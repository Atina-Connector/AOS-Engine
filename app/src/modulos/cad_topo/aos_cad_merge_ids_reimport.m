function [modelo, reporte, id_index_new] = aos_cad_merge_ids_reimport(modelo, id_index_prev, silencioso)
% AOS_CAD_MERGE_IDS_REIMPORT Conserva IDs estables por handle (o clave STEP) al reimportar.
% Snapshot previo: CONFIG_ACTIVA.cad_topologia.id_index (handle -> id + tabla).
% Handles nuevos -> ALTA; ausentes -> BAJA (items en validaciones; no reinserta geometria).
  if nargin < 3, silencioso = false; endif
  if nargin < 2, id_index_prev = []; endif
  reporte = struct('n_reutilizados', 0, 'n_altas', 0, 'n_bajas', 0, ...
    'altas', {{}}, 'bajas', {{}});
  id_index_new = struct('por_handle', struct(), 'items', {{}});

  if nargin < 1 || isempty(modelo) || ~isstruct(modelo)
    return;
  endif

  if isempty(id_index_prev) || ~isstruct(id_index_prev)
    id_index_prev = struct('por_handle', struct(), 'items', {{}});
  endif
  if ~isfield(id_index_prev, 'por_handle') || ~isstruct(id_index_prev.por_handle)
    id_index_prev.por_handle = struct();
  endif

  tablas = {'nodos', 'tramos', 'equipos', 'valvulas', 'accesorios', ...
            'condiciones_borde', 'camaras', 'ramales', 'accesos'};
  vistos = {};

  for t = 1:numel(tablas)
    nom = tablas{t};
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    for i = 1:numel(filas)
      row = filas{i};
      key = clave_fila_local(row);
      if isempty(key)
        reporte.n_altas = reporte.n_altas + 1;
        reporte.altas{end+1} = struct('tabla', nom, 'id', char(row.id), 'handle', ''); %#ok<AGROW>
        continue;
      endif
      % Clave namespaced por tabla: evita colision CIRCLE→nodo+equipo (mismo handle).
      safe = key_safe_local([nom ':' key]);
      safe_legacy = key_safe_local(key);
      vistos{end+1} = safe; %#ok<AGROW>
      prev = [];
      if isfield(id_index_prev.por_handle, safe)
        prev = id_index_prev.por_handle.(safe);
      elseif isfield(id_index_prev.por_handle, safe_legacy)
        % Compat indices pre-fix: solo reusar si la entrada era de esta tabla
        % (o no declara tabla). Evita que equipos pisen ids de nodos.
        cand = id_index_prev.por_handle.(safe_legacy);
        tab_prev = '';
        if isfield(cand, 'tabla'), tab_prev = char(cand.tabla); endif
        if isempty(tab_prev) || strcmp(tab_prev, nom)
          prev = cand;
          vistos{end+1} = safe_legacy; %#ok<AGROW>
        endif
      endif
      if ~isempty(prev) && isfield(prev, 'id') && ~isempty(prev.id)
        row.id = char(prev.id);
        row.id_estable = char(prev.id);
        if isfield(prev, 'id_estable') && ~isempty(prev.id_estable)
          row.id_estable = char(prev.id_estable);
        endif
        reporte.n_reutilizados = reporte.n_reutilizados + 1;
      else
        reporte.n_altas = reporte.n_altas + 1;
        reporte.altas{end+1} = struct('tabla', nom, 'id', char(row.id), 'handle', key); %#ok<AGROW>
      endif
      filas{i} = row; %#ok<AGROW>
    endfor
    modelo.tablas_entrada.(nom) = filas;
  endfor

  if isfield(id_index_prev, 'por_handle')
    prev_keys = fieldnames(id_index_prev.por_handle);
    for i = 1:numel(prev_keys)
      k = prev_keys{i};
      if ~any(strcmp(vistos, k))
        prev = id_index_prev.por_handle.(k);
        idp = '';
        tab = '';
        if isfield(prev, 'id'), idp = char(prev.id); endif
        if isfield(prev, 'tabla'), tab = char(prev.tabla); endif
        reporte.n_bajas = reporte.n_bajas + 1;
        reporte.bajas{end+1} = struct('tabla', tab, 'id', idp, 'handle', k); %#ok<AGROW>
      endif
    endfor
  endif

  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'OK', 'items', {{}});
  endif
  if ~isfield(modelo.validaciones, 'items') || ~iscell(modelo.validaciones.items)
    modelo.validaciones.items = {};
  endif
  for i = 1:numel(reporte.altas)
    a = reporte.altas{i};
    modelo.validaciones.items{end+1} = struct( ...
      'codigo', 'ID_ALTA', ...
      'mensaje', sprintf('Alta %s id=%s handle=%s', a.tabla, a.id, a.handle), ...
      'severidad', 'INFO'); %#ok<AGROW>
  endfor
  for i = 1:numel(reporte.bajas)
    b = reporte.bajas{i};
    modelo.validaciones.items{end+1} = struct( ...
      'codigo', 'ID_BAJA', ...
      'mensaje', sprintf('Baja %s id=%s handle=%s (no reinsertado)', b.tabla, b.id, b.handle), ...
      'severidad', 'ADVERTENCIA'); %#ok<AGROW>
    if ~strcmp(modelo.validaciones.estado, 'ERROR')
      modelo.validaciones.estado = 'ADVERTENCIA';
    endif
  endfor

  id_index_new = build_index_from_modelo_local(modelo);

  if ~silencioso
    fprintf('Round-trip IDs: reutilizados=%d altas=%d bajas=%d\n', ...
      reporte.n_reutilizados, reporte.n_altas, reporte.n_bajas);
  endif
endfunction

function idx = build_index_from_modelo_local(modelo)
  idx = struct('por_handle', struct(), 'items', {{}});
  if isempty(modelo) || ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada')
    return;
  endif
  tablas = {'nodos', 'tramos', 'equipos', 'valvulas', 'accesorios', ...
            'condiciones_borde', 'camaras', 'ramales', 'accesos'};
  for t = 1:numel(tablas)
    nom = tablas{t};
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    for i = 1:numel(filas)
      row = filas{i};
      key = clave_fila_local(row);
      if isempty(key), continue; endif
      safe = key_safe_local([nom ':' key]);
      ent = struct();
      ent.handle = key;
      ent.id = char(row.id);
      ent.id_estable = '';
      if isfield(row, 'id_estable') && ~isempty(row.id_estable)
        ent.id_estable = char(row.id_estable);
      endif
      ent.tabla = nom;
      idx.por_handle.(safe) = ent;
      idx.items{end+1} = ent; %#ok<AGROW>
    endfor
  endfor
endfunction

function key = clave_fila_local(row)
  key = '';
  % INSERT: clave estable por bloque + posicion (sobrevive export REV con handles nuevos)
  if isfield(row, 'block_name') && ~isempty(row.block_name)
    x = 0; y = 0;
    if isfield(row, 'insert_x') && isnumeric(row.insert_x) && ~isempty(row.insert_x)
      x = row.insert_x(1);
    endif
    if isfield(row, 'insert_y') && isnumeric(row.insert_y) && ~isempty(row.insert_y)
      y = row.insert_y(1);
    endif
    key = sprintf('INSERT:%s:%.6f:%.6f', char(row.block_name), x, y);
    return;
  endif
  if isfield(row, 'handle') && ~isempty(row.handle)
    key = char(row.handle);
    return;
  endif
  if isfield(row, 'id_estable') && ~isempty(row.id_estable)
    key = ['IDEST:' char(row.id_estable)];
    return;
  endif
  if isfield(row, 'step_product') && ~isempty(row.step_product)
    key = ['STEP:' char(row.step_product)];
  endif
endfunction

function s = key_safe_local(key)
  s = upper(char(key));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'H_EMPTY'; endif
  if s(1) >= '0' && s(1) <= '9'
    s = ['H_' s];
  endif
endfunction

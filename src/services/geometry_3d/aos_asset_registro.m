function [registro, items] = aos_asset_registro(modelo)
% AOS_ASSET_REGISTRO Construye el registro de activos del modelo.
% Detecta colisiones de hash (misma asset_id, distinta clave) y desambigua
% con sufijo determinista; emite ASSET_ID_COLISION (nunca silencioso).
%
% [registro, items] = aos_asset_registro(modelo)

  registro = {};
  items = {};

  if nargin < 1 || isempty(modelo) || ~isstruct(modelo)
    return;
  endif
  if ~isfield(modelo, 'tablas_entrada') || ~isstruct(modelo.tablas_entrada)
    return;
  endif

  map_tabla = { ...
    'nodos', 'NODO'; ...
    'tramos', 'TRAMO'; ...
    'equipos', 'EQUIPO'; ...
    'valvulas', 'VALVULA'; ...
    'accesorios', 'ACCESORIO'; ...
    'condiciones_borde', 'BC'; ...
    'camaras', 'CAMARA'; ...
    'ramales', 'RAMAL'; ...
    'accesos', 'ACCESO'; ...
    'step_product', 'STEP_PRODUCT'; ...
    'step_products', 'STEP_PRODUCT'; ...
    'productos_step', 'STEP_PRODUCT'};

  pend = {};  % {asset_id0, clave, activo}

  for t = 1:size(map_tabla, 1)
    nom = map_tabla{t, 1};
    tipo = map_tabla{t, 2};
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    if isempty(filas), continue; endif
    if ~iscell(filas)
      filas = {filas};
    endif
    for i = 1:numel(filas)
      fila = filas{i};
      if isempty(fila) || ~isstruct(fila), continue; endif
      [aid, clave, adv] = aos_asset_id_generar(tipo, fila, nom, struct());
      act = activo_desde_fila_local(aid, tipo, fila, nom, clave, adv);
      pend{end+1} = struct('asset_id0', aid, 'clave', clave, 'activo', act); %#ok<AGROW>
    endfor
  endfor

  if isempty(pend)
    return;
  endif

  % Colisiones: misma asset_id0 con claves distintas
  ids0 = cell(size(pend));
  for i = 1:numel(pend)
    ids0{i} = pend{i}.asset_id0;
  endfor
  [uids, ~, ic] = unique(ids0, 'stable');

  for u = 1:numel(uids)
    idxs = find(ic == u);
    claves_u = cell(numel(idxs), 1);
    for k = 1:numel(idxs)
      claves_u{k} = pend{idxs(k)}.clave;
    endfor
    claves_dist = unique(claves_u, 'stable');
    if numel(claves_dist) <= 1
      for k = 1:numel(idxs)
        registro{end+1} = pend{idxs(k)}.activo; %#ok<AGROW>
      endfor
      continue;
    endif

    % Desambiguacion determinista: ordenar por clave, primero sin sufijo,
    % siguientes con -2, -3, ...
    claves_ord = sort(claves_dist);
    base_id = uids{u};
    for k = 1:numel(idxs)
      p = pend{idxs(k)};
      ii = find(strcmp(claves_ord, p.clave), 1);
      if isempty(ii)
        ii = 1;
      endif
      if ii == 1
        suf = '';
      else
        suf = sprintf('-%d', ii);
      endif
      aid_new = [base_id suf];
      p.activo.asset_id = aid_new;
      if isfield(p.activo, 'links') && isstruct(p.activo.links)
        p.activo.links.clave = p.clave;
      endif
      registro{end+1} = p.activo; %#ok<AGROW>

      items{end+1} = struct( ...
        'codigo', 'ASSET_ID_COLISION', ...
        'mensaje', sprintf('Colision hash asset_id=%s clave=%s -> %s', ...
          base_id, p.clave, aid_new), ...
        'severidad', 'ADVERTENCIA'); %#ok<AGROW>
    endfor
  endfor
endfunction

function act = activo_desde_fila_local(aid, tipo, fila, tabla, clave, adv)
  act = struct();
  act.asset_id = aid;
  act.asset_type = tipo;
  act.source = source_local(fila, tabla);
  if ~isempty(adv) && strcmp(adv, 'ASSET_CLAVE_NO_ESTABLE')
    act.validation_status = 'ADVERTENCIA';
  else
    act.validation_status = 'OK';
  endif
  act.location = location_local(fila);
  act.links = struct();
  act.links.id = '';
  if isfield(fila, 'id') && ~isempty(fila.id)
    act.links.id = char(fila.id);
  endif
  act.links.tabla = tabla;
  act.links.clave = clave;
  if ~isempty(adv)
    act.links.adv = adv;
  endif
endfunction

function src = source_local(fila, tabla)
  if isfield(fila, 'step_product') && ~isempty(fila.step_product)
    src = 'STEP';
    return;
  endif
  if strcmpi(tabla, 'step_product') || strcmpi(tabla, 'step_products') ...
      || strcmpi(tabla, 'productos_step')
    src = 'STEP';
    return;
  endif
  if isfield(fila, 'handle') || isfield(fila, 'capa') || isfield(fila, 'block_name')
    src = 'DXF';
    return;
  endif
  src = 'CAD';
endfunction

function loc = location_local(fila)
  loc = struct('x', [], 'y', [], 'z', [], 'unidad', 'm');
  if isfield(fila, 'x') && isnumeric(fila.x) && ~isempty(fila.x)
    loc.x = double(fila.x(1));
    loc.y = num_or_empty_local(fila, 'y');
    loc.z = num_or_empty_local(fila, 'z');
    if isempty(loc.z), loc.z = 0; endif
    return;
  endif
  if isfield(fila, 'insert_x') && isnumeric(fila.insert_x) && ~isempty(fila.insert_x)
    loc.x = double(fila.insert_x(1));
    loc.y = num_or_empty_local(fila, 'insert_y');
    loc.z = num_or_empty_local(fila, 'insert_z');
    if isempty(loc.z), loc.z = 0; endif
    return;
  endif
  if isfield(fila, 'x1') && isnumeric(fila.x1) && ~isempty(fila.x1) ...
      && isfield(fila, 'x2') && isnumeric(fila.x2) && ~isempty(fila.x2)
    y1 = num_or_empty_local(fila, 'y1'); if isempty(y1), y1 = 0; endif
    y2 = num_or_empty_local(fila, 'y2'); if isempty(y2), y2 = 0; endif
    loc.x = 0.5 * (double(fila.x1(1)) + double(fila.x2(1)));
    loc.y = 0.5 * (y1 + y2);
    loc.z = 0;
  endif
endfunction

function v = num_or_empty_local(fila, nom)
  v = [];
  if ~isfield(fila, nom), return; endif
  x = fila.(nom);
  if isnumeric(x) && ~isempty(x)
    v = double(x(1));
  endif
endfunction

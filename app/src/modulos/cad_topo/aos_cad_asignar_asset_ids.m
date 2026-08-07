function [modelo, items] = aos_cad_asignar_asset_ids(modelo)
% AOS_CAD_ASIGNAR_ASSET_IDS Asigna asset_id a filas y construye modelo.activos.
% Usa el servicio geometry_3d (aos_asset_id_generar / aos_asset_registro).
% Debe invocarse DESPUES de aos_cad_merge_ids_reimport (id_estable reconciliado).
%
% [modelo, items] = aos_cad_asignar_asset_ids(modelo)
%   items: advertencias ASSET_ID_COLISION u otras del registro

  items = {};
  if nargin < 1 || isempty(modelo) || ~isstruct(modelo)
    return;
  endif
  if ~isfield(modelo, 'tablas_entrada') || ~isstruct(modelo.tablas_entrada)
    modelo.activos = {};
    return;
  endif

  if ~isfield(modelo, 'info') || ~isstruct(modelo.info)
    modelo.info = struct();
  endif
  modelo.info.asset_identity_schema = 'AOS_ASSET_IDENTITY_0_2_0';

  [registro, items] = aos_asset_registro(modelo);

  % Propagar asset_id (posiblemente desambiguado) desde el registro a las filas
  for k = 1:numel(registro)
    act = registro{k};
    if isempty(act) || ~isstruct(act), continue; endif
    if ~isfield(act, 'links') || ~isstruct(act.links), continue; endif
    if ~isfield(act.links, 'tabla') || isempty(act.links.tabla), continue; endif
    nom = char(act.links.tabla);
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    if isempty(filas), continue; endif
    if ~iscell(filas), filas = {filas}; endif
    id_loc = '';
    if isfield(act.links, 'id') && ~isempty(act.links.id)
      id_loc = char(act.links.id);
    endif
    for i = 1:numel(filas)
      fila = filas{i};
      if isempty(fila) || ~isstruct(fila), continue; endif
      if ~isempty(id_loc)
        if ~isfield(fila, 'id') || ~strcmp(char(fila.id), id_loc)
          continue;
        endif
      elseif isfield(fila, 'asset_id') && ~isempty(fila.asset_id)
        continue;  % ya asignada; evita sobrescribir otra fila sin id
      endif
      fila.asset_id = char(act.asset_id);
      filas{i} = fila;
      break;
    endfor
    modelo.tablas_entrada.(nom) = filas;
  endfor

  % Filas que quedaron sin asset_id (p.ej. tablas no cubiertas por el registro)
  tablas = {'nodos', 'tramos', 'equipos', 'valvulas', 'accesorios', ...
            'condiciones_borde', 'camaras', 'ramales', 'accesos'};
  for t = 1:numel(tablas)
    nom = tablas{t};
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    if isempty(filas), continue; endif
    if ~iscell(filas), filas = {filas}; endif
    for i = 1:numel(filas)
      fila = filas{i};
      if isempty(fila) || ~isstruct(fila), continue; endif
      if isfield(fila, 'asset_id') && ~isempty(fila.asset_id), continue; endif
      tipo = tipo_desde_tabla_local(nom);
      [aid, ~, ~] = aos_asset_id_generar(tipo, fila, nom, struct());
      fila.asset_id = aid;
      filas{i} = fila;
    endfor
    modelo.tablas_entrada.(nom) = filas;
  endfor

  modelo.activos = registro;

  % Incorporar items de colision a validaciones (sin silenciar)
  if ~isempty(items)
    if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
      modelo.validaciones = struct('estado', 'ADVERTENCIA', 'items', {{}});
    endif
    if ~isfield(modelo.validaciones, 'items') || isempty(modelo.validaciones.items)
      modelo.validaciones.items = {};
    elseif ~iscell(modelo.validaciones.items)
      modelo.validaciones.items = {modelo.validaciones.items};
    endif
    for k = 1:numel(items)
      modelo.validaciones.items{end+1} = items{k}; %#ok<AGROW>
    endfor
    if ~isfield(modelo.validaciones, 'estado') ...
        || strcmp(modelo.validaciones.estado, 'PENDIENTE') ...
        || strcmp(modelo.validaciones.estado, 'OK')
      modelo.validaciones.estado = 'ADVERTENCIA';
    endif
  endif
endfunction

function tipo = tipo_desde_tabla_local(tabla)
  switch lower(char(tabla))
    case 'nodos', tipo = 'NODO';
    case 'tramos', tipo = 'TRAMO';
    case 'equipos', tipo = 'EQUIPO';
    case 'valvulas', tipo = 'VALVULA';
    case 'accesorios', tipo = 'ACCESORIO';
    case 'condiciones_borde', tipo = 'BC';
    case 'camaras', tipo = 'CAMARA';
    case 'ramales', tipo = 'RAMAL';
    case 'accesos', tipo = 'ACCESO';
    otherwise, tipo = 'NODO';
  endswitch
endfunction

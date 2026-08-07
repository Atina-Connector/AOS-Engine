function [seleccion, items] = aos_cad_escena_seleccionar(escena, criterio)
% AOS_CAD_ESCENA_SELECCIONAR Seleccion por datos (asset_id / geometry_id / tipo).
% Devuelve indices y objetos; no graficos. Un asset_id con varias ocurrencias
% devuelve todas (relacion uno a muchos).
%
% [seleccion, items] = aos_cad_escena_seleccionar(escena, criterio)
%   criterio: struct con campos asset_id, geometry_id, tipo y/o
%             fuente_federada (opcional, aditivo Sprint 6)
%             o char/cellstr interpretado como asset_id
  items = {};
  seleccion = struct();
  seleccion.indices = [];
  seleccion.objetos = {};
  seleccion.n = 0;
  seleccion.bbox = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  seleccion.criterio = struct();

  if nargin < 1 || isempty(escena) || ~isstruct(escena)
    items{end+1} = item_vacia_local('Escena ausente o invalida');
    return;
  endif
  if nargin < 2, criterio = struct(); endif

  crit = normalizar_criterio_local(criterio);
  seleccion.criterio = crit;

  objetos = {};
  if isfield(escena, 'objetos') && iscell(escena.objetos)
    objetos = escena.objetos;
  endif
  if isempty(objetos)
    items{end+1} = item_vacia_local('Escena sin objetos');
    return;
  endif

  idx = [];
  for i = 1:numel(objetos)
    o = objetos{i};
    if ~isstruct(o), continue; endif
    if coincide_local(o, crit)
      idx(end+1) = i; %#ok<AGROW>
    endif
  endfor

  if isempty(idx)
    items{end+1} = item_vacia_local(sprintf( ...
      'Sin coincidencias para criterio %s', resumen_criterio_local(crit)));
    return;
  endif

  sel_objs = {};
  pts = zeros(0, 3);
  for k = 1:numel(idx)
    o = objetos{idx(k)};
    sel_objs{end+1} = o; %#ok<AGROW>
    if isfield(o, 'puntos') && ~isempty(o.puntos)
      p = double(o.puntos);
      if size(p, 2) == 2, p = [p, zeros(size(p, 1), 1)]; endif
      if size(p, 2) >= 3
        pts = [pts; p(:, 1:3)]; %#ok<AGROW>
      endif
    elseif isfield(o, 'bbox') && isstruct(o.bbox)
      c = corners_local(o.bbox);
      if ~isempty(c), pts = [pts; c]; endif %#ok<AGROW>
    endif
  endfor

  seleccion.indices = idx;
  seleccion.objetos = sel_objs;
  seleccion.n = numel(idx);
  if ~isempty(pts)
    [bb, ~] = aos_geom_bbox(pts);
    seleccion.bbox.xmin = bb.xmin; seleccion.bbox.xmax = bb.xmax;
    seleccion.bbox.ymin = bb.ymin; seleccion.bbox.ymax = bb.ymax;
    if isfield(bb, 'zmin'), seleccion.bbox.zmin = bb.zmin; else, seleccion.bbox.zmin = 0; endif
    if isfield(bb, 'zmax'), seleccion.bbox.zmax = bb.zmax; else, seleccion.bbox.zmax = 0; endif
  endif
endfunction

function crit = normalizar_criterio_local(criterio)
  crit = struct('asset_id', '', 'geometry_id', '', 'tipo', '', ...
    'fuente_federada', '');
  if isempty(criterio), return; endif
  if ischar(criterio)
    crit.asset_id = char(criterio);
    return;
  endif
  if iscell(criterio) && ~isempty(criterio) && ischar(criterio{1})
    crit.asset_id = char(criterio{1});
    return;
  endif
  if ~isstruct(criterio), return; endif
  if isfield(criterio, 'asset_id') && ~isempty(criterio.asset_id)
    crit.asset_id = char(criterio.asset_id);
  endif
  if isfield(criterio, 'geometry_id') && ~isempty(criterio.geometry_id)
    crit.geometry_id = char(criterio.geometry_id);
  endif
  if isfield(criterio, 'tipo') && ~isempty(criterio.tipo)
    crit.tipo = upper(char(criterio.tipo));
  endif
  if isfield(criterio, 'type') && isempty(crit.tipo) && ~isempty(criterio.type)
    crit.tipo = upper(char(criterio.type));
  endif
  if isfield(criterio, 'fuente_federada') && ~isempty(criterio.fuente_federada)
    crit.fuente_federada = upper(char(criterio.fuente_federada));
  endif
endfunction

function tf = coincide_local(o, crit)
  tf = true;
  hubo = false;
  if ~isempty(crit.asset_id)
    hubo = true;
    aid = '';
    if isfield(o, 'asset_id'), aid = char(o.asset_id); endif
    if ~strcmp(aid, crit.asset_id)
      tf = false; return;
    endif
  endif
  if ~isempty(crit.geometry_id)
    hubo = true;
    gid = '';
    if isfield(o, 'geometry_id'), gid = char(o.geometry_id); endif
    if ~strcmp(gid, crit.geometry_id)
      tf = false; return;
    endif
  endif
  if ~isempty(crit.tipo)
    hubo = true;
    tipo = '';
    if isfield(o, 'tipo'), tipo = upper(char(o.tipo)); endif
    if ~strcmp(tipo, crit.tipo)
      tf = false; return;
    endif
  endif
  if ~isempty(crit.fuente_federada)
    hubo = true;
    ff = '';
    if isfield(o, 'fuente_federada'), ff = upper(char(o.fuente_federada)); endif
    if ~strcmp(ff, crit.fuente_federada)
      tf = false; return;
    endif
  endif
  if ~hubo
    tf = false;
  endif
endfunction

function s = resumen_criterio_local(crit)
  partes = {};
  if ~isempty(crit.asset_id), partes{end+1} = ['asset_id=' crit.asset_id]; endif
  if ~isempty(crit.geometry_id), partes{end+1} = ['geometry_id=' crit.geometry_id]; endif
  if ~isempty(crit.tipo), partes{end+1} = ['tipo=' crit.tipo]; endif
  if isfield(crit, 'fuente_federada') && ~isempty(crit.fuente_federada)
    partes{end+1} = ['fuente_federada=' crit.fuente_federada];
  endif
  if isempty(partes)
    s = '(vacio)';
  else
    s = partes{1};
    for i = 2:numel(partes)
      s = [s, ',', partes{i}]; %#ok<AGROW>
    endfor
  endif
endfunction

function it = item_vacia_local(msg)
  it = struct('codigo', 'ESCENA_SELECCION_VACIA', ...
    'mensaje', char(msg), 'severidad', 'INFO');
endfunction

function pts = corners_local(bb)
  pts = zeros(0, 3);
  req = {'xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'};
  for i = 1:numel(req)
    if ~isfield(bb, req{i}) || ~isfinite(bb.(req{i})), return; endif
  endfor
  xs = [bb.xmin, bb.xmax];
  ys = [bb.ymin, bb.ymax];
  zs = [bb.zmin, bb.zmax];
  pts = zeros(8, 3);
  k = 0;
  for ix = 1:2
    for iy = 1:2
      for iz = 1:2
        k = k + 1;
        pts(k, :) = [xs(ix), ys(iy), zs(iz)];
      endfor
    endfor
  endfor
endfunction

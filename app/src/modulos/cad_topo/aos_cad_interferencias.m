function [tabla_interferencias, items] = aos_cad_interferencias(escena, opciones)
% AOS_CAD_INTERFERENCIAS Deteccion conservadora de interferencias por AABB.
% Sin BRep/OCCT: solo solape de bounding box y distancia minima entre cajas.
% Dato puro: sin figure/plot/print. Orden estable por (indice_a, indice_b).
%
% [tabla_interferencias, items] = aos_cad_interferencias(escena, opciones)
%   escena: struct con .objetos (cell) de aos_cad_escena_3d
%   opciones:
%     distancia_minima_m (default 0): si > 0, reporta PROXIMIDAD cuando
%       distancia_m <= umbral (ademas de SOLAPE con volumen > 0)
%     max_pares (default Inf): tope de pares reportados; si se alcanza,
%       item INTERFERENCIAS_TRUNCADAS
%
% Exclusiones: mismo geometry_id (ambos no vacios); pares NODO-TRAMO que
% comparten nodo_ref / nodo_o / nodo_d con el id del nodo.
% Bbox indeterminada: item INTERFERENCIA_BBOX_INDETERMINADA, no se asume 0.
  tabla_interferencias = {};
  items = {};
  if nargin < 1 || isempty(escena) || ~isstruct(escena)
    return;
  endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif

  distancia_minima_m = 0;
  if isfield(opciones, 'distancia_minima_m') && isnumeric(opciones.distancia_minima_m) ...
      && ~isempty(opciones.distancia_minima_m) && isfinite(opciones.distancia_minima_m(1))
    distancia_minima_m = double(opciones.distancia_minima_m(1));
    if distancia_minima_m < 0, distancia_minima_m = 0; endif
  endif

  max_pares = Inf;
  if isfield(opciones, 'max_pares') && isnumeric(opciones.max_pares) ...
      && ~isempty(opciones.max_pares) && isfinite(opciones.max_pares(1))
    max_pares = double(opciones.max_pares(1));
    if max_pares < 0, max_pares = 0; endif
  endif

  objetos = {};
  if isfield(escena, 'objetos') && iscell(escena.objetos)
    objetos = escena.objetos;
  endif
  n = numel(objetos);
  if n < 1, return; endif

  % Marcar bbox indeterminadas (una sola vez por objeto)
  det = false(1, n);
  for i = 1:n
    o = objetos{i};
    if ~isstruct(o), continue; endif
    if ~isfield(o, 'bbox') || ~bbox_determinada_local(o.bbox)
      aid = '';
      if isfield(o, 'asset_id'), aid = char(o.asset_id); endif
      gid = '';
      if isfield(o, 'geometry_id'), gid = char(o.geometry_id); endif
      oid = '';
      if isfield(o, 'id'), oid = char(o.id); endif
      items{end+1} = struct( ...
        'codigo', 'INTERFERENCIA_BBOX_INDETERMINADA', ...
        'mensaje', sprintf( ...
          'Objeto indice %d id=%s asset=%s geometry=%s: bbox indeterminada (omitido)', ...
          i, oid, aid, gid), ...
        'severidad', 'ADVERTENCIA', ...
        'indice', i, ...
        'asset_id', aid, ...
        'geometry_id', gid); %#ok<AGROW>
      continue;
    endif
    det(i) = true;
  endfor

  truncado = false;
  for ia = 1:n
    if ~det(ia), continue; endif
    oa = objetos{ia};
    for ib = (ia + 1):n
      if ~det(ib), continue; endif
      if numel(tabla_interferencias) >= max_pares
        truncado = true;
        break;
      endif
      ob = objetos{ib};
      if mismo_geometry_id_local(oa, ob), continue; endif
      if es_par_nodo_tramo_conectado_local(oa, ob), continue; endif

      [hay_solape, vol, dist] = aos_geom_bbox_solape(oa.bbox, ob.bbox);
      tipo = '';
      if hay_solape && vol > 0
        tipo = 'SOLAPE';
      elseif distancia_minima_m > 0 && isfinite(dist) && dist <= distancia_minima_m
        tipo = 'PROXIMIDAD';
      else
        continue;
      endif

      if strcmp(tipo, 'SOLAPE')
        sev = 'ADVERTENCIA';
      else
        sev = 'INFO';
      endif

      fila = struct();
      fila.asset_a = campo_char_local(oa, 'asset_id');
      fila.geometry_a = campo_char_local(oa, 'geometry_id');
      fila.asset_b = campo_char_local(ob, 'asset_id');
      fila.geometry_b = campo_char_local(ob, 'geometry_id');
      fila.tipo = tipo;
      fila.volumen_solape_m3 = vol;
      fila.distancia_m = dist;
      fila.severidad = sev;
      tabla_interferencias{end+1} = fila; %#ok<AGROW>
    endfor
    if truncado, break; endif
  endfor

  if truncado
    items{end+1} = struct( ...
      'codigo', 'INTERFERENCIAS_TRUNCADAS', ...
      'mensaje', sprintf( ...
        'Barrido truncado en max_pares=%g (pares reportados=%d)', ...
        max_pares, numel(tabla_interferencias)), ...
      'severidad', 'ADVERTENCIA', ...
      'max_pares', max_pares, ...
      'n_pares', numel(tabla_interferencias));
  endif
endfunction

function tf = bbox_determinada_local(bb)
  tf = false;
  if ~isstruct(bb), return; endif
  req = {'xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'};
  for i = 1:numel(req)
    if ~isfield(bb, req{i}) || ~isfinite(bb.(req{i}))
      return;
    endif
  endfor
  tf = true;
endfunction

function tf = mismo_geometry_id_local(oa, ob)
  tf = false;
  ga = campo_char_local(oa, 'geometry_id');
  gb = campo_char_local(ob, 'geometry_id');
  if isempty(ga) || isempty(gb), return; endif
  tf = strcmp(ga, gb);
endfunction

function tf = es_par_nodo_tramo_conectado_local(oa, ob)
  tf = false;
  ta = upper(campo_char_local(oa, 'tipo'));
  tb = upper(campo_char_local(ob, 'tipo'));
  if strcmp(ta, 'NODO') && strcmp(tb, 'TRAMO')
    tf = tramo_refiere_nodo_local(ob, oa);
  elseif strcmp(ta, 'TRAMO') && strcmp(tb, 'NODO')
    tf = tramo_refiere_nodo_local(oa, ob);
  endif
endfunction

function tf = tramo_refiere_nodo_local(tramo, nodo)
  tf = false;
  nid = campo_char_local(nodo, 'id');
  if isempty(nid)
    nid = campo_char_local(nodo, 'nodo_ref');
  endif
  if isempty(nid), return; endif

  refs = {};
  if isfield(tramo, 'nodo_ref') && ~isempty(tramo.nodo_ref)
    refs{end+1} = char(tramo.nodo_ref); %#ok<AGROW>
  endif
  if isfield(tramo, 'nodo_o') && ~isempty(tramo.nodo_o)
    refs{end+1} = char(tramo.nodo_o); %#ok<AGROW>
  endif
  if isfield(tramo, 'nodo_d') && ~isempty(tramo.nodo_d)
    refs{end+1} = char(tramo.nodo_d); %#ok<AGROW>
  endif
  % Ambos con nodo_ref igual (conexion explicita)
  nref = campo_char_local(nodo, 'nodo_ref');
  if ~isempty(nref) && isfield(tramo, 'nodo_ref') && ~isempty(tramo.nodo_ref)
    if strcmp(char(tramo.nodo_ref), nref)
      tf = true;
      return;
    endif
  endif
  for i = 1:numel(refs)
    if strcmp(refs{i}, nid)
      tf = true;
      return;
    endif
  endfor
endfunction

function s = campo_char_local(o, campo)
  s = '';
  if isstruct(o) && isfield(o, campo) && ~isempty(o.(campo))
    try
      s = char(o.(campo));
    catch
      s = '';
    end_try_catch
  endif
endfunction

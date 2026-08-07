function [escena, items] = aos_escena_federada(fuentes, opciones)
% AOS_ESCENA_FEDERADA Compone escena 3D multi-fuente (red, pozo, instalaciones).
% Reutiliza aos_cad_escena_3d por fuente; concatena en orden fijo
% red -> pozo -> instalaciones. Solo geometria/seleccion; sin fisica ni graficos.
%
% [escena, items] = aos_escena_federada(fuentes, opciones)
%   fuentes: struct opcional con campos
%     .red            cad_topologia / modelo .aoscad
%     .pozo           survey (MD/TVD/...)
%     .instalaciones  indice geometrico STEP
%   opciones: se reenvian a aos_cad_escena_3d salvo incluir_* (forzados por fuente)
%
% Cada objeto recibe fuente_federada en {RED, POZO, INSTALACIONES} e id
% namespaced "FUENTE:id_local". Items: FEDERACION_FUENTE_AUSENTE (INFO),
% FEDERACION_ASSET_DUPLICADO, FEDERACION_ASSET_INCONSISTENTE (ADVERTENCIA).
  if nargin < 1 || isempty(fuentes), fuentes = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(fuentes), fuentes = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  items = {};

  tiene_red = campo_presente_local(fuentes, 'red');
  tiene_pozo = campo_presente_local(fuentes, 'pozo');
  tiene_inst = campo_presente_local(fuentes, 'instalaciones');

  if ~tiene_red
    items{end+1} = item_fed_local('FEDERACION_FUENTE_AUSENTE', ...
      'Fuente federada RED ausente', 'INFO', 'RED', '', ''); %#ok<AGROW>
  endif
  if ~tiene_pozo
    items{end+1} = item_fed_local('FEDERACION_FUENTE_AUSENTE', ...
      'Fuente federada POZO ausente', 'INFO', 'POZO', '', ''); %#ok<AGROW>
  endif
  if ~tiene_inst
    items{end+1} = item_fed_local('FEDERACION_FUENTE_AUSENTE', ...
      'Fuente federada INSTALACIONES ausente', 'INFO', 'INSTALACIONES', '', ''); %#ok<AGROW>
  endif

  objetos = {};
  % Orden fijo: red -> pozo -> instalaciones (igual que aos_cad_escena_3d)
  if tiene_red
    [objs, its] = escena_fuente_local(fuentes.red, 'RED', opciones);
    items = anexar_items_local(items, its);
    objetos = concat_objs_local(objetos, objs);
  endif
  if tiene_pozo
    [objs, its] = escena_fuente_local(fuentes.pozo, 'POZO', opciones);
    items = anexar_items_local(items, its);
    objetos = concat_objs_local(objetos, objs);
  endif
  if tiene_inst
    [objs, its] = escena_fuente_local(fuentes.instalaciones, 'INSTALACIONES', opciones);
    items = anexar_items_local(items, its);
    objetos = concat_objs_local(objetos, objs);
  endif

  items = anexar_items_local(items, consistencia_asset_local(objetos));

  escena = struct();
  escena.objetos = objetos;
  escena.n_objetos = numel(objetos);
  escena.unidades = 'm';
  escena.fuentes = struct( ...
    'red', tiene_red, ...
    'pozo', tiene_pozo, ...
    'instalaciones', tiene_inst);
  escena.orden = (1:numel(objetos));
  escena.n_objetos_por_tipo = contar_tipos_local(objetos);
  escena.bbox_global = bbox_global_local(objetos);
  escena.vigente = true;
  escena.federada = true;
endfunction

function tf = campo_presente_local(fuentes, nom)
  tf = false;
  if ~isstruct(fuentes) || ~isfield(fuentes, nom), return; endif
  v = fuentes.(nom);
  if isempty(v), return; endif
  if isstruct(v) && isempty(fieldnames(v)), return; endif
  tf = true;
endfunction

function [objs, items] = escena_fuente_local(dato, etiqueta, opciones)
  objs = {};
  items = {};
  opts = opciones;
  if ~isstruct(opts), opts = struct(); endif
  opts.usar_geometria_activa = false;

  switch upper(char(etiqueta))
    case 'RED'
      opts.incluir_red = true;
      opts.incluir_pozo = false;
      opts.incluir_step = false;
      fuente = dato;
    case 'POZO'
      opts.incluir_red = false;
      opts.incluir_pozo = true;
      opts.incluir_step = false;
      fuente = struct('survey', dato);
    case 'INSTALACIONES'
      opts.incluir_red = false;
      opts.incluir_pozo = false;
      opts.incluir_step = true;
      fuente = envolver_indice_local(dato);
    otherwise
      return;
  endswitch

  [esc, its] = aos_cad_escena_3d(fuente, opts);

  if iscell(its)
    for i = 1:numel(its)
      items{end+1} = its{i}; %#ok<AGROW>
    endfor
  endif

  if ~isstruct(esc) || ~isfield(esc, 'objetos') || ~iscell(esc.objetos)
    return;
  endif

  for i = 1:numel(esc.objetos)
    o = esc.objetos{i};
    if ~isstruct(o), continue; endif
    id_loc = '';
    if isfield(o, 'id'), id_loc = char(o.id); endif
    if isempty(id_loc)
      id_loc = sprintf('#%d', i);
    endif
    o.fuente_federada = upper(char(etiqueta));
    o.id = sprintf('%s:%s', o.fuente_federada, id_loc);
    objs{end+1} = o; %#ok<AGROW>
  endfor
endfunction

function fuente = envolver_indice_local(dato)
  if isstruct(dato) && (isfield(dato, 'ocurrencias') || isfield(dato, 'productos') ...
      || isfield(dato, 'n_entidades'))
    fuente = struct('indice_geometrico', dato);
    return;
  endif
  if isstruct(dato) && isfield(dato, 'step_indice_geometrico')
    fuente = dato;
    return;
  endif
  if isstruct(dato) && isfield(dato, 'indice_geometrico')
    fuente = dato;
    return;
  endif
  fuente = struct('indice_geometrico', dato);
endfunction

function items = consistencia_asset_local(objetos)
  items = {};
  % asset_id -> struct de fuentes (claves RED/POZO/INSTALACIONES)
  por_aid = struct();
  % geometry_id -> struct de asset_ids distintos
  por_gid = struct();
  aids_orden = {};
  gids_orden = {};

  for i = 1:numel(objetos)
    o = objetos{i};
    if ~isstruct(o), continue; endif
    ff = '';
    if isfield(o, 'fuente_federada'), ff = upper(char(o.fuente_federada)); endif
    if isempty(ff), ff = 'DESCONOCIDA'; endif

    aid = '';
    if isfield(o, 'asset_id'), aid = char(o.asset_id); endif
    gid = '';
    if isfield(o, 'geometry_id'), gid = char(o.geometry_id); endif

    if ~isempty(aid)
      ak = safe_key_local(aid);
      if ~isfield(por_aid, ak)
        por_aid.(ak) = struct('asset_id', aid, 'fuentes', struct(), ...
          'tipos', struct(), 'gids', struct());
        aids_orden{end+1} = ak; %#ok<AGROW>
      endif
      por_aid.(ak).fuentes.(safe_key_local(ff)) = true;
      tipo = '';
      if isfield(o, 'tipo'), tipo = upper(char(o.tipo)); endif
      if ~isempty(tipo)
        por_aid.(ak).tipos.(safe_key_local(tipo)) = true;
      endif
      if ~isempty(gid)
        por_aid.(ak).gids.(safe_key_local(gid)) = true;
      endif
    endif

    if ~isempty(gid) && ~isempty(aid)
      gk = safe_key_local(gid);
      if ~isfield(por_gid, gk)
        por_gid.(gk) = struct('geometry_id', gid, 'assets', struct());
        gids_orden{end+1} = gk; %#ok<AGROW>
      endif
      por_gid.(gk).assets.(safe_key_local(aid)) = aid;
    endif
  endfor

  for i = 1:numel(aids_orden)
    ak = aids_orden{i};
    info = por_aid.(ak);
    n_f = numel(fieldnames(info.fuentes));
    if n_f >= 2
      fuentes_txt = join_keys_local(info.fuentes);
      items{end+1} = item_fed_local('FEDERACION_ASSET_DUPLICADO', ...
        sprintf('asset_id %s presente en fuentes %s (sin fusion)', ...
          info.asset_id, fuentes_txt), ...
        'ADVERTENCIA', fuentes_txt, info.asset_id, ''); %#ok<AGROW>
    endif
    n_tipos = numel(fieldnames(info.tipos));
    n_gids = numel(fieldnames(info.gids));
    if n_f >= 2 && (n_tipos >= 2 || n_gids >= 2)
      items{end+1} = item_fed_local('FEDERACION_ASSET_INCONSISTENTE', ...
        sprintf('asset_id %s con tipo/geometry_id conflictivos entre fuentes', ...
          info.asset_id), ...
        'ADVERTENCIA', '', info.asset_id, ''); %#ok<AGROW>
    endif
  endfor

  for i = 1:numel(gids_orden)
    gk = gids_orden{i};
    info = por_gid.(gk);
    aids = fieldnames(info.assets);
    if numel(aids) >= 2
      lista = {};
      for j = 1:numel(aids)
        lista{end+1} = info.assets.(aids{j}); %#ok<AGROW>
      endfor
      items{end+1} = item_fed_local('FEDERACION_ASSET_INCONSISTENTE', ...
        sprintf('geometry_id %s asociado a asset_id distintos: %s', ...
          info.geometry_id, strjoin_local(lista)), ...
        'ADVERTENCIA', '', '', info.geometry_id); %#ok<AGROW>
    endif
  endfor
endfunction

function it = item_fed_local(codigo, mensaje, severidad, fuente, asset_id, geometry_id)
  it = struct( ...
    'codigo', char(codigo), ...
    'mensaje', char(mensaje), ...
    'severidad', char(severidad), ...
    'fuente_federada', char(fuente), ...
    'asset_id', char(asset_id), ...
    'geometry_id', char(geometry_id));
endfunction

function items = anexar_items_local(items, nuevos)
  if ~iscell(nuevos), return; endif
  for i = 1:numel(nuevos)
    items{end+1} = nuevos{i}; %#ok<AGROW>
  endfor
endfunction

function out = concat_objs_local(a, b)
  out = a;
  if ~iscell(b), return; endif
  for i = 1:numel(b)
    out{end+1} = b{i}; %#ok<AGROW>
  endfor
endfunction

function c = contar_tipos_local(objetos)
  c = struct('NODO', 0, 'TRAMO', 0, 'POZO', 0, 'EQUIPO_3D', 0);
  for i = 1:numel(objetos)
    if ~isstruct(objetos{i}) || ~isfield(objetos{i}, 'tipo'), continue; endif
    t = char(objetos{i}.tipo);
    if isfield(c, t)
      c.(t) = c.(t) + 1;
    else
      c.(t) = 1;
    endif
  endfor
endfunction

function bb = bbox_global_local(objetos)
  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  pts = zeros(0, 3);
  for i = 1:numel(objetos)
    o = objetos{i};
    if ~isstruct(o), continue; endif
    if isfield(o, 'puntos') && ~isempty(o.puntos)
      p = double(o.puntos);
      if size(p, 2) == 2, p = [p, zeros(size(p, 1), 1)]; endif
      if size(p, 2) >= 3
        pts = [pts; p(:, 1:3)]; %#ok<AGROW>
      endif
    elseif isfield(o, 'bbox')
      c = corners_bbox_local(o.bbox);
      if ~isempty(c), pts = [pts; c]; endif %#ok<AGROW>
    endif
  endfor
  if isempty(pts), return; endif
  [bb2, ~] = aos_geom_bbox(pts);
  bb.xmin = bb2.xmin; bb.xmax = bb2.xmax;
  bb.ymin = bb2.ymin; bb.ymax = bb2.ymax;
  if isfield(bb2, 'zmin'), bb.zmin = bb2.zmin; else, bb.zmin = 0; endif
  if isfield(bb2, 'zmax'), bb.zmax = bb2.zmax; else, bb.zmax = 0; endif
endfunction

function pts = corners_bbox_local(bb)
  pts = zeros(0, 3);
  if ~isstruct(bb), return; endif
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

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction

function s = join_keys_local(mapa)
  fn = fieldnames(mapa);
  % Orden canonico de fuentes federadas
  orden = {'RED', 'POZO', 'INSTALACIONES'};
  partes = {};
  for i = 1:numel(orden)
    if isfield(mapa, orden{i})
      partes{end+1} = orden{i}; %#ok<AGROW>
    endif
  endfor
  for i = 1:numel(fn)
    if ~any(strcmp(fn{i}, orden))
      partes{end+1} = fn{i}; %#ok<AGROW>
    endif
  endfor
  s = strjoin_local(partes);
endfunction

function s = strjoin_local(partes)
  if isempty(partes)
    s = '';
    return;
  endif
  s = char(partes{1});
  for i = 2:numel(partes)
    s = [s, ',', char(partes{i})]; %#ok<AGROW>
  endfor
endfunction

function [vinculo, modelo, items] = aos_cad_vincular_asset_3d(modelo, opciones)
% AOS_CAD_VINCULAR_ASSET_3D Mapa bidireccional asset_id <-> geometry_id.
% Persiste de forma aditiva: geometry_id / geometry_ids en activos y
% modelo.vinculo_3d con por_asset_id / por_geometry_id.
%
% [vinculo, modelo, items] = aos_cad_vincular_asset_3d(modelo, opciones)
%   modelo: .aoscad o struct con activos / id_index_step / indice
%   opciones: indice_geometrico, id_index_step, cad_topologia (opcionales)
%
% Items: VINCULO_3D_ASSET_SIN_GEOMETRIA, VINCULO_3D_GEOMETRIA_SIN_ASSET (ADV).
  if nargin < 1 || isempty(modelo), modelo = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(modelo), modelo = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  items = {};

  [activos, indice, id_index] = resolver_entradas_local(modelo, opciones);

  % Si no hay activos pero hay indice STEP, sintetizar desde id_index
  if isempty(activos) && ~isempty(id_index)
    activos = activos_desde_index_local(id_index);
  endif

  mapa_prod_aid = mapa_producto_asset_local(activos, id_index);

  por_asset = struct();
  por_geom = struct();
  gids_por_aid = struct();
  n_vinculados = 0;
  n_geom_sin_asset = 0;
  ocurrencias = {};
  if isstruct(indice) && isfield(indice, 'ocurrencias') && iscell(indice.ocurrencias)
    ocurrencias = indice.ocurrencias;
  endif

  for i = 1:numel(ocurrencias)
    oc = ocurrencias{i};
    if isempty(oc) || ~isstruct(oc), continue; endif
    gid = '';
    if isfield(oc, 'geometry_id'), gid = char(oc.geometry_id); endif
    if isempty(gid), continue; endif

    aid = '';
    if isfield(oc, 'asset_id') && ~isempty(oc.asset_id)
      aid = char(oc.asset_id);
    endif
    if isempty(aid)
      aid = resolver_asset_de_oc_local(oc, mapa_prod_aid);
    endif

    gk = safe_key_local(gid);
    if isempty(aid)
      n_geom_sin_asset = n_geom_sin_asset + 1;
      por_geom.(gk) = '';
      items{end+1} = struct( ...
        'codigo', 'VINCULO_3D_GEOMETRIA_SIN_ASSET', ...
        'mensaje', sprintf('geometry_id sin asset_id: %s', gid), ...
        'severidad', 'ADVERTENCIA', ...
        'geometry_id', gid); %#ok<AGROW>
      continue;
    endif

    por_geom.(gk) = aid;
    ak = safe_key_local(aid);
    if ~isfield(gids_por_aid, ak)
      gids_por_aid.(ak) = {gid};
      por_asset.(ak) = gid; % primario
    else
      gids_por_aid.(ak){end+1} = gid; %#ok<AGROW>
    endif
    n_vinculados = n_vinculados + 1;
    ocurrencias{i}.asset_id = aid;
  endfor

  % Actualizar indice en modelo si se paso por referencia estructural
  if isstruct(indice) && isfield(indice, 'ocurrencias')
    indice.ocurrencias = ocurrencias;
  endif

  % Persistir geometry_id(s) en activos
  n_asset_sin_geom = 0;
  aids_con_geom = fieldnames(gids_por_aid);
  for i = 1:numel(activos)
    a = activos{i};
    if isempty(a) || ~isstruct(a), continue; endif
    aid = '';
    if isfield(a, 'asset_id'), aid = char(a.asset_id); endif
    if isempty(aid), continue; endif
    ak = safe_key_local(aid);
    if isfield(gids_por_aid, ak)
      gids = gids_por_aid.(ak);
      a.geometry_id = gids{1};
      if numel(gids) > 1
        a.geometry_ids = gids;
      else
        a.geometry_ids = gids;
      endif
    else
      n_asset_sin_geom = n_asset_sin_geom + 1;
      items{end+1} = struct( ...
        'codigo', 'VINCULO_3D_ASSET_SIN_GEOMETRIA', ...
        'mensaje', sprintf('asset_id sin geometry_id: %s', aid), ...
        'severidad', 'ADVERTENCIA', ...
        'asset_id', aid); %#ok<AGROW>
    endif
    activos{i} = a;
  endfor

  vinculo = struct();
  vinculo.por_asset_id = por_asset;
  vinculo.por_geometry_id = por_geom;
  vinculo.geometry_ids_por_asset = gids_por_aid;
  vinculo.n_vinculados = n_vinculados;
  vinculo.n_asset_sin_geometria = n_asset_sin_geom;
  vinculo.n_geometria_sin_asset = n_geom_sin_asset;
  vinculo.vigente = true;

  modelo.activos = activos;
  modelo.vinculo_3d = vinculo;
  if isstruct(indice) && ~isempty(fieldnames(indice))
    modelo.step_indice_geometrico = indice;
  endif

  % Incorporar items a validaciones sin silenciar
  if ~isempty(items)
    modelo = anexar_validaciones_local(modelo, items);
  endif
endfunction

function [activos, indice, id_index] = resolver_entradas_local(modelo, opciones)
  activos = {};
  indice = struct();
  id_index = struct();

  cad = struct();
  if isfield(opciones, 'cad_topologia') && isstruct(opciones.cad_topologia)
    cad = opciones.cad_topologia;
  endif

  if isfield(modelo, 'activos') && ~isempty(modelo.activos)
    activos = modelo.activos;
  elseif isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad) ...
      && isfield(cad.modelo_aoscad, 'activos')
    activos = cad.modelo_aoscad.activos;
  endif
  if ~isempty(activos) && ~iscell(activos), activos = {activos}; endif

  if isfield(opciones, 'indice_geometrico') && isstruct(opciones.indice_geometrico)
    indice = opciones.indice_geometrico;
  elseif isfield(modelo, 'step_indice_geometrico') && isstruct(modelo.step_indice_geometrico)
    indice = modelo.step_indice_geometrico;
  elseif isfield(modelo, 'indice_geometrico') && isstruct(modelo.indice_geometrico)
    indice = modelo.indice_geometrico;
  elseif isfield(cad, 'step_indice_geometrico') && isstruct(cad.step_indice_geometrico)
    indice = cad.step_indice_geometrico;
  endif

  if isfield(opciones, 'id_index_step') && isstruct(opciones.id_index_step)
    id_index = opciones.id_index_step;
  elseif isfield(modelo, 'id_index_step') && isstruct(modelo.id_index_step)
    id_index = modelo.id_index_step;
  elseif isfield(cad, 'id_index_step') && isstruct(cad.id_index_step)
    id_index = cad.id_index_step;
  endif
endfunction

function activos = activos_desde_index_local(id_index)
  activos = {};
  if ~isstruct(id_index) || ~isfield(id_index, 'items'), return; endif
  items = id_index.items;
  if ~iscell(items), items = {items}; endif
  for i = 1:numel(items)
    ent = items{i};
    if isempty(ent) || ~isstruct(ent), continue; endif
    act = struct();
    if isfield(ent, 'asset_id'), act.asset_id = char(ent.asset_id);
    else, act.asset_id = ''; endif
    act.asset_type = 'STEP_PRODUCT';
    act.source = 'STEP';
    act.validation_status = 'OK';
    act.links = struct('id', '', 'tabla', 'equipos', 'producto', '');
    if isfield(ent, 'id'), act.links.id = char(ent.id); endif
    if isfield(ent, 'producto'), act.links.producto = char(ent.producto); endif
    if isfield(ent, 'geometry_id') && ~isempty(ent.geometry_id)
      act.geometry_id = char(ent.geometry_id);
    endif
    activos{end+1} = act; %#ok<AGROW>
  endfor
endfunction

function mapa = mapa_producto_asset_local(activos, id_index)
  mapa = struct();
  if isstruct(id_index) && isfield(id_index, 'items')
    items = id_index.items;
    if ~iscell(items), items = {items}; endif
    for i = 1:numel(items)
      it = items{i};
      if ~isstruct(it) || ~isfield(it, 'asset_id'), continue; endif
      aid = char(it.asset_id);
      if isfield(it, 'producto') && ~isempty(it.producto)
        mapa.(safe_key_local(char(it.producto))) = aid;
      endif
      if isfield(it, 'id') && ~isempty(it.id)
        mapa.(safe_key_local(char(it.id))) = aid;
      endif
    endfor
  endif
  for i = 1:numel(activos)
    a = activos{i};
    if isempty(a) || ~isstruct(a) || ~isfield(a, 'asset_id'), continue; endif
    aid = char(a.asset_id);
    if isfield(a, 'links') && isstruct(a.links)
      if isfield(a.links, 'producto') && ~isempty(a.links.producto)
        mapa.(safe_key_local(char(a.links.producto))) = aid;
      endif
      if isfield(a.links, 'id') && ~isempty(a.links.id)
        mapa.(safe_key_local(char(a.links.id))) = aid;
      endif
    endif
  endfor
endfunction

function aid = resolver_asset_de_oc_local(oc, mapa)
  aid = '';
  keys = {};
  if isfield(oc, 'nombre') && ~isempty(oc.nombre)
    keys{end+1} = char(oc.nombre); %#ok<AGROW>
  endif
  if isfield(oc, 'product_id') && ~isempty(oc.product_id)
    keys{end+1} = char(oc.product_id); %#ok<AGROW>
  endif
  for i = 1:numel(keys)
    sk = safe_key_local(keys{i});
    if isfield(mapa, sk)
      aid = mapa.(sk);
      return;
    endif
  endfor
  % Generar asset_id estable STEP:<nombre> (misma clave que id_index)
  nom = '';
  if ~isempty(keys), nom = keys{1}; endif
  if isempty(nom), return; endif
  fila = struct('nombre', nom, 'product_name', nom, 'step_product', nom);
  [aid, ~, ~] = aos_asset_id_generar('STEP_PRODUCT', fila, 'step_product', struct());
endfunction

function modelo = anexar_validaciones_local(modelo, items)
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
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['H_' s]; endif
  k = s;
endfunction

function [escena, items] = aos_cad_escena_3d(fuente, opciones)
% AOS_CAD_ESCENA_3D Constructor de escena 3D como dato puro (sin graficos).
% Compone red hidraulica (nodos/tramos), trayectoria de pozo y cajas STEP.
% Restriccion: ninguna llamada grafica (ni fig, ni plot, ni export de imagen).
% Determinista: misma entrada => misma estructura (orden estable).
%
% [escena, items] = aos_cad_escena_3d(fuente, opciones)
%   fuente: modelo .aoscad, cad_topologia, o struct con tablas_entrada /
%           step_indice_geometrico / indice_geometrico / survey.
%   opciones: incluir_red, incluir_pozo, incluir_step (default true);
%             usar_geometria_activa (default true para pozo);
%             incluir_puertos (default false; tipos PUERTO/CONEXION).
%
% Dato puro: no abre figuras ni renderiza.
  if nargin < 1, fuente = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  items = {};

  incluir_red = true;
  incluir_pozo = true;
  incluir_step = true;
  usar_geom_act = true;
  incluir_puertos = false;
  if isfield(opciones, 'incluir_red'), incluir_red = logical(opciones.incluir_red); endif
  if isfield(opciones, 'incluir_pozo'), incluir_pozo = logical(opciones.incluir_pozo); endif
  if isfield(opciones, 'incluir_step'), incluir_step = logical(opciones.incluir_step); endif
  if isfield(opciones, 'usar_geometria_activa')
    usar_geom_act = logical(opciones.usar_geometria_activa);
  endif
  if isfield(opciones, 'incluir_puertos')
    incluir_puertos = logical(opciones.incluir_puertos);
  endif

  [modelo, indice, survey, fuentes_pres] = resolver_fuente_local(fuente, ...
    incluir_red, incluir_pozo, incluir_step, usar_geom_act);

  objetos = {};
  if incluir_red
    [objs_red, fuentes_pres] = objetos_red_local(modelo, fuentes_pres);
    for i = 1:numel(objs_red)
      objetos{end+1} = objs_red{i}; %#ok<AGROW>
    endfor
  endif
  if incluir_pozo
    [obj_pozo, fuentes_pres] = objeto_pozo_local(survey, fuentes_pres);
    if ~isempty(obj_pozo)
      objetos{end+1} = obj_pozo; %#ok<AGROW>
    endif
  endif
  if incluir_step
    [objs_step, fuentes_pres] = objetos_step_local(indice, modelo, fuentes_pres);
    for i = 1:numel(objs_step)
      objetos{end+1} = objs_step{i}; %#ok<AGROW>
    endfor
  endif
  if incluir_puertos
    [objs_pto, it_pto, fuentes_pres] = objetos_puertos_local(modelo, opciones, fuentes_pres);
    for i = 1:numel(it_pto)
      items{end+1} = it_pto{i}; %#ok<AGROW>
    endfor
    for i = 1:numel(objs_pto)
      objetos{end+1} = objs_pto{i}; %#ok<AGROW>
    endfor
  endif

  escena = struct();
  escena.objetos = objetos;
  escena.n_objetos = numel(objetos);
  escena.unidades = 'm';
  escena.fuentes = fuentes_pres;
  escena.orden = (1:numel(objetos));
  escena.n_objetos_por_tipo = contar_tipos_local(objetos);
  escena.bbox_global = bbox_global_local(objetos);
  escena.vigente = true;
endfunction

function [modelo, indice, survey, fuentes] = resolver_fuente_local(fuente, ...
    incluir_red, incluir_pozo, incluir_step, usar_geom_act)
  modelo = struct();
  indice = struct();
  survey = [];
  fuentes = struct('red', false, 'pozo', false, 'step', false);

  if isempty(fuente)
    fuente = struct();
  elseif ischar(fuente)
    fuente = struct('archivo', char(fuente));
  endif
  if ~isstruct(fuente), fuente = struct(); endif

  % Modelo .aoscad directo
  if isfield(fuente, 'tablas_entrada')
    modelo = fuente;
  elseif isfield(fuente, 'modelo_aoscad') && isstruct(fuente.modelo_aoscad)
    modelo = fuente.modelo_aoscad;
  elseif isfield(fuente, 'modelo') && isstruct(fuente.modelo)
    modelo = fuente.modelo;
  endif

  % cad_topologia (import STEP / DXF en CONFIG)
  cad = struct();
  if isfield(fuente, 'cad_topologia') && isstruct(fuente.cad_topologia)
    cad = fuente.cad_topologia;
  elseif isfield(fuente, 'step_indice_geometrico') || isfield(fuente, 'step_productos')
    cad = fuente;
  endif
  if isempty(fieldnames(modelo)) && isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad)
    modelo = cad.modelo_aoscad;
  endif

  % Indice geometrico STEP
  if isfield(fuente, 'indice_geometrico') && isstruct(fuente.indice_geometrico)
    indice = fuente.indice_geometrico;
  elseif isfield(fuente, 'step_indice_geometrico') && isstruct(fuente.step_indice_geometrico)
    indice = fuente.step_indice_geometrico;
  elseif isfield(cad, 'step_indice_geometrico') && isstruct(cad.step_indice_geometrico)
    indice = cad.step_indice_geometrico;
  elseif isfield(modelo, 'step_indice_geometrico') && isstruct(modelo.step_indice_geometrico)
    indice = modelo.step_indice_geometrico;
  endif

  % Survey explicito
  if isfield(fuente, 'survey') && ~isempty(fuente.survey)
    survey = fuente.survey;
  endif

  if incluir_pozo && isempty(survey) && usar_geom_act
    try
      [survey, ~, ~] = aos_obtener_geometria_activa();
    catch
      survey = [];
    end_try_catch
  endif

  % id_index_step para asset_id de ocurrencias
  if ~isfield(modelo, 'id_index_step') && isfield(cad, 'id_index_step')
    modelo.id_index_step = cad.id_index_step;
  endif
  if ~isfield(modelo, 'activos') && isfield(cad, 'activos')
    modelo.activos = cad.activos;
  endif

  fuentes.red = incluir_red && tiene_red_local(modelo);
  fuentes.pozo = incluir_pozo && ~isempty(survey);
  fuentes.step = incluir_step && tiene_indice_local(indice);
endfunction

function tf = tiene_red_local(modelo)
  tf = false;
  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada'), return; endif
  te = modelo.tablas_entrada;
  n_n = 0; n_t = 0;
  if isfield(te, 'nodos'), n_n = numel(te.nodos); endif
  if isfield(te, 'tramos'), n_t = numel(te.tramos); endif
  tf = (n_n + n_t) > 0;
endfunction

function tf = tiene_indice_local(indice)
  tf = false;
  if ~isstruct(indice), return; endif
  if isfield(indice, 'ocurrencias') && ~isempty(indice.ocurrencias)
    tf = true; return;
  endif
  if isfield(indice, 'productos') && ~isempty(indice.productos)
    tf = true;
  endif
endfunction

function [objs, fuentes] = objetos_red_local(modelo, fuentes)
  objs = {};
  if ~tiene_red_local(modelo), return; endif
  fuentes.red = true;
  te = modelo.tablas_entrada;
  nodos = {};
  tramos = {};
  if isfield(te, 'nodos'), nodos = te.nodos; endif
  if isfield(te, 'tramos'), tramos = te.tramos; endif
  if ~iscell(nodos), nodos = {}; endif
  if ~iscell(tramos), tramos = {}; endif

  mapa_xyz = struct();
  for i = 1:numel(nodos)
    n = nodos{i};
    if ~isstruct(n), continue; endif
    nid = '';
    if isfield(n, 'id'), nid = char(n.id); endif
    x = num_campo_local(n, 'x', 0);
    y = num_campo_local(n, 'y', 0);
    z = num_campo_local(n, 'z', 0);
    if ~isempty(nid)
      mapa_xyz.(safe_key_local(nid)) = [x, y, z];
    endif
    aid = '';
    if isfield(n, 'asset_id'), aid = char(n.asset_id); endif
    obj = objeto_base_local('NODO', aid, '', 'RED');
    obj.id = nid;
    obj.puntos = [x, y, z];
    obj.bbox = bbox_de_puntos_local(obj.puntos);
    objs{end+1} = obj; %#ok<AGROW>
  endfor

  for i = 1:numel(tramos)
    tr = tramos{i};
    if ~isstruct(tr), continue; endif
    tid = '';
    if isfield(tr, 'id'), tid = char(tr.id); endif
    [p1, p2] = extremos_tramo_local(tr, mapa_xyz);
    aid = '';
    if isfield(tr, 'asset_id'), aid = char(tr.asset_id); endif
    obj = objeto_base_local('TRAMO', aid, '', 'RED');
    obj.id = tid;
    obj.puntos = [p1; p2];
    obj.bbox = bbox_de_puntos_local(obj.puntos);
    objs{end+1} = obj; %#ok<AGROW>
  endfor
endfunction

function [p1, p2] = extremos_tramo_local(tr, mapa_xyz)
  x1 = num_campo_local(tr, 'x1', NaN);
  y1 = num_campo_local(tr, 'y1', NaN);
  x2 = num_campo_local(tr, 'x2', NaN);
  y2 = num_campo_local(tr, 'y2', NaN);
  z1 = 0; z2 = 0;
  if isfield(tr, 'nodo_o')
    k = safe_key_local(char(tr.nodo_o));
    if isfield(mapa_xyz, k)
      p = mapa_xyz.(k);
      if ~isfinite(x1), x1 = p(1); endif
      if ~isfinite(y1), y1 = p(2); endif
      z1 = p(3);
    endif
  endif
  if isfield(tr, 'nodo_d')
    k = safe_key_local(char(tr.nodo_d));
    if isfield(mapa_xyz, k)
      p = mapa_xyz.(k);
      if ~isfinite(x2), x2 = p(1); endif
      if ~isfinite(y2), y2 = p(2); endif
      z2 = p(3);
    endif
  endif
  if ~isfinite(x1), x1 = 0; endif
  if ~isfinite(y1), y1 = 0; endif
  if ~isfinite(x2), x2 = 0; endif
  if ~isfinite(y2), y2 = 0; endif
  p1 = [x1, y1, z1];
  p2 = [x2, y2, z2];
endfunction

function [obj, fuentes] = objeto_pozo_local(survey, fuentes)
  obj = [];
  if isempty(survey), return; endif
  pts = survey_a_xyz_local(survey);
  if size(pts, 1) < 2, return; endif
  fuentes.pozo = true;
  obj = objeto_base_local('POZO', '', '', 'POZO');
  obj.id = 'POZO';
  obj.puntos = pts;
  obj.bbox = bbox_de_puntos_local(pts);
endfunction

function pts = survey_a_xyz_local(survey)
  pts = zeros(0, 3);
  if ~isstruct(survey) || ~isfield(survey, 'MD') || ~isfield(survey, 'TVD')
    return;
  endif
  md = double(survey.MD(:));
  tvd = double(survey.TVD(:));
  n = min(numel(md), numel(tvd));
  if n < 2, return; endif
  md = md(1:n); tvd = tvd(1:n);
  inc = zeros(n, 1); azi = zeros(n, 1);
  if isfield(survey, 'inclinacion') && numel(survey.inclinacion) >= n
    inc = double(survey.inclinacion(1:n)(:));
  endif
  if isfield(survey, 'azimut') && numel(survey.azimut) >= n
    azi = double(survey.azimut(1:n)(:));
  endif
  norte = zeros(n, 1); este = zeros(n, 1);
  for i = 2:n
    dmd = md(i) - md(i-1);
    i1 = inc(i-1) * pi / 180; i2 = inc(i) * pi / 180;
    a1 = azi(i-1) * pi / 180; a2 = azi(i) * pi / 180;
    dogleg = acos(max(-1, min(1, cos(i2 - i1) - sin(i1) * sin(i2) * (1 - cos(a2 - a1)))));
    rf = 1;
    if abs(dogleg) > 1e-10, rf = 2 / dogleg * tan(dogleg / 2); endif
    dn = 0.5 * dmd * (sin(i1) * cos(a1) + sin(i2) * cos(a2)) * rf;
    de = 0.5 * dmd * (sin(i1) * sin(a1) + sin(i2) * sin(a2)) * rf;
    norte(i) = norte(i-1) + dn;
    este(i) = este(i-1) + de;
  endfor
  % Este, Norte, -TVD (misma convencion que survey 3D del repo)
  pts = [este, norte, -tvd];
endfunction

function [objs, fuentes] = objetos_step_local(indice, modelo, fuentes)
  objs = {};
  if ~tiene_indice_local(indice), return; endif

  mapa_aid = mapa_asset_step_local(modelo);
  ocurrencias = {};
  if isfield(indice, 'ocurrencias') && iscell(indice.ocurrencias)
    ocurrencias = indice.ocurrencias;
  endif

  if ~isempty(ocurrencias)
    fuentes.step = true;
    for i = 1:numel(ocurrencias)
      oc = ocurrencias{i};
      if ~isstruct(oc), continue; endif
      objs{end+1} = caja_step_local(oc, mapa_aid); %#ok<AGROW>
    endfor
    return;
  endif

  % Sin NAUO: caja por producto con bbox determinada (pieza unica)
  productos = {};
  if isfield(indice, 'productos') && iscell(indice.productos)
    productos = indice.productos;
  endif
  for i = 1:numel(productos)
    p = productos{i};
    if ~isstruct(p), continue; endif
    if isfield(p, 'bbox_determinada') && ~p.bbox_determinada, continue; endif
    fuentes.step = true;
    objs{end+1} = caja_step_local(p, mapa_aid); %#ok<AGROW>
  endfor
endfunction

function obj = caja_step_local(ent, mapa_aid)
  gid = '';
  if isfield(ent, 'geometry_id'), gid = char(ent.geometry_id); endif
  aid = '';
  if isfield(ent, 'asset_id') && ~isempty(ent.asset_id)
    aid = char(ent.asset_id);
  endif
  key_nom = '';
  if isfield(ent, 'nombre'), key_nom = char(ent.nombre); endif
  if isempty(aid) && ~isempty(key_nom) && isfield(mapa_aid, safe_key_local(key_nom))
    aid = mapa_aid.(safe_key_local(key_nom));
  endif
  if isempty(aid) && isfield(ent, 'product_id')
    pk = char(ent.product_id);
    if isfield(mapa_aid, safe_key_local(pk))
      aid = mapa_aid.(safe_key_local(pk));
    endif
  endif

  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  if isfield(ent, 'bbox_absoluta') && isstruct(ent.bbox_absoluta)
    bb = ent.bbox_absoluta;
  endif
  ancla = [];
  if isfield(ent, 'ancla') && isnumeric(ent.ancla) && numel(ent.ancla) >= 3 ...
      && all(isfinite(ent.ancla(1:3)))
    ancla = double(ent.ancla(1:3)(:)');
  elseif isfield(bb, 'xmin') && isfinite(bb.xmin)
    ancla = [(bb.xmin + bb.xmax) / 2, (bb.ymin + bb.ymax) / 2, ...
      (bb.zmin + bb.zmax) / 2];
  endif

  obj = objeto_base_local('EQUIPO_3D', aid, gid, 'STEP');
  if isfield(ent, 'nombre'), obj.id = char(ent.nombre); endif
  obj.ancla = ancla;
  obj.bbox = bb;
  obj.puntos = corners_bbox_local(bb);
  if isempty(obj.puntos) && ~isempty(ancla) && all(isfinite(ancla))
    obj.puntos = ancla;
  endif
endfunction

function mapa = mapa_asset_step_local(modelo)
  mapa = struct();
  if ~isstruct(modelo), return; endif
  if isfield(modelo, 'id_index_step') && isstruct(modelo.id_index_step) && ...
      isfield(modelo.id_index_step, 'items')
    items = modelo.id_index_step.items;
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
endfunction

function obj = objeto_base_local(tipo, asset_id, geometry_id, origen)
  obj = struct();
  obj.tipo = char(tipo);
  obj.asset_id = char(asset_id);
  obj.geometry_id = char(geometry_id);
  obj.origen = char(origen);
  obj.puntos = zeros(0, 3);
  obj.bbox = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  obj.visible = true;
  obj.id = '';
  % Vacio (no NaN): isequal trata NaN~=NaN y romperia determinismo V2.
  obj.ancla = [];
endfunction

function bb = bbox_de_puntos_local(pts)
  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
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

function bb = bbox_global_local(objetos)
  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  pts = zeros(0, 3);
  for i = 1:numel(objetos)
    o = objetos{i};
    if isfield(o, 'puntos') && ~isempty(o.puntos)
      pts = [pts; o.puntos]; %#ok<AGROW>
    elseif isfield(o, 'bbox')
      c = corners_bbox_local(o.bbox);
      if ~isempty(c), pts = [pts; c]; endif %#ok<AGROW>
    endif
  endfor
  if isempty(pts), return; endif
  bb = bbox_de_puntos_local(pts);
endfunction

function [objs, items, fuentes] = objetos_puertos_local(modelo, opciones, fuentes)
  objs = {};
  items = {};
  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada'), return; endif
  te = modelo.tablas_entrada;
  if ~isfield(te, 'puertos') || isempty(te.puertos), return; endif

  [p3, it_p] = aos_cad_puertos_3d(modelo, opciones);
  for k = 1:numel(it_p)
    items{end+1} = it_p{k}; %#ok<AGROW>
  endfor

  opt_c = opciones;
  if ~isfield(opt_c, 'tolerancia_m') && isfield(modelo, 'topologia') ...
      && isstruct(modelo.topologia) && isfield(modelo.topologia, 'tolerancia_m')
    opt_c.tolerancia_m = modelo.topologia.tolerancia_m;
  endif
  [cnx, it_c] = aos_cad_conexiones_3d(p3, opt_c);
  for k = 1:numel(it_c)
    items{end+1} = it_c{k}; %#ok<AGROW>
  endfor

  mapa_pto = struct();
  if isfield(p3, 'lista')
    for i = 1:numel(p3.lista)
      p = p3.lista{i};
      if ~isstruct(p) || ~isfield(p, 'id'), continue; endif
      mapa_pto.(safe_key_local(char(p.id))) = p;

      if ~isfield(p, 'posicion_resuelta') || ~p.posicion_resuelta, continue; endif
      pos = p.posicion;
      xyz = [double(pos.x(1)), double(pos.y(1)), double(pos.z(1))];
      aid = '';
      if isfield(p, 'asset_id_componente'), aid = char(p.asset_id_componente); endif
      gid = '';
      if isfield(p, 'geometry_id'), gid = char(p.geometry_id); endif
      obj = objeto_base_local('PUERTO', aid, gid, 'PUERTOS');
      obj.id = char(p.id);
      obj.puntos = xyz;
      obj.bbox = bbox_de_puntos_local(obj.puntos);
      obj.ancla = xyz;
      if isfield(p, 'nodo_ref'), obj.nodo_ref = char(p.nodo_ref); endif
      objs{end+1} = obj; %#ok<AGROW>
    endfor
  endif

  for i = 1:numel(cnx)
    c = cnx{i};
    if ~isstruct(c), continue; endif
    est = '';
    if isfield(c, 'estado'), est = char(c.estado); endif
    if strcmp(est, 'ABIERTA'), continue; endif
    pa = ''; pb = '';
    if isfield(c, 'puerto_a'), pa = char(c.puerto_a); endif
    if isfield(c, 'puerto_b'), pb = char(c.puerto_b); endif
    if isempty(pa) || isempty(pb), continue; endif
    ka = safe_key_local(pa); kb = safe_key_local(pb);
    if ~isfield(mapa_pto, ka) || ~isfield(mapa_pto, kb), continue; endif
    pa_s = mapa_pto.(ka); pb_s = mapa_pto.(kb);
    if ~isfield(pa_s, 'posicion_resuelta') || ~pa_s.posicion_resuelta, continue; endif
    if ~isfield(pb_s, 'posicion_resuelta') || ~pb_s.posicion_resuelta, continue; endif
    p1 = [double(pa_s.posicion.x(1)), double(pa_s.posicion.y(1)), ...
      double(pa_s.posicion.z(1))];
    p2 = [double(pb_s.posicion.x(1)), double(pb_s.posicion.y(1)), ...
      double(pb_s.posicion.z(1))];
    aid = '';
    if isfield(pa_s, 'asset_id_componente') && ~isempty(pa_s.asset_id_componente)
      aid = char(pa_s.asset_id_componente);
    endif
    gid = '';
    if isfield(pa_s, 'geometry_id'), gid = char(pa_s.geometry_id); endif
    obj = objeto_base_local('CONEXION', aid, gid, 'PUERTOS');
    if isfield(c, 'id'), obj.id = char(c.id); endif
    obj.puntos = [p1; p2];
    obj.bbox = bbox_de_puntos_local(obj.puntos);
    obj.puerto_a = pa;
    obj.puerto_b = pb;
    if isfield(c, 'nodo_ref'), obj.nodo_ref = char(c.nodo_ref); endif
    if isfield(c, 'estado'), obj.estado = char(c.estado); endif
    objs{end+1} = obj; %#ok<AGROW>
  endfor

  if ~isempty(objs)
    fuentes.puertos = true;
  endif
endfunction

function c = contar_tipos_local(objetos)
  % Base congelada R14; PUERTO/CONEXION solo aparecen si hay objetos (aditivo).
  c = struct('NODO', 0, 'TRAMO', 0, 'POZO', 0, 'EQUIPO_3D', 0);
  for i = 1:numel(objetos)
    t = char(objetos{i}.tipo);
    if isfield(c, t)
      c.(t) = c.(t) + 1;
    else
      c.(t) = 1;
    endif
  endfor
endfunction

function v = num_campo_local(s, nom, def)
  v = def;
  if isfield(s, nom) && isnumeric(s.(nom)) && ~isempty(s.(nom))
    v = double(s.(nom)(1));
  endif
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction

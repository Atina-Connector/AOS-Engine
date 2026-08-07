function modelo = aos_cad_mapear_objetos(cad, silencioso)
% AOS_CAD_MAPEAR_OBJETOS Normaliza inventario DXF a tablas AOSCAD (fuente primaria).
% Aplica metadatos del plano (AOS_META / capa / ATTRIB) antes de DEFAULT_MODULO.
% NO escribe .aoscad.
  global CONFIG_ACTIVA;
  if nargin < 2, silencioso = false; endif
  if nargin < 1 || isempty(cad)
    if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
        ~isfield(CONFIG_ACTIVA, 'cad_topologia')
      error('AOS CAD_TOPO: no hay cad_topologia importada. Importe un DXF primero.');
    endif
    cad = CONFIG_ACTIVA.cad_topologia;
  endif

  prefs = aos_cad_topo_preferencias('cargar');
  meta_tol = 2.0;
  if isfield(prefs, 'meta_tol_m') && ~isempty(prefs.meta_tol_m)
    meta_tol = prefs.meta_tol_m;
  endif

  % Unidades DXF -> SI (metros). Escala geometria una sola vez antes del mapeo.
  [factor_m, nombre_u, origen_u, adv_u] = aos_cad_unidades_dxf(cad, prefs);
  origen_geom = origen_u;
  if strcmp(origen_u, 'DEFAULT_MODULO')
    origen_geom = 'DXF';
  endif
  cad = escalar_geometria_dxf_local(cad, factor_m);

  dxf_clase = detectar_dxf_clase_local(cad);
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', dxf_clase, 'HIDRAULICO');
  if isfield(cad, 'dxf_archivo'), modelo.info.fuente_dxf = char(cad.dxf_archivo); endif
  modelo.geometria.unidades = 'm';
  modelo.unidades_dxf = struct('factor', factor_m, 'nombre', nombre_u, 'origen', origen_u);
  if isfield(cad, 'sistema_coordenadas') && ~isempty(cad.sistema_coordenadas)
    modelo.geometria.sistema_coordenadas = char(cad.sistema_coordenadas);
  endif
  if isfield(cad, 'bloques')
    modelo.geometria.bloques = cad.bloques;
  endif
  if isfield(cad, 'capas')
    modelo.geometria.capas = cad.capas;
  endif

  entidades = {};
  if isfield(cad, 'entidades'), entidades = cad.entidades; endif
  modelo.geometria.entidades_dxf = entidades;

  metas = aos_cad_extraer_metadatos(entidades, prefs);

  % --- GALERIAS: tablas camaras/ramales/accesos (sin red hidraulica de pozos) ---
  if strcmp(dxf_clase, 'GALERIAS')
    modelo = mapear_galerias_local(modelo, entidades, metas, meta_tol, cad, silencioso);
    % Persistir geometria escalada tambien en rama galerias
    global CONFIG_ACTIVA;
    if isstruct(CONFIG_ACTIVA) && isfield(CONFIG_ACTIVA, 'cad_topologia')
      CONFIG_ACTIVA.cad_topologia.entidades = cad.entidades;
      if isfield(cad, 'bloques'), CONFIG_ACTIVA.cad_topologia.bloques = cad.bloques; endif
      CONFIG_ACTIVA.cad_topologia.unidades = 'm';
      CONFIG_ACTIVA.cad_topologia.unidades_dxf = modelo.unidades_dxf;
    endif
    return;
  endif

  nodos = {};
  tramos = {};
  equipos = {};
  accesorios = {};
  valvulas = {};
  bcs = {};
  n_dxf = 0;
  n_def = 0;

  % 1) CIRCLE / INSERT → nodos + equipos
  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getfield_safe(e, 'entity_type', '')));
    capa = upper(char(getfield_safe(e, 'layer', '')));
    geom = getfield_safe(e, 'geometry', []);
    if isempty(geom), continue; endif

    if strcmp(tipo, 'CIRCLE') || strcmp(tipo, 'INSERT')
      xy = geom(1, 1:min(2, size(geom, 2)));
      if numel(xy) < 2, continue; endif
      nid = sprintf('N%03d', numel(nodos) + 1);
      nodo = struct();
      nodo.id = nid;
      nodo.x = xy(1); nodo.y = xy(2); nodo.z = 0;
      if size(geom, 2) >= 3, nodo.z = geom(1, 3); endif
      nodo.tipo = clasificar_nodo_local(capa, tipo, e);
      nodo.cota = campo_ok_local(nodo.z, 'm', origen_geom, 'OK', '');
      nodo.handle = char(getfield_safe(e, 'handle', ''));
      nodo.capa = char(getfield_safe(e, 'layer', ''));
      nodo.estado_conexion = 'CONFIRMADA';
      nodos{end+1} = nodo; %#ok<AGROW>

      eq = struct();
      eq.id = sprintf('EQ%03d', numel(equipos) + 1);
      eq.nodo_ref = nid;
      eq.tipo = clasificar_equipo_local(capa, tipo, e);
      eq.etiqueta = char(getfield_safe(e, 'block_name', ''));
      if isempty(eq.etiqueta)
        eq.etiqueta = sprintf('%s_%s', eq.tipo, nid);
      endif
      r0 = getfield_safe(e, 'radius', 0.05);
      if isnan(r0), r0 = 0.05; endif
      eq.diametro_equiv_m = campo_ok_local(r0 * 2, 'm', origen_geom, 'OK', '');
      eq.capa = char(getfield_safe(e, 'layer', ''));
      eq.handle = char(getfield_safe(e, 'handle', ''));
      eq.block_name = char(getfield_safe(e, 'block_name', ''));
      eq.insert_x = xy(1);
      eq.insert_y = xy(2);
      n_dxf = n_dxf + 1;

      % Meta cerca del equipo/nodo (ID / TIPO=BOMBA / curva)
      [meta, ~] = aos_cad_meta_cercana(metas, xy(1), xy(2), meta_tol, {'AOS_META', capa});
      if ~isempty(meta)
        app = aos_cad_meta_aplicar(meta.keys, meta.fuente);
        if ~isempty(app.id)
          eq.etiqueta = app.id;
          eq.id_estable = app.id;
          n_dxf = n_dxf + 1;
        endif
        if ~isempty(app.TIPO) && strcmp(app.TIPO, 'BOMBA')
          eq.tipo = 'BOMBA';
          n_dxf = n_dxf + 1;
        endif
        [eq, n_add] = aplicar_meta_bomba_local(eq, app);
        n_dxf = n_dxf + n_add;
      endif
      if ~isempty(strfind(capa, 'BOMBA')) || ~isempty(strfind(capa, 'PUMP'))
        eq.tipo = 'BOMBA';
      endif
      equipos{end+1} = eq; %#ok<AGROW>
    endif
  endfor

  % 2) TEXT/MTEXT → etiquetas cercanas / valvulas por texto (no AOS_META puro)
  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getfield_safe(e, 'entity_type', '')));
    if ~ismember(tipo, {'TEXT', 'MTEXT'}), continue; endif
    txt = char(getfield_safe(e, 'text', ''));
    geom = getfield_safe(e, 'geometry', []);
    capa = upper(char(getfield_safe(e, 'layer', '')));
    if isempty(txt) || isempty(geom), continue; endif
    if strcmp(capa, 'AOS_META') || ~isempty(strfind(upper(txt), ' D=')) ...
        || ~isempty(strfind(upper(txt), 'MAT=')) || ~isempty(strfind(upper(txt), 'TIPO='))
      continue; % metadatos tecnicos, no etiqueta
    endif
    xy = geom(1, 1:min(2, size(geom, 2)));
    [idxn, dmin] = aos_geom_punto_mas_cercano(nodos, xy(1), xy(2), []);
    nid = '';
    if ~isempty(idxn), nid = nodos{idxn}.id; endif
    if ~isempty(nid) && dmin <= 5.0
      for k = 1:numel(equipos)
        if strcmp(equipos{k}.nodo_ref, nid)
          equipos{k}.etiqueta = txt; %#ok<AGROW>
        endif
      endfor
    endif
    utxt = upper(txt);
    if (~isempty(strfind(utxt, 'VALV')) || ~isempty(strfind(utxt, 'VLV')) ...
        || ~isempty(strfind(capa, 'VALV'))) && ~isempty(nid)
      if ~valvula_existe_en_nodo_local(valvulas, nid)
        v = struct();
        v.id = sprintf('V%03d', numel(valvulas) + 1);
        v.nodo_ref = nid;
        v.tramo_ref = '';
        v.estado = campo_ok_local('ABIERTA', '', 'DXF', 'OK', '');
        [v.Kv, n_dxf, n_def] = campo_default_local(100, 'm3/h', n_dxf, n_def);
        v.etiqueta = txt;
        valvulas{end+1} = v; %#ok<AGROW>
      endif
    endif
  endfor

  % 3) LINE / LWPOLYLINE / POLYLINE → tramos
  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getfield_safe(e, 'entity_type', '')));
    if ~ismember(tipo, {'LINE', 'LWPOLYLINE', 'POLYLINE'}), continue; endif
    geom = getfield_safe(e, 'geometry', []);
    if isempty(geom) || size(geom, 1) < 2, continue; endif
    capa = char(getfield_safe(e, 'layer', ''));

    for s = 1:(size(geom, 1) - 1)
      p1 = geom(s, 1:min(3, size(geom, 2)));
      p2 = geom(s + 1, 1:min(3, size(geom, 2)));
      if numel(p1) < 2 || numel(p2) < 2, continue; endif
      if any(isnan(p1(1:2))) || any(isnan(p2(1:2))), continue; endif
      if hypot(p2(1) - p1(1), p2(2) - p1(2)) < 1e-9, continue; endif

      [nodos, id_o] = asegurar_nodo_local(nodos, p1, 0.05, 'INFERIDA_POR_PROXIMIDAD');
      [nodos, id_d] = asegurar_nodo_local(nodos, p2, 0.05, 'INFERIDA_POR_PROXIMIDAD');
      if strcmp(id_o, id_d), continue; endif

      tid = sprintf('T%03d', numel(tramos) + 1);
      L = hypot(p2(1) - p1(1), p2(2) - p1(2));
      mx = (p1(1) + p2(1)) / 2;
      my = (p1(2) + p2(2)) / 2;

      tr = struct();
      tr.id = tid;
      tr.nodo_o = id_o;
      tr.nodo_d = id_d;
      tr.longitud_m = campo_ok_local(L, 'm', origen_geom, 'OK', '');
      tr.capa = capa;
      tr.handle = char(getfield_safe(e, 'handle', ''));
      tr.x1 = p1(1); tr.y1 = p1(2);
      tr.x2 = p2(1); tr.y2 = p2(2);

      % --- metadatos: TEXT AOS_META > capa > default ---
      [meta, ~] = aos_cad_meta_cercana(metas, mx, my, meta_tol, {'AOS_META', capa});
      app = struct();
      fuente = '';
      if ~isempty(meta)
        fuente = meta.fuente;
        app = aos_cad_meta_aplicar(meta.keys, fuente);
      endif
      if isempty(fieldnames_safe(app)) || (isempty(app.diametro_m) && isempty(app.material) && isempty(app.rugosidad))
        keys_capa = aos_cad_meta_parse_capa(capa);
        if ~isempty(fieldnames(keys_capa))
          app2 = aos_cad_meta_aplicar(keys_capa, 'CAPA');
          app = merge_app_local(app, app2);
          if isempty(fuente), fuente = 'CAPA'; endif
        endif
      endif

      if ~isempty(app) && isfield(app, 'diametro_m') && ~isempty(app.diametro_m)
        tr.diametro_m = campo_ok_local(app.diametro_m, 'm', app.origen_diametro, ...
          app.estado_diametro, app.adv_diametro);
        n_dxf = n_dxf + 1;
      else
        [tr.diametro_m, n_dxf, n_def] = campo_default_local(0.1, 'm', n_dxf, n_def);
      endif

      if ~isempty(app) && isfield(app, 'material') && ~isempty(app.material)
        tr.material = campo_ok_local(app.material, '', app.origen_material, ...
          app.estado_material, app.adv_material);
        n_dxf = n_dxf + 1;
      else
        [tr.material, n_dxf, n_def] = campo_default_local('ACERO', '', n_dxf, n_def);
      endif

      if ~isempty(app) && isfield(app, 'rugosidad') && ~isempty(app.rugosidad)
        tr.rugosidad = campo_ok_local(app.rugosidad, 'm', app.origen_rugosidad, ...
          app.estado_rugosidad, app.adv_rugosidad);
        n_dxf = n_dxf + 1;
      else
        [tr.rugosidad, n_dxf, n_def] = campo_default_local(0.045e-3, 'm', n_dxf, n_def);
      endif

      if ~isempty(app) && isfield(app, 'id') && ~isempty(app.id)
        tr.id_estable = app.id;
        tr.etiqueta = app.id;
      endif

      tramos{end+1} = tr; %#ok<AGROW>
    endfor
  endfor

  % 4) BC: primero metas P/Q cerca de nodos; si hay >=1 P/Q explicito, NO inventar
  bc_nodos_p = {};
  bc_nodos_q = {};
  bc_nodos_qg = {};
  for i = 1:numel(metas)
    m = metas{i};
    app = aos_cad_meta_aplicar(m.keys, m.fuente);
    if isempty(app.P) && isempty(app.Q) && isempty(app.QG), continue; endif
    [idxn, dmin] = aos_geom_punto_mas_cercano(nodos, m.x, m.y, []);
    nid = '';
    if ~isempty(idxn), nid = nodos{idxn}.id; endif
    if isempty(nid) || dmin > meta_tol, continue; endif
    if ~isempty(app.P) && ~ismember(nid, bc_nodos_p)
      bc = struct();
      bc.id = sprintf('BC%03d', numel(bcs) + 1);
      bc.nodo_ref = nid;
      bc.tipo_bc = 'PRESION';
      bc.valor = campo_ok_local(app.P, 'Pa', app.origen_P, 'OK', '');
      bc.unidad = 'Pa';
      bcs{end+1} = bc; %#ok<AGROW>
      bc_nodos_p{end+1} = nid; %#ok<AGROW>
      n_dxf = n_dxf + 1;
    endif
    if ~isempty(app.Q) && ~ismember(nid, bc_nodos_q)
      bc = struct();
      bc.id = sprintf('BC%03d', numel(bcs) + 1);
      bc.nodo_ref = nid;
      bc.tipo_bc = 'CAUDAL';
      bc.valor = campo_ok_local(app.Q, 'm3/s', app.origen_Q, 'OK', '');
      bc.unidad = 'm3/s';
      bcs{end+1} = bc; %#ok<AGROW>
      bc_nodos_q{end+1} = nid; %#ok<AGROW>
      n_dxf = n_dxf + 1;
    endif
    if ~isempty(app.QG) && ~ismember(nid, bc_nodos_qg)
      bc = struct();
      bc.id = sprintf('BC%03d', numel(bcs) + 1);
      bc.nodo_ref = nid;
      bc.tipo_bc = 'CAUDAL_GAS_STD';
      bc.valor = campo_ok_local(app.QG, 'Sm3/s', app.origen_QG, 'OK', '');
      bc.unidad = 'Sm3/s';
      bcs{end+1} = bc; %#ok<AGROW>
      bc_nodos_qg{end+1} = nid; %#ok<AGROW>
      n_dxf = n_dxf + 1;
    endif
  endfor

  % 5) TIPO= desde AOS_META cerca de nodos → valvulas / bombas / accesorios
  for i = 1:numel(metas)
    m = metas{i};
    app = aos_cad_meta_aplicar(m.keys, m.fuente);
    if isempty(app.TIPO), continue; endif
    [idxn, dmin] = aos_geom_punto_mas_cercano(nodos, m.x, m.y, []);
    nid = '';
    if ~isempty(idxn), nid = nodos{idxn}.id; endif
    if isempty(nid) || dmin > meta_tol, continue; endif
    tip = upper(char(app.TIPO));
    if strcmp(tip, 'VALVULA')
      if valvula_existe_en_nodo_local(valvulas, nid), continue; endif
      v = struct();
      v.id = sprintf('V%03d', numel(valvulas) + 1);
      if ~isempty(app.id), v.id = char(app.id); v.id_estable = char(app.id); endif
      v.nodo_ref = nid;
      v.tramo_ref = '';
      est = 'ABIERTA';
      if ~isempty(app.ESTADO), est = char(app.ESTADO); endif
      v.estado = campo_ok_local(est, '', app.origen_ESTADO, 'OK', '');
      if isempty(app.origen_ESTADO)
        v.estado = campo_ok_local(est, '', 'TEXTO_AOS_META', 'OK', '');
      endif
      if ~isempty(app.KV)
        v.Kv = campo_ok_local(app.KV, 'm3/h', app.origen_KV, 'OK', '');
        n_dxf = n_dxf + 1;
      else
        [v.Kv, n_dxf, n_def] = campo_default_local(100, 'm3/h', n_dxf, n_def);
      endif
      v.etiqueta = tip;
      if ~isempty(app.id), v.etiqueta = char(app.id); endif
      valvulas{end+1} = v; %#ok<AGROW>
      n_dxf = n_dxf + 1;
    elseif strcmp(tip, 'BOMBA')
      % Reforzar equipo BOMBA en el nodo (crear si no hay)
      hay = false;
      for k = 1:numel(equipos)
        if strcmp(equipos{k}.nodo_ref, nid)
          equipos{k}.tipo = 'BOMBA'; %#ok<AGROW>
          if ~isempty(app.id)
            equipos{k}.etiqueta = char(app.id); %#ok<AGROW>
            equipos{k}.id_estable = char(app.id); %#ok<AGROW>
          endif
          [equipos{k}, n_add] = aplicar_meta_bomba_local(equipos{k}, app); %#ok<AGROW>
          n_dxf = n_dxf + n_add;
          hay = true;
        endif
      endfor
      if ~hay
        eq = struct();
        eq.id = sprintf('EQ%03d', numel(equipos) + 1);
        if ~isempty(app.id), eq.id = char(app.id); eq.id_estable = char(app.id); endif
        eq.nodo_ref = nid;
        eq.tipo = 'BOMBA';
        eq.etiqueta = 'BOMBA';
        if ~isempty(app.id), eq.etiqueta = char(app.id); endif
        eq.capa = 'AOS_META';
        [eq, n_add] = aplicar_meta_bomba_local(eq, app);
        n_dxf = n_dxf + n_add;
        equipos{end+1} = eq; %#ok<AGROW>
      endif
      n_dxf = n_dxf + 1;
    elseif ismember(tip, {'CODO', 'TEE', 'REDUCCION'})
      if accesorio_existe_en_nodo_local(accesorios, nid, tip), continue; endif
      ac = struct();
      ac.id = sprintf('AC%03d', numel(accesorios) + 1);
      if ~isempty(app.id), ac.id = char(app.id); ac.id_estable = char(app.id); endif
      ac.nodo_ref = nid;
      ac.tipo = tip;
      ac.etiqueta = tip;
      if ~isempty(app.id), ac.etiqueta = char(app.id); endif
      accesorios{end+1} = ac; %#ok<AGROW>
      n_dxf = n_dxf + 1;
    endif
  endfor

  % Solo inventar BC si NO hay ningun P/Q explicito
  if isempty(bcs) && ~isempty(nodos)
    bc1 = struct();
    bc1.id = 'BC001';
    bc1.nodo_ref = nodos{1}.id;
    bc1.tipo_bc = 'PRESION';
    [bc1.valor, n_dxf, n_def] = campo_default_local(1.5e6, 'Pa', n_dxf, n_def);
    bc1.unidad = 'Pa';
    bcs{end+1} = bc1;
    if numel(nodos) >= 2
      bc2 = struct();
      bc2.id = 'BC002';
      bc2.nodo_ref = nodos{end}.id;
      bc2.tipo_bc = 'CAUDAL';
      [bc2.valor, n_dxf, n_def] = campo_default_local(0.02, 'm3/s', n_dxf, n_def);
      bc2.unidad = 'm3/s';
      bcs{end+1} = bc2;
    endif
  endif

  modelo.tablas_entrada.nodos = nodos;
  modelo.tablas_entrada.tramos = tramos;
  modelo.tablas_entrada.equipos = equipos;
  modelo.tablas_entrada.accesorios = accesorios;
  modelo.tablas_entrada.valvulas = valvulas;
  modelo.tablas_entrada.condiciones_borde = bcs;

  n_bombas = 0;
  for i = 1:numel(equipos)
    if strcmpi(char(equipos{i}.tipo), 'BOMBA'), n_bombas = n_bombas + 1; endif
  endfor

  items = { ...
    struct('codigo', 'MAPEO_DXF', 'mensaje', sprintf( ...
      'Normalizado: %d nodos, %d tramos, %d equipos, %d valvulas, %d accesorios, %d BC', ...
      numel(nodos), numel(tramos), numel(equipos), numel(valvulas), ...
      numel(accesorios), numel(bcs)), 'severidad', 'INFO'), ...
    struct('codigo', 'META_DXF', 'mensaje', sprintf( ...
      'Campos desde plano=%d, defaults=%d, metas=%d', n_dxf, n_def, numel(metas)), ...
      'severidad', 'INFO')};
  sev_u = 'INFO';
  if ~isempty(adv_u), sev_u = 'ADVERTENCIA'; endif
  items{end+1} = struct('codigo', 'UNIDADES_DXF', 'mensaje', sprintf( ...
    'factor=%g nombre=%s origen=%s', factor_m, nombre_u, origen_u), ...
    'severidad', sev_u);
  for iu = 1:numel(adv_u)
    items{end+1} = struct('codigo', char(adv_u{iu}), 'mensaje', ...
      sprintf('Unidad DXF: %s', char(adv_u{iu})), 'severidad', 'ADVERTENCIA'); %#ok<AGROW>
  endfor
  if n_def > 0
    items{end+1} = struct('codigo', 'META_DEFAULT', 'mensaje', sprintf( ...
      '%d campos con DEFAULT_MODULO (sin metadato DXF)', n_def), 'severidad', 'ADVERTENCIA');
  endif
  modelo.validaciones.estado = 'OK';
  if n_def > 0 || ~isempty(adv_u), modelo.validaciones.estado = 'ADVERTENCIA'; endif
  modelo.validaciones.items = items;

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = cad;
  endif
  % Persistir geometria ya normalizada a metros (SI).
  CONFIG_ACTIVA.cad_topologia.entidades = cad.entidades;
  if isfield(cad, 'bloques'), CONFIG_ACTIVA.cad_topologia.bloques = cad.bloques; endif
  CONFIG_ACTIVA.cad_topologia.unidades = 'm';
  CONFIG_ACTIVA.cad_topologia.unidades_dxf = modelo.unidades_dxf;
  if isfield(cad, 'factor_escala_m')
    CONFIG_ACTIVA.cad_topologia.factor_escala_m = cad.factor_escala_m;
  endif
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.dxf_clase = dxf_clase;
  CONFIG_ACTIVA.cad_topologia.inventario_tabular = struct( ...
    'n_nodos', numel(nodos), ...
    'n_tramos', numel(tramos), ...
    'n_equipos', numel(equipos), ...
    'n_valvulas', numel(valvulas), ...
    'n_accesorios', numel(accesorios), ...
    'n_bombas', n_bombas, ...
    'n_bcs', numel(bcs), ...
    'n_campos_dxf', n_dxf, ...
    'n_campos_default', n_def, ...
    'n_metas', numel(metas));

  % Round-trip IDs si hay snapshot previo (reimport / remap)
  id_prev = [];
  if isfield(CONFIG_ACTIVA.cad_topologia, 'id_index')
    id_prev = CONFIG_ACTIVA.cad_topologia.id_index;
  endif
  try
    [modelo, ~, id_new] = aos_cad_merge_ids_reimport(modelo, id_prev, true);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    CONFIG_ACTIVA.cad_topologia.id_index = id_new;
  catch
    % merge opcional si no disponible
  end_try_catch

  % Asset_id determinista (despues del merge; id_estable ya reconciliado)
  try
    [modelo, ~] = aos_cad_asignar_asset_ids(modelo);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  catch
    % asignacion opcional si el servicio no esta disponible
  end_try_catch

  % Puertos solo-datos (2 por tramo; estado se refresca al construir topologia)
  try
    [modelo, ~] = aos_cad_puertos_derivar(modelo);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  catch
  end_try_catch

  if ~silencioso
    fprintf('\n--- OBJETOS AOS RECONOCIDOS (tablas; sin .aoscad) ---\n');
    fprintf('dxf_clase   : %s\n', dxf_clase);
    fprintf('nodos       : %d\n', numel(nodos));
    fprintf('tramos      : %d\n', numel(tramos));
    fprintf('equipos     : %d (bombas=%d)\n', numel(equipos), n_bombas);
    fprintf('valvulas    : %d\n', numel(valvulas));
    fprintf('accesorios  : %d\n', numel(accesorios));
    fprintf('BC          : %d\n', numel(bcs));
    fprintf('meta DXF    : %d campos | defaults: %d | etiquetas: %d\n', ...
      n_dxf, n_def, numel(metas));
    fprintf('Nota: .aoscad se escribe SOLO despues de simular.\n');
  endif
endfunction

function dxf_clase = detectar_dxf_clase_local(cad)
  dxf_clase = 'INSTALACION';
  capas = {};
  if isfield(cad, 'capas')
    for i = 1:numel(cad.capas)
      if isstruct(cad.capas{i}) && isfield(cad.capas{i}, 'name')
        capas{end+1} = upper(char(cad.capas{i}.name)); %#ok<AGROW>
      endif
    endfor
  endif
  blob = strjoin(capas, ' ');
  if ~isempty(strfind(blob, 'GALER')) || ~isempty(strfind(blob, 'TUNEL')) || ...
      ~isempty(strfind(blob, 'RAMAL')) || ~isempty(strfind(blob, 'CAMARA')) || ...
      ~isempty(strfind(blob, 'ACCESO'))
    dxf_clase = 'GALERIAS';
  endif
endfunction

function modelo = mapear_galerias_local(modelo, entidades, metas, meta_tol, cad, silencioso)
  global CONFIG_ACTIVA;
  camaras = {};
  ramales = {};
  accesos = {};
  n_dxf = 0; n_def = 0;

  % CIRCLE → camara (capa AOS_CAMARAS / GALER / TIPO=CAMARA)
  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getfield_safe(e, 'entity_type', '')));
    capa = upper(char(getfield_safe(e, 'layer', '')));
    geom = getfield_safe(e, 'geometry', []);
    if isempty(geom), continue; endif
    if ~strcmp(tipo, 'CIRCLE'), continue; endif
    if isempty(strfind(capa, 'CAMARA')) && isempty(strfind(capa, 'GALER')) ...
        && isempty(strfind(capa, 'WELL'))
      % aun aceptar CIRCLE genericos en planos galeria
    endif
    xy = geom(1, 1:min(2, size(geom, 2)));
    if numel(xy) < 2, continue; endif
    c = struct();
    c.id = sprintf('C%03d', numel(camaras) + 1);
    c.x = xy(1); c.y = xy(2); c.z = 0;
    if size(geom, 2) >= 3, c.z = geom(1, 3); endif
    r0 = getfield_safe(e, 'radius', 1.0);
    if isnan(r0), r0 = 1.0; endif
    c.radio_m = campo_ok_local(r0, 'm', 'DXF', 'OK', '');
    c.capa = char(getfield_safe(e, 'layer', ''));
    c.handle = char(getfield_safe(e, 'handle', ''));
    [meta, ~] = aos_cad_meta_cercana(metas, xy(1), xy(2), meta_tol, {'AOS_META', capa});
    if ~isempty(meta)
      app = aos_cad_meta_aplicar(meta.keys, meta.fuente);
      if ~isempty(app.id), c.id = char(app.id); c.id_estable = char(app.id); n_dxf = n_dxf + 1; endif
      if ~isempty(app.TIPO) && ~strcmp(app.TIPO, 'CAMARA') && ~strcmp(app.TIPO, '')
        % skip if meta says other tipo
      endif
    endif
    camaras{end+1} = c; %#ok<AGROW>
  endfor

  % LINE → ramal
  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getfield_safe(e, 'entity_type', '')));
    if ~ismember(tipo, {'LINE', 'LWPOLYLINE', 'POLYLINE'}), continue; endif
    geom = getfield_safe(e, 'geometry', []);
    if isempty(geom) || size(geom, 1) < 2, continue; endif
    capa = char(getfield_safe(e, 'layer', ''));
    for s = 1:(size(geom, 1) - 1)
      p1 = geom(s, 1:min(2, size(geom, 2)));
      p2 = geom(s + 1, 1:min(2, size(geom, 2)));
      if hypot(p2(1) - p1(1), p2(2) - p1(2)) < 1e-9, continue; endif
      [idx_o, ~] = aos_geom_punto_mas_cercano(camaras, p1(1), p1(2), []);
      [idx_d, ~] = aos_geom_punto_mas_cercano(camaras, p2(1), p2(2), []);
      cid_o = ''; cid_d = '';
      if ~isempty(idx_o), cid_o = camaras{idx_o}.id; endif
      if ~isempty(idx_d), cid_d = camaras{idx_d}.id; endif
      r = struct();
      r.id = sprintf('R%03d', numel(ramales) + 1);
      r.camara_o = cid_o;
      r.camara_d = cid_d;
      L = hypot(p2(1) - p1(1), p2(2) - p1(2));
      r.longitud_m = campo_ok_local(L, 'm', 'DXF', 'OK', '');
      r.capa = capa;
      r.handle = char(getfield_safe(e, 'handle', ''));
      r.x1 = p1(1); r.y1 = p1(2); r.x2 = p2(1); r.y2 = p2(2);
      mx = (p1(1)+p2(1))/2; my = (p1(2)+p2(2))/2;
      [meta, ~] = aos_cad_meta_cercana(metas, mx, my, meta_tol, {'AOS_META', capa});
      if ~isempty(meta)
        app = aos_cad_meta_aplicar(meta.keys, meta.fuente);
        if ~isempty(app.id), r.id = char(app.id); r.id_estable = char(app.id); n_dxf = n_dxf + 1; endif
      endif
      ramales{end+1} = r; %#ok<AGROW>
    endfor
  endfor

  % TEXT / POINT → acceso
  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getfield_safe(e, 'entity_type', '')));
    capa = upper(char(getfield_safe(e, 'layer', '')));
    geom = getfield_safe(e, 'geometry', []);
    if isempty(geom), continue; endif
    es_acceso = ~isempty(strfind(capa, 'ACCESO')) || strcmp(tipo, 'POINT');
    txt = '';
    if ismember(tipo, {'TEXT', 'MTEXT'})
      txt = char(getfield_safe(e, 'text', ''));
      if strcmp(capa, 'AOS_META') || ~isempty(strfind(upper(txt), 'TIPO=')) ...
          || ~isempty(strfind(upper(txt), ' D='))
        % META TIPO=ACCESO
        app = aos_cad_meta_aplicar(parse_meta_keys_quick_local(txt), 'TEXTO_AOS_META');
        if isempty(app.TIPO) || ~strcmp(app.TIPO, 'ACCESO')
          continue;
        endif
        es_acceso = true;
      elseif ~es_acceso
        continue;
      endif
    elseif ~es_acceso
      continue;
    endif
    xy = geom(1, 1:min(2, size(geom, 2)));
    if numel(xy) < 2, continue; endif
    a = struct();
    a.id = sprintf('A%03d', numel(accesos) + 1);
    a.x = xy(1); a.y = xy(2); a.z = 0;
    [idxc, ~] = aos_geom_punto_mas_cercano(camaras, xy(1), xy(2), []);
    cref = '';
    if ~isempty(idxc), cref = camaras{idxc}.id; endif
    a.camara_ref = cref;
    a.etiqueta = txt;
    a.capa = char(getfield_safe(e, 'layer', ''));
    a.handle = char(getfield_safe(e, 'handle', ''));
    if ismember(tipo, {'TEXT', 'MTEXT'}) && ~isempty(strfind(upper(txt), 'TIPO='))
      app = aos_cad_meta_aplicar(parse_meta_keys_quick_local(txt), 'TEXTO_AOS_META');
      if ~isempty(app.id), a.id = char(app.id); a.id_estable = char(app.id); a.etiqueta = char(app.id); n_dxf = n_dxf + 1; endif
    endif
    accesos{end+1} = a; %#ok<AGROW>
  endfor

  modelo.info.dominio_sim = 'HIDRAULICO';
  modelo.info.notas = 'GALERIAS: tablas camaras/ramales/accesos; sin solver oficial.';
  modelo.tablas_entrada.camaras = camaras;
  modelo.tablas_entrada.ramales = ramales;
  modelo.tablas_entrada.accesos = accesos;
  modelo.tablas_entrada.nodos = {};
  modelo.tablas_entrada.tramos = {};
  modelo.tablas_entrada.equipos = {};
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.accesorios = {};
  modelo.tablas_entrada.condiciones_borde = {};

  items = {struct('codigo', 'MAPEO_GALERIAS', 'mensaje', sprintf( ...
    'Galerias: %d camaras, %d ramales, %d accesos', ...
    numel(camaras), numel(ramales), numel(accesos)), 'severidad', 'INFO'), ...
    struct('codigo', 'GALERIAS_SIN_SOLVER', ...
      'mensaje', 'dxf_clase=GALERIAS sin corrida hidraulica de pozos', ...
      'severidad', 'ADVERTENCIA')};
  modelo.validaciones.estado = 'ADVERTENCIA';
  modelo.validaciones.items = items;

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = cad;
  endif
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.dxf_clase = 'GALERIAS';
  CONFIG_ACTIVA.cad_topologia.inventario_tabular = struct( ...
    'n_camaras', numel(camaras), 'n_ramales', numel(ramales), 'n_accesos', numel(accesos), ...
    'n_nodos', 0, 'n_tramos', 0, 'n_equipos', 0, 'n_valvulas', 0, 'n_accesorios', 0, ...
    'n_bombas', 0, 'n_bcs', 0, 'n_campos_dxf', n_dxf, 'n_campos_default', n_def, ...
    'n_metas', numel(metas));

  id_prev = [];
  if isfield(CONFIG_ACTIVA.cad_topologia, 'id_index')
    id_prev = CONFIG_ACTIVA.cad_topologia.id_index;
  endif
  try
    [modelo, ~, id_new] = aos_cad_merge_ids_reimport(modelo, id_prev, true);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    CONFIG_ACTIVA.cad_topologia.id_index = id_new;
  catch
  end_try_catch

  try
    [modelo, ~] = aos_cad_asignar_asset_ids(modelo);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  catch
  end_try_catch

  try
    [modelo, ~] = aos_cad_puertos_derivar(modelo);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  catch
  end_try_catch

  if ~silencioso
    fprintf('\n--- OBJETOS GALERIAS (tablas; sin .aoscad) ---\n');
    fprintf('dxf_clase   : GALERIAS\n');
    fprintf('camaras     : %d\n', numel(camaras));
    fprintf('ramales     : %d\n', numel(ramales));
    fprintf('accesos     : %d\n', numel(accesos));
    fprintf('Nota: sin solver de galerias; .aoscad solo post-sim (si aplica).\n');
  endif
endfunction

function keys = parse_meta_keys_quick_local(txt)
  keys = struct();
  t = strtrim(char(txt));
  if strncmpi(t, 'AOS ', 4), t = strtrim(t(5:end)); endif
  parts = regexp(t, '[\s;,]+', 'split');
  for i = 1:numel(parts)
    part = strtrim(parts{i});
    eq = strfind(part, '=');
    if isempty(eq), continue; endif
    k = upper(strtrim(part(1:eq(1)-1)));
    v = strtrim(part(eq(1)+1:end));
    if ~isempty(k) && ~isempty(v), keys.(k) = v; endif
  endfor
endfunction

function t = clasificar_nodo_local(capa, tipo, e)
  if ~isempty(strfind(capa, 'WELL')) || ~isempty(strfind(capa, 'POZO'))
    t = 'POZO';
  elseif ~isempty(strfind(capa, 'EQUIPO')) || strcmp(tipo, 'INSERT')
    t = 'EQUIPO';
  else
    t = 'JUNCTION';
  endif
endfunction

function t = clasificar_equipo_local(capa, tipo, e)
  if ~isempty(strfind(capa, 'WELL')) || ~isempty(strfind(capa, 'POZO'))
    t = 'POZO';
  elseif ~isempty(strfind(capa, 'BOMBA')) || ~isempty(strfind(capa, 'PUMP'))
    t = 'BOMBA';
  else
    t = 'EQUIPO';
  endif
endfunction

function [nodos, nid] = asegurar_nodo_local(nodos, p, tol, estado)
  x = p(1); y = p(2); z = 0;
  if numel(p) >= 3, z = p(3); endif
  [idxn, dmin] = aos_geom_punto_mas_cercano(nodos, x, y, []);
  nid = '';
  if ~isempty(idxn), nid = nodos{idxn}.id; endif
  if ~isempty(nid) && dmin <= tol
    return;
  endif
  nid = sprintf('N%03d', numel(nodos) + 1);
  nodo = struct();
  nodo.id = nid;
  nodo.x = x; nodo.y = y; nodo.z = z;
  nodo.tipo = 'JUNCTION';
  nodo.cota = campo_ok_local(z, 'm', 'DXF', 'OK', '');
  nodo.handle = '';
  nodo.capa = '';
  nodo.estado_conexion = estado;
  nodos{end+1} = nodo;
endfunction

function [eq, n_add] = aplicar_meta_bomba_local(eq, app)
  % Mapea CURVA_*/BOMBA_* de meta_aplicar a fila de equipos (schema aditivo).
  n_add = 0;
  if nargin < 2 || ~isstruct(app) || ~isstruct(eq), return; endif

  if isfield(app, 'BOMBA_ESTADO') && ~isempty(app.BOMBA_ESTADO)
    origen = 'TEXTO_AOS_META';
    if isfield(app, 'origen_BOMBA_ESTADO') && ~isempty(app.origen_BOMBA_ESTADO)
      origen = app.origen_BOMBA_ESTADO;
    endif
    eq.bomba_estado = campo_ok_local(char(app.BOMBA_ESTADO), '', origen, 'OK', '');
    n_add = n_add + 1;
  endif

  if isfield(app, 'BOMBA_MODELO') && ~isempty(app.BOMBA_MODELO)
    origen = 'TEXTO_AOS_META';
    if isfield(app, 'origen_BOMBA_MODELO') && ~isempty(app.origen_BOMBA_MODELO)
      origen = app.origen_BOMBA_MODELO;
    endif
    eq.bomba_modelo = campo_ok_local(char(app.BOMBA_MODELO), '', origen, 'OK', '');
    n_add = n_add + 1;
  endif

  Q = [];
  H = [];
  if isfield(app, 'CURVA_Q') && ~isempty(app.CURVA_Q), Q = app.CURVA_Q(:)'; endif
  if isfield(app, 'CURVA_H') && ~isempty(app.CURVA_H), H = app.CURVA_H(:)'; endif
  if ~isempty(Q) && ~isempty(H)
    unidad = 'm3/d';
    if isfield(app, 'CURVA_Q_UNIDAD') && ~isempty(app.CURVA_Q_UNIDAD)
      unidad = lower(strtrim(char(app.CURVA_Q_UNIDAD)));
    endif
    Q_m3d = Q;
    if any(strcmp(unidad, {'m3/s', 'm3s', 'm^3/s'}))
      Q_m3d = Q * 86400;
    endif
    origen_q = 'TEXTO_AOS_META';
    origen_h = 'TEXTO_AOS_META';
    if isfield(app, 'origen_CURVA_Q') && ~isempty(app.origen_CURVA_Q)
      origen_q = app.origen_CURVA_Q;
    endif
    if isfield(app, 'origen_CURVA_H') && ~isempty(app.origen_CURVA_H)
      origen_h = app.origen_CURVA_H;
    endif
    adv_q = '';
    adv_h = '';
    if isfield(app, 'adv_CURVA_Q'), adv_q = char(app.adv_CURVA_Q); endif
    if isfield(app, 'adv_CURVA_H'), adv_h = char(app.adv_CURVA_H); endif
    if numel(Q_m3d) ~= numel(H)
      if isempty(adv_q), adv_q = 'CURVA_LONGITUDES_DISTINTAS';
      else, adv_q = [adv_q '|CURVA_LONGITUDES_DISTINTAS']; endif
    endif
    cb = struct();
    cb.Q_m3d = campo_ok_local(Q_m3d(:)', 'm3/d', origen_q, 'OK', adv_q);
    cb.H_m = campo_ok_local(H(:)', 'm', origen_h, 'OK', adv_h);
    cb.fuente = 'INLINE';
    eq.curva_bomba = cb;
    n_add = n_add + 1;
  endif
endfunction

function c = campo_ok_local(valor, unidad, origen, estado, advertencia)
  c = aos_aoscad_campo(valor, unidad, origen, 'aos_cad_mapear_objetos', advertencia);
  if nargin >= 4 && ~isempty(estado)
    c.estado_de_validacion = char(estado);
  endif
endfunction

function [c, n_dxf, n_def] = campo_default_local(valor, unidad, n_dxf, n_def)
  c = aos_aoscad_campo(valor, unidad, 'DEFAULT_MODULO', 'aos_cad_mapear_objetos', 'META_DEFAULT');
  c.estado_de_validacion = 'PENDIENTE';
  n_def = n_def + 1;
endfunction

function app = merge_app_local(a, b)
  app = b;
  if isempty(a) || ~isstruct(a), return; endif
  if isempty(b) || ~isstruct(b), app = a; return; endif
  if isfield(a, 'diametro_m') && ~isempty(a.diametro_m)
    app.diametro_m = a.diametro_m;
    app.origen_diametro = a.origen_diametro;
    app.estado_diametro = a.estado_diametro;
    app.adv_diametro = a.adv_diametro;
  endif
  if isfield(a, 'material') && ~isempty(a.material)
    app.material = a.material;
    app.origen_material = a.origen_material;
    app.estado_material = a.estado_material;
    app.adv_material = a.adv_material;
  endif
  if isfield(a, 'rugosidad') && ~isempty(a.rugosidad)
    app.rugosidad = a.rugosidad;
    app.origen_rugosidad = a.origen_rugosidad;
    app.estado_rugosidad = a.estado_rugosidad;
    app.adv_rugosidad = a.adv_rugosidad;
  endif
  if isfield(a, 'id') && ~isempty(a.id)
    app.id = a.id;
    app.origen_id = a.origen_id;
  endif
endfunction

function fn = fieldnames_safe(s)
  fn = {};
  if isstruct(s), fn = fieldnames(s); endif
endfunction

function tf = valvula_existe_en_nodo_local(valvulas, nid)
  tf = false;
  for i = 1:numel(valvulas)
    if strcmp(valvulas{i}.nodo_ref, nid), tf = true; return; endif
  endfor
endfunction

function tf = accesorio_existe_en_nodo_local(accesorios, nid, tip)
  tf = false;
  for i = 1:numel(accesorios)
    if strcmp(accesorios{i}.nodo_ref, nid) && strcmpi(char(accesorios{i}.tipo), tip)
      tf = true; return;
    endif
  endfor
endfunction

function v = getfield_safe(s, name, default)
  if isstruct(s) && isfield(s, name)
    v = s.(name);
  else
    v = default;
  endif
endfunction

function cad = escalar_geometria_dxf_local(cad, factor_m)
% Escala coordenadas/radios DXF a metros. factor_m=1 => no-op.
  if nargin < 2 || isempty(factor_m) || abs(factor_m - 1) < 1e-15
    return;
  endif
  if ~isstruct(cad) || ~isfield(cad, 'entidades'), return; endif
  for i = 1:numel(cad.entidades)
    e = cad.entidades{i};
    if ~isstruct(e), continue; endif
    if isfield(e, 'geometry') && ~isempty(e.geometry) && isnumeric(e.geometry)
      e.geometry = e.geometry * factor_m;
    endif
    for f = {'x1','y1','z1','x2','y2','z2','radius'}
      fn = f{1};
      if isfield(e, fn) && isnumeric(e.(fn)) && ~isempty(e.(fn)) && isfinite(e.(fn))
        e.(fn) = e.(fn) * factor_m;
      endif
    endfor
    if isfield(e, 'xs') && ~isempty(e.xs), e.xs = e.xs * factor_m; endif
    if isfield(e, 'ys') && ~isempty(e.ys), e.ys = e.ys * factor_m; endif
    cad.entidades{i} = e; %#ok<AGROW>
  endfor
  % Definiciones de bloque: geometria relativa al base point (tambien escala)
  if isfield(cad, 'bloques')
    for b = 1:numel(cad.bloques)
      blk = cad.bloques{b};
      if isfield(blk, 'base_x'), blk.base_x = blk.base_x * factor_m; endif
      if isfield(blk, 'base_y'), blk.base_y = blk.base_y * factor_m; endif
      if isfield(blk, 'base_z'), blk.base_z = blk.base_z * factor_m; endif
      if isfield(blk, 'entidades')
        for j = 1:numel(blk.entidades)
          e = blk.entidades{j};
          if isfield(e, 'geometry') && ~isempty(e.geometry) && isnumeric(e.geometry)
            e.geometry = e.geometry * factor_m;
          endif
          for f = {'x1','y1','z1','x2','y2','z2','radius'}
            fn = f{1};
            if isfield(e, fn) && isnumeric(e.(fn)) && ~isempty(e.(fn)) && isfinite(e.(fn))
              e.(fn) = e.(fn) * factor_m;
            endif
          endfor
          blk.entidades{j} = e; %#ok<AGROW>
        endfor
      endif
      cad.bloques{b} = blk; %#ok<AGROW>
    endfor
  endif
  cad.unidades = 'm';
  cad.factor_escala_m = factor_m;
endfunction

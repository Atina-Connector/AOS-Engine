function [indice, items] = aos_step_indice_geometrico(tabla, opciones)
% AOS_STEP_INDICE_GEOMETRICO Indice: productos, NAUO, placement, bbox (SI).
% Sin BRep. Sin error() por STEP inesperado (degrada con items).
  if nargin < 1, tabla = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  items = {};
  indice = indice_vacio_local();

  if ~isstruct(tabla) || ~isfield(tabla, 'por_id') || isempty(tabla.por_id)
    items{end+1} = struct('codigo', 'STEP_SIN_PRODUCTOS', ...
      'mensaje', 'Tabla de entidades vacia', 'severidad', 'ADVERTENCIA');
    return;
  endif

  nombre_archivo = '';
  if isfield(opciones, 'nombre_archivo'), nombre_archivo = char(opciones.nombre_archivo); endif
  if isempty(nombre_archivo) && isfield(opciones, 'archivo')
    [~, nombre_archivo, ext] = fileparts(char(opciones.archivo));
    nombre_archivo = [nombre_archivo, ext];
  endif
  if isempty(nombre_archivo), nombre_archivo = 'step'; endif

  try
    [indice, items] = construir_indice_local(tabla, nombre_archivo, items);
  catch err
    items{end+1} = struct('codigo', 'STEP_INDICE_PARCIAL', ...
      'mensaje', sprintf('Indice parcial: %s', err.message), ...
      'severidad', 'ADVERTENCIA');
  end_try_catch
endfunction

function indice = indice_vacio_local()
  indice = struct();
  indice.productos = {};
  indice.ocurrencias = {};
  indice.n_productos = 0;
  indice.n_ocurrencias = 0;
  indice.profundidad_max = 0;
  indice.unidades = struct('factor_a_metros', 1, 'origen', '', 'consistente', true);
endfunction

function [indice, items] = construir_indice_local(tabla, nombre_archivo, items)
  indice = indice_vacio_local();
  por_id = tabla.por_id;

  % --- Productos ---
  ids_product = listar_por_tipo_local(tabla, 'PRODUCT');
  if isempty(ids_product)
    items{end+1} = struct('codigo', 'STEP_SIN_PRODUCTOS', ...
      'mensaje', 'Sin entidades PRODUCT', 'severidad', 'ADVERTENCIA');
    return;
  endif

  % Indices auxiliares (definicion / forma / representacion)
  productos_meta = {};
  def_to_prod_idx = struct();

  for i = 1:numel(ids_product)
    pid = ids_product(i);
    pent = por_id{pid};
    [prod_id_str, prod_nombre] = parsear_product_local(pent);
    id_form = buscar_quien_referencia_local(tabla, pid, 'PRODUCT_DEFINITION_FORMATION');
    id_def = [];
    if ~isempty(id_form)
      id_def = buscar_quien_referencia_local(tabla, id_form, 'PRODUCT_DEFINITION');
    endif
    id_pds = [];
    id_repr = [];
    id_ctx = [];
    if ~isempty(id_def)
      id_pds = buscar_pds_de_definicion_local(tabla, id_def);
      if ~isempty(id_pds)
        id_repr = buscar_repr_de_pds_local(tabla, id_pds);
        if ~isempty(id_repr)
          id_ctx = contexto_de_repr_local(tabla, id_repr);
        endif
      endif
    endif

    n_solidos = contar_solidos_desde_local(tabla, id_repr);

    pm = struct();
    pm.product_entity_id = pid;
    pm.product_id = prod_id_str;
    pm.nombre = prod_nombre;
    pm.id_definicion = id_def;
    pm.id_formation = id_form;
    pm.id_pds = id_pds;
    pm.id_repr = id_repr;
    pm.id_contexto = id_ctx;
    pm.n_solidos = n_solidos;
    pm.es_raiz = true;
    pm.profundidad = 0;
    pm.padre = [];
    pm.hijos = [];
    pm.placement_local = eye(4);
    pm.placement_absoluto = eye(4);
    pm.bbox_local = bbox_indet_local();
    pm.bbox_absoluta = bbox_indet_local();
    pm.centroide = [NaN, NaN, NaN];
    pm.ancla = [0, 0, 0];
    pm.factor_a_metros = 1;
    pm.unidades_origen = '';
    pm.bbox_determinada = false;
    productos_meta{end+1} = pm; %#ok<AGROW>
    if ~isempty(id_def)
      def_to_prod_idx.(sprintf('d%d', id_def)) = numel(productos_meta);
    endif
  endfor

  % --- Unidades por producto ---
  factores = [];
  origenes = {};
  for i = 1:numel(productos_meta)
    ctx = productos_meta{i}.id_contexto;
    if isempty(ctx)
      [f, info_u, it_u] = aos_step_unidades(tabla, []);
    else
      [f, info_u, it_u] = aos_step_unidades(tabla, ctx);
    endif
    productos_meta{i}.factor_a_metros = f;
    productos_meta{i}.unidades_origen = info_u.origen;
    factores(end+1) = f; %#ok<AGROW>
    origenes{end+1} = info_u.origen; %#ok<AGROW>
    for k = 1:numel(it_u)
      items{end+1} = it_u{k}; %#ok<AGROW>
    endfor
  endfor
  consistente = true;
  if numel(factores) > 1
    if max(factores) - min(factores) > 1e-15
      consistente = false;
      items{end+1} = struct('codigo', 'STEP_UNIDADES_INCONSISTENTES', ...
        'mensaje', sprintf('Factores de unidad distintos entre contextos: [%s]', ...
          sprintf('%g ', factores)), ...
        'severidad', 'ADVERTENCIA');
    endif
  endif
  if ~isempty(factores)
    indice.unidades.factor_a_metros = factores(1);
    indice.unidades.origen = origenes{1};
  endif
  indice.unidades.consistente = consistente;

  % --- Jerarquia NAUO ---
  ids_nauo = listar_por_tipo_local(tabla, 'NEXT_ASSEMBLY_USAGE_OCCURRENCE');
  arcos = {}; % struct padre_def, hijo_def, nauo_id, nauo_key
  hijos_de = struct();
  es_hijo = struct();

  for i = 1:numel(ids_nauo)
    nent = por_id{ids_nauo(i)};
    [nauo_key, id_padre, id_hijo] = parsear_nauo_local(nent);
    if isempty(id_padre) || isempty(id_hijo), continue; endif
    arc = struct('padre_def', id_padre, 'hijo_def', id_hijo, ...
      'nauo_id', ids_nauo(i), 'nauo_key', nauo_key);
    arcos{end+1} = arc; %#ok<AGROW>
    pk = sprintf('d%d', id_padre);
    if ~isfield(hijos_de, pk), hijos_de.(pk) = []; endif
    hijos_de.(pk)(end+1) = numel(arcos);
    es_hijo.(sprintf('d%d', id_hijo)) = 1;
  endfor

  if isempty(arcos)
    items{end+1} = struct('codigo', 'STEP_SIN_ENSAMBLE', ...
      'mensaje', 'Sin NEXT_ASSEMBLY_USAGE_OCCURRENCE; productos como raices planas', ...
      'severidad', 'INFO');
  endif

  for i = 1:numel(productos_meta)
    id_def = productos_meta{i}.id_definicion;
    if isempty(id_def), continue; endif
    dk = sprintf('d%d', id_def);
    if isfield(es_hijo, dk)
      productos_meta{i}.es_raiz = false;
    else
      productos_meta{i}.es_raiz = true;
    endif
    if isfield(hijos_de, dk)
      for j = 1:numel(hijos_de.(dk))
        ai = hijos_de.(dk)(j);
        hd = arcos{ai}.hijo_def;
        if isfield(def_to_prod_idx, sprintf('d%d', hd))
          productos_meta{i}.hijos(end+1) = def_to_prod_idx.(sprintf('d%d', hd));
        endif
      endfor
    endif
  endfor

  % Padres
  for i = 1:numel(arcos)
    hd = arcos{i}.hijo_def;
    pd = arcos{i}.padre_def;
    if isfield(def_to_prod_idx, sprintf('d%d', hd)) && isfield(def_to_prod_idx, sprintf('d%d', pd))
      hi = def_to_prod_idx.(sprintf('d%d', hd));
      pi = def_to_prod_idx.(sprintf('d%d', pd));
      productos_meta{hi}.padre = pi;
    endif
  endfor

  % Profundidad + ciclo
  profundidades = zeros(1, numel(productos_meta));
  visitando = false(1, numel(productos_meta));
  visitado = false(1, numel(productos_meta));
  hay_ciclo = false;
  for i = 1:numel(productos_meta)
    if productos_meta{i}.es_raiz
      [profundidades, visitando, visitado, hay_ciclo] = dfs_prof_local( ...
        i, productos_meta, profundidades, visitando, visitado, hay_ciclo, 0);
    endif
  endfor
  for i = 1:numel(productos_meta)
    if ~visitado(i)
      [profundidades, visitando, visitado, hay_ciclo] = dfs_prof_local( ...
        i, productos_meta, profundidades, visitando, visitado, hay_ciclo, 0);
    endif
  endfor
  if hay_ciclo
    items{end+1} = struct('codigo', 'STEP_ENSAMBLE_CICLICO', ...
      'mensaje', 'Ciclo detectado en jerarquia NAUO', 'severidad', 'ADVERTENCIA');
  endif
  for i = 1:numel(productos_meta)
    productos_meta{i}.profundidad = profundidades(i);
  endfor
  indice.profundidad_max = max([0, profundidades]);

  % --- Placement por NAUO ---
  T_por_nauo = struct();
  for i = 1:numel(arcos)
    [Tloc, ok_p] = placement_de_nauo_local(tabla, arcos{i}.nauo_id);
    if ~ok_p, Tloc = eye(4); endif
    T_por_nauo.(sprintf('n%d', arcos{i}.nauo_id)) = Tloc;
  endfor

  % Placement absoluto por producto (composicion desde raiz)
  for i = 1:numel(productos_meta)
    if productos_meta{i}.es_raiz || isempty(productos_meta{i}.padre)
      productos_meta{i}.placement_local = eye(4);
      productos_meta{i}.placement_absoluto = eye(4);
      productos_meta{i}.ancla = [0, 0, 0];
    endif
  endfor

  % Orden topologico: raices primero
  orden = orden_topologico_local(productos_meta);
  for oi = 1:numel(orden)
    i = orden(oi);
    if productos_meta{i}.es_raiz || isempty(productos_meta{i}.padre)
      continue;
    endif
    % Buscar arco padre->este
    Tloc = eye(4);
    pi = productos_meta{i}.padre;
    id_def_p = productos_meta{pi}.id_definicion;
    id_def_h = productos_meta{i}.id_definicion;
    for a = 1:numel(arcos)
      if arcos{a}.padre_def == id_def_p && arcos{a}.hijo_def == id_def_h
        nk = sprintf('n%d', arcos{a}.nauo_id);
        if isfield(T_por_nauo, nk)
          Tloc = T_por_nauo.(nk);
        endif
        break;
      endif
    endfor
    productos_meta{i}.placement_local = Tloc;
    Tabs = productos_meta{pi}.placement_absoluto * Tloc;
    productos_meta{i}.placement_absoluto = Tabs;
    productos_meta{i}.ancla = (Tabs(1:3, 4))';
  endfor

  % Placement absoluto RAW por NAUO (cada ocurrencia con su propia transformacion).
  % Necesario cuando dos NAUO apuntan al mismo producto con T distintas (S7).
  Tabs_raw_por_nauo = struct();
  for i = 1:numel(arcos)
    hd = arcos{i}.hijo_def;
    pd = arcos{i}.padre_def;
    if ~isfield(def_to_prod_idx, sprintf('d%d', hd)), continue; endif
    nk = sprintf('n%d', arcos{i}.nauo_id);
    Tloc = eye(4);
    if isfield(T_por_nauo, nk), Tloc = T_por_nauo.(nk); endif
    if isfield(def_to_prod_idx, sprintf('d%d', pd))
      pi = def_to_prod_idx.(sprintf('d%d', pd));
      Tabs_raw_por_nauo.(nk) = productos_meta{pi}.placement_absoluto * Tloc;
    else
      Tabs_raw_por_nauo.(nk) = Tloc;
    endif
  endfor

  % --- Normalizar placements a SI y bbox por cierre de referencias ---
  for i = 1:numel(productos_meta)
    f = productos_meta{i}.factor_a_metros;
    T_raw = productos_meta{i}.placement_absoluto;
    T_si = T_raw;
    T_si(1:3, 4) = T_raw(1:3, 4) * f;
    productos_meta{i}.placement_absoluto = T_si;
    Tloc_raw = productos_meta{i}.placement_local;
    Tloc_si = Tloc_raw;
    Tloc_si(1:3, 4) = Tloc_raw(1:3, 4) * f;
    productos_meta{i}.placement_local = Tloc_si;
    productos_meta{i}.ancla = (T_si(1:3, 4))';

    pts = recolectar_puntos_local(tabla, productos_meta{i}.id_repr);
    if isempty(pts)
      productos_meta{i}.bbox_determinada = false;
      productos_meta{i}.bbox_local = bbox_indet_local();
      productos_meta{i}.bbox_absoluta = bbox_indet_local();
      productos_meta{i}.centroide = [NaN, NaN, NaN];
      items{end+1} = struct('codigo', 'STEP_BBOX_INDETERMINADA', ...
        'mensaje', sprintf('Producto "%s" sin CARTESIAN_POINT alcanzables', ...
          char(productos_meta{i}.nombre)), ...
        'severidad', 'ADVERTENCIA', ...
        'product_id', productos_meta{i}.product_id); %#ok<AGROW>
      continue;
    endif
    pts_m = pts * f;
    [bb, cen] = aos_geom_bbox(pts_m);
    if ~isfield(bb, 'zmin'), bb.zmin = 0; bb.zmax = 0; endif
    productos_meta{i}.bbox_local = bb;
    productos_meta{i}.centroide = cen;
    productos_meta{i}.bbox_determinada = true;
    productos_meta{i}.bbox_absoluta = aos_geom_transformar_bbox(bb, T_si);
  endfor

  % --- Ocurrencias (placement/ancla/bbox propios por NAUO) ---
  ocurrencias = {};
  for i = 1:numel(arcos)
    hd = arcos{i}.hijo_def;
    if ~isfield(def_to_prod_idx, sprintf('d%d', hd)), continue; endif
    hi = def_to_prod_idx.(sprintf('d%d', hd));
    ruta = construir_ruta_local(arcos, i, productos_meta, def_to_prod_idx);
    gid = sprintf('STEPOCC:%s:%s', nombre_archivo, ruta);
    nk = sprintf('n%d', arcos{i}.nauo_id);
    f = productos_meta{hi}.factor_a_metros;
    if isfield(Tabs_raw_por_nauo, nk)
      T_raw = Tabs_raw_por_nauo.(nk);
    else
      T_raw = eye(4);
    endif
    T_si = T_raw;
    T_si(1:3, 4) = T_raw(1:3, 4) * f;
    oc = struct();
    oc.nauo_id = arcos{i}.nauo_id;
    oc.ruta_ensamble = ruta;
    oc.geometry_id = gid;
    oc.product_id = productos_meta{hi}.product_id;
    oc.nombre = productos_meta{hi}.nombre;
    oc.asset_id = ''; % se completa aditivamente en import / vinculo
    oc.placement_absoluto = T_si;
    oc.ancla = (T_si(1:3, 4))';
    if productos_meta{hi}.bbox_determinada
      oc.bbox_absoluta = aos_geom_transformar_bbox(productos_meta{hi}.bbox_local, T_si);
    else
      oc.bbox_absoluta = bbox_indet_local();
    endif
    oc.idx_producto = hi;
    ocurrencias{end+1} = oc; %#ok<AGROW>
  endfor

  % Empaquetar productos publicos
  productos_out = {};
  for i = 1:numel(productos_meta)
    p = productos_meta{i};
    % geometry_id de ocurrencia primaria (primera que apunte a este producto)
    gid_prim = '';
    for j = 1:numel(ocurrencias)
      if ocurrencias{j}.idx_producto == i
        gid_prim = ocurrencias{j}.geometry_id;
        break;
      endif
    endfor
    out = struct();
    out.product_id = p.product_id;
    out.nombre = p.nombre;
    out.id_definicion = p.id_definicion;
    out.es_raiz = p.es_raiz;
    out.profundidad = p.profundidad;
    out.padre = p.padre;
    out.hijos = p.hijos;
    out.placement_local = p.placement_local;
    out.placement_absoluto = p.placement_absoluto;
    out.bbox_local = p.bbox_local;
    out.bbox_absoluta = p.bbox_absoluta;
    out.centroide = p.centroide;
    out.ancla = p.ancla;
    out.n_solidos = p.n_solidos;
    out.factor_a_metros = p.factor_a_metros;
    out.unidades_origen = p.unidades_origen;
    out.bbox_determinada = p.bbox_determinada;
    out.geometry_id = gid_prim;
    out.product_entity_id = p.product_entity_id;
    productos_out{end+1} = out; %#ok<AGROW>
  endfor

  indice.productos = productos_out;
  indice.ocurrencias = ocurrencias;
  indice.n_productos = numel(productos_out);
  indice.n_ocurrencias = numel(ocurrencias);
endfunction

function bb = bbox_indet_local()
  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
endfunction

function ids = listar_por_tipo_local(tabla, tipo)
  ids = [];
  tipo = upper(char(tipo));
  for i = 1:numel(tabla.por_id)
    e = tabla.por_id{i};
    if isempty(e) || ~isstruct(e), continue; endif
    if strcmpi(char(e.tipo), tipo)
      ids(end+1) = e.id; %#ok<AGROW>
    endif
  endfor
endfunction

function [prod_id, nombre] = parsear_product_local(ent)
  prod_id = ''; nombre = '';
  if isempty(ent), return; endif
  toks = regexp(ent.argumentos, '''([^'']*)''', 'tokens');
  if numel(toks) >= 1, prod_id = toks{1}{1}; endif
  if numel(toks) >= 2, nombre = toks{2}{1}; endif
  if isempty(nombre), nombre = prod_id; endif
endfunction

function id = buscar_quien_referencia_local(tabla, target, tipo)
  id = [];
  tipo = upper(char(tipo));
  for i = 1:numel(tabla.por_id)
    e = tabla.por_id{i};
    if isempty(e) || ~isstruct(e), continue; endif
    if ~strcmpi(char(e.tipo), tipo), continue; endif
    if any(e.referencias == target)
      id = e.id;
      return;
    endif
  endfor
endfunction

function id_pds = buscar_pds_de_definicion_local(tabla, id_def)
  id_pds = [];
  for i = 1:numel(tabla.por_id)
    e = tabla.por_id{i};
    if isempty(e) || ~isstruct(e), continue; endif
    if ~strcmpi(char(e.tipo), 'PRODUCT_DEFINITION_SHAPE'), continue; endif
    % Evitar PDS de placement (referencian NAUO)
    if any(e.referencias == id_def)
      % Comprobar que no sea NAUO
      ok = true;
      for j = 1:numel(e.referencias)
        r = e.referencias(j);
        if r >= 1 && r <= numel(tabla.por_id) && ~isempty(tabla.por_id{r})
          if strcmpi(char(tabla.por_id{r}.tipo), 'NEXT_ASSEMBLY_USAGE_OCCURRENCE')
            ok = false; break;
          endif
        endif
      endfor
      if ok
        id_pds = e.id;
        return;
      endif
    endif
  endfor
endfunction

function id_repr = buscar_repr_de_pds_local(tabla, id_pds)
  id_repr = [];
  for i = 1:numel(tabla.por_id)
    e = tabla.por_id{i};
    if isempty(e) || ~isstruct(e), continue; endif
    if ~strcmpi(char(e.tipo), 'SHAPE_DEFINITION_REPRESENTATION'), continue; endif
    if numel(e.referencias) >= 2 && e.referencias(1) == id_pds
      id_repr = e.referencias(2);
      return;
    endif
    if any(e.referencias == id_pds) && numel(e.referencias) >= 2
      % tomar la otra ref como repr
      for j = 1:numel(e.referencias)
        if e.referencias(j) ~= id_pds
          id_repr = e.referencias(j);
          return;
        endif
      endfor
    endif
  endfor
endfunction

function id_ctx = contexto_de_repr_local(tabla, id_repr)
  id_ctx = [];
  if isempty(id_repr) || id_repr < 1 || id_repr > numel(tabla.por_id), return; endif
  e = tabla.por_id{id_repr};
  if isempty(e), return; endif
  % Ultima referencia de SHAPE_REPRESENTATION / ADVANCED_BREP... suele ser contexto
  if ~isempty(e.referencias)
    id_ctx = e.referencias(end);
  endif
endfunction

function n = contar_solidos_desde_local(tabla, id_repr)
  n = 0;
  if isempty(id_repr), return; endif
  pts_visited = false(1, numel(tabla.por_id));
  stack = id_repr;
  while ~isempty(stack)
    cur = stack(1); stack(1) = [];
    if cur < 1 || cur > numel(tabla.por_id), continue; endif
    if pts_visited(cur), continue; endif
    pts_visited(cur) = true;
    e = tabla.por_id{cur};
    if isempty(e), continue; endif
    if strcmpi(char(e.tipo), 'MANIFOLD_SOLID_BREP') || ...
        strcmpi(char(e.tipo), 'BREP_WITH_VOIDS')
      n = n + 1;
    endif
    for j = 1:numel(e.referencias)
      stack(end+1) = e.referencias(j); %#ok<AGROW>
    endfor
  endwhile
endfunction

function [nauo_key, id_padre, id_hijo] = parsear_nauo_local(ent)
  nauo_key = ''; id_padre = []; id_hijo = [];
  if isempty(ent), return; endif
  toks = regexp(ent.argumentos, '''([^'']*)''', 'tokens');
  if ~isempty(toks), nauo_key = toks{1}{1}; endif
  refs = ent.referencias;
  if numel(refs) >= 2
    id_padre = refs(1);
    id_hijo = refs(2);
  endif
  if isempty(nauo_key)
    nauo_key = sprintf('%d', ent.id);
  endif
endfunction

function [profundidades, visitando, visitado, hay_ciclo] = dfs_prof_local( ...
    i, productos_meta, profundidades, visitando, visitado, hay_ciclo, depth)
  if visitando(i)
    hay_ciclo = true;
    return;
  endif
  if visitado(i) && profundidades(i) >= depth
    return;
  endif
  visitando(i) = true;
  profundidades(i) = max(profundidades(i), depth);
  hijos = productos_meta{i}.hijos;
  for k = 1:numel(hijos)
    [profundidades, visitando, visitado, hay_ciclo] = dfs_prof_local( ...
      hijos(k), productos_meta, profundidades, visitando, visitado, hay_ciclo, depth + 1);
  endfor
  visitando(i) = false;
  visitado(i) = true;
endfunction

function orden = orden_topologico_local(productos_meta)
  n = numel(productos_meta);
  orden = [];
  puesto = false(1, n);
  % raices primero
  cambiado = true;
  while cambiado
    cambiado = false;
    for i = 1:n
      if puesto(i), continue; endif
      p = productos_meta{i}.padre;
      if isempty(p) || (p >= 1 && p <= n && puesto(p)) || productos_meta{i}.es_raiz
        if productos_meta{i}.es_raiz || isempty(p) || puesto(p)
          orden(end+1) = i; %#ok<AGROW>
          puesto(i) = true;
          cambiado = true;
        endif
      endif
    endfor
  endwhile
  for i = 1:n
    if ~puesto(i)
      orden(end+1) = i; %#ok<AGROW>
    endif
  endfor
endfunction

function [T, ok] = placement_de_nauo_local(tabla, nauo_id)
  T = eye(4); ok = false;
  % PDS que referencia este NAUO
  id_pds = [];
  for i = 1:numel(tabla.por_id)
    e = tabla.por_id{i};
    if isempty(e) || ~isstruct(e), continue; endif
    if ~strcmpi(char(e.tipo), 'PRODUCT_DEFINITION_SHAPE'), continue; endif
    if any(e.referencias == nauo_id)
      id_pds = e.id;
      break;
    endif
  endfor
  if isempty(id_pds), return; endif

  % CDSR que referencia el PDS
  id_rel = [];
  for i = 1:numel(tabla.por_id)
    e = tabla.por_id{i};
    if isempty(e) || ~isstruct(e), continue; endif
    if ~strcmpi(char(e.tipo), 'CONTEXT_DEPENDENT_SHAPE_REPRESENTATION'), continue; endif
    if any(e.referencias == id_pds)
      % la otra ref es la relacion
      for j = 1:numel(e.referencias)
        if e.referencias(j) ~= id_pds
          id_rel = e.referencias(j);
          break;
        endif
      endfor
      break;
    endif
  endfor
  if isempty(id_rel), return; endif

  % ITEM_DEFINED_TRANSFORMATION en la relacion (compleja o directa)
  id_idt = buscar_idt_local(tabla, id_rel);
  if isempty(id_idt), return; endif
  idt = tabla.por_id{id_idt};
  if isempty(idt) || numel(idt.referencias) < 2, return; endif
  id_origen = idt.referencias(1);
  id_destino = idt.referencias(2);
  [To, oko] = axis2_a_matriz_local(tabla, id_origen);
  [Td, okd] = axis2_a_matriz_local(tabla, id_destino);
  if ~(oko && okd), return; endif
  T = Td / To;  % Td * inv(To)
  ok = true;
endfunction

function id_idt = buscar_idt_local(tabla, id_rel)
  id_idt = [];
  if id_rel < 1 || id_rel > numel(tabla.por_id), return; endif
  e = tabla.por_id{id_rel};
  if isempty(e), return; endif
  if strcmpi(char(e.tipo), 'ITEM_DEFINED_TRANSFORMATION')
    id_idt = e.id; return;
  endif
  % Compleja: REPRESENTATION_RELATIONSHIP_WITH_TRANSFORMATION(#idt)
  for j = 1:numel(e.referencias)
    r = e.referencias(j);
    if r < 1 || r > numel(tabla.por_id), continue; endif
    re = tabla.por_id{r};
    if ~isempty(re) && strcmpi(char(re.tipo), 'ITEM_DEFINED_TRANSFORMATION')
      id_idt = r;
      return;
    endif
  endfor
  m = regexp(e.argumentos, 'REPRESENTATION_RELATIONSHIP_WITH_TRANSFORMATION\s*\(\s*#(\d+)', ...
    'tokens', 'once');
  if ~isempty(m)
    id_idt = str2double(m{1});
  endif
endfunction

function [T, ok] = axis2_a_matriz_local(tabla, id_axis)
  T = eye(4); ok = false;
  if isempty(id_axis) || id_axis < 1 || id_axis > numel(tabla.por_id), return; endif
  e = tabla.por_id{id_axis};
  if isempty(e), return; endif
  refs = e.referencias;
  origen = [0, 0, 0];
  eje_z = [0, 0, 1];
  dir_x = [1, 0, 0];
  if numel(refs) >= 1
    origen = leer_xyz_local(tabla, refs(1), origen);
  endif
  if numel(refs) >= 2
    eje_z = leer_xyz_local(tabla, refs(2), eje_z);
  endif
  if numel(refs) >= 3
    dir_x = leer_xyz_local(tabla, refs(3), dir_x);
  endif
  [T, ~] = aos_geom_axis2_matriz(origen, eje_z, dir_x);
  ok = true;
endfunction

function xyz = leer_xyz_local(tabla, id, default_xyz)
  xyz = default_xyz;
  if isempty(id) || id < 1 || id > numel(tabla.por_id), return; endif
  e = tabla.por_id{id};
  if isempty(e), return; endif
  % CARTESIAN_POINT('',(x,y,z)) o DIRECTION('',(x,y,z))
  m = regexp(e.argumentos, '\(\s*([-+0-9.Ee]+)\s*,\s*([-+0-9.Ee]+)\s*,\s*([-+0-9.Ee]+)\s*\)', ...
    'tokens', 'once');
  if isempty(m)
    m = regexp(e.raw, '\(\s*([-+0-9.Ee]+)\s*,\s*([-+0-9.Ee]+)\s*,\s*([-+0-9.Ee]+)\s*\)', ...
      'tokens', 'once');
  endif
  if ~isempty(m)
    xyz = [str2double(m{1}), str2double(m{2}), str2double(m{3})];
  endif
endfunction

function pts = recolectar_puntos_local(tabla, id_repr)
  pts = [];
  if isempty(id_repr) || id_repr < 1, return; endif
  nmax = numel(tabla.por_id);
  visited = false(1, nmax);
  stack = id_repr;
  acc = zeros(0, 3);
  while ~isempty(stack)
    cur = stack(1); stack(1) = [];
    if cur < 1 || cur > nmax || visited(cur), continue; endif
    visited(cur) = true;
    e = tabla.por_id{cur};
    if isempty(e), continue; endif
    if strcmpi(char(e.tipo), 'CARTESIAN_POINT')
      xyz = leer_xyz_local(tabla, cur, [NaN, NaN, NaN]);
      if all(isfinite(xyz))
        acc(end+1, :) = xyz; %#ok<AGROW>
      endif
    endif
    for j = 1:numel(e.referencias)
      stack(end+1) = e.referencias(j); %#ok<AGROW>
    endfor
  endwhile
  pts = acc;
endfunction

function ruta = construir_ruta_local(arcos, idx_arco, productos_meta, def_to_prod_idx)
  % Cadena de nauo_key desde la raiz hasta este arco
  keys = {arcos{idx_arco}.nauo_key};
  hd = arcos{idx_arco}.padre_def;
  guard = 0;
  while guard < 64
    guard = guard + 1;
    % buscar arco cuyo hijo_def == hd
    found = false;
    for a = 1:numel(arcos)
      if arcos{a}.hijo_def == hd
        keys = [{arcos{a}.nauo_key}, keys]; %#ok<AGROW>
        hd = arcos{a}.padre_def;
        found = true;
        break;
      endif
    endfor
    if ~found, break; endif
  endwhile
  ruta = keys{1};
  for k = 2:numel(keys)
    ruta = [ruta, '/', keys{k}]; %#ok<AGROW>
  endfor
endfunction

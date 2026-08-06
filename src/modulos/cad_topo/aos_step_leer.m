function modelo = aos_step_leer(archivo, opciones)
% AOS_STEP_LEER Inventario ASCII ISO-10303-21 (STEP) para CAD_TOPO.
% No interpreta BRep completo: cuenta tipos, extrae PRODUCT y metadata HEADER.
% Aditivo Sprint 5: indice_geometrico e items (desactivable por opciones).
  if nargin < 1 || isempty(archivo)
    error('AOS CAD_TOPO: aos_step_leer requiere ruta de archivo STEP.');
  endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if exist(archivo, 'file') ~= 2
    error('AOS CAD_TOPO: no existe el STEP: %s', archivo);
  endif

  fid = fopen(archivo, 'rt');
  if fid < 0
    error('AOS CAD_TOPO: no se pudo abrir %s', archivo);
  endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);

  modelo = struct();
  modelo.step_archivo = char(archivo);
  modelo.formato = 'ISO-10303-21';
  modelo.schema = '';
  modelo.file_name = '';
  modelo.productos = {};
  modelo.conteo_tipos = struct();
  modelo.n_entidades = 0;
  modelo.n_productos = 0;
  modelo.n_solidos = 0;
  modelo.importado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  modelo.indice_geometrico = struct();
  modelo.items = {};

  if isempty(strfind(upper(raw), 'ISO-10303-21'))
    error('AOS CAD_TOPO: el archivo no parece STEP ASCII (ISO-10303-21): %s', archivo);
  endif

  % HEADER metadata (best-effort)
  modelo.schema = extraer_entre_local(raw, 'FILE_SCHEMA', ');');
  modelo.schema = strtrim(regexprep(modelo.schema, '[''\n\r]', ''));
  fn = extraer_entre_local(raw, 'FILE_NAME', ');');
  if ~isempty(fn)
    toks = regexp(fn, '''([^'']*)''', 'tokens');
    if ~isempty(toks)
      modelo.file_name = toks{1}{1};
    endif
  endif

  % Contar entidades DATA: #n = TIPO( ...  (inventario historico; no tocar)
  [~, ~, ~, ~, tokens] = regexp(raw, '#\d+\s*=\s*([A-Za-z0-9_]+)\s*\(');
  if ~isempty(tokens)
    modelo.n_entidades = numel(tokens);
    for i = 1:numel(tokens)
      t = upper(strtrim(tokens{i}{1}));
      if isfield(modelo.conteo_tipos, t)
        modelo.conteo_tipos.(t) = modelo.conteo_tipos.(t) + 1;
      else
        modelo.conteo_tipos.(t) = 1;
      endif
    endfor
  endif

  if isfield(modelo.conteo_tipos, 'PRODUCT')
    modelo.n_productos = modelo.conteo_tipos.PRODUCT;
  endif
  if isfield(modelo.conteo_tipos, 'MANIFOLD_SOLID_BREP')
    modelo.n_solidos = modelo.conteo_tipos.MANIFOLD_SOLID_BREP;
  elseif isfield(modelo.conteo_tipos, 'BREP_WITH_VOIDS')
    modelo.n_solidos = modelo.conteo_tipos.BREP_WITH_VOIDS;
  endif

  % Nombres de PRODUCT('id','name',...)
  [~, ~, ~, ~, ptoks] = regexp(raw, ...
    'PRODUCT\s*\(\s*''([^'']*)''\s*,\s*''([^'']*)''');
  for i = 1:numel(ptoks)
    p = struct();
    p.id = ptoks{i}{1};
    p.nombre = ptoks{i}{2};
    modelo.productos{end+1} = p; %#ok<AGROW>
  endfor
  if isempty(modelo.productos) && modelo.n_productos > 0
    modelo.n_productos = modelo.n_productos;
  elseif ~isempty(modelo.productos)
    modelo.n_productos = numel(modelo.productos);
  endif

  % --- Indice geometrico aditivo (Sprint 5) ---
  modelo = enriquecer_indice_local(modelo, raw, archivo, opciones);
endfunction

function modelo = enriquecer_indice_local(modelo, raw, archivo, opciones)
  activar = true;
  if isfield(opciones, 'indice_geometrico') && ~opciones.indice_geometrico
    activar = false;
  endif
  if isfield(opciones, 'sin_indice') && opciones.sin_indice
    activar = false;
  endif

  tope_bytes = 8e6;
  if isfield(opciones, 'tope_bytes') && isfinite(opciones.tope_bytes)
    tope_bytes = opciones.tope_bytes;
  endif

  items = {};
  if ~activar
    modelo.items = items;
    return;
  endif

  if numel(raw) > tope_bytes
    items{end+1} = struct('codigo', 'STEP_ARCHIVO_GRANDE_INDICE_OMITIDO', ...
      'mensaje', sprintf('Archivo %d bytes supera tope %g; indice omitido', ...
        numel(raw), tope_bytes), ...
      'severidad', 'ADVERTENCIA');
    modelo.items = items;
    return;
  endif

  try
    [tabla, items_t] = aos_step_tabla_entidades(raw, opciones);
    for i = 1:numel(items_t), items{end+1} = items_t{i}; endfor %#ok<AGROW>

    opt_idx = opciones;
    opt_idx.archivo = archivo;
    [~, nom, ext] = fileparts(char(archivo));
    opt_idx.nombre_archivo = [nom, ext];

    [indice, items_i] = aos_step_indice_geometrico(tabla, opt_idx);
    for i = 1:numel(items_i), items{end+1} = items_i{i}; endfor %#ok<AGROW>

    modelo.indice_geometrico = indice;
    modelo.tabla_entidades_n = tabla.n_entidades;

    % Campos aditivos en productos existentes (sin perder id/nombre)
    if isstruct(indice) && isfield(indice, 'productos')
      for i = 1:min(numel(modelo.productos), numel(indice.productos))
        ip = indice.productos{i};
        if isfield(ip, 'placement_absoluto')
          modelo.productos{i}.placement_absoluto = ip.placement_absoluto;
        endif
        if isfield(ip, 'bbox_absoluta')
          modelo.productos{i}.bbox_absoluta = ip.bbox_absoluta;
        endif
        if isfield(ip, 'geometry_id')
          modelo.productos{i}.geometry_id = ip.geometry_id;
        endif
        if isfield(ip, 'ancla')
          modelo.productos{i}.ancla = ip.ancla;
        endif
        if isfield(ip, 'factor_a_metros')
          modelo.productos{i}.factor_a_metros = ip.factor_a_metros;
        endif
      endfor
      % Emparejar por nombre si el orden no coincide
      if numel(modelo.productos) ~= numel(indice.productos) || ...
          (numel(modelo.productos) >= 1 && numel(indice.productos) >= 1 && ...
           ~strcmp(char(modelo.productos{1}.nombre), char(indice.productos{1}.nombre)))
        for i = 1:numel(modelo.productos)
          nom = '';
          if isfield(modelo.productos{i}, 'nombre'), nom = char(modelo.productos{i}.nombre); endif
          for j = 1:numel(indice.productos)
            if strcmp(nom, char(indice.productos{j}.nombre))
              ip = indice.productos{j};
              if isfield(ip, 'placement_absoluto')
                modelo.productos{i}.placement_absoluto = ip.placement_absoluto;
              endif
              if isfield(ip, 'bbox_absoluta')
                modelo.productos{i}.bbox_absoluta = ip.bbox_absoluta;
              endif
              if isfield(ip, 'geometry_id')
                modelo.productos{i}.geometry_id = ip.geometry_id;
              endif
              break;
            endif
          endfor
        endfor
      endif
    endif
  catch err
    items{end+1} = struct('codigo', 'STEP_INDICE_PARCIAL', ...
      'mensaje', sprintf('Indice omitido por error: %s', err.message), ...
      'severidad', 'ADVERTENCIA');
  end_try_catch

  modelo.items = items;
endfunction

function s = extraer_entre_local(raw, marca, fin)
  s = '';
  idx = strfind(upper(raw), upper(marca));
  if isempty(idx), return; endif
  i0 = idx(1) + numel(marca);
  resto = raw(i0:end);
  j = strfind(resto, fin);
  if isempty(j), return; endif
  s = resto(1:j(1)-1);
endfunction

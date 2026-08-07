function modelo = aos_dxf_leer(archivo)
% AOS_DXF_LEER Parser ASCII DXF minimo para inventario AOS CAD-TOP.
% Soporta HEADER $INSUNITS, capas TABLE/LAYER, BLOCKS (definiciones) y ENTITIES:
% LINE, LWPOLYLINE, POLYLINE, CIRCLE, TEXT, MTEXT, INSERT, ATTRIB, ATTDEF.
  if nargin < 1 || isempty(archivo)
    error('AOS: aos_dxf_leer requiere ruta de archivo DXF.');
  endif
  if exist(archivo, 'file') ~= 2
    error('AOS: no existe el DXF: %s', archivo);
  endif

  modelo = struct();
  modelo.dxf_archivo = char(archivo);
  modelo.acadver = '';
  modelo.insunits = NaN;
  modelo.unidades = 'DESCONOCIDA';
  modelo.capas = {};
  modelo.bloques = {};
  modelo.entidades = {};
  modelo.n_entidades = 0;
  modelo.n_capas = 0;
  modelo.n_bloques = 0;
  modelo.conteo_tipos = struct();
  modelo.importado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  mt = aos_cad_mtime(archivo);
  if isempty(mt)
    modelo.revision = 'sin_mtime';
  else
    modelo.revision = sprintf('mtime_%s', datestr(mt, 'yyyymmdd_HHMMSS'));
  endif

  lineas = leer_lineas_local(archivo);
  n = numel(lineas);
  i = 1;
  en_entities = false;
  en_tables = false;
  en_header = false;
  en_blocks = false;
  bloque_actual = [];

  while i <= n - 1
    code = str2double(strtrim(lineas{i}));
    value = lineas{i + 1};
    i = i + 2;
    if isnan(code), continue; endif

    if code == 0 && strcmpi(strtrim(value), 'SECTION')
      if i <= n - 1
        c2 = str2double(strtrim(lineas{i}));
        v2 = lineas{i + 1};
        i = i + 2;
        if c2 == 2
          sec = upper(strtrim(v2));
          en_header = strcmp(sec, 'HEADER');
          en_tables = strcmp(sec, 'TABLES');
          en_entities = strcmp(sec, 'ENTITIES');
          en_blocks = strcmp(sec, 'BLOCKS');
          bloque_actual = [];
        endif
      endif
      continue;
    endif
    if code == 0 && strcmpi(strtrim(value), 'ENDSEC')
      if en_blocks && ~isempty(bloque_actual)
        modelo.bloques{end+1} = bloque_actual; %#ok<AGROW>
        bloque_actual = [];
      endif
      en_header = false; en_tables = false; en_entities = false; en_blocks = false;
      continue;
    endif

    if en_header && code == 9
      var = strtrim(value);
      if i <= n - 1
        c2 = str2double(strtrim(lineas{i}));
        v2 = lineas{i + 1};
        i = i + 2;
        if strcmpi(var, '$ACADVER') && c2 == 1
          modelo.acadver = strtrim(v2);
        elseif strcmpi(var, '$INSUNITS') && (c2 == 70 || c2 == 90)
          modelo.insunits = str2double(strtrim(v2));
          modelo.unidades = unidades_local(modelo.insunits);
        endif
      endif
      continue;
    endif

    if en_tables && code == 0 && strcmpi(strtrim(value), 'LAYER')
      layer0 = struct('name', '', 'color', NaN, 'flags', NaN);
      [layer, i] = leer_hasta_0_local(lineas, i, @parse_layer_local, layer0);
      if ~isempty(layer) && isfield(layer, 'name') && ~isempty(layer.name)
        modelo.capas{end+1} = layer; %#ok<AGROW>
      endif
      continue;
    endif

    if en_blocks && code == 0
      tipo_b = upper(strtrim(value));
      if strcmp(tipo_b, 'BLOCK')
        if ~isempty(bloque_actual)
          modelo.bloques{end+1} = bloque_actual; %#ok<AGROW>
        endif
        blk0 = struct('name', '', 'handle', '', 'base_x', 0, 'base_y', 0, 'base_z', 0, 'entidades', {{}});
        [bloque_actual, i] = leer_hasta_0_local(lineas, i, @parse_block_hdr_local, blk0);
        continue;
      elseif strcmp(tipo_b, 'ENDBLK')
        if ~isempty(bloque_actual)
          modelo.bloques{end+1} = bloque_actual; %#ok<AGROW>
          bloque_actual = [];
        endif
        continue;
      else
        % Entidad interna del bloque (misma gramatica que ENTITIES)
        [ent, i] = leer_entidad_tipo_local(lineas, i, tipo_b);
        if ~isempty(ent) && ~isempty(bloque_actual)
          bloque_actual.entidades{end+1} = ent; %#ok<AGROW>
        endif
        continue;
      endif
    endif

    if en_entities && code == 0
      tipo = upper(strtrim(value));
      [ent, i] = leer_entidad_tipo_local(lineas, i, tipo);
      if ~isempty(ent)
        modelo.entidades{end+1} = ent; %#ok<AGROW>
        t = ent.entity_type;
        if isfield(modelo.conteo_tipos, t)
          modelo.conteo_tipos.(t) = modelo.conteo_tipos.(t) + 1;
        else
          modelo.conteo_tipos.(t) = 1;
        endif
      endif
    endif
  endwhile

  modelo.n_entidades = numel(modelo.entidades);
  modelo.n_capas = numel(modelo.capas);
  modelo.n_bloques = numel(modelo.bloques);
  if modelo.n_bloques > 0
    modelo.conteo_tipos.BLOCKS = modelo.n_bloques;
  endif
endfunction

function [ent, i] = leer_entidad_tipo_local(lineas, i, tipo)
  switch tipo
    case 'LINE'
      [ent, i] = leer_hasta_0_local(lineas, i, @parse_line_local, base_ent_local('LINE'));
    case 'LWPOLYLINE'
      [ent, i] = leer_hasta_0_local(lineas, i, @parse_lwpolyline_local, base_ent_local('LWPOLYLINE'));
    case 'POLYLINE'
      [ent, i] = leer_polyline_local(lineas, i);
    case 'CIRCLE'
      [ent, i] = leer_hasta_0_local(lineas, i, @parse_circle_local, base_ent_local('CIRCLE'));
    case {'TEXT', 'MTEXT'}
      [ent, i] = leer_hasta_0_local(lineas, i, @(e,c,v) parse_text_local(e, c, v, tipo), base_ent_local(tipo));
    case 'INSERT'
      [ent, i] = leer_hasta_0_local(lineas, i, @parse_insert_local, base_ent_local('INSERT'));
    case {'ATTRIB', 'ATTDEF'}
      [ent, i] = leer_hasta_0_local(lineas, i, @(e,c,v) parse_attrib_local(e, c, v, tipo), base_ent_local(tipo));
    otherwise
      % Saltar campos hasta el siguiente grupo 0 sin materializar la entidad.
      ent = [];
      n = numel(lineas);
      while i <= n - 1
        code = str2double(strtrim(lineas{i}));
        if ~isnan(code) && code == 0, break; endif
        i = i + 2;
      endwhile
  endswitch
endfunction

function blk = parse_block_hdr_local(blk, code, value)
  if nargin < 1 || isempty(blk) || ~isstruct(blk)
    blk = struct('name', '', 'handle', '', 'base_x', 0, 'base_y', 0, 'base_z', 0, 'entidades', {{}});
  endif
  if nargin < 2 || isempty(code), return; endif
  switch code
    case 2, blk.name = strtrim(value);
    case 5, blk.handle = strtrim(value);
    case 10, blk.base_x = str2double(strtrim(value));
    case 20, blk.base_y = str2double(strtrim(value));
    case 30, blk.base_z = str2double(strtrim(value));
  endswitch
endfunction
function lineas = leer_lineas_local(archivo)
  fid = fopen(archivo, 'rt');
  if fid < 0
    error('AOS: no se pudo abrir %s', archivo);
  endif
  lineas = {};
  while true
    L = fgetl(fid);
    if ~ischar(L), break; endif
    lineas{end+1} = L; %#ok<AGROW>
  endwhile
  fclose(fid);
endfunction

function [ent, i] = leer_hasta_0_local(lineas, i, parse_fn, init)
  if nargin < 4 || isempty(init)
    init = base_ent_local('');
  endif
  ent = init;
  n = numel(lineas);
  while i <= n - 1
    code = str2double(strtrim(lineas{i}));
    value = lineas{i + 1};
    if ~isnan(code) && code == 0
      break;
    endif
    i = i + 2;
    if isnan(code), continue; endif
    ent = parse_fn(ent, code, value);
  endwhile
  ent = parse_fn(ent, [], []);
endfunction

function [ent, i] = leer_polyline_local(lineas, i)
  ent = base_ent_local('POLYLINE');
  pts = [];
  n = numel(lineas);
  while i <= n - 1
    code = str2double(strtrim(lineas{i}));
    value = lineas{i + 1};
    i = i + 2;
    if isnan(code), continue; endif
    if code == 0 && strcmpi(strtrim(value), 'SEQEND')
      break;
    endif
    if code == 0 && strcmpi(strtrim(value), 'VERTEX')
      x = NaN; y = NaN; z = 0;
      while i <= n - 1
        c2 = str2double(strtrim(lineas{i}));
        v2 = lineas{i + 1};
        if ~isnan(c2) && c2 == 0
          break;
        endif
        i = i + 2;
        if isnan(c2), continue; endif
        switch c2
          case 10, x = str2double(strtrim(v2));
          case 20, y = str2double(strtrim(v2));
          case 30, z = str2double(strtrim(v2));
          case 8, if isempty(ent.layer), ent.layer = strtrim(v2); endif
          case 5, if isempty(ent.handle), ent.handle = strtrim(v2); endif
        endswitch
      endwhile
      pts(end+1, :) = [x y z]; %#ok<AGROW>
    elseif code == 8
      ent.layer = strtrim(value);
    elseif code == 5
      ent.handle = strtrim(value);
    endif
  endwhile
  ent.geometry = pts;
endfunction

function ent = base_ent_local(tipo)
  ent = struct();
  ent.entity_type = tipo;
  ent.handle = '';
  ent.layer = '';
  ent.block_name = '';
  ent.geometry = [];
  ent.text = '';
  ent.tag = '';
  ent.attribs = {};
  ent.radius = NaN;
  ent.x1 = NaN; ent.y1 = NaN; ent.z1 = 0;
  ent.x2 = NaN; ent.y2 = NaN; ent.z2 = 0;
  ent.xs = []; ent.ys = [];
endfunction

function layer = parse_layer_local(layer, code, value)
  if nargin < 1 || isempty(layer) || ~isstruct(layer)
    layer = struct('name', '', 'color', NaN, 'flags', NaN);
  endif
  if nargin < 2 || isempty(code), return; endif
  switch code
    case 2, layer.name = strtrim(value);
    case 62, layer.color = str2double(strtrim(value));
    case 70, layer.flags = str2double(strtrim(value));
  endswitch
endfunction

function ent = parse_line_local(ent, code, value)
  if isempty(ent.entity_type), ent.entity_type = 'LINE'; endif
  if nargin < 2 || isempty(code)
    if ~isnan(ent.x1)
      ent.geometry = [ent.x1 ent.y1 ent.z1; ent.x2 ent.y2 ent.z2];
    endif
    return;
  endif
  switch code
    case 5, ent.handle = strtrim(value);
    case 8, ent.layer = strtrim(value);
    case 10, ent.x1 = str2double(strtrim(value));
    case 20, ent.y1 = str2double(strtrim(value));
    case 30, ent.z1 = str2double(strtrim(value));
    case 11, ent.x2 = str2double(strtrim(value));
    case 21, ent.y2 = str2double(strtrim(value));
    case 31, ent.z2 = str2double(strtrim(value));
  endswitch
  if ~isnan(ent.x1) && ~isnan(ent.x2)
    ent.geometry = [ent.x1 ent.y1 ent.z1; ent.x2 ent.y2 ent.z2];
  endif
endfunction

function ent = parse_lwpolyline_local(ent, code, value)
  if isempty(ent.entity_type), ent.entity_type = 'LWPOLYLINE'; endif
  if nargin < 2 || isempty(code)
    n = min(numel(ent.xs), numel(ent.ys));
    if n > 0
      ent.geometry = [ent.xs(1:n)' ent.ys(1:n)' zeros(n, 1)];
    endif
    return;
  endif
  switch code
    case 5, ent.handle = strtrim(value);
    case 8, ent.layer = strtrim(value);
    case 10, ent.xs(end+1) = str2double(strtrim(value));
    case 20, ent.ys(end+1) = str2double(strtrim(value));
  endswitch
  n = min(numel(ent.xs), numel(ent.ys));
  if n > 0
    ent.geometry = [ent.xs(1:n)' ent.ys(1:n)' zeros(n, 1)];
  endif
endfunction

function ent = parse_circle_local(ent, code, value)
  if isempty(ent.entity_type), ent.entity_type = 'CIRCLE'; endif
  if nargin < 2 || isempty(code)
    if ~isnan(ent.x1)
      ent.geometry = [ent.x1 ent.y1 ent.z1];
    endif
    return;
  endif
  switch code
    case 5, ent.handle = strtrim(value);
    case 8, ent.layer = strtrim(value);
    case 10, ent.x1 = str2double(strtrim(value));
    case 20, ent.y1 = str2double(strtrim(value));
    case 30, ent.z1 = str2double(strtrim(value));
    case 40, ent.radius = str2double(strtrim(value));
  endswitch
  if ~isnan(ent.x1)
    ent.geometry = [ent.x1 ent.y1 ent.z1];
  endif
endfunction

function ent = parse_text_local(ent, code, value, tipo)
  if isempty(ent.entity_type), ent.entity_type = tipo; endif
  if nargin < 2 || isempty(code)
    if ~isnan(ent.x1)
      ent.geometry = [ent.x1 ent.y1 ent.z1];
    endif
    return;
  endif
  switch code
    case 5, ent.handle = strtrim(value);
    case 8, ent.layer = strtrim(value);
    case 10, ent.x1 = str2double(strtrim(value));
    case 20, ent.y1 = str2double(strtrim(value));
    case 30, ent.z1 = str2double(strtrim(value));
    case 1, ent.text = strtrim(value);
  endswitch
  if ~isnan(ent.x1)
    ent.geometry = [ent.x1 ent.y1 ent.z1];
  endif
endfunction

function ent = parse_insert_local(ent, code, value)
  if isempty(ent.entity_type), ent.entity_type = 'INSERT'; endif
  if nargin < 2 || isempty(code)
    if ~isnan(ent.x1)
      ent.geometry = [ent.x1 ent.y1 ent.z1];
    endif
    return;
  endif
  switch code
    case 5, ent.handle = strtrim(value);
    case 8, ent.layer = strtrim(value);
    case 2, ent.block_name = strtrim(value);
    case 10, ent.x1 = str2double(strtrim(value));
    case 20, ent.y1 = str2double(strtrim(value));
    case 30, ent.z1 = str2double(strtrim(value));
  endswitch
  if ~isnan(ent.x1)
    ent.geometry = [ent.x1 ent.y1 ent.z1];
  endif
endfunction

function ent = parse_attrib_local(ent, code, value, tipo)
  if isempty(ent.entity_type), ent.entity_type = tipo; endif
  if nargin < 2 || isempty(code)
    if ~isnan(ent.x1)
      ent.geometry = [ent.x1 ent.y1 ent.z1];
    endif
    return;
  endif
  switch code
    case 5, ent.handle = strtrim(value);
    case 8, ent.layer = strtrim(value);
    case 2, ent.tag = strtrim(value);
    case 1, ent.text = strtrim(value);
    case 10, ent.x1 = str2double(strtrim(value));
    case 20, ent.y1 = str2double(strtrim(value));
    case 30, ent.z1 = str2double(strtrim(value));
  endswitch
  if ~isnan(ent.x1)
    ent.geometry = [ent.x1 ent.y1 ent.z1];
  endif
endfunction

function u = unidades_local(code)
  switch code
    case 0, u = 'SIN_UNIDAD';
    case 1, u = 'in';
    case 2, u = 'ft';
    case 3, u = 'mi';
    case 4, u = 'mm';
    case 5, u = 'cm';
    case 6, u = 'm';
    case 7, u = 'km';
    case 8, u = 'uin';
    case 9, u = 'mil';
    case 10, u = 'yd';
    otherwise, u = sprintf('INSUNITS_%g', code);
  endswitch
endfunction

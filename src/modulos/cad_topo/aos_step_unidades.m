function [factor, info, items] = aos_step_unidades(tabla, id_contexto)
% AOS_STEP_UNIDADES Factor a SI (metros) por contexto de representacion STEP.
% Atraviesa entidad compleja / GLOBAL_UNIT_ASSIGNED_CONTEXT / LENGTH_UNIT.
  factor = 1;
  info = struct('unidad', 'm', 'prefijo', '', 'origen', 'DEFAULT_AUSENTE', ...
    'factor_a_metros', 1, 'id_contexto', [], 'id_length_unit', []);
  items = {};
  if nargin < 1 || isempty(tabla) || ~isstruct(tabla), return; endif
  if nargin < 2 || isempty(id_contexto)
    items{end+1} = struct('codigo', 'STEP_UNIDADES_AUSENTES', ...
      'mensaje', 'Sin id de contexto de representacion; se asume metros', ...
      'severidad', 'ADVERTENCIA');
    return;
  endif

  info.id_contexto = id_contexto;
  ent = obtener_entidad_local(tabla, id_contexto);
  if isempty(ent)
    items{end+1} = struct('codigo', 'STEP_UNIDADES_AUSENTES', ...
      'mensaje', sprintf('Contexto #%d ausente; se asume metros', id_contexto), ...
      'severidad', 'ADVERTENCIA');
    return;
  endif

  % Buscar LENGTH_UNIT referenciado desde el contexto (directo o via GUAC)
  id_lu = buscar_length_unit_local(tabla, ent);
  if isempty(id_lu) || id_lu < 1
    items{end+1} = struct('codigo', 'STEP_UNIDADES_AUSENTES', ...
      'mensaje', sprintf('Sin LENGTH_UNIT en contexto #%d; se asume metros', id_contexto), ...
      'severidad', 'ADVERTENCIA');
    return;
  endif

  info.id_length_unit = id_lu;
  lu = obtener_entidad_local(tabla, id_lu);
  if isempty(lu)
    items{end+1} = struct('codigo', 'STEP_UNIDADES_AUSENTES', ...
      'mensaje', sprintf('LENGTH_UNIT #%d colgada; se asume metros', id_lu), ...
      'severidad', 'ADVERTENCIA');
    return;
  endif

  [factor, info] = interpretar_length_unit_local(tabla, lu, info);
  info.factor_a_metros = factor;
  if isempty(info.prefijo)
    u_txt = char(info.unidad);
  elseif strcmpi(char(info.unidad), 'm')
    u_txt = sprintf('%s.METRE', char(info.prefijo));
  else
    u_txt = sprintf('%s.%s', char(info.prefijo), char(info.unidad));
  endif
  items{end+1} = struct('codigo', 'STEP_UNIDADES', ...
    'mensaje', sprintf('Unidad STEP: %s factor=%g (origen=%s, ctx=#%d)', ...
      u_txt, factor, char(info.origen), id_contexto), ...
    'severidad', 'INFO', ...
    'factor_a_metros', factor, ...
    'id_contexto', id_contexto);
endfunction

function ent = obtener_entidad_local(tabla, id)
  ent = [];
  if ~isstruct(tabla) || ~isfield(tabla, 'por_id'), return; endif
  if id < 1 || id > numel(tabla.por_id), return; endif
  e = tabla.por_id{id};
  if ~isempty(e) && isstruct(e), ent = e; endif
endfunction

function id_lu = buscar_length_unit_local(tabla, ent)
  id_lu = [];
  % 1) Si la propia entidad es LENGTH_UNIT / SI_UNIT compleja
  if es_length_unit_local(ent)
    id_lu = ent.id;
    return;
  endif

  % 2) Recorrer refs del contexto buscando GLOBAL_UNIT_ASSIGNED_CONTEXT o LENGTH_UNIT
  candidatos = [];
  if isfield(ent, 'referencias')
    candidatos = ent.referencias(:)';
  endif
  % Tambien parsear args por si GUAC esta embebido como texto en compleja
  extras = regexp(ent.argumentos, '#(\d+)', 'tokens');
  for i = 1:numel(extras)
    candidatos(end+1) = str2double(extras{i}{1}); %#ok<AGROW>
  endfor
  candidatos = unique(candidatos, 'stable');

  for i = 1:numel(candidatos)
    e = obtener_entidad_local(tabla, candidatos(i));
    if isempty(e), continue; endif
    if es_length_unit_local(e)
      id_lu = e.id;
      return;
    endif
    % GLOBAL_UNIT_ASSIGNED_CONTEXT: sus refs incluyen units
    if tiene_tipo_local(e, 'GLOBAL_UNIT_ASSIGNED_CONTEXT') || ...
        (~isempty(strfind(upper(e.argumentos), 'GLOBAL_UNIT_ASSIGNED_CONTEXT')))
      for j = 1:numel(e.referencias)
        u = obtener_entidad_local(tabla, e.referencias(j));
        if ~isempty(u) && es_length_unit_local(u)
          id_lu = u.id;
          return;
        endif
      endfor
    endif
  endfor

  % 3) Contexto complejo: tipicamente contiene GLOBAL_UNIT_ASSIGNED_CONTEXT((#a,#b,#c))
  m = regexp(upper(ent.argumentos), ...
    'GLOBAL_UNIT_ASSIGNED_CONTEXT\s*\(\s*\(([^)]*)\)', 'tokens', 'once');
  if ~isempty(m)
    refs = regexp(m{1}, '#(\d+)', 'tokens');
    for i = 1:numel(refs)
      uid = str2double(refs{i}{1});
      u = obtener_entidad_local(tabla, uid);
      if ~isempty(u) && es_length_unit_local(u)
        id_lu = uid;
        return;
      endif
    endfor
  endif
endfunction

function tf = es_length_unit_local(ent)
  tf = false;
  if isempty(ent) || ~isstruct(ent), return; endif
  if tiene_tipo_local(ent, 'LENGTH_UNIT'), tf = true; return; endif
  if tiene_tipo_local(ent, 'SI_UNIT') && ...
      (~isempty(strfind(upper(ent.argumentos), '.METRE.')) || ...
       ~isempty(strfind(upper(ent.raw), '.METRE.')))
    tf = true;
    return;
  endif
  if tiene_tipo_local(ent, 'CONVERSION_BASED_UNIT')
    tf = true;
  endif
endfunction

function tf = tiene_tipo_local(ent, tipo)
  tf = false;
  tipo = upper(char(tipo));
  if isfield(ent, 'tipo') && strcmpi(char(ent.tipo), tipo)
    tf = true; return;
  endif
  if isfield(ent, 'tipos_complejos')
    for i = 1:numel(ent.tipos_complejos)
      if strcmpi(char(ent.tipos_complejos{i}), tipo)
        tf = true; return;
      endif
    endfor
  endif
endfunction

function [factor, info] = interpretar_length_unit_local(tabla, lu, info)
  factor = 1;
  txt = '';
  if isfield(lu, 'raw'), txt = [txt char(lu.raw)]; endif
  if isfield(lu, 'argumentos'), txt = [txt ' ' char(lu.argumentos)]; endif
  up = upper(txt);

  % CONVERSION_BASED_UNIT (p.ej. pulgadas)
  if tiene_tipo_local(lu, 'CONVERSION_BASED_UNIT') || ...
      ~isempty(strfind(up, 'CONVERSION_BASED_UNIT'))
    [f_c, nom, ok] = conversion_based_local(tabla, lu);
    if ok
      factor = f_c;
      info.unidad = nom;
      info.prefijo = '';
      info.origen = sprintf('CONVERSION_BASED_UNIT(#%d)', lu.id);
      return;
    endif
  endif

  % SI_UNIT(.PREF.,.METRE.) o SI_UNIT($,.METRE.)
  prefijo = '';
  m = regexp(up, 'SI_UNIT\s*\(\s*([^,]*)\s*,\s*\.METRE\.', 'tokens', 'once');
  if ~isempty(m)
    pref_tok = strtrim(m{1});
    pref_tok = regexprep(pref_tok, '[\.\$]', '');
    prefijo = upper(pref_tok);
  elseif ~isempty(strfind(up, '.METRE.'))
    prefijo = '';
  else
    info.unidad = 'm';
    info.prefijo = '';
    info.origen = sprintf('LENGTH_UNIT(#%d)_SIN_SI', lu.id);
    factor = 1;
    return;
  endif

  switch prefijo
    case 'MILLI'
      factor = 1e-3; info.unidad = 'm'; info.prefijo = 'MILLI';
    case 'CENTI'
      factor = 1e-2; info.unidad = 'm'; info.prefijo = 'CENTI';
    case 'DECI'
      factor = 1e-1; info.unidad = 'm'; info.prefijo = 'DECI';
    case 'KILO'
      factor = 1e3; info.unidad = 'm'; info.prefijo = 'KILO';
    case 'MICRO'
      factor = 1e-6; info.unidad = 'm'; info.prefijo = 'MICRO';
    case 'NANO'
      factor = 1e-9; info.unidad = 'm'; info.prefijo = 'NANO';
    otherwise
      factor = 1; info.unidad = 'm'; info.prefijo = '';
  endswitch
  info.origen = sprintf('SI_UNIT(#%d)', lu.id);
endfunction

function [factor, nombre, ok] = conversion_based_local(tabla, lu)
  factor = 1; nombre = 'm'; ok = false;
  % Nombre tipico: CONVERSION_BASED_UNIT('INCH',...) o 'inch'
  m = regexp(lu.argumentos, '''([^'']+)''', 'tokens', 'once');
  nom = '';
  if ~isempty(m), nom = upper(strtrim(m{1})); endif
  if isempty(nom) && isfield(lu, 'raw')
    m2 = regexp(lu.raw, '''([^'']+)''', 'tokens', 'once');
    if ~isempty(m2), nom = upper(strtrim(m2{1})); endif
  endif

  % Factor numerico embebido LENGTH_MEASURE(x) o similar
  f_num = [];
  m3 = regexp(upper([lu.argumentos ' ' lu.raw]), ...
    'LENGTH_MEASURE\s*\(\s*([0-9.+-E]+)\s*\)', 'tokens', 'once');
  if ~isempty(m3)
    f_num = str2double(m3{1});
  endif

  if strcmp(nom, 'INCH') || strcmp(nom, 'IN') || strcmp(nom, 'INCHES')
    if ~isempty(f_num) && isfinite(f_num)
      factor = f_num;
    else
      factor = 0.0254;
    endif
    nombre = 'in';
    ok = true;
    return;
  endif
  if strcmp(nom, 'FOOT') || strcmp(nom, 'FT') || strcmp(nom, 'FEET')
    if ~isempty(f_num) && isfinite(f_num)
      factor = f_num;
    else
      factor = 0.3048;
    endif
    nombre = 'ft';
    ok = true;
    return;
  endif
  if ~isempty(f_num) && isfinite(f_num) && f_num > 0
    factor = f_num;
    if ~isempty(nom), nombre = lower(nom); else, nombre = 'conv'; endif
    ok = true;
  endif
endfunction

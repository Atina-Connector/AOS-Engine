function [tabla, items] = aos_step_tabla_entidades(raw, opciones)
% AOS_STEP_TABLA_ENTIDADES Tabla lexica #id -> tipo/args/refs (ISO-10303-21).
% Sin semantica BRep. Sin error() por STEP inesperado.
  if nargin < 1, raw = ''; endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  items = {};
  tabla = struct();
  tabla.ids = [];
  tabla.por_id = {};
  tabla.n_entidades = 0;
  tabla.tipos = struct();

  if isempty(raw) || ~ischar(raw)
    return;
  endif

  data = extraer_seccion_data_local(raw);
  if isempty(data)
    return;
  endif

  stmts = partir_sentencias_local(data);
  max_id = 0;
  ents = {};
  ids = [];

  for i = 1:numel(stmts)
    ent = parsear_entidad_local(stmts{i});
    if isempty(ent) || ~isfield(ent, 'id') || ~isfinite(ent.id) || ent.id < 1
      continue;
    endif
    ents{end+1} = ent; %#ok<AGROW>
    ids(end+1) = ent.id; %#ok<AGROW>
    if ent.id > max_id, max_id = ent.id; endif

    tkey = upper(char(ent.tipo));
    if isempty(tkey), tkey = 'COMPLEX'; endif
    tkey = regexprep(tkey, '[^A-Z0-9_]', '_');
    if isempty(tkey), tkey = 'COMPLEX'; endif
    if isfield(tabla.tipos, tkey)
      tabla.tipos.(tkey) = tabla.tipos.(tkey) + 1;
    else
      tabla.tipos.(tkey) = 1;
    endif
  endfor

  por_id = cell(1, max(max_id, 1));
  for i = 1:numel(ents)
    por_id{ents{i}.id} = ents{i};
  endfor

  % Referencias colgadas (informativo, sin excepcion)
  vistos_colg = struct();
  for i = 1:numel(ents)
    refs = ents{i}.referencias;
    for j = 1:numel(refs)
      rid = refs(j);
      if rid < 1 || rid > numel(por_id) || isempty(por_id{rid})
        k = sprintf('r%d', rid);
        if ~isfield(vistos_colg, k)
          vistos_colg.(k) = 1;
          items{end+1} = struct( ...
            'codigo', 'STEP_REFERENCIA_COLGADA', ...
            'mensaje', sprintf('Referencia #%d no existe en la tabla', rid), ...
            'severidad', 'ADVERTENCIA', ...
            'id_origen', ents{i}.id, ...
            'id_ref', rid); %#ok<AGROW>
        endif
      endif
    endfor
  endfor

  tabla.ids = ids(:)';
  tabla.por_id = por_id;
  tabla.n_entidades = numel(ents);
endfunction

function data = extraer_seccion_data_local(raw)
  data = '';
  up = upper(raw);
  i0 = strfind(up, 'DATA;');
  if isempty(i0), return; endif
  start = i0(1) + 5;
  i1 = strfind(up(start:end), 'ENDSEC;');
  if isempty(i1)
    data = raw(start:end);
  else
    data = raw(start:start + i1(1) - 2);
  endif
endfunction

function stmts = partir_sentencias_local(data)
  stmts = {};
  n = numel(data);
  if n < 1, return; endif
  buf = char(zeros(1, n));
  nb = 0;
  in_str = false;
  i = 1;
  while i <= n
    c = data(i);
    if in_str
      nb = nb + 1; buf(nb) = c;
      if c == ''''
        if i < n && data(i + 1) == ''''
          nb = nb + 1; buf(nb) = '''';
          i = i + 2;
          continue;
        else
          in_str = false;
        endif
      endif
      i = i + 1;
      continue;
    endif
    if c == ''''
      in_str = true;
      nb = nb + 1; buf(nb) = c;
      i = i + 1;
      continue;
    endif
    if c == ';'
      s = strtrim(buf(1:nb));
      if ~isempty(s)
        stmts{end+1} = s; %#ok<AGROW>
      endif
      nb = 0;
      i = i + 1;
      continue;
    endif
    nb = nb + 1; buf(nb) = c;
    i = i + 1;
  endwhile
  if nb > 0
    s = strtrim(buf(1:nb));
    if ~isempty(s)
      stmts{end+1} = s;
    endif
  endif
endfunction

function ent = parsear_entidad_local(stmt)
  ent = [];
  m = regexp(stmt, '^\s*#(\d+)\s*=\s*(.*)$', 'tokens', 'once');
  if isempty(m), return; endif
  id = str2double(m{1});
  resto = strtrim(m{2});
  if isempty(resto), return; endif

  ent = struct();
  ent.id = id;
  ent.tipo = '';
  ent.tipos_complejos = {};
  ent.argumentos = '';
  ent.referencias = [];
  ent.compleja = false;
  ent.raw = stmt;

  if resto(1) == '('
    % Entidad compleja: ( TIPO_A(...) TIPO_B(...) )
    ent.compleja = true;
    cuerpo = strtrim(resto);
    if cuerpo(1) == '(' && cuerpo(end) == ')'
      cuerpo = strtrim(cuerpo(2:end-1));
    endif
    ent.argumentos = cuerpo;
    tipos = regexp(cuerpo, '([A-Za-z][A-Za-z0-9_]*)\s*\(', 'tokens');
    for k = 1:numel(tipos)
      ent.tipos_complejos{end+1} = upper(tipos{k}{1}); %#ok<AGROW>
    endfor
    if ~isempty(ent.tipos_complejos)
      ent.tipo = ent.tipos_complejos{1};
    else
      ent.tipo = 'COMPLEX';
    endif
  else
    m2 = regexp(resto, '^([A-Za-z][A-Za-z0-9_]*)\s*\((.*)\)\s*$', 'tokens', 'once');
    if isempty(m2)
      % Fallback: tipo sin parentesis bien cerrados
      m3 = regexp(resto, '^([A-Za-z][A-Za-z0-9_]*)', 'tokens', 'once');
      if ~isempty(m3)
        ent.tipo = upper(m3{1});
      else
        ent.tipo = 'UNKNOWN';
      endif
      ent.argumentos = resto;
    else
      ent.tipo = upper(m2{1});
      ent.argumentos = m2{2};
    endif
  endif

  ent.referencias = extraer_refs_local(ent.argumentos);
endfunction

function refs = extraer_refs_local(txt)
  refs = [];
  if isempty(txt), return; endif
  n = numel(txt);
  in_str = false;
  i = 1;
  while i <= n
    c = txt(i);
    if in_str
      if c == ''''
        if i < n && txt(i + 1) == ''''
          i = i + 2;
          continue;
        else
          in_str = false;
        endif
      endif
      i = i + 1;
      continue;
    endif
    if c == ''''
      in_str = true;
      i = i + 1;
      continue;
    endif
    if c == '#'
      j = i + 1;
      while j <= n && txt(j) >= '0' && txt(j) <= '9'
        j = j + 1;
      endwhile
      if j > i + 1
        refs(end+1) = str2double(txt(i+1:j-1)); %#ok<AGROW>
        i = j;
        continue;
      endif
    endif
    i = i + 1;
  endwhile
  if ~isempty(refs)
    refs = unique(refs, 'stable');
  endif
endfunction

function metas = aos_cad_extraer_metadatos(entidades, preferencias)
% AOS_CAD_EXTRAER_METADATOS Extrae claves tecnicas desde TEXT/MTEXT/ATTRIB.
% Compatible con LibreCAD (prioridad: AOS_META > capa > ATTRIB).
  if nargin < 1 || isempty(entidades), entidades = {}; endif
  if nargin < 2 || isempty(preferencias)
    preferencias = struct('meta_tol_m', 2.0); %#ok<NASGU>
  endif

  metas = {};
  attribs_pending = {};

  for i = 1:numel(entidades)
    e = entidades{i};
    tipo = upper(char(getf(e, 'entity_type', '')));
    capa = char(getf(e, 'layer', ''));
    geom = getf(e, 'geometry', []);
    txt = char(getf(e, 'text', ''));
    tag = char(getf(e, 'tag', ''));
    handle = char(getf(e, 'handle', ''));

    if ismember(tipo, {'TEXT', 'MTEXT'})
      if isempty(txt) || isempty(geom), continue; endif
      xy = geom(1, 1:min(2, size(geom, 2)));
      if numel(xy) < 2, continue; endif
      keys = parse_keys_local(txt);
      if isempty(fieldnames(keys)), continue; endif
      m = struct();
      m.x = xy(1); m.y = xy(2);
      m.layer = capa;
      m.handle = handle;
      m.fuente = 'TEXTO_AOS_META';
      m.texto_crudo = txt;
      m.keys = keys;
      metas{end+1} = m; %#ok<AGROW>
    elseif ismember(tipo, {'ATTRIB', 'ATTDEF'})
      if isempty(tag) && isempty(txt), continue; endif
      xy = [NaN NaN];
      if ~isempty(geom)
        xy = geom(1, 1:min(2, size(geom, 2)));
      endif
      a = struct();
      a.x = xy(1); a.y = xy(2);
      a.layer = capa;
      a.handle = handle;
      a.tag = tag;
      a.text = txt;
      a.block_name = char(getf(e, 'block_name', ''));
      attribs_pending{end+1} = a; %#ok<AGROW>
    endif
  endfor

  usados = false(1, numel(attribs_pending));
  for i = 1:numel(attribs_pending)
    if usados(i), continue; endif
    a0 = attribs_pending{i};
    keys = struct();
    keys = merge_attrib_key_local(keys, a0.tag, a0.text);
    usados(i) = true;
    for j = (i+1):numel(attribs_pending)
      if usados(j), continue; endif
      aj = attribs_pending{j};
      cerca = false;
      if ~isnan(a0.x) && ~isnan(aj.x)
        cerca = hypot(a0.x - aj.x, a0.y - aj.y) <= 1.0;
      endif
      mismo_blk = ~isempty(a0.block_name) && strcmpi(a0.block_name, aj.block_name);
      if cerca || mismo_blk
        keys = merge_attrib_key_local(keys, aj.tag, aj.text);
        usados(j) = true;
      endif
    endfor
    if isempty(fieldnames(keys)), continue; endif
    m = struct();
    m.x = a0.x; m.y = a0.y;
    m.layer = a0.layer;
    m.handle = a0.handle;
    m.fuente = 'DXF';
    m.texto_crudo = sprintf('ATTRIB:%s', a0.tag);
    m.keys = keys;
    metas{end+1} = m; %#ok<AGROW>
  endfor
endfunction

function keys = parse_keys_local(txt)
  keys = struct();
  txt = char(txt);
  if isempty(txt), return; endif
  t = strtrim(txt);
  if strncmpi(t, 'AOS ', 4)
    t = strtrim(t(5:end));
  elseif strcmpi(t, 'AOS')
    t = '';
  endif
  parts = regexp(t, '[\s;,]+', 'split');
  for i = 1:numel(parts)
    part = strtrim(parts{i});
    if isempty(part), continue; endif
    eq = strfind(part, '=');
    if isempty(eq), continue; endif
    k = upper(strtrim(part(1:eq(1)-1)));
    v = strtrim(part(eq(1)+1:end));
    if isempty(k) || isempty(v), continue; endif
    keys.(k) = v;
  endfor
endfunction

function keys = merge_attrib_key_local(keys, tag, text)
  tag = upper(strtrim(char(tag)));
  text = strtrim(char(text));
  if isempty(tag) && isempty(text), return; endif
  if ~isempty(tag) && ~isempty(text)
    keys.(tag) = text;
    return;
  endif
  if ~isempty(text)
    k2 = parse_keys_local(text);
    fn = fieldnames(k2);
    for i = 1:numel(fn)
      keys.(fn{i}) = k2.(fn{i});
    endfor
  endif
endfunction

function v = getf(s, name, default)
  if isstruct(s) && isfield(s, name)
    v = s.(name);
  else
    v = default;
  endif
endfunction

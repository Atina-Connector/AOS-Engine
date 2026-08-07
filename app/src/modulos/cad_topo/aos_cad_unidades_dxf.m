function [factor_m, nombre, origen, advertencias] = aos_cad_unidades_dxf(modelo_dxf, preferencias)
% AOS_CAD_UNIDADES_DXF Resuelve factor de escala DXF -> metros (SI).
% Prioridad: metadato AOS UNIDADES= > $INSUNITS > preferencias > default m.
  if nargin < 1, modelo_dxf = struct(); endif
  if nargin < 2, preferencias = struct(); endif
  factor_m = 1;
  nombre = 'm';
  origen = 'DEFAULT_MODULO';
  advertencias = {};

  % 1) Metadato explicito AOS UNIDADES= en TEXT/MTEXT
  [f_meta, n_meta, ok_meta] = meta_unidades_local(modelo_dxf);
  if ok_meta
    factor_m = f_meta;
    nombre = n_meta;
    origen = 'TEXTO_AOS_META';
    return;
  endif

  % 2) $INSUNITS del HEADER
  if isstruct(modelo_dxf) && isfield(modelo_dxf, 'insunits') && isfinite(modelo_dxf.insunits)
    [f_ins, n_ins, ok_ins, adv_ins] = mapa_insunits_local(modelo_dxf.insunits);
    if ok_ins
      factor_m = f_ins;
      nombre = n_ins;
      origen = sprintf('DXF($INSUNITS=%g)', modelo_dxf.insunits);
      if ~isempty(adv_ins), advertencias{end+1} = adv_ins; endif %#ok<AGROW>
      return;
    else
      advertencias{end+1} = adv_ins; %#ok<AGROW>
    endif
  endif

  % 3) Preferencia del modulo
  if isstruct(preferencias) && isfield(preferencias, 'dxf_unidades') && ...
      ~isempty(preferencias.dxf_unidades)
    [f_p, n_p, ok_p] = nombre_a_factor_local(preferencias.dxf_unidades);
    if ok_p
      factor_m = f_p;
      nombre = n_p;
      origen = 'PREFERENCIA_MODULO';
      return;
    endif
  endif

  % 4) Default metros con advertencia solo si el DXF no declaro nada util
  factor_m = 1;
  nombre = 'm';
  origen = 'DEFAULT_MODULO';
  if isstruct(modelo_dxf) && isfield(modelo_dxf, 'insunits') && isfinite(modelo_dxf.insunits)
    % Ya se reporto INSUNITS_NO_SOPORTADO arriba; no duplicar asumida
  elseif isstruct(modelo_dxf) && isfield(modelo_dxf, 'unidades') && ...
      (strcmpi(char(modelo_dxf.unidades), 'm') || strcmpi(char(modelo_dxf.unidades), 'DESCONOCIDA') ...
       || strcmpi(char(modelo_dxf.unidades), 'SIN_UNIDAD'))
    if strcmpi(char(modelo_dxf.unidades), 'DESCONOCIDA') || ...
        strcmpi(char(modelo_dxf.unidades), 'SIN_UNIDAD') || ...
        (isfield(modelo_dxf, 'insunits') && ~isfinite(modelo_dxf.insunits))
      advertencias{end+1} = 'UNIDAD_DXF_ASUMIDA_M'; %#ok<AGROW>
    endif
  else
    advertencias{end+1} = 'UNIDAD_DXF_ASUMIDA_M'; %#ok<AGROW>
  endif
endfunction

function [factor, nombre, ok, adv] = mapa_insunits_local(code)
  ok = true; adv = '';
  switch code
    case 0
      factor = 1; nombre = 'm'; ok = true;
      adv = 'UNIDAD_DXF_ASUMIDA_M'; % SIN_UNIDAD -> m
    case 1, factor = 0.0254; nombre = 'in';
    case 2, factor = 0.3048; nombre = 'ft';
    case 3, factor = 1609.344; nombre = 'mi'; % millas (raro en CAD)
    case 4, factor = 0.001; nombre = 'mm';
    case 5, factor = 0.01; nombre = 'cm';
    case 6, factor = 1; nombre = 'm';
    case 7, factor = 1000; nombre = 'km';
    case 8, factor = 2.54e-5; nombre = 'uin'; % microinches
    case 9, factor = 2.54e-8; nombre = 'mil';
    case 10, factor = 0.9144; nombre = 'yd';
    otherwise
      factor = 1; nombre = 'm'; ok = false;
      adv = sprintf('INSUNITS_NO_SOPORTADO_%g', code);
  endswitch
endfunction

function [factor, nombre, ok] = meta_unidades_local(modelo)
  factor = 1; nombre = 'm'; ok = false;
  if ~isstruct(modelo) || ~isfield(modelo, 'entidades'), return; endif
  for i = 1:numel(modelo.entidades)
    e = modelo.entidades{i};
    if ~isstruct(e), continue; endif
    tipo = '';
    if isfield(e, 'entity_type'), tipo = upper(char(e.entity_type)); endif
    if ~ismember(tipo, {'TEXT', 'MTEXT'}), continue; endif
    txt = '';
    if isfield(e, 'text'), txt = char(e.text); endif
    if isempty(txt), continue; endif
    keys = parse_keys_simple_local(txt);
    if isfield(keys, 'UNIDADES')
      [factor, nombre, ok] = nombre_a_factor_local(keys.UNIDADES);
      if ok, return; endif
    endif
  endfor
endfunction

function [factor, nombre, ok] = nombre_a_factor_local(nom)
  [factor, nombre, ok] = aos_units_factor_a_metros(nom);
endfunction

function keys = parse_keys_simple_local(txt)
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
    if isempty(k) || isempty(v), continue; endif
    keys.(k) = v;
  endfor
endfunction

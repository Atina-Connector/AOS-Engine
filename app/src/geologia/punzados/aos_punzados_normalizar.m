function [punzados, avisos] = aos_punzados_normalizar(entrada, opciones)
% AOS_PUNZADOS_NORMALIZAR Normaliza intervalos sin perder metadatos.
%
% Contrato canonico AOS_PUNZADOS_1.0 por tramo:
%   id, nombre, MD_desde, MD_hasta, densidad_tpm,
%   diametro_punzado_m, activo, fase_deg, penetracion_m,
%   tipo_disparo, formacion, permeabilidad_mD, skin,
%   estado_validacion, observaciones, origen y extras.
%
% Acepta:
%   - matriz numerica: MD_desde, MD_hasta, densidad, diametro_m,
%     activo, fase_deg, penetracion_m, permeabilidad_mD, skin;
%   - struct array;
%   - struct con campo tramos.
%
% Los campos no reconocidos se conservan dentro de extras. La funcion no
% inventa geologia ni Survey. Los intervalos con MD invalidos se descartan
% con un aviso para evitar que lleguen silenciosamente a los solvers.

  if nargin < 2 || ~isstruct(opciones), opciones = struct(); endif
  avisos = {};
  densidad_default = opcion_num_local(opciones, 'densidad_default_tpm', 0);
  diametro_default = opcion_num_local(opciones, 'diametro_default_m', 0.010);
  origen_default = opcion_txt_local(opciones, 'origen', 'NO_ESPECIFICADO');
  ordenar = opcion_log_local(opciones, 'ordenar', true);

  wrapper = struct();
  raw = entrada;
  if isstruct(entrada) && isscalar(entrada) && isfield(entrada, 'tramos')
    wrapper = entrada;
    raw = entrada.tramos;
    wrapper = rmfield(wrapper, 'tramos');
  endif

  tramos = struct([]);
  if isempty(raw)
    punzados = finalizar_local(wrapper, tramos);
    return;
  endif

  if isnumeric(raw)
    for i = 1:rows(raw)
      if columns(raw) < 2, break; endif
      t = tramo_base_local(i, origen_default, densidad_default, diametro_default);
      t.MD_desde = raw(i,1);
      t.MD_hasta = raw(i,2);
      if columns(raw) >= 3, t.densidad_tpm = raw(i,3); endif
      if columns(raw) >= 4, t.diametro_punzado_m = raw(i,4); endif
      if columns(raw) >= 5, t.activo = raw(i,5) ~= 0; endif
      if columns(raw) >= 6, t.fase_deg = raw(i,6); endif
      if columns(raw) >= 7, t.penetracion_m = raw(i,7); endif
      if columns(raw) >= 8, t.permeabilidad_mD = raw(i,8); endif
      if columns(raw) >= 9, t.skin = raw(i,9); endif
      [t, ok, aviso] = normalizar_tramo_local(t, i, origen_default, ...
        densidad_default, diametro_default);
      if ~isempty(aviso), avisos{end+1} = aviso; endif %#ok<AGROW>
      if ok, tramos = agregar_local(tramos, t); endif
    endfor
  elseif isstruct(raw)
    for i = 1:numel(raw)
      t = convertir_struct_local(raw(i), i, origen_default, ...
        densidad_default, diametro_default);
      [t, ok, aviso] = normalizar_tramo_local(t, i, origen_default, ...
        densidad_default, diametro_default);
      if ~isempty(aviso), avisos{end+1} = aviso; endif %#ok<AGROW>
      if ok, tramos = agregar_local(tramos, t); endif
    endfor
  else
    avisos{end+1} = 'Formato de punzados no reconocido; se devuelve una lista vacia.';
  endif

  if ordenar && ~isempty(tramos)
    claves = [[tramos.MD_desde].', [tramos.MD_hasta].'];
    [~, idx] = sortrows(claves, [1 2]);
    tramos = tramos(idx);
  endif
  tramos = ids_unicos_local(tramos);
  punzados = finalizar_local(wrapper, tramos);
endfunction

function p = finalizar_local(wrapper, tramos)
  p = wrapper;
  p.tramos = tramos;
  p.schema = 'AOS_PUNZADOS_1.0';
  p.n_tramos = numel(tramos);
  p.n_activos = 0;
  p.longitud_total_m = 0;
  p.tiros_totales_estimados = 0;
  for i = 1:numel(tramos)
    if tramos(i).activo
      L = max(tramos(i).MD_hasta - tramos(i).MD_desde, 0);
      p.n_activos = p.n_activos + 1;
      p.longitud_total_m = p.longitud_total_m + L;
      p.tiros_totales_estimados = p.tiros_totales_estimados + ...
        L * max(tramos(i).densidad_tpm, 0);
    endif
  endfor
endfunction

function t = convertir_struct_local(s, idx, origen_default, densidad_default, diametro_default)
  t = tramo_base_local(idx, origen_default, densidad_default, diametro_default);

  t.MD_desde = num_alias_local(s, ...
    {'MD_desde','MD_desde_m','md_desde','tope','top','MD_top','desde'}, NaN);
  t.MD_hasta = num_alias_local(s, ...
    {'MD_hasta','MD_hasta_m','md_hasta','base','bottom','MD_base','hasta','fondo'}, NaN);
  t.densidad_tpm = num_alias_local(s, ...
    {'densidad_tpm','densidad','tiros_m','tiros_por_metro','tiros_por_m','shot_density'}, ...
    densidad_default);

  if tiene_local(s, 'diametro_punzado_mm')
    t.diametro_punzado_m = num_alias_local(s, {'diametro_punzado_mm'}, ...
      diametro_default * 1000) / 1000;
  elseif tiene_local(s, 'shot_diameter_mm')
    t.diametro_punzado_m = num_alias_local(s, {'shot_diameter_mm'}, ...
      diametro_default * 1000) / 1000;
  else
    t.diametro_punzado_m = num_alias_local(s, ...
      {'diametro_punzado_m','diametro_m','shot_diameter_m'}, diametro_default);
  endif

  t.id = txt_alias_local(s, {'id','punzado_id','intervalo_id','codigo'}, t.id);
  t.nombre = txt_alias_local(s, {'nombre','etiqueta','zona'}, t.id);
  t.activo = log_alias_local(s, {'activo','habilitado','open','abierto'}, true);
  t.fase_deg = num_alias_local(s, {'fase_deg','fase','phasing_deg'}, NaN);
  if tiene_local(s, 'penetracion_mm')
    t.penetracion_m = num_alias_local(s, {'penetracion_mm'}, NaN) / 1000;
  else
    t.penetracion_m = num_alias_local(s, {'penetracion_m','penetration_m'}, NaN);
  endif
  t.tipo_disparo = txt_alias_local(s, ...
    {'tipo_disparo','tipo_carga','sistema_disparo'}, '');
  t.formacion = txt_alias_local(s, {'formacion','capa','zona_geologica'}, '');
  t.permeabilidad_mD = num_alias_local(s, ...
    {'permeabilidad_mD','permeabilidad_md','permeabilidad_h_mD','k_mD'}, NaN);
  t.skin = num_alias_local(s, {'skin','skin_factor'}, NaN);
  t.estado_validacion = txt_alias_local(s, ...
    {'estado_validacion','validacion','validation_status'}, 'NO_VALIDADO');
  t.observaciones = txt_alias_local(s, ...
    {'observaciones','comentario','nota'}, '');
  t.origen = txt_alias_local(s, {'origen','source'}, origen_default);

  if isfield(s, 'extras') && isstruct(s.extras)
    t.extras = s.extras;
  endif
  conocidos = campos_conocidos_local();
  fn = fieldnames(s);
  for k = 1:numel(fn)
    if any(strcmp(fn{k}, conocidos)), continue; endif
    t.extras.(aos_sanitizar_campo(fn{k})) = s.(fn{k});
  endfor
endfunction

function [t, ok, aviso] = normalizar_tramo_local(t, idx, origen_default, densidad_default, diametro_default)
  ok = true;
  aviso = '';
  [a, oka] = aos_numero_seguro(t.MD_desde, NaN);
  [b, okb] = aos_numero_seguro(t.MD_hasta, NaN);
  if ~oka || ~okb || ~isfinite(a) || ~isfinite(b) || abs(a-b) <= 1e-12
    ok = false;
    aviso = sprintf('Tramo %d descartado: MD desde/hasta no validos.', idx);
    return;
  endif
  if b < a
    tmp = a; a = b; b = tmp;
    aviso = sprintf('Tramo %d: MD invertidos; se normalizaron.', idx);
  endif
  t.MD_desde = a;
  t.MD_hasta = b;

  [d, okd] = aos_numero_seguro(t.densidad_tpm, densidad_default);
  if ~okd || ~isfinite(d), d = densidad_default; endif
  t.densidad_tpm = max(d, 0);

  [diam, okdiam] = aos_numero_seguro(t.diametro_punzado_m, diametro_default);
  if ~okdiam || ~isfinite(diam) || diam <= 0, diam = diametro_default; endif
  t.diametro_punzado_m = diam;

  [act, okact] = aos_logico_seguro(t.activo, true);
  if ~okact, act = true; endif
  t.activo = logical(act);

  t.fase_deg = numero_opcional_local(t.fase_deg, NaN);
  t.penetracion_m = numero_opcional_local(t.penetracion_m, NaN);
  if isfinite(t.penetracion_m) && t.penetracion_m < 0, t.penetracion_m = NaN; endif
  t.permeabilidad_mD = numero_opcional_local(t.permeabilidad_mD, NaN);
  if isfinite(t.permeabilidad_mD) && t.permeabilidad_mD < 0, t.permeabilidad_mD = NaN; endif
  t.skin = numero_opcional_local(t.skin, NaN);

  [t.id, okid] = aos_texto_seguro(t.id, sprintf('PUNZ-%03d', idx));
  if ~okid || isempty(strtrim(t.id)), t.id = sprintf('PUNZ-%03d', idx); endif
  [t.nombre, oknom] = aos_texto_seguro(t.nombre, t.id);
  if ~oknom || isempty(strtrim(t.nombre)), t.nombre = t.id; endif
  [t.tipo_disparo, oktipo] = aos_texto_seguro(t.tipo_disparo, '');
  if ~oktipo, t.tipo_disparo = ''; endif
  [t.formacion, okform] = aos_texto_seguro(t.formacion, '');
  if ~okform, t.formacion = ''; endif
  [t.estado_validacion, okval] = aos_texto_seguro(t.estado_validacion, 'NO_VALIDADO');
  if ~okval || isempty(strtrim(t.estado_validacion)), t.estado_validacion = 'NO_VALIDADO'; endif
  [t.observaciones, okobs] = aos_texto_seguro(t.observaciones, '');
  if ~okobs, t.observaciones = ''; endif
  [t.origen, okori] = aos_texto_seguro(t.origen, origen_default);
  if ~okori || isempty(strtrim(t.origen)), t.origen = origen_default; endif
  if ~isstruct(t.extras), t.extras = struct(); endif
endfunction

function v = numero_opcional_local(x, defecto)
  [v, ok] = aos_numero_seguro(x, defecto);
  if ~ok || ~isfinite(v), v = defecto; endif
endfunction

function t = tramo_base_local(idx, origen, densidad, diametro)
  id = sprintf('PUNZ-%03d', idx);
  t = struct('id',id,'nombre',id,'MD_desde',NaN,'MD_hasta',NaN, ...
    'densidad_tpm',densidad,'diametro_punzado_m',diametro,'activo',true, ...
    'fase_deg',NaN,'penetracion_m',NaN,'tipo_disparo','', ...
    'formacion','','permeabilidad_mD',NaN,'skin',NaN, ...
    'estado_validacion','NO_VALIDADO','observaciones','', ...
    'origen',origen,'extras',struct());
endfunction

function tramos = agregar_local(tramos, t)
  if isempty(tramos), tramos = t; else, tramos(end+1) = t; endif
endfunction

function tramos = ids_unicos_local(tramos)
  usados = {};
  for i = 1:numel(tramos)
    base = limpiar_id_local(tramos(i).id);
    if isempty(base), base = sprintf('PUNZ-%03d', i); endif
    candidato = base; n = 2;
    while any(strcmpi(usados, candidato))
      candidato = sprintf('%s_%d', base, n); n = n + 1;
    endwhile
    tramos(i).id = candidato;
    if isempty(strtrim(tramos(i).nombre)), tramos(i).nombre = candidato; endif
    usados{end+1} = candidato; %#ok<AGROW>
  endfor
endfunction

function s = limpiar_id_local(s)
  [s, ok] = aos_texto_seguro(s, '');
  if ~ok, s = ''; return; endif
  s = regexprep(strtrim(s), '[^A-Za-z0-9_.-]+', '_');
  s = regexprep(s, '_+', '_');
endfunction

function v = num_alias_local(s, campos, defecto)
  v = defecto;
  for i = 1:numel(campos)
    if isfield(s, campos{i})
      [x, ok] = aos_numero_seguro(s.(campos{i}), defecto);
      if ok, v = x; return; endif
    endif
  endfor
endfunction

function v = txt_alias_local(s, campos, defecto)
  v = defecto;
  for i = 1:numel(campos)
    if isfield(s, campos{i})
      [x, ok] = aos_texto_seguro(s.(campos{i}), defecto);
      if ok, v = x; return; endif
    endif
  endfor
endfunction

function v = log_alias_local(s, campos, defecto)
  v = defecto;
  for i = 1:numel(campos)
    if isfield(s, campos{i})
      [x, ok] = aos_logico_seguro(s.(campos{i}), defecto);
      if ok, v = x; return; endif
    endif
  endfor
endfunction

function tf = tiene_local(s, campo)
  tf = isstruct(s) && isfield(s, campo) && ~isempty(s.(campo));
endfunction

function c = campos_conocidos_local()
  c = {'tramos','schema','n_tramos','n_activos','longitud_total_m', ...
    'tiros_totales_estimados','id','punzado_id','intervalo_id','codigo', ...
    'nombre','etiqueta','zona','MD_desde','MD_desde_m','md_desde', ...
    'tope','top','MD_top','desde','MD_hasta','MD_hasta_m','md_hasta', ...
    'base','bottom','MD_base','hasta','fondo','densidad_tpm','densidad', ...
    'tiros_m','tiros_por_metro','tiros_por_m','shot_density', ...
    'diametro_punzado_m','diametro_m','diametro_punzado_mm', ...
    'shot_diameter_m','shot_diameter_mm','activo','habilitado','open', ...
    'abierto','fase_deg','fase','phasing_deg','penetracion_m', ...
    'penetracion_mm','penetration_m','tipo_disparo','tipo_carga', ...
    'sistema_disparo','formacion','capa','zona_geologica', ...
    'permeabilidad_mD','permeabilidad_md','permeabilidad_h_mD','k_mD', ...
    'skin','skin_factor','estado_validacion','validacion', ...
    'validation_status','observaciones','comentario','nota','origen', ...
    'source','extras','longitud_m','n_tiros','n_tiros_estimado'};
endfunction

function v = opcion_num_local(s, campo, defecto)
  v = defecto;
  if isfield(s, campo)
    [x, ok] = aos_numero_seguro(s.(campo), defecto);
    if ok, v = x; endif
  endif
endfunction

function v = opcion_txt_local(s, campo, defecto)
  v = defecto;
  if isfield(s, campo)
    [x, ok] = aos_texto_seguro(s.(campo), defecto);
    if ok, v = x; endif
  endif
endfunction

function v = opcion_log_local(s, campo, defecto)
  v = defecto;
  if isfield(s, campo)
    [x, ok] = aos_logico_seguro(s.(campo), defecto);
    if ok, v = x; endif
  endif
endfunction

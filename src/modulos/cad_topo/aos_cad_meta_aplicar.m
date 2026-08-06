function out = aos_cad_meta_aplicar(keys, fuente_default)
% AOS_CAD_META_APLICAR Resuelve diametro/material/rugosidad/id/P/Q/TIPO/KV/ESTADO.
% Sprint1: UNIDADES=, D_M=, D_MM=, D_IN=; heuristica D>1 marca META_UNIDAD_HEURISTICA.
% Sprint3 B1: CURVA_Q=/CURVA_H= (separador |), CURVA_Q_UNIDAD=, BOMBA_MODELO=, BOMBA_ESTADO=.
  if nargin < 2 || isempty(fuente_default), fuente_default = 'TEXTO_AOS_META'; endif
  out = struct();
  out.diametro_m = [];
  out.material = '';
  out.rugosidad = [];
  out.id = '';
  out.P = [];
  out.Q = [];
  out.QG = [];
  out.TIPO = '';
  out.KV = [];
  out.ESTADO = '';
  out.UNIDADES = '';
  out.CURVA_Q = [];
  out.CURVA_H = [];
  out.CURVA_Q_UNIDAD = 'm3/d';
  out.BOMBA_MODELO = '';
  out.BOMBA_ESTADO = '';
  out.origen_diametro = '';
  out.origen_material = '';
  out.origen_rugosidad = '';
  out.origen_id = '';
  out.origen_P = '';
  out.origen_Q = '';
  out.origen_QG = '';
  out.origen_TIPO = '';
  out.origen_KV = '';
  out.origen_ESTADO = '';
  out.origen_CURVA_Q = '';
  out.origen_CURVA_H = '';
  out.origen_CURVA_Q_UNIDAD = '';
  out.origen_BOMBA_MODELO = '';
  out.origen_BOMBA_ESTADO = '';
  out.estado_diametro = 'PENDIENTE';
  out.estado_material = 'PENDIENTE';
  out.estado_rugosidad = 'PENDIENTE';
  out.adv_diametro = '';
  out.adv_material = '';
  out.adv_rugosidad = '';
  out.adv_CURVA_Q = '';
  out.adv_CURVA_H = '';

  if nargin < 1 || isempty(keys) || ~isstruct(keys), return; endif

  if isfield(keys, 'UNIDADES')
    out.UNIDADES = lower(strtrim(char(keys.UNIDADES)));
  endif

  % Diametro — claves con unidad explicita primero (sin heuristica)
  if isfield(keys, 'D_M')
    [v, est, adv] = num_local(keys.D_M);
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  elseif isfield(keys, 'D_MM')
    [v, est, adv] = num_local(keys.D_MM);
    if ~isempty(v), v = v / 1000; endif
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  elseif isfield(keys, 'D_IN')
    [v, est, adv] = num_local(keys.D_IN);
    if ~isempty(v), v = v * 0.0254; endif
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  elseif isfield(keys, 'D')
    [v, est, adv] = num_local(keys.D);
    if ~isempty(v) && v > 1
      v = v / 1000;
      if isempty(adv), adv = 'META_UNIDAD_HEURISTICA'; else, adv = [adv '|META_UNIDAD_HEURISTICA']; endif
    endif
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  elseif isfield(keys, 'DN')
    [v, est, adv] = num_local(keys.DN);
    if ~isempty(v) && v > 1
      v = v / 1000;
      if isempty(adv), adv = 'META_UNIDAD_HEURISTICA'; else, adv = [adv '|META_UNIDAD_HEURISTICA']; endif
    endif
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  elseif isfield(keys, 'ID_MM')
    [v, est, adv] = num_local(keys.ID_MM);
    if ~isempty(v), v = v / 1000; endif
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  elseif isfield(keys, 'NOMINAL_DIAMETER')
    [v, est, adv] = num_local(keys.NOMINAL_DIAMETER);
    if ~isempty(v) && v >= 1 && v <= 48
      v = v * 0.0254;
      if isempty(adv), adv = 'META_UNIDAD_HEURISTICA'; else, adv = [adv '|META_UNIDAD_HEURISTICA']; endif
    endif
    out.diametro_m = v; out.origen_diametro = fuente_default;
    out.estado_diametro = est; out.adv_diametro = adv;
  endif

  % Material
  if isfield(keys, 'MAT')
    out.material = upper(char(keys.MAT));
    out.origen_material = fuente_default;
    out.estado_material = 'OK';
  elseif isfield(keys, 'MATERIAL')
    out.material = upper(char(keys.MATERIAL));
    out.origen_material = fuente_default;
    out.estado_material = 'OK';
  endif

  % Rugosidad
  if isfield(keys, 'EPS')
    [v, est, adv] = num_local(keys.EPS);
    out.rugosidad = v; out.origen_rugosidad = fuente_default;
    out.estado_rugosidad = est; out.adv_rugosidad = adv;
  elseif isfield(keys, 'ROUGHNESS_MM')
    [v, est, adv] = num_local(keys.ROUGHNESS_MM);
    if ~isempty(v), v = v / 1000; endif
    out.rugosidad = v; out.origen_rugosidad = fuente_default;
    out.estado_rugosidad = est; out.adv_rugosidad = adv;
  endif

  % ID
  if isfield(keys, 'ID')
    out.id = char(keys.ID);
    out.origen_id = fuente_default;
  elseif isfield(keys, 'AOS_OBJECT_ID')
    out.id = char(keys.AOS_OBJECT_ID);
    out.origen_id = fuente_default;
  endif

  % BC
  if isfield(keys, 'P')
    [v, est, adv] = num_local(keys.P); %#ok<ASGLU>
    out.P = v; out.origen_P = fuente_default;
  endif
  if isfield(keys, 'Q')
    [v, est, adv] = num_local(keys.Q); %#ok<ASGLU>
    out.Q = v; out.origen_Q = fuente_default;
  endif
  if isfield(keys, 'QG')
    [v, est, adv] = num_local(keys.QG); %#ok<ASGLU>
    out.QG = v; out.origen_QG = fuente_default;
  elseif isfield(keys, 'QG_SM3D')
    [v, est, adv] = num_local(keys.QG_SM3D); %#ok<ASGLU>
    if ~isempty(v), v = v / 86400; endif
    out.QG = v; out.origen_QG = fuente_default;
  endif

  % Tipo de objeto / valvula / accesorio
  if isfield(keys, 'TIPO')
    out.TIPO = upper(char(keys.TIPO));
    out.origen_TIPO = fuente_default;
  endif
  if isfield(keys, 'KV')
    [v, est, adv] = num_local(keys.KV); %#ok<ASGLU>
    out.KV = v; out.origen_KV = fuente_default;
  endif
  if isfield(keys, 'ESTADO')
    out.ESTADO = upper(char(keys.ESTADO));
    out.origen_ESTADO = fuente_default;
  endif

  % Curva head-caudal de bomba (separador de lista = | ; no usar coma)
  if isfield(keys, 'CURVA_Q_UNIDAD')
    out.CURVA_Q_UNIDAD = lower(strtrim(char(keys.CURVA_Q_UNIDAD)));
    out.origen_CURVA_Q_UNIDAD = fuente_default;
  endif
  if isfield(keys, 'CURVA_Q')
    [v, adv] = lista_num_local(keys.CURVA_Q);
    out.CURVA_Q = v; out.origen_CURVA_Q = fuente_default; out.adv_CURVA_Q = adv;
  endif
  if isfield(keys, 'CURVA_H')
    [v, adv] = lista_num_local(keys.CURVA_H);
    out.CURVA_H = v; out.origen_CURVA_H = fuente_default; out.adv_CURVA_H = adv;
  endif
  if isfield(keys, 'BOMBA_MODELO')
    out.BOMBA_MODELO = strtrim(char(keys.BOMBA_MODELO));
    out.origen_BOMBA_MODELO = fuente_default;
  endif
  if isfield(keys, 'BOMBA_ESTADO')
    out.BOMBA_ESTADO = upper(strtrim(char(keys.BOMBA_ESTADO)));
    out.origen_BOMBA_ESTADO = fuente_default;
  endif
endfunction

function [valor, estado, advertencia] = num_local(v)
  estado = 'OK'; advertencia = '';
  if isnumeric(v)
    valor = v;
    if isempty(valor) || any(isnan(valor))
      estado = 'ADVERTENCIA'; advertencia = 'NUM_INVALIDO';
    endif
    return;
  endif
  s = strrep(strtrim(char(v)), ',', '.');
  valor = str2double(s);
  if isnan(valor)
    valor = [];
    estado = 'ADVERTENCIA';
    advertencia = 'NUM_INVALIDO';
  endif
endfunction

function [vals, adv] = lista_num_local(v)
  % Listas de curva: separador | (parse_keys_local parte por coma).
  adv = '';
  if isnumeric(v)
    vals = v(:)';
    if isempty(vals) || any(~isfinite(vals))
      vals = []; adv = 'NUM_INVALIDO';
    endif
    return;
  endif
  s = strtrim(char(v));
  if isempty(s)
    vals = []; adv = 'NUM_INVALIDO';
    return;
  endif
  parts = regexp(s, '\|', 'split');
  vals = [];
  for i = 1:numel(parts)
    tok = strrep(strtrim(parts{i}), ',', '.');
    if isempty(tok), continue; endif
    x = str2double(tok);
    if isnan(x)
      vals = []; adv = 'NUM_INVALIDO';
      return;
    endif
    vals(end+1) = x; %#ok<AGROW>
  endfor
  if isempty(vals)
    adv = 'NUM_INVALIDO';
  endif
endfunction

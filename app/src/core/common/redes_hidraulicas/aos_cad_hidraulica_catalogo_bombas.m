function [curva, adv, info] = aos_cad_hidraulica_catalogo_bombas(modelo_id, ruta_catalogo)
% AOS_CAD_HIDRAULICA_CATALOGO_BOMBAS Resuelve BOMBA_MODELO desde JSON en disco.
%   [curva, adv, info] = aos_cad_hidraulica_catalogo_bombas(modelo_id)
%   [curva, adv, info] = aos_cad_hidraulica_catalogo_bombas(modelo_id, ruta)
% No hardcodea curvas: lee datos/catalogos/aos_bombas_catalogo_0_0_1.json.
  curva = struct();
  adv = {};
  info = struct('encontrada', false, 'modelo', '', 'ruta', '', 'fuente', '');

  if nargin < 1 || isempty(modelo_id)
    adv{end+1} = 'BOMBA_MODELO_VACIO';
    return;
  endif
  modelo_id = strtrim(char(modelo_id));
  info.modelo = modelo_id;

  if nargin < 2 || isempty(ruta_catalogo)
    ruta_catalogo = fullfile(aos_cad_raiz(), 'datos', 'catalogos', ...
                             'aos_bombas_catalogo_0_0_1.json');
  endif
  info.ruta = ruta_catalogo;

  if exist(ruta_catalogo, 'file') ~= 2
    adv{end+1} = 'CATALOGO_BOMBAS_NO_ENCONTRADO';
    return;
  endif

  try
    cat = leer_json_local(ruta_catalogo);
  catch
    adv{end+1} = 'CATALOGO_BOMBAS_JSON_INVALIDO';
    return;
  end_try_catch

  bombas = {};
  if isstruct(cat) && isfield(cat, 'bombas')
    bombas = cat.bombas;
    if isstruct(bombas), bombas = num2cell(bombas); endif
  endif

  for i = 1:numel(bombas)
    b = bombas{i};
    if ~isstruct(b) || ~isfield(b, 'modelo'), continue; endif
    if ~strcmpi(strtrim(char(b.modelo)), modelo_id), continue; endif

    Q = vector_campo_local(b, {'curva_Q_m3d', 'Q_m3d', 'Q'});
    H = vector_campo_local(b, {'curva_H_m', 'H_m', 'H', 'head_m'});
    if numel(Q) < 2 || numel(H) < 2 || numel(Q) ~= numel(H)
      adv{end+1} = 'CURVA_INSUFICIENTE_PUNTOS';
      info.encontrada = true;
      return;
    endif

    curva = struct();
    curva.Q_m3d = Q(:)';
    curva.H_m = H(:)';
    curva.modelo = char(b.modelo);
    if isfield(b, 'fuente'), curva.fuente = char(b.fuente); else, curva.fuente = 'CATALOGO'; endif
    if isfield(b, 'fabricante'), curva.fabricante = char(b.fabricante); endif
    if isfield(b, 'rango_valido'), curva.rango_valido = b.rango_valido; endif

    info.encontrada = true;
    info.fuente = curva.fuente;
    return;
  endfor

  adv{end+1} = 'BOMBA_MODELO_NO_ENCONTRADO';
endfunction

function s = leer_json_local(ruta)
  if ~(exist('jsondecode', 'builtin') == 5 || exist('jsondecode', 'file') == 2)
    error('jsondecode no disponible');
  endif
  fid = fopen(ruta, 'rt');
  if fid < 0, error('no se pudo abrir catalogo'); endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
  s = jsondecode(raw);
endfunction

function v = vector_campo_local(s, nombres)
  v = [];
  for i = 1:numel(nombres)
    if isfield(s, nombres{i})
      x = s.(nombres{i});
      if iscell(x)
        tmp = [];
        for k = 1:numel(x)
          if isnumeric(x{k}), tmp(end+1) = x{k}(1); endif %#ok<AGROW>
        endfor
        v = tmp(:);
      elseif isnumeric(x)
        v = x(:);
      endif
      return;
    endif
  endfor
endfunction

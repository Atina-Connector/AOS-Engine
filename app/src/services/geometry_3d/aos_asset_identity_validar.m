function [ok, items] = aos_asset_identity_validar(activo)
% AOS_ASSET_IDENTITY_VALIDAR Valida un activo contra aos_asset_identity_0_2_0.json.
% Lee los campos required del contrato en disco (no hardcodea la lista).
%
% [ok, items] = aos_asset_identity_validar(activo)

  ok = false;
  items = {};

  required = leer_required_contrato_local();
  if isempty(required)
    items{end+1} = struct( ...
      'codigo', 'ASSET_IDENTITY_CONTRATO', ...
      'mensaje', 'No se pudo leer required de aos_asset_identity_0_2_0.json', ...
      'severidad', 'ERROR');
    return;
  endif

  if nargin < 1 || isempty(activo) || ~isstruct(activo)
    items{end+1} = struct( ...
      'codigo', 'ASSET_IDENTITY_VACIO', ...
      'mensaje', 'Activo vacio o no struct', ...
      'severidad', 'ERROR');
    return;
  endif

  faltan = {};
  for i = 1:numel(required)
    campo = char(required{i});
    if ~isfield(activo, campo) || isempty_campo_local(activo.(campo))
      faltan{end+1} = campo; %#ok<AGROW>
      items{end+1} = struct( ...
        'codigo', 'ASSET_IDENTITY_REQUIRED', ...
        'mensaje', sprintf('Falta campo requerido: %s', campo), ...
        'severidad', 'ERROR'); %#ok<AGROW>
    endif
  endfor

  ok = isempty(faltan);
endfunction

function required = leer_required_contrato_local()
  required = {};
  try
    esta = fileparts(mfilename('fullpath'));
    ruta = fullfile(esta, 'aos_asset_identity_0_2_0.json');
    if exist(ruta, 'file') ~= 2
      return;
    endif
    raw = fileread(ruta);
    contrato = jsondecode(raw);
    if ~isstruct(contrato) || ~isfield(contrato, 'required')
      return;
    endif
    req = contrato.required;
    if ischar(req) || isstring(req)
      required = {char(req)};
    elseif iscell(req)
      required = {};
      for i = 1:numel(req)
        required{end+1} = char(req{i}); %#ok<AGROW>
      endfor
    else
      % Algunos Octave devuelven arreglo de chars
      try
        required = cellstr(req);
      catch
        required = {};
      end_try_catch
    endif
  catch
    required = {};
  end_try_catch
endfunction

function tf = isempty_campo_local(v)
  if isempty(v)
    tf = true;
    return;
  endif
  if ischar(v) || isstring(v)
    tf = isempty(strtrim(char(v)));
    return;
  endif
  tf = false;
endfunction

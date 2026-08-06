function [numero, ok] = aos_numero_seguro(valor, defecto)
% AOS_NUMERO_SEGURO Convierte un escalar a numero sin evaluar expresiones.
% Rechaza estructuras, vectores y listas. Admite notacion cientifica,
% NaN e Inf. GNU Octave es el motor oficial.

  if nargin < 2 || ~isnumeric(defecto) || ~isscalar(defecto)
    defecto = NaN;
  endif
  numero = defecto;
  ok = false;

  if isempty(valor)
    return;
  endif
  if islogical(valor) && isscalar(valor)
    numero = double(valor);
    ok = true;
    return;
  endif
  if isnumeric(valor) && isscalar(valor) && isreal(valor)
    numero = double(valor);
    ok = true;
    return;
  endif
  if iscell(valor) && numel(valor) == 1
    [numero, ok] = aos_numero_seguro(valor{1}, defecto);
    return;
  endif
  if isa(valor, 'string')
    try
      valor = char(valor);
    catch
      return;
    end_try_catch
  endif
  if ~ischar(valor)
    return;
  endif

  texto = strtrim(valor);
  if rows(texto) > 1
    return;
  endif
  if numel(texto) >= 2 && ...
     ((texto(1) == '"' && texto(end) == '"') || ...
      (texto(1) == '''' && texto(end) == ''''))
    texto = strtrim(texto(2:end-1));
  endif
  if isempty(texto)
    return;
  endif

  if any(strcmpi(texto, {'nan','+nan','-nan'}))
    numero = NaN;
    ok = true;
    return;
  endif
  if any(strcmpi(texto, {'inf','+inf','infinity','+infinity'}))
    numero = Inf;
    ok = true;
    return;
  endif
  if any(strcmpi(texto, {'-inf','-infinity'}))
    numero = -Inf;
    ok = true;
    return;
  endif

  patron = '^[+-]?((([0-9]+)(\.[0-9]*)?)|(\.[0-9]+))([eEdD][+-]?[0-9]+)?$';
  if isempty(regexp(texto, patron, 'once'))
    return;
  endif

  normalizado = regexprep(texto, '[dD]', 'e');
  numero = str2double(normalizado);
  ok = ~isempty(numero) && isscalar(numero) && (isfinite(numero) || isnan(numero) || isinf(numero));
  if ~ok
    numero = defecto;
  endif
endfunction

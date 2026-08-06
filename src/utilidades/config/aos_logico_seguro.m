function [valor, ok] = aos_logico_seguro(entrada, defecto)
% AOS_LOGICO_SEGURO Convierte booleanos sin forzar estructuras o vectores.
  if nargin < 2 || ~islogical(defecto) || ~isscalar(defecto)
    defecto = false;
  endif
  valor = defecto;
  ok = false;
  if isempty(entrada), return; endif
  if islogical(entrada) && isscalar(entrada)
    valor = entrada; ok = true; return;
  endif
  if isnumeric(entrada) && isscalar(entrada) && isreal(entrada) && isfinite(entrada)
    valor = entrada ~= 0; ok = true; return;
  endif
  if iscell(entrada) && numel(entrada) == 1
    [valor, ok] = aos_logico_seguro(entrada{1}, defecto); return;
  endif
  if isa(entrada, 'string')
    try entrada = char(entrada); catch, return; end_try_catch
  endif
  if ~ischar(entrada) || rows(entrada) > 1, return; endif
  texto = lower(strtrim(entrada));
  if any(strcmp(texto, {'s','si','sí','y','yes','true','verdadero','1'}))
    valor = true; ok = true;
  elseif any(strcmp(texto, {'n','no','false','falso','0'}))
    valor = false; ok = true;
  endif
endfunction

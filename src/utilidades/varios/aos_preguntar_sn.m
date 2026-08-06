function respuesta = aos_preguntar_sn(mensaje, defecto)
% AOS_PREGUNTAR_SN Pregunta binaria uniforme y valida la respuesta.
% Usar solo cuando existe una unica accion claramente expresada.
  if nargin < 2 || ~islogical(defecto) || ~isscalar(defecto)
    defecto = false;
  endif
  while true
    texto = input(mensaje, 's');
    if isempty(strtrim(texto))
      respuesta = defecto;
      return;
    endif
    [respuesta, ok] = aos_logico_seguro(texto, defecto);
    if ok, return; endif
    fprintf('Respuesta no valida. Ingrese s/si o n/no.\n');
  endwhile
endfunction

function valor = aos_parse_valor(texto)
% AOS_PARSE_VALOR Convierte solo escalares inequivocos de .aosdat.
% Las listas (por ejemplo 10,20,30 o [10 20 30]) se conservan como texto
% para que el importador especializado las interprete sin ambiguedad.
% No usa eval ni str2num. GNU Octave es el motor oficial.

  if nargin < 1
    valor = '';
    return;
  endif
  if ~ischar(texto)
    valor = texto;
    return;
  endif

  texto = strtrim(texto);
  if numel(texto) >= 2 && ...
     ((texto(1) == '"' && texto(end) == '"') || ...
      (texto(1) == '''' && texto(end) == ''''))
    texto = texto(2:end-1);
  endif

  [numero, ok_num] = aos_numero_seguro(texto, NaN);
  if ok_num
    valor = numero;
    return;
  endif

  % Mantener la compatibilidad historica sin convertir letras sueltas
  % como S/N, que pueden ser codigos validos dentro de catalogos.
  if any(strcmpi(texto, {'true','si','sí','yes','verdadero'}))
    valor = true;
  elseif any(strcmpi(texto, {'false','no','falso'}))
    valor = false;
  else
    valor = texto;
  endif
endfunction

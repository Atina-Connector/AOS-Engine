function [vector, ok] = aos_vector_seguro(valor, defecto)
% AOS_VECTOR_SEGURO Convierte listas numericas sin usar eval/str2num.
% Admite vectores numericos, celdas escalares y texto con separadores por
% coma, punto y coma o espacios, opcionalmente entre corchetes.

  if nargin < 2 || ~isnumeric(defecto)
    defecto = [];
  endif
  vector = defecto;
  ok = false;

  if isempty(valor)
    return;
  endif
  if (isnumeric(valor) || islogical(valor)) && isreal(valor)
    vector = double(valor(:)');
    ok = true;
    return;
  endif
  if iscell(valor)
    salida = zeros(1, numel(valor));
    for i = 1:numel(valor)
      [salida(i), valido] = aos_numero_seguro(valor{i}, NaN);
      if ~valido
        vector = defecto;
        return;
      endif
    endfor
    vector = salida;
    ok = true;
    return;
  endif
  if isa(valor, 'string')
    try
      valor = char(valor);
    catch
      return;
    end_try_catch
  endif
  if ~ischar(valor) || rows(valor) > 1
    return;
  endif

  texto = strtrim(valor);
  if numel(texto) >= 2 && ...
     ((texto(1) == '"' && texto(end) == '"') || ...
      (texto(1) == '''' && texto(end) == ''''))
    texto = strtrim(texto(2:end-1));
  endif
  if numel(texto) >= 2
    pares = {'[',']'; '(',')'; '{','}'};
    for i = 1:rows(pares)
      if texto(1) == pares{i,1} && texto(end) == pares{i,2}
        texto = strtrim(texto(2:end-1));
        break;
      endif
    endfor
  endif
  if isempty(texto)
    vector = [];
    ok = true;
    return;
  endif

  texto = strrep(texto, ',', ' ');
  texto = strrep(texto, ';', ' ');
  partes = strsplit(strtrim(texto));
  partes = partes(~cellfun(@isempty, partes));
  if isempty(partes)
    return;
  endif

  salida = zeros(1, numel(partes));
  for i = 1:numel(partes)
    [salida(i), valido] = aos_numero_seguro(partes{i}, NaN);
    if ~valido
      vector = defecto;
      return;
    endif
  endfor
  vector = salida;
  ok = true;
endfunction

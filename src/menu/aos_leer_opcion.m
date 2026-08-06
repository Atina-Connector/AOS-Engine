function op = aos_leer_opcion(mensaje, defecto)
% AOS_LEER_OPCION Lee una opcion numerica sin ejecutar expresiones arbitrarias.
  if nargin < 1 || isempty(mensaje), mensaje = 'Seleccione una opcion: '; endif
  if nargin < 2, defecto = []; endif
  txt = input(mensaje, 's');
  txt = strtrim(txt);
  if isempty(txt)
    op = defecto;
    return;
  endif
  op = str2double(txt);
  if ~isfinite(op)
    op = NaN;
  else
    op = round(op);
  endif
endfunction

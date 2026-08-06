function s = sens_si_no(valor)
% SENS_SI_NO Convierte un escalar logico/numerico en SI o NO.
  tf = false;
  if islogical(valor) && ~isempty(valor)
    tf = valor(1);
  elseif isnumeric(valor) && ~isempty(valor) && isfinite(valor(1))
    tf = valor(1) ~= 0;
  endif
  if tf
    s = 'SI';
  else
    s = 'NO';
  endif
endfunction

function txt = cond_val_local(valido, valor)
% COND_VAL_LOCAL Texto compacto de progreso para una sensibilidad.
  if valido && isnumeric(valor) && ~isempty(valor) && isfinite(valor(1))
    txt = sprintf('Ql=%.2f', valor(1));
  else
    txt = 'RECHAZADO';
  endif
endfunction

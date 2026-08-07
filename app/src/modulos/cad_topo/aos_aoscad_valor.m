function v = aos_aoscad_valor(campo)
% AOS_AOSCAD_VALOR Valor efectivo de un campo trazable (editado si existe).
  if nargin < 1 || isempty(campo)
    v = [];
    return;
  endif
  if isstruct(campo) && isfield(campo, 'valor_editado') && ~isempty(campo.valor_editado)
    v = campo.valor_editado;
  elseif isstruct(campo) && isfield(campo, 'valor_original')
    v = campo.valor_original;
  else
    v = campo;
  endif
endfunction

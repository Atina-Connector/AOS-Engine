function op = aos_opcion_modelo_ipr(modelo)
% Devuelve la opcion de menu correspondiente al nombre del modelo IPR.
  op = 1;
  if nargin < 1 || isempty(modelo), return; end
  m = lower(strtrim(modelo));
  if ~isempty(strfind(m, 'vogel'))
      op = 2;
  elseif ~isempty(strfind(m, 'fetkov'))
      op = 3;
  end
end

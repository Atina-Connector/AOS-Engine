function op = aos_opcion_modelo_vlp(modelo)
% Devuelve la opcion de menu correspondiente al nombre del modelo VLP.
  op = 1;
  if nargin < 1 || isempty(modelo), return; end
  m = lower(strtrim(modelo));
  if strcmp(m, 'hb') || ~isempty(strfind(m, 'hagedorn'))
      op = 2;
  elseif strcmp(m, 'dr') || ~isempty(strfind(m, 'duns'))
      op = 3;
  end
end

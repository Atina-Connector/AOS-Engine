function id = aosbck_id_seguro(texto, prefijo)
% AOSBCK_ID_SEGURO Normaliza identificadores persistentes.
  if nargin < 2 || isempty(prefijo), prefijo = 'BCK'; endif
  if nargin < 1 || isempty(texto), texto = datestr(now,'yyyymmddHHMMSS'); endif
  id = upper(char(texto));
  id = regexprep(id, '[^A-Z0-9]+', '-');
  id = regexprep(id, '^-+|-+$', '');
  if isempty(id), id = datestr(now,'yyyymmddHHMMSS'); endif
  if isempty(strfind(id, [upper(prefijo) '-'])) || ~strncmp(id,[upper(prefijo) '-'],numel(prefijo)+1)
    id = [upper(prefijo) '-' id];
  endif
endfunction

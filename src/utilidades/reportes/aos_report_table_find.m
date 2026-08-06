function [tabla, indice] = aos_report_table_find(tablas, id)
% AOS_REPORT_TABLE_FIND Busca una tabla por identificador.
  tabla = struct([]); indice = [];
  if ~isstruct(tablas) || ~ischar(id), return; endif
  ids = {};
  try, ids = {tablas.id}; catch, return; end_try_catch
  indice = find(strcmpi(ids,id),1);
  if ~isempty(indice), tabla = tablas(indice); endif
endfunction

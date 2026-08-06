function modo = aos_report_table_mode(tablas, id, defecto)
% AOS_REPORT_TABLE_MODE Devuelve el modo de renderizado de una tabla.
  if nargin<3||isempty(defecto),defecto='FULL_BODY';endif
  modo=upper(defecto);[t,~]=aos_report_table_find(tablas,id);
  if ~isempty(t)&&isfield(t,'render_mode')&&ischar(t.render_mode)&&~isempty(strtrim(t.render_mode))
    modo=upper(strtrim(t.render_mode));
  endif
endfunction

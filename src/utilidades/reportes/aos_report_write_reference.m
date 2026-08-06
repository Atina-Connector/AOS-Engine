function aos_report_write_reference(fid, seccion, tabla, estado)
% AOS_REPORT_WRITE_REFERENCE Escribe una seccion legacy compacta referida a tabla nativa.
  if nargin<4||isempty(estado),estado='DISPONIBLE';endif
  if ~isstruct(tabla),return;endif
  fprintf(fid,'\n[%s]\n',upper(regexprep(seccion,'[^A-Za-z0-9_-]+','_')));
  fprintf(fid,'estado=%s\n',clean_local(estado));
  fprintf(fid,'table_id=%s\n',clean_local(tabla.id));
  fprintf(fid,'table_title=%s\n',clean_local(tabla.title));
  fprintf(fid,'n_rows=%d\n',tabla.n_rows);
  fprintf(fid,'n_columns=%d\n',tabla.n_columns);
  fprintf(fid,'render_mode=%s\n',clean_local(tabla.render_mode));
  fprintf(fid,'datos_completos=TABLA_NATIVA_O_ARCHIVO_INTERNO\n');
endfunction
function s=clean_local(s),if ~ischar(s),s='';endif;s=regexprep(s,'[\r\n=]',' ');endfunction

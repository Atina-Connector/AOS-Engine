function aos_report_write_manifest(fid, info, composicion)
% AOS_REPORT_WRITE_MANIFEST Manifiesto coherente con la composicion real.
  if nargin<2||~isstruct(info),info=struct();endif
  if nargin<3||~isstruct(composicion),composicion=aos_report_composition_stats(struct([]),'TECHNICAL');endif
  id=txt_local(info,'report_id','reporte');tipo=txt_local(info,'report_type','GENERAL_REPORT');
  modulo=txt_local(info,'module','GENERAL');schema=txt_local(info,'viewer_schema','AOS_VIEWER_CONTEXT_1.0');
  workbench=txt_local(info,'workbench','AOS_SIM');ng=num_local(info,'graphics_count',0);
  fprintf(fid,'\n[REPORT_MANIFEST]\n');
  fprintf(fid,'schema=AOS_REPORT_MANIFEST_1.1\n');
  fprintf(fid,'report_id=%s\nrun_id=%s\n',clean_local(id),clean_local(id));
  fprintf(fid,'report_type=%s\n',clean_local(tipo));
  fprintf(fid,'generator=%s\n',clean_local(aos_version_actual()));
  fprintf(fid,'created_at=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
  fprintf(fid,'module=%s\nworkbench=%s\n',clean_local(modulo),clean_local(workbench));
  fprintf(fid,'viewer_schema=%s\nencoding=UTF-8\nidioma=es\nsistema_unidades=SI_METRICO\n',clean_local(schema));
  fprintf(fid,'tablas_embebidas=%d\n',composicion.table_count_available);
  fprintf(fid,'table_count=%d\n',composicion.table_count_available);
  fprintf(fid,'table_count_rendered=%d\n',composicion.table_count_rendered);
  fprintf(fid,'table_count_available=%d\n',composicion.table_count_available);
  fprintf(fid,'table_count_archived=%d\n',composicion.table_count_archived);
  fprintf(fid,'table_count_excluded=%d\n',composicion.table_count_excluded);
  fprintf(fid,'estimated_table_pages=%d\n',composicion.estimated_pages);
  fprintf(fid,'report_profile=%s\n',clean_local(composicion.profile));
  fprintf(fid,'embedded_graphics=%d\ngraphics_count=%d\n',ng,ng);
  fprintf(fid,'corrida_inmutable=1\n');
  fprintf(fid,'\n[REPORT_CAPABILITIES]\n');
  fprintf(fid,'schema=AOS_REPORT_CAPABILITIES_1.1\n');
  fprintf(fid,'native_tables=1\nsupports_native_tables=1\n');
  fprintf(fid,'table_schema=AOS_NATIVE_TABLE_1.1\n');
  fprintf(fid,'table_archive_schema=AOS_TABLE_ARCHIVE_1.0\n');
  fprintf(fid,'report_composition_schema=AOS_REPORT_COMPOSITION_1.0\n');
  fprintf(fid,'supports_table_profiles=1\nsupports_table_sampling=1\nsupports_viewer_only_tables=1\n');
  fprintf(fid,'executive_diagnosis=1\ndiagnostics_schema=AOS_EXECUTIVE_DIAGNOSIS_1.0\n');
  fprintf(fid,'supports_embedded_graphics=1\nviewer_empty_sections_compactable=1\n');
endfunction
function s=txt_local(x,c,d),s=d;if isfield(x,c)&&ischar(x.(c))&&!isempty(strtrim(x.(c))),s=strtrim(x.(c));endif,endfunction
function v=num_local(x,c,d),v=d;if isfield(x,c)&&isnumeric(x.(c))&&isscalar(x.(c))&&isfinite(x.(c)),v=round(x.(c));endif,endfunction
function s=clean_local(s),if ~ischar(s),s='';endif;s=regexprep(s,'[\r\n=]',' ');endfunction

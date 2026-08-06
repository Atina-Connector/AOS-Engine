function composicion = aos_rpt_escribir_tablas(fid, tablas, composicion)
% AOS_RPT_ESCRIBIR_TABLAS Contrato transversal de tablas HF3.5.
% Escribe tablas visibles, anexos y un archivo interno de datos completos.
% Las tablas VIEWER_ONLY quedan en TABLE_ARCHIVE_* y no ocupan paginas en
% visores que solo consumen TABLE_INDEX/TABLE_*.
  if nargin<2||isempty(tablas)
    if nargin<3||isempty(composicion),composicion=aos_report_composition_stats(struct([]),'TECHNICAL');endif
    escribir_composicion_local(fid,composicion,struct([]));
    return;
  endif
  if ~isstruct(tablas),error('tablas debe ser struct o vector de struct.');endif
  tablas=normalizar_arreglo_local(tablas);
  if nargin<3||~isstruct(composicion)||~isfield(composicion,'schema')
    [tablas,composicion]=aos_report_apply_profile(tablas,'TECHNICAL',struct());
  else
    % La estructura de tablas es la fuente de los modos; recalcular estadisticas.
    perfil='CUSTOM';if isfield(composicion,'profile'),perfil=composicion.profile;endif
    composicion=aos_report_composition_stats(tablas,perfil);
  endif

  escribir_composicion_local(fid,composicion,tablas);
  visibles=struct([]);archivos=struct([]);
  for i=1:numel(tablas)
    t=tablas(i);m=upper(t.render_mode);
    if strcmp(m,'FULL_BODY')||strcmp(m,'FULL_APPENDIX')
      v=t;
      if strcmp(m,'FULL_APPENDIX'),v.section=['ANEXO_' t.section];endif
      v.presentation=m;visibles=append_struct_local(visibles,v);
    elseif strcmp(m,'SUMMARY')
      v=aos_report_table_summary(t);v.presentation='SUMMARY';visibles=append_struct_local(visibles,v);
      if t.archive_full,archivos=append_struct_local(archivos,t);endif
    elseif strcmp(m,'SAMPLED')
      v=aos_report_table_sample(t,t.sample_step);v.presentation='SAMPLED';visibles=append_struct_local(visibles,v);
      if t.archive_full,archivos=append_struct_local(archivos,t);endif
    elseif strcmp(m,'VIEWER_ONLY') || strcmp(m,'EXCLUDED_EXPORT')
      % HF3.5: ocultar una tabla nunca elimina los datos tecnicos.
      archivos=append_struct_local(archivos,t);
    endif
  endfor

  escribir_indice_local(fid,visibles,'TABLE_INDEX','TABLE',true);
  for i=1:numel(visibles),escribir_tabla_local(fid,visibles(i),'TABLE',i,true);endfor

  escribir_indice_local(fid,archivos,'TABLE_ARCHIVE_INDEX','TABLE_ARCHIVE',false);
  for i=1:numel(archivos),escribir_tabla_local(fid,archivos(i),'TABLE_ARCHIVE',i,false);endfor
endfunction

function tablas=normalizar_arreglo_local(tablas)
  entrada=tablas(:)';tablas=struct([]);
  for i=1:numel(entrada)
    t=aos_report_table_normalize(entrada(i),i);
    tablas=append_struct_local(tablas,t);
  endfor
endfunction

function arr=append_struct_local(arr,x)
  if isempty(arr),arr=x;else,arr(end+1)=x;endif
endfunction

function escribir_composicion_local(fid,c,tablas)
  fprintf(fid,'\n[REPORT_COMPOSITION]\n');
  fprintf(fid,'schema=AOS_REPORT_COMPOSITION_1.0\n');
  fprintf(fid,'profile=%s\n',clean_local(valor_local(c,'profile','TECHNICAL')));
  fprintf(fid,'table_count_available=%d\n',num_local(c,'table_count_available',numel(tablas)));
  fprintf(fid,'table_count_rendered=%d\n',num_local(c,'table_count_rendered',0));
  fprintf(fid,'table_count_body=%d\n',num_local(c,'table_count_body',0));
  fprintf(fid,'table_count_appendix=%d\n',num_local(c,'table_count_appendix',0));
  fprintf(fid,'table_count_archived=%d\n',num_local(c,'table_count_archived',0));
  fprintf(fid,'table_count_excluded=%d\n',num_local(c,'table_count_excluded',0));
  fprintf(fid,'estimated_table_pages=%d\n',num_local(c,'estimated_pages',0));
  fprintf(fid,'full_data_policy=ALWAYS_PRESERVE\n');
  fprintf(fid,'archive_schema=AOS_TABLE_ARCHIVE_1.0\n');
  for i=1:numel(tablas)
    t=tablas(i);id=clean_id_local(t.id);
    fprintf(fid,'\n[TABLE_PRESENTATION_%s]\n',id);
    fprintf(fid,'schema=AOS_TABLE_PRESENTATION_1.0\n');
    fprintf(fid,'table_id=%s\n',id);
    fprintf(fid,'title=%s\n',clean_local(t.title));
    fprintf(fid,'category=%s\n',clean_local(t.category));
    fprintf(fid,'priority=%s\n',clean_local(t.priority));
    fprintf(fid,'render_mode=%s\n',clean_local(t.render_mode));
    fprintf(fid,'sample_step=%d\n',t.sample_step);
    fprintf(fid,'n_rows=%d\n',t.n_rows);
    fprintf(fid,'n_columns=%d\n',t.n_columns);
    fprintf(fid,'estimated_pages=%d\n',t.estimated_pages);
    fprintf(fid,'full_data_preserved=%d\n', ...
      1);
  endfor
endfunction

function escribir_indice_local(fid,tablas,seccion,prefijo,visible)
  fprintf(fid,'\n[%s]\n',seccion);
  if visible
    fprintf(fid,'schema=AOS_TABLE_INDEX_1.1\n');
  else
    fprintf(fid,'schema=AOS_TABLE_ARCHIVE_INDEX_1.0\n');
  endif
  fprintf(fid,'n_tables=%d\n',numel(tablas));
  fprintf(fid,'native_tables_embedded=%d\n',visible~=0);
  fprintf(fid,'table_data_encoding=UTF-8\n');
  fprintf(fid,'default_visible=%d\n',visible~=0);
  for i=1:numel(tablas)
    t=tablas(i);
    fprintf(fid,'table_%03d_id=%s\n',i,clean_id_local(t.id));
    fprintf(fid,'table_%03d_title=%s\n',i,clean_local(t.title));
    fprintf(fid,'table_%03d_section=%s\n',i,clean_local(t.section));
    fprintf(fid,'table_%03d_ref=%s_%03d\n',i,prefijo,i);
    fprintf(fid,'table_%03d_render_mode=%s\n',i,clean_local(valor_local(t,'presentation',t.render_mode)));
  endfor
endfunction

function escribir_tabla_local(fid,t,prefijo,idx,visible)
  fprintf(fid,'\n[%s_%03d]\n',prefijo,idx);
  fprintf(fid,'schema=%s\n',tern_local(visible,'AOS_NATIVE_TABLE_1.1','AOS_TABLE_ARCHIVE_1.0'));
  fprintf(fid,'table_id=%s\n',clean_id_local(t.id));
  fprintf(fid,'title=%s\n',clean_local(t.title));
  fprintf(fid,'section=%s\n',clean_local(t.section));
  fprintf(fid,'role=%s\n',clean_local(t.role));
  fprintf(fid,'source=%s\n',clean_local(t.source));
  fprintf(fid,'category=%s\n',clean_local(t.category));
  fprintf(fid,'priority=%s\n',clean_local(t.priority));
  fprintf(fid,'render_mode=%s\n',clean_local(valor_local(t,'presentation',t.render_mode)));
  fprintf(fid,'visible_default=%d\n',visible~=0);
  fprintf(fid,'render_preferred=TABLE_NATIVE\n');
  fprintf(fid,'embedded=1\npayload=INLINE_CSV\nencoding=UTF-8\n');
  fprintf(fid,'delimiter=,\ndecimal_separator=.\nmissing_value=NA\n');
  fprintf(fid,'missing_display=no disponible\nlocale=es-AR\nunit_system=SI_METRIC\n');
  fprintf(fid,'orientation=ROWS\nheader_row=1\nrow_key_column=1\nrepeat_header=1\n');
  fprintf(fid,'paginate=1\nwidth_policy=AUTO\nallow_sort=1\nallow_filter=1\ncopy_enabled=1\n');
  fprintf(fid,'n_rows=%d\nn_columns=%d\n',t.n_rows,t.n_columns);
  fprintf(fid,'columns=%s\n',join_txt_local(t.columns));
  fprintf(fid,'labels=%s\n',join_txt_local(t.labels));
  fprintf(fid,'units=%s\n',join_txt_local(t.units));
  fprintf(fid,'types=%s\n',join_txt_local(t.types));
  fprintf(fid,'precision=%s\n',join_num_local(t.precision));
  fprintf(fid,'data_begin=1\n');
  for r=1:t.n_rows
    vals=cell(1,t.n_columns);
    for c=1:t.n_columns,vals{c}=csv_local(t.rows{r,c});endfor
    fprintf(fid,'%s\n',strjoin(vals,','));
  endfor
  fprintf(fid,'data_end=1\n');
endfunction

function s=csv_local(v)
  if isnumeric(v)||islogical(v)
    if isempty(v)||~isscalar(v)||~isfinite(double(v)),s='NA';else,s=sprintf('%.12g',double(v));endif
  elseif ischar(v)
    x=strrep(regexprep(v,'[\r\n]',' '),'"','""');s=['"' x '"'];
  else
    if exist('aos_texto_seguro','file')==2
      [x,ok]=aos_texto_seguro(v,'');if ok,s=['"' strrep(x,'"','""') '"'];else,s='NA';endif
    else,s='NA';endif
  endif
endfunction
function s=join_txt_local(c),o=cell(1,numel(c));for i=1:numel(c),o{i}=strrep(clean_local(c{i}),',',';');endfor;s=strjoin(o,',');endfunction
function s=join_num_local(v),c=cell(1,numel(v));for i=1:numel(v),c{i}=sprintf('%d',round(v(i)));endfor;s=strjoin(c,',');endfunction
function s=clean_local(x),if ~ischar(x),x='';endif;s=regexprep(x,'[\r\n=]',' ');endfunction
function s=clean_id_local(x),s=regexprep(clean_local(x),'[^A-Za-z0-9_-]+','_');s=regexprep(s,'^_+|_+$','');if isempty(s),s='table';endif,endfunction
function v=valor_local(s,c,d),v=d;if isstruct(s)&&isfield(s,c)&&~isempty(s.(c)),v=s.(c);endif,endfunction
function v=num_local(s,c,d),v=d;if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&isscalar(s.(c))&&isfinite(s.(c)),v=round(s.(c));endif,endfunction
function s=tern_local(c,a,b),if c,s=a;else,s=b;endif,endfunction

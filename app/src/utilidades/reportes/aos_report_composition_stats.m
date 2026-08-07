function c = aos_report_composition_stats(tablas, perfil)
% AOS_REPORT_COMPOSITION_STATS Resume la seleccion de tablas del reporte.
% Ningun modo de presentacion borra datos: todas las tablas se conservan
% en TABLE_* o TABLE_ARCHIVE_* dentro del .aosrpt.

  if nargin < 2 || isempty(perfil), perfil = 'TECHNICAL'; endif
  c = struct();
  c.schema = 'AOS_REPORT_COMPOSITION_1.0';
  c.profile = upper(char(perfil));
  c.created_at = datestr(now(), 'yyyy-mm-dd HH:MM:SS');
  c.data_policy = 'ALWAYS_PRESERVE';
  c.table_count_available = numel(tablas);
  c.table_count_rendered = 0;
  c.table_count_archived = 0;
  c.table_count_excluded = 0;
  c.table_count_body = 0;
  c.table_count_appendix = 0;
  c.estimated_pages = 0;
  c.tables = struct('id',{},'title',{},'render_mode',{},'n_rows',{}, ...
    'n_columns',{},'estimated_pages',{},'sample_step',{}, ...
    'priority',{},'category',{},'full_data_preserved',{});

  for i = 1:numel(tablas)
    t = aos_report_table_normalize(tablas(i), i);
    m = upper(t.render_mode);
    render = any(strcmp(m, {'FULL_BODY','SUMMARY','SAMPLED','FULL_APPENDIX'}));
    archive = any(strcmp(m, {'SUMMARY','SAMPLED','VIEWER_ONLY','EXCLUDED_EXPORT'}));
    hidden = strcmp(m, 'EXCLUDED_EXPORT');

    if render, c.table_count_rendered += 1; endif
    if archive, c.table_count_archived += 1; endif
    if hidden, c.table_count_excluded += 1; endif
    if strcmp(m, 'FULL_APPENDIX')
      c.table_count_appendix += 1;
    elseif render
      c.table_count_body += 1;
    endif

    if any(strcmp(m, {'FULL_BODY','FULL_APPENDIX'}))
      c.estimated_pages += t.estimated_pages;
    elseif strcmp(m, 'SUMMARY')
      c.estimated_pages += min(2, max(1, ceil(t.n_columns / 6)));
    elseif strcmp(m, 'SAMPLED')
      nr = max(2, ceil(t.n_rows / max(1,t.sample_step)) + 2);
      tmp = t;
      tmp.n_rows = nr;
      c.estimated_pages += aos_report_estimar_paginas_tabla(tmp);
    endif

    x = struct('id',t.id,'title',t.title,'render_mode',m, ...
      'n_rows',t.n_rows,'n_columns',t.n_columns, ...
      'estimated_pages',t.estimated_pages,'sample_step',t.sample_step, ...
      'priority',t.priority,'category',t.category, ...
      'full_data_preserved',true);
    c.tables(end+1) = x;
  endfor
endfunction

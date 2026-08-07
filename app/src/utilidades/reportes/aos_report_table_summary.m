function s = aos_report_table_summary(t)
% AOS_REPORT_TABLE_SUMMARY Resume una tabla sin perder la tabla completa archivada.
  t=aos_report_table_normalize(t,1);
  rows={};
  for j=1:t.n_columns
    nombre=t.labels{j};unidad=t.units{j};tipo=t.types{j};
    col=t.rows(:,j);
    if strcmpi(tipo,'NUMBER')
      vals=[];
      for i=1:numel(col)
        v=col{i};if isnumeric(v)&&isscalar(v)&&isfinite(v),vals(end+1)=double(v);endif
      endfor
      if isempty(vals)
        rows(end+1,:)={nombre,'COUNT_VALID',0,unidad};
      else
        rows(end+1,:)={nombre,'COUNT_VALID',numel(vals),unidad};
        rows(end+1,:)={nombre,'MIN',min(vals),unidad};
        rows(end+1,:)={nombre,'MAX',max(vals),unidad};
        rows(end+1,:)={nombre,'MEAN',mean(vals),unidad};
        rows(end+1,:)={nombre,'FIRST',vals(1),unidad};
        rows(end+1,:)={nombre,'LAST',vals(end),unidad};
      endif
    else
      textos={};
      for i=1:numel(col)
        v=col{i};
        if ischar(v)&&~isempty(strtrim(v)),textos{end+1}=strtrim(v);endif
      endfor
      if isempty(textos)
        rows(end+1,:)={nombre,'COUNT_VALID',0,unidad};
      else
        rows(end+1,:)={nombre,'COUNT_VALID',numel(textos),unidad};
        rows(end+1,:)={nombre,'FIRST',textos{1},unidad};
        rows(end+1,:)={nombre,'LAST',textos{end},unidad};
        rows(end+1,:)={nombre,'UNIQUE_COUNT',numel(unique(textos)),unidad};
      endif
    endif
  endfor
  s=struct('id',t.id,'title',[t.title ' - resumen'],'section',t.section, ...
    'role','SUMMARY_TABLE','source',t.id,'category',t.category,'priority',t.priority, ...
    'columns',{{'column','statistic','value','unit'}}, ...
    'labels',{{'Columna','Estadistica','Valor','Unidad'}}, ...
    'units',{{'','','',''}},'types',{{'TEXT','TEXT','TEXT','TEXT'}}, ...
    'rows',{rows},'render_mode','FULL_BODY','default_mode','FULL_BODY', ...
    'archive_full',false,'mandatory',t.mandatory,'sample_step',t.sample_step);
  s=aos_report_table_normalize(s,1);
endfunction

function s = aos_report_table_sample(t, paso)
% AOS_REPORT_TABLE_SAMPLE Conserva extremos y una muestra regular trazable.
  t=aos_report_table_normalize(t,1);
  if nargin<2||isempty(paso),paso=t.sample_step;endif
  paso=max(1,round(paso));n=t.n_rows;
  if n==0,s=t;return;endif
  idx=[1:paso:n,n];
  for j=1:t.n_columns
    vals=nan(n,1);ok=false(n,1);
    for i=1:n
      v=t.rows{i,j};
      if isnumeric(v)&&isscalar(v)&&isfinite(v),vals(i)=double(v);ok(i)=true;endif
    endfor
    if any(ok)
      valid=find(ok);[~,a]=min(vals(ok));[~,b]=max(vals(ok));
      idx=[idx,valid(a),valid(b)];
    endif
  endfor
  idx=unique(idx);idx=idx(idx>=1&idx<=n);
  rows=cell(numel(idx),t.n_columns+1);
  for k=1:numel(idx)
    rows{k,1}=idx(k);
    rows(k,2:end)=t.rows(idx(k),:);
  endfor
  s=t;
  s.title=sprintf('%s - muestra cada %d filas',t.title,paso);
  s.columns=[{'source_row'},t.columns];
  s.labels=[{'Fila original'},t.labels];
  s.units=[{''},t.units];
  s.types=[{'NUMBER'},t.types];
  s.precision=[0,t.precision];
  s.rows=rows;
  s.render_mode='FULL_BODY';
  s.archive_full=false;
  s.sample_step=paso;
  s=aos_report_table_normalize(s,1);
endfunction

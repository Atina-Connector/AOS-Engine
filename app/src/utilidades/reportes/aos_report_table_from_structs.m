function t = aos_report_table_from_structs(id,title,section,filas,campos,labels,units,varargin)
% AOS_REPORT_TABLE_FROM_STRUCTS Convierte vector/celda de estructuras a tabla.
  if nargin<5,error('Faltan argumentos.');endif
  if nargin<6||isempty(labels),labels=campos;endif
  if nargin<7||isempty(units),units=repmat({''},1,numel(campos));endif
  if iscell(filas), n=numel(filas); else, n=numel(filas); endif
  rows=cell(n,numel(campos));
  for i=1:n
    if iscell(filas), s=filas{i}; else, s=filas(i); endif
    for j=1:numel(campos)
      if isstruct(s) && isfield(s,campos{j})
        rows{i,j}=s.(campos{j});
      else
        rows{i,j}='';
      endif
    endfor
  endfor
  t=struct('id',id,'title',title,'section',section,'columns',{campos(:)'}, ...
    'labels',{labels(:)'},'units',{units(:)'},'rows',{rows}, ...
    'role','RESULT_TABLE','source','AOS_CALCULATION','category','RESULTS', ...
    'priority','SECONDARY','render_mode','','default_mode','','sample_step',10, ...
    'archive_full',true,'mandatory',false);
  if mod(numel(varargin),2)~=0,error('Opciones nombre/valor invalidas.');endif
  for k=1:2:numel(varargin),t.(varargin{k})=varargin{k+1};endfor
  t=aos_report_table_normalize(t,1);
endfunction

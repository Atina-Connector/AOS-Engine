function modelo = aos_aoscad_report_composition(modelo, silencioso)
% AOS_AOSCAD_REPORT_COMPOSITION Inventario de tablas sin duplicar datos JSON.
  if nargin<2,silencioso=false;endif
  tablas=struct([]);
  grupos={'tablas_entrada','tablas_resultados'};
  for g=1:numel(grupos)
    gn=grupos{g};if ~isfield(modelo,gn)||~isstruct(modelo.(gn)),continue;endif
    f=fieldnames(modelo.(gn));
    for i=1:numel(f)
      v=modelo.(gn).(f{i});[rows,cols]=shape_local(v);
      if rows<=0,continue;endif
      cat='RESULTS';pri='SECONDARY';role='RESULT_TABLE';
      if strcmp(gn,'tablas_entrada'),cat='INPUTS';role='INPUT_TABLE';endif
      if any(strcmpi(f{i},{'nodos','tramos','condiciones_borde','resultados_nodales','resultados_tramos'})),pri='PRIMARY';endif
      dummy=cell(rows,cols);names=columns_local(v,cols);
      t=struct('id',['aoscad_' gn '_' f{i}],'title',strrep([gn ' - ' f{i}],'_',' '), ...
        'section','AOSCAD','role',role,'source',['AOSCAD.' gn '.' f{i}], ...
        'category',cat,'priority',pri,'columns',{names},'labels',{names}, ...
        'units',{repmat({''},1,cols)},'rows',{dummy},'archive_full',true);
      if rows>150,t.default_mode='VIEWER_ONLY';elseif rows>40,t.default_mode='FULL_APPENDIX';else,t.default_mode='FULL_BODY';endif
      tablas=aos_report_append_tables(tablas,t);
    endfor
  endfor
  opt=struct('no_interactivo',logical(silencioso),'profile','TECHNICAL');
  [tablas,comp]=aos_report_configure_tables(tablas,opt);
  % En AOSCAD los datos siempre permanecen en tablas_entrada/resultados.
  comp.data_policy='ALWAYS_PRESERVED_IN_AOSCAD_JSON';
  comp.table_presentation=comp.tables;
  if isfield(comp,'tables'),comp=rmfield(comp,'tables');endif
  modelo.report_composition=comp;
endfunction
function [r,c]=shape_local(v)
  r=0;c=0;
  if isstruct(v)&&~isempty(v),r=numel(v);c=max(1,numel(fieldnames(v(1))));
  elseif isnumeric(v)||islogical(v)||iscell(v),r=size(v,1);c=size(v,2);if isvector(v),r=numel(v);c=1;endif
  endif
endfunction
function n=columns_local(v,c)
  if isstruct(v)&&~isempty(v),n=fieldnames(v(1))';else,n=cell(1,c);for i=1:c,n{i}=sprintf('col_%03d',i);endfor,endif
endfunction

function t = aos_report_table_normalize(t, indice)
% AOS_REPORT_TABLE_NORMALIZE Normaliza una tabla al contrato transversal HF3.5.
  if nargin < 2 || isempty(indice), indice = 1; endif
  if ~isstruct(t), error('La tabla debe ser una estructura.'); endif

  t.id = texto_local(t, 'id', sprintf('table_%03d', indice));
  t.id = limpiar_id_local(t.id);
  t.title = texto_local(t, 'title', t.id);
  t.section = texto_local(t, 'section', 'RESULTADOS');
  t.role = upper(texto_local(t, 'role', 'RESULT_TABLE'));
  t.source = texto_local(t, 'source', 'AOS_CALCULATION');
  t.category = upper(texto_local(t, 'category', categoria_local(t.role)));
  t.priority = upper(texto_local(t, 'priority', prioridad_local(t.role, t.category)));
  t.render_mode = upper(texto_local(t, 'render_mode', ''));
  t.default_mode = upper(texto_local(t, 'default_mode', ''));
  t.description = texto_local(t, 'description', '');
  t.archive_full = logico_local(t, 'archive_full', true);
  t.mandatory = logico_local(t, 'mandatory', false);
  t.sample_step = max(1, round(numero_local(t, 'sample_step', 10)));

  if ~isfield(t, 'rows') || ~iscell(t.rows)
    t.rows = cell(0, 0);
  endif
  if isvector(t.rows) && ~isempty(t.rows) && size(t.rows,1) == 1
    % Mantener una fila; no convertir automaticamente a columna.
  endif
  nc = size(t.rows, 2);
  if isfield(t, 'columns') && iscell(t.columns)
    t.columns = t.columns(:)';
  else
    t.columns = generar_local('col', nc);
  endif
  nc = numel(t.columns);
  if size(t.rows,2) ~= nc
    if isempty(t.rows)
      t.rows = cell(0,nc);
    else
      error('La tabla %s tiene %d columnas de datos y %d nombres.', ...
        t.id, size(t.rows,2), nc);
    endif
  endif
  if isfield(t,'labels') && iscell(t.labels) && numel(t.labels)==nc
    t.labels=t.labels(:)';
  else
    t.labels=t.columns;
  endif
  if isfield(t,'units') && iscell(t.units) && numel(t.units)==nc
    t.units=t.units(:)';
  else
    t.units=repmat({''},1,nc);
  endif
  if isfield(t,'types') && iscell(t.types) && numel(t.types)==nc
    t.types=t.types(:)';
  else
    t.types=inferir_tipos_local(t.rows,nc);
  endif
  if isfield(t,'precision') && isnumeric(t.precision) && numel(t.precision)==nc
    t.precision=round(t.precision(:)');
  else
    t.precision=precision_local(t.units,t.types);
  endif

  t.n_rows = size(t.rows,1);
  t.n_columns = nc;
  t.estimated_pages = aos_report_estimar_paginas_tabla(t);

  % Contrato canonico: todas las tablas normalizadas comparten exactamente
  % los mismos campos para poder formar vectores de struct sin conflictos.
  metadata = struct();
  if isfield(t,'metadata') && isstruct(t.metadata), metadata = t.metadata; endif
  t = struct('id',t.id,'title',t.title,'section',t.section, ...
    'role',t.role,'source',t.source,'category',t.category, ...
    'priority',t.priority,'render_mode',t.render_mode, ...
    'default_mode',t.default_mode,'description',t.description, ...
    'archive_full',t.archive_full,'mandatory',t.mandatory, ...
    'sample_step',t.sample_step,'columns',{t.columns}, ...
    'labels',{t.labels},'units',{t.units},'types',{t.types}, ...
    'precision',t.precision,'rows',{t.rows},'n_rows',t.n_rows, ...
    'n_columns',t.n_columns,'estimated_pages',t.estimated_pages, ...
    'metadata',metadata);
endfunction

function s = texto_local(x, campo, defecto)
  s = defecto;
  if isfield(x,campo)
    if exist('aos_texto_seguro','file') == 2
      [v, ok] = aos_texto_seguro(x.(campo), defecto);
      if ok && ischar(v), s = strtrim(v); endif
    elseif ischar(x.(campo))
      s = strtrim(x.(campo));
    endif
  endif
  if isempty(s), s = defecto; endif
endfunction

function v = numero_local(x,campo,defecto)
  v=defecto;
  if isfield(x,campo)
    y=x.(campo);
    if isnumeric(y) && isscalar(y) && isfinite(y), v=double(y); endif
  endif
endfunction

function tf = logico_local(x,campo,defecto)
  tf=defecto;
  if isfield(x,campo)
    y=x.(campo);
    if islogical(y) && isscalar(y), tf=logical(y);
    elseif isnumeric(y) && isscalar(y) && isfinite(y), tf=(y~=0);
    elseif ischar(y), tf=any(strcmpi(strtrim(y),{'1','s','si','true','yes','y'})); endif
  endif
endfunction

function s = limpiar_id_local(s)
  if ~ischar(s), s='table'; endif
  s=regexprep(s,'[^A-Za-z0-9_-]+','_');
  s=regexprep(s,'^_+|_+$','');
  if isempty(s),s='table';endif
endfunction

function c=generar_local(pref,n)
  c=cell(1,n);
  for i=1:n,c{i}=sprintf('%s_%03d',pref,i);endfor
endfunction

function tipos=inferir_tipos_local(rows,nc)
  tipos=repmat({'TEXT'},1,nc);
  for j=1:nc
    ok=true;hay=false;
    for i=1:size(rows,1)
      v=rows{i,j};
      if isempty(v),continue;endif
      hay=true;
      if ~((isnumeric(v)||islogical(v))&&isscalar(v)),ok=false;break;endif
    endfor
    if hay&&ok,tipos{j}='NUMBER';endif
  endfor
endfunction

function p=precision_local(u,t)
  p=zeros(1,numel(u));
  for i=1:numel(u)
    if strcmpi(t{i},'NUMBER')
      x=lower(strtrim(u{i}));
      if any(strcmp(x,{'%','bar','m3/d','sm3/d','kw','c','a','kn','kn.m'}))
        p(i)=2;
      elseif any(strcmp(x,{'hz','m','s','m/s'}))
        p(i)=3;
      else
        p(i)=6;
      endif
    endif
  endfor
endfunction

function c=categoria_local(role)
  if ~isempty(strfind(upper(role),'SENS')), c='SENSITIVITY';
  elseif ~isempty(strfind(upper(role),'PROFILE')), c='PROFILE';
  elseif ~isempty(strfind(upper(role),'TIME')), c='TIME_SERIES';
  elseif ~isempty(strfind(upper(role),'CATALOG')), c='CATALOG';
  else, c='RESULTS'; endif
endfunction

function p=prioridad_local(role,cat)
  if any(strcmpi(cat,{'SENSITIVITY'})) || any(strcmpi(role,{'PRIMARY_RESULT','SUMMARY_TABLE'}))
    p='PRIMARY';
  elseif any(strcmpi(cat,{'TIME_SERIES','PROFILE'}))
    p='DETAIL';
  else
    p='SECONDARY';
  endif
endfunction

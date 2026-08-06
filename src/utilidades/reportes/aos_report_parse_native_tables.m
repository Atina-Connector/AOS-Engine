function [visibles, archivadas, info] = aos_report_parse_native_tables(fuente)
% AOS_REPORT_PARSE_NATIVE_TABLES Lee TABLE_* y TABLE_ARCHIVE_* de un .aosrpt.
% Acepta una ruta o un cell array de lineas. No ejecuta expresiones.

  visibles = struct([]);
  archivadas = struct([]);
  info = struct('schema','AOS_NATIVE_TABLE_READER_1.0', ...
    'n_visibles',0,'n_archivadas',0,'n_total',0);

  lineas = lineas_local(fuente);
  if isempty(lineas), return; endif

  i = 1;
  while i <= numel(lineas)
    ln = strtrim(lineas{i});
    tok = regexp(ln, '^\[(TABLE|TABLE_ARCHIVE)_([0-9]+)\]$', 'tokens', 'once');
    if isempty(tok)
      i += 1;
      continue;
    endif

    es_archivo = strcmp(tok{1}, 'TABLE_ARCHIVE');
    meta = struct();
    data_lines = {};
    leyendo = false;
    i += 1;
    while i <= numel(lineas)
      raw = lineas{i};
      t = strtrim(raw);
      if ~isempty(t) && t(1) == '['
        break;
      endif
      if strcmpi(t, 'data_begin=1')
        leyendo = true;
      elseif strcmpi(t, 'data_end=1')
        leyendo = false;
      elseif leyendo
        if ~isempty(t), data_lines{end+1} = raw; endif
      elseif ~isempty(t) && t(1) ~= '#'
        k = find(t == '=', 1);
        if ~isempty(k)
          clave = limpiar_campo_local(strtrim(t(1:k-1)));
          if ~isempty(clave), meta.(clave) = strtrim(t(k+1:end)); endif
        endif
      endif
      i += 1;
    endwhile

    tabla = tabla_local(meta, data_lines, es_archivo);
    if es_archivo
      archivadas = append_local(archivadas, tabla);
    else
      visibles = append_local(visibles, tabla);
    endif
  endwhile

  info.n_visibles = numel(visibles);
  info.n_archivadas = numel(archivadas);
  info.n_total = info.n_visibles + info.n_archivadas;
endfunction

function lineas = lineas_local(fuente)
  lineas = {};
  if iscell(fuente)
    lineas = fuente(:)';
    return;
  endif
  if ~ischar(fuente) || exist(fuente,'file') ~= 2, return; endif
  fid = fopen(fuente,'rt');
  if fid < 0, return; endif
  unwind_protect
    while ~feof(fid), lineas{end+1} = fgetl(fid); endwhile
  unwind_protect_cleanup
    fclose(fid);
  end_unwind_protect
endfunction

function tabla = tabla_local(meta, data_lines, archivada)
  columnas = lista_local(valor_local(meta,'columns',''));
  labels = lista_local(valor_local(meta,'labels',''));
  units = lista_local(valor_local(meta,'units',''));
  types = lista_local(valor_local(meta,'types',''));
  precision = numeros_local(valor_local(meta,'precision',''));
  nc = max([numel(columnas), numel(labels), numel(units), numel(types), 0]);
  if nc == 0 && ~isempty(data_lines), nc = numel(csv_local(data_lines{1})); endif
  if isempty(columnas), columnas = nombres_local('col',nc); endif
  if numel(labels) ~= nc, labels = columnas; endif
  if numel(units) ~= nc, units = repmat({''},1,nc); endif
  if numel(types) ~= nc, types = repmat({'TEXT'},1,nc); endif
  if numel(precision) ~= nc, precision = zeros(1,nc); endif

  rows = cell(numel(data_lines),nc);
  for r = 1:numel(data_lines)
    vals = csv_local(data_lines{r});
    for c = 1:nc
      raw = '';
      if c <= numel(vals), raw = vals{c}; endif
      rows{r,c} = valor_celda_local(raw, types{c});
    endfor
  endfor

  tabla = struct('id',valor_local(meta,'table_id','table'), ...
    'title',valor_local(meta,'title','Tabla'), ...
    'section',valor_local(meta,'section','RESULTADOS'), ...
    'role',valor_local(meta,'role','RESULT_TABLE'), ...
    'source',valor_local(meta,'source','AOSRPT'), ...
    'category',valor_local(meta,'category','RESULTS'), ...
    'priority',valor_local(meta,'priority','SECONDARY'), ...
    'render_mode',valor_local(meta,'render_mode',tern_local(archivada,'VIEWER_ONLY','FULL_BODY')), ...
    'columns',{columnas},'labels',{labels},'units',{units},'types',{types}, ...
    'precision',precision,'rows',{rows},'archive_full',true, ...
    'mandatory',false,'sample_step',10,'archived',logical(archivada));
  tabla = aos_report_table_normalize(tabla,1);
  tabla.archived = logical(archivada);
endfunction

function v = valor_celda_local(raw, tipo)
  if strcmpi(strtrim(raw),'NA') || isempty(strtrim(raw)), v = NaN; return; endif
  if strcmpi(tipo,'NUMBER')
    [x,ok] = aos_numero_seguro(strtrim(raw),NaN);
    if ok, v = x; else, v = NaN; endif
  else
    v = descomillar_local(raw);
  endif
endfunction

function vals = csv_local(linea)
  vals = {}; actual = ''; entre = false; i = 1;
  while i <= numel(linea)
    ch = linea(i);
    if ch == '"'
      if entre && i < numel(linea) && linea(i+1) == '"'
        actual(end+1) = '"'; i += 2; continue;
      endif
      entre = ~entre;
    elseif ch == ',' && ~entre
      vals{end+1} = actual; actual = '';
    else
      actual(end+1) = ch;
    endif
    i += 1;
  endwhile
  vals{end+1} = actual;
endfunction

function s = descomillar_local(s)
  s = strtrim(s);
  if numel(s) >= 2 && s(1) == '"' && s(end) == '"', s = s(2:end-1); endif
  s = strrep(s,'""','"');
endfunction
function c = lista_local(s), if isempty(s),c={};else,c=csv_local(s);for i=1:numel(c),c{i}=descomillar_local(c{i});endfor,endif,endfunction
function v = numeros_local(s), [v,ok]=aos_vector_seguro(s,[]);if ~ok,v=[];endif,v=v(:)';endfunction
function s = valor_local(x,c,d),s=d;if isstruct(x)&&isfield(x,c)&&ischar(x.(c)),s=x.(c);endif,endfunction
function f = limpiar_campo_local(s),f=regexprep(s,'[^A-Za-z0-9_]','_');if isempty(f)||~isletter(f(1)),f=['f_' f];endif,endfunction
function a = append_local(a,x),if isempty(a),a=x;else,a(end+1)=x;endif,endfunction
function c = nombres_local(p,n),c=cell(1,n);for i=1:n,c{i}=sprintf('%s_%03d',p,i);endfor,endfunction
function s = tern_local(tf,a,b),if tf,s=a;else,s=b;endif,endfunction

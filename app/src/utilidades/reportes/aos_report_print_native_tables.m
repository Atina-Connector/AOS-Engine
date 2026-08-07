function info = aos_report_print_native_tables(fuente)
% AOS_REPORT_PRINT_NATIVE_TABLES Muestra tablas visibles y lista el archivo interno.
  [visibles, archivadas, info] = aos_report_parse_native_tables(fuente);
  if info.n_total == 0, return; endif

  fprintf('\n=== TABLAS NATIVAS DEL REPORTE ===\n');
  fprintf('Visibles: %d | Solo datos/Viewer: %d | Total preservadas: %d\n', ...
    info.n_visibles, info.n_archivadas, info.n_total);
  for i = 1:numel(visibles)
    t = visibles(i);
    fprintf('\n[%d] %s (%d x %d) [%s]\n',i,t.title,t.n_rows,t.n_columns,t.render_mode);
    mostrar_local(t);
  endfor
  if ~isempty(archivadas)
    fprintf('\nTablas completas preservadas fuera de la salida visible:\n');
    for i=1:numel(archivadas)
      fprintf('  - %s: %d filas x %d columnas [%s]\n', ...
        archivadas(i).title,archivadas(i).n_rows,archivadas(i).n_columns,archivadas(i).render_mode);
    endfor
  endif
endfunction

function mostrar_local(t)
  es_sens = strcmpi(t.category,'SENSITIVITY') || ~isempty(strfind(upper(t.role),'SENS'));
  limite = 20;
  if es_sens, limite = 200; endif
  n = min(t.n_rows,limite);
  if t.n_columns == 0, return; endif
  fprintf('  %s\n',strjoin(t.labels,' | '));
  for r=1:n
    c=cell(1,t.n_columns);
    for j=1:t.n_columns,c{j}=celda_local(t.rows{r,j});endfor
    fprintf('  %s\n',strjoin(c,' | '));
  endfor
  if t.n_rows>n
    fprintf('  ... %d filas adicionales preservadas en el .aosrpt.\n',t.n_rows-n);
  endif
endfunction
function s=celda_local(v)
  if isnumeric(v)||islogical(v)
    if isempty(v)||~isscalar(v)||~isfinite(double(v)),s='NA';else,s=sprintf('%.8g',double(v));endif
  elseif ischar(v),s=regexprep(v,'[\r\n|]',' ');
  else,[s,ok]=aos_texto_seguro(v,'NA');if ~ok,s='NA';endif,endif
endfunction

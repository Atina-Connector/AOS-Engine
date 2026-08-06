function [tablas, composicion] = aos_report_configure_tables(tablas, opciones)
% AOS_REPORT_CONFIGURE_TABLES Seleccion transversal de tablas del informe.
% Opciones: no_interactivo, profile, overrides, prompt_each, title.

  if nargin < 2 || ~isstruct(opciones), opciones = struct(); endif
  entrada = tablas(:)';
  if isempty(entrada)
    tablas = struct([]);
    composicion = aos_report_composition_stats(tablas, 'TECHNICAL');
    return;
  endif

  tablas = struct([]);
  for i = 1:numel(entrada)
    t = aos_report_table_normalize(entrada(i), i);
    tablas = append_local(tablas, t);
  endfor

  no_interactivo = logico_local(opciones, 'no_interactivo', false);
  perfil = upper(texto_local(opciones, 'profile', ''));
  overrides = struct();
  if isfield(opciones,'overrides') && isstruct(opciones.overrides)
    overrides = opciones.overrides;
  endif
  revisar_todas = logico_local(opciones, 'prompt_each', false);

  if no_interactivo
    if isempty(perfil), perfil = 'TECHNICAL'; endif
    [tablas, composicion] = aos_report_apply_profile(tablas, perfil, overrides);
    return;
  endif

  fprintf('\n====================================================\n');
  fprintf(' COMPOSICION TRANSVERSAL DE TABLAS DEL REPORTE\n');
  fprintf('====================================================\n');
  fprintf('La simulacion conserva todos los datos. Esta seleccion solo controla\n');
  fprintf('que tablas se muestran en el cuerpo, anexo o quedan ocultas.\n\n');
  imprimir_inventario_local(tablas);
  fprintf('\n 1 - Ejecutivo\n');
  fprintf(' 2 - Tecnico\n');
  fprintf(' 3 - Auditoria completa\n');
  fprintf(' 4 - Personalizado: decidir tabla por tabla\n');
  op = input('Perfil [2]: ');
  if isempty(op), op = 2; endif
  if ~isnumeric(op) || ~isscalar(op) || ~isfinite(op) || ~any(round(op) == [1 2 3 4])
    op = 2;
  endif
  perfiles = {'EXECUTIVE','TECHNICAL','AUDIT','CUSTOM'};
  perfil = perfiles{round(op)};
  [tablas, composicion] = aos_report_apply_profile(tablas, perfil, overrides);

  if ~strcmp(perfil,'CUSTOM') && ~revisar_todas
    fprintf('\nPropuesta del perfil %s:\n', perfil);
    imprimir_seleccion_local(tablas);
    fprintf('\n 1 - Aceptar esta composicion\n');
    fprintf(' 2 - Revisar tabla por tabla\n');
    r = input('Seleccione [1]: ');
    if isempty(r), r = 1; endif
    revisar_todas = isnumeric(r) && isscalar(r) && isfinite(r) && round(r) == 2;
  else
    revisar_todas = true;
  endif

  if revisar_todas
    for i = 1:numel(tablas)
      tablas(i) = preguntar_tabla_local(tablas(i), i, numel(tablas));
    endfor
    perfil = 'CUSTOM';
    composicion = aos_report_composition_stats(tablas, perfil);
  endif

  fprintf('\n--- RESUMEN DE COMPOSICION ---\n');
  fprintf('Tablas disponibles          : %d\n', composicion.table_count_available);
  fprintf('Tablas visibles             : %d\n', composicion.table_count_rendered);
  fprintf('Tablas completas archivadas : %d\n', composicion.table_count_archived);
  fprintf('Tablas ocultas de la salida : %d\n', composicion.table_count_excluded);
  fprintf('Paginas estimadas de tablas : %d\n', composicion.estimated_pages);
  fprintf('Politica de datos            : TODOS LOS DATOS PRESERVADOS\n');
endfunction

function imprimir_inventario_local(tablas)
  fprintf(' ID  Tabla                                      Filas Cols Pag  Prioridad\n');
  for i = 1:numel(tablas)
    t = tablas(i);
    titulo = t.title;
    if numel(titulo) > 40, titulo = [titulo(1:37) '...']; endif
    fprintf('%3d  %-40s %5d %4d %3d  %s\n', i, titulo, ...
      t.n_rows, t.n_columns, t.estimated_pages, t.priority);
  endfor
endfunction

function imprimir_seleccion_local(tablas)
  for i = 1:numel(tablas)
    fprintf(' %2d - %-38s -> %s\n', i, tablas(i).title, tablas(i).render_mode);
  endfor
endfunction

function t = preguntar_tabla_local(t, indice, total)
  fprintf('\nTabla %d/%d - %s\n', indice, total, t.title);
  fprintf('ID: %s | %d filas x %d columnas | %d pagina(s) estimada(s)\n', ...
    t.id, t.n_rows, t.n_columns, t.estimated_pages);
  if t.mandatory
    fprintf('Clasificacion: RESULTADO PRIMARIO (inclusion completa recomendada).\n');
  endif
  fprintf(' 1 - Incluir completa en el cuerpo\n');
  fprintf(' 2 - Incluir resumen; conservar tabla completa\n');
  fprintf(' 3 - Incluir muestra cada N filas; conservar tabla completa\n');
  fprintf(' 4 - Incluir completa como anexo\n');
  fprintf(' 5 - Conservar completa solo para datos/Viewer\n');
  fprintf(' 0 - No mostrar en esta exportacion; conservar datos\n');
  defecto = modo_a_op_local(t.render_mode);
  op = input(sprintf('Seleccione [%d]: ', defecto));
  if isempty(op), op = defecto; endif
  if ~isnumeric(op) || ~isscalar(op) || ~isfinite(op) || ~any(round(op) == [0 1 2 3 4 5])
    op = defecto;
  endif
  modos = {'EXCLUDED_EXPORT','FULL_BODY','SUMMARY','SAMPLED','FULL_APPENDIX','VIEWER_ONLY'};
  t.render_mode = modos{round(op)+1};
  if strcmp(t.render_mode,'SAMPLED')
    paso = input(sprintf('Una fila cada N [%d]: ', t.sample_step));
    if ~isempty(paso) && isnumeric(paso) && isscalar(paso) && isfinite(paso) && paso >= 1
      t.sample_step = round(paso);
    endif
  endif
endfunction

function op = modo_a_op_local(modo)
  modo = upper(modo);
  mapa = struct('FULL_BODY',1,'SUMMARY',2,'SAMPLED',3, ...
    'FULL_APPENDIX',4,'VIEWER_ONLY',5,'EXCLUDED_EXPORT',0);
  if isfield(mapa,modo), op = mapa.(modo); else, op = 1; endif
endfunction

function s = texto_local(x,campo,defecto)
  s = defecto;
  if isfield(x,campo) && ischar(x.(campo)) && ~isempty(strtrim(x.(campo)))
    s = strtrim(x.(campo));
  endif
endfunction

function tf = logico_local(x,campo,defecto)
  tf = defecto;
  if isfield(x,campo)
    y = x.(campo);
    if islogical(y) && isscalar(y)
      tf = y;
    elseif isnumeric(y) && isscalar(y) && isfinite(y)
      tf = y ~= 0;
    endif
  endif
endfunction

function arr = append_local(arr, x)
  if isempty(arr), arr = x; else, arr(end+1) = x; endif
endfunction

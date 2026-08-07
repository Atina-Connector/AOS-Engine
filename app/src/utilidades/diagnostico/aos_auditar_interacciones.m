function reporte = aos_auditar_interacciones(raiz, imprimir)
% AOS_AUDITAR_INTERACCIONES Revisa patrones de interfaz y conversion.
% Detecta preguntas binarias ambiguas, defaults ausentes, conversiones que
% evalúan texto y tests que retiran su propio path. No ejecuta solvers.

  if nargin < 1 || isempty(raiz)
    raiz = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
  endif
  if nargin < 2, imprimir = true; endif
  [raiz, ok_raiz] = aos_texto_seguro(raiz, '');
  if ~ok_raiz || exist(fullfile(raiz, 'src'), 'dir') ~= 7
    error('Auditoria AOS: raiz invalida.');
  endif

  archivos = listar_m_local(fullfile(raiz, 'src'));
  hallazgos = struct('severidad', {}, 'codigo', {}, 'archivo', {}, ...
    'linea', {}, 'mensaje', {});
  conteo_preguntas = 0;
  conteo_binarias_directas = 0;

  for i = 1:numel(archivos)
    ruta = archivos{i};
    rel = relativa_local(ruta, raiz);
    rel_low = lower(strrep(rel, '\\', '/'));
    if ~isempty(strfind(rel_low, '/legacy/')) || ...
       ~isempty(strfind(rel_low, '/historial/'))
      continue;
    endif

    texto = fileread(ruta);
    lineas = strsplit(texto, sprintf('\n'));
    es_test = ~isempty(regexp(lower(fileparts_y_nombre_local(rel)), ...
      '(^|/)test_[^/]*\.m$', 'once'));

    for n = 1:numel(lineas)
      linea = lineas{n};
      low = lower(linea);
      if ~isempty(strfind(low, 'input(')) || ...
         ~isempty(strfind(low, 'aos_preguntar_sn'))
        conteo_preguntas = conteo_preguntas + 1;
      endif

      if ~isempty(regexp(low, 'str2num\s*\(', 'once'))
        hallazgos = agregar_local(hallazgos, 'ERROR', 'CONVERSION_EVAL', ...
          rel, n, 'Uso activo de str2num; reemplazar por parser seguro.');
      endif

      if ~isempty(strfind(low, '(s/n)')) && ...
         ~isempty(strfind(low, 'input(')) && ...
         isempty(strfind(low, 'aos_preguntar_sn'))
        conteo_binarias_directas = conteo_binarias_directas + 1;
        hallazgos = agregar_local(hallazgos, 'ERROR', 'BINARIA_DIRECTA_NO_UNIFORME', ...
          rel, n, 'Usar aos_preguntar_sn para validar respuestas y defaults.');
      endif

      if ~isempty(regexp(low, '\(s/n\)\s*:\s*', 'once')) && ...
         isempty(strfind(low, '[s]')) && isempty(strfind(low, '[n]')) && ...
         isempty(strfind(low, '[%s]'))
        hallazgos = agregar_local(hallazgos, 'ERROR', 'BINARIA_SIN_DEFAULT', ...
          rel, n, 'Pregunta s/n sin valor predeterminado visible.');
      endif

      if ~isempty(strfind(low, '(s/n)')) && ...
         ( ~isempty(strfind(low, 'reemplazar o editar')) || ...
           ~isempty(strfind(low, 'editar o reemplazar')) || ...
           ~isempty(strfind(low, 'fusionar o reemplazar')) || ...
           ~isempty(strfind(low, 'reemplazar o fusionar')) )
        hallazgos = agregar_local(hallazgos, 'ERROR', 'BINARIA_MULTIACCION', ...
          rel, n, 'Una pregunta s/n no puede representar varias acciones validas.');
      endif

      if ~isempty(regexp(low, 'if\s+~ischar\([^\)]*\).*num2str', 'once'))
        hallazgos = agregar_local(hallazgos, 'ERROR', 'TEXTO_NO_SEGURO', ...
          rel, n, 'Conversion generica num2str sobre tipo desconocido.');
      endif

      if es_test && ~isempty(regexp(low, ...
          'iniciar_aos\s*(;|\(\s*\)\s*;)', 'once'))
        hallazgos = agregar_local(hallazgos, 'ERROR', 'TEST_RETIRA_PATH', ...
          rel, n, 'El selftest debe usar iniciar_aos(true).');
      endif

      if ~isempty(strfind(low, '[s]')) && ...
         ( ~isempty(strfind(low, 'eliminar')) || ...
           ~isempty(strfind(low, 'borrar')) || ...
           ~isempty(strfind(low, 'descartar')) || ...
           ~isempty(strfind(low, 'reemplazar')) || ...
           ~isempty(strfind(low, 'sobrescribir')) )
        hallazgos = agregar_local(hallazgos, 'ERROR', 'DESTRUCTIVA_DEFAULT_SI', ...
          rel, n, 'Una accion destructiva no puede tener SI por defecto.');
      endif
    endfor
  endfor

  if isempty(hallazgos)
    severidades = {};
  else
    severidades = {hallazgos.severidad};
  endif
  n_error = sum(strcmp(severidades, 'ERROR'));
  n_aviso = sum(strcmp(severidades, 'AVISO'));
  reporte = struct('ok', n_error == 0, 'raiz', raiz, ...
    'archivos_revisados', numel(archivos), ...
    'preguntas_detectadas', conteo_preguntas, ...
    'preguntas_binarias_directas', conteo_binarias_directas, ...
    'errores', n_error, 'avisos', n_aviso, 'hallazgos', hallazgos);

  if imprimir
    fprintf('\n--- AUDITORIA TRANSVERSAL DE INTERACCIONES AOS ---\n');
    fprintf('Archivos .m revisados        : %d\n', reporte.archivos_revisados);
    fprintf('Interacciones detectadas     : %d\n', reporte.preguntas_detectadas);
    fprintf('Preguntas binarias directas  : %d\n', reporte.preguntas_binarias_directas);
    fprintf('Errores                      : %d\n', reporte.errores);
    fprintf('Avisos                       : %d\n', reporte.avisos);
    for i = 1:numel(hallazgos)
      fprintf('%s %-24s %s:%d - %s\n', hallazgos(i).severidad, ...
        hallazgos(i).codigo, hallazgos(i).archivo, ...
        hallazgos(i).linea, hallazgos(i).mensaje);
    endfor
    if reporte.ok
      fprintf('RESULTADO: AUDITORIA DE INTERACCIONES APROBADA\n');
    else
      fprintf(2, 'RESULTADO: AUDITORIA DE INTERACCIONES NO APROBADA\n');
    endif
  endif
endfunction

function h = agregar_local(h, severidad, codigo, archivo, linea, mensaje)
  item = struct('severidad', severidad, 'codigo', codigo, ...
    'archivo', archivo, 'linea', linea, 'mensaje', mensaje);
  if isempty(h), h = item; else, h(end+1) = item; endif
endfunction

function lista = listar_m_local(carpeta)
  lista = {};
  d = dir(carpeta);
  for i = 1:numel(d)
    if strcmp(d(i).name, '.') || strcmp(d(i).name, '..'), continue; endif
    ruta = fullfile(carpeta, d(i).name);
    if d(i).isdir
      sub = listar_m_local(ruta);
      lista = [lista sub]; %#ok<AGROW>
    else
      [~,~,ext] = fileparts(d(i).name);
      if strcmpi(ext, '.m'), lista{end+1} = ruta; endif %#ok<AGROW>
    endif
  endfor
endfunction

function rel = relativa_local(ruta, raiz)
  ruta = strrep(ruta, '\\', '/');
  raiz = strrep(raiz, '\\', '/');
  if numel(ruta) > numel(raiz) && strcmp(ruta(1:numel(raiz)), raiz)
    rel = ruta(numel(raiz)+2:end);
  else
    rel = ruta;
  endif
endfunction

function s = fileparts_y_nombre_local(p)
  s = strrep(p, '\\', '/');
endfunction

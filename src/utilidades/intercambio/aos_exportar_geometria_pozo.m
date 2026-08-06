function archivos = aos_exportar_geometria_pozo(survey, punzados, info, carpeta, nombre_base)
% Exporta survey, punzados y resumen geometrico a archivos legibles.
  archivos = {};
  if nargin < 1, survey = []; endif
  if nargin < 2, punzados = []; endif
  if nargin < 3 || ~isstruct(info), info = struct(); endif

  if isempty(survey) && ~tiene_punzados_local(punzados)
    fprintf('No hay geometria cargada para exportar.\n');
    return;
  endif

  root = raiz_aos_local();
  if nargin < 4 || isempty(carpeta)
    defecto = fullfile(root, 'exportaciones', 'geometria');
    txt = input(sprintf('Carpeta de salida [%s]: ', defecto), 's');
    if isempty(strtrim(txt)), carpeta = defecto; else, carpeta = strtrim(txt); endif
  endif
  if exist(carpeta, 'dir') ~= 7
    [ok, msg] = mkdir(carpeta);
    if ~ok, error('No se pudo crear la carpeta %s: %s', carpeta, msg); endif
  endif

  if nargin < 5 || isempty(nombre_base)
    nombre_base = 'pozo';
    if isfield(info, 'pozo') && ~isempty(info.pozo), nombre_base = info.pozo; endif
    txt = input(sprintf('Nombre base [%s]: ', nombre_base), 's');
    if ~isempty(strtrim(txt)), nombre_base = strtrim(txt); endif
  endif
  nombre_base = limpiar_nombre_local(nombre_base);

  if ~isempty(survey)
    ruta = fullfile(carpeta, [nombre_base '_survey.csv']);
    escribir_survey_local(ruta, survey);
    archivos{end+1} = ruta;
  endif

  if tiene_punzados_local(punzados)
    ruta = fullfile(carpeta, [nombre_base '_punzados.csv']);
    escribir_punzados_local(ruta, punzados);
    archivos{end+1} = ruta;
  endif

  ruta = fullfile(carpeta, [nombre_base '_geometria_resumen.txt']);
  escribir_resumen_local(ruta, survey, punzados, info);
  archivos{end+1} = ruta;

  fprintf('\nGEOMETRIA EXPORTADA\n');
  for i = 1:numel(archivos)
    fprintf('  %s\n', archivos{i});
  endfor
endfunction

function escribir_survey_local(ruta, s)
  fid = fopen(ruta, 'w');
  if fid < 0, error('No se pudo abrir %s.', ruta); endif
  limpiar = onCleanup(@() fclose(fid));
  fprintf(fid, 'N,MD_m,TVD_m,Inclinacion_deg,Azimut_deg,ID_tubing_m,ID_casing_m,Rugosidad_m\n');
  for i = 1:numel(s.MD)
    fprintf(fid, '%d,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g\n', ...
            i, s.MD(i), s.TVD(i), s.inclinacion(i), s.azimut(i), ...
            s.ID_tubing(i), s.ID_casing(i), s.rugosidad(i));
  endfor
endfunction

function escribir_punzados_local(ruta, p)
  fid = fopen(ruta, 'w');
  if fid < 0, error('No se pudo abrir %s.', ruta); endif
  limpiar = onCleanup(@() fclose(fid));
  fprintf(fid, 'N,MD_desde_m,MD_hasta_m,Longitud_m,Densidad_tiros_m,Activo,Nombre\n');
  for i = 1:numel(p.tramos)
    t = p.tramos(i);
    fprintf(fid, '%d,%.10g,%.10g,%.10g,%.10g,%d,%s\n', ...
            i, t.MD_desde, t.MD_hasta, t.MD_hasta - t.MD_desde, ...
            t.densidad_tpm, logical(t.activo), csv_texto_local(t.nombre));
  endfor
endfunction

function escribir_resumen_local(ruta, survey, punzados, info)
  fid = fopen(ruta, 'w');
  if fid < 0, error('No se pudo abrir %s.', ruta); endif
  limpiar = onCleanup(@() fclose(fid));
  fprintf(fid, 'AOS 0.1.1-R1 - RESUMEN DE GEOMETRIA DEL POZO\n');
  fprintf(fid, 'Fecha: %s\n', datestr(now(), 'yyyy-mm-dd HH:MM:SS'));
  if isfield(info, 'pozo'), fprintf(fid, 'Pozo: %s\n', info.pozo); endif
  if isfield(info, 'archivo_aosdat'), fprintf(fid, 'AOSDAT: %s\n', info.archivo_aosdat); endif
  if isfield(info, 'origen_survey'), fprintf(fid, 'Origen survey: %s\n', info.origen_survey); endif
  if isfield(info, 'origen_punzados'), fprintf(fid, 'Origen punzados: %s\n', info.origen_punzados); endif
  if isempty(survey)
    fprintf(fid, 'Survey: NO CARGADO\n');
  else
    fprintf(fid, 'Survey: %d puntos\n', numel(survey.MD));
    fprintf(fid, 'Rango MD: %.3f a %.3f m\n', min(survey.MD), max(survey.MD));
    fprintf(fid, 'Rango TVD: %.3f a %.3f m\n', min(survey.TVD), max(survey.TVD));
  endif
  if tiene_punzados_local(punzados)
    fprintf(fid, 'Punzados: %d intervalos\n', numel(punzados.tramos));
    fprintf(fid, 'Rango punzado MD: %.3f a %.3f m\n', ...
            min([punzados.tramos.MD_desde]), max([punzados.tramos.MD_hasta]));
  else
    fprintf(fid, 'Punzados: NO CARGADOS\n');
  endif
  r = aos_validar_geometria_pozo(survey, punzados, false);
  fprintf(fid, 'Validacion: %s\n', estado_local(r.ok));
  for i = 1:numel(r.errores), fprintf(fid, 'ERROR: %s\n', r.errores{i}); endfor
  for i = 1:numel(r.avisos), fprintf(fid, 'AVISO: %s\n', r.avisos{i}); endfor
endfunction

function root = raiz_aos_local()
  a = fileparts(mfilename('fullpath'));
  root = a;
  for k = 1:8
    if exist(fullfile(root, 'AOS.m'), 'file') == 2 && exist(fullfile(root, 'src'), 'dir') == 7
      return;
    endif
    b = fileparts(root);
    if strcmp(b, root), break; endif
    root = b;
  endfor
  root = pwd();
endfunction

function s = limpiar_nombre_local(s)
  if ~ischar(s) || isempty(strtrim(s)), s = 'pozo'; endif
  s = regexprep(strtrim(s), '[^A-Za-z0-9_-]+', '_');
  s = regexprep(s, '_+', '_');
  if isempty(s), s = 'pozo'; endif
endfunction

function s = csv_texto_local(s)
  if ~ischar(s), s = ''; endif
  s = strrep(s, '"', '""');
  s = ['"' s '"'];
endfunction

function tf = tiene_punzados_local(p)
  tf = isstruct(p) && isfield(p, 'tramos') && ~isempty(p.tramos);
endfunction

function s = estado_local(ok)
  if ok, s = 'APROBADA'; else, s = 'REQUIERE_REVISION'; endif
endfunction

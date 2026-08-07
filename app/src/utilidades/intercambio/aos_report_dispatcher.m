function salida = aos_report_dispatcher(contexto)
% AOS_REPORT_DISPATCHER Flujo transversal de informes AOS.
% Debe llamarse al finalizar correctamente una simulacion, sensibilidad,
% diseno, calibracion u optimizacion.
%
% Exportadores especificos opcionales:
%   archivo = exportador_simple(contexto, archivo_salida)
%   archivo = exportador_enriquecido(contexto, archivo_salida)
%
% Para ejecucion automatizada se pueden definir:
%   modo_no_interactivo = true
%   opcion_reporte = 1, 2, 3 o 4
%   incluir_contexto = true/false
%   carpeta_salida, nombre_base y preguntar_crypto

  if nargin < 1 || ~isstruct(contexto)
    error('aos_report_dispatcher requiere un contexto struct.');
  end

  contexto = normalizar_contexto_local(contexto);
  salida = struct();
  salida.opcion = 0;
  salida.cancelado = false;
  salida.archivos = {};
  salida.tipos = {};
  salida.codificados = [];
  salida.errores = {};
  salida.contexto_incluido = true;

  no_interactivo = false;
  if isfield(contexto, 'modo_no_interactivo')
    no_interactivo = logical(contexto.modo_no_interactivo);
  end

  % DEV5.4: solicitar identificador cuando el reporte no puede obtenerlo.
  contexto = asegurar_nombre_pozo_local(contexto, no_interactivo);

  fprintf('\n====================================================\n');
  fprintf(' INFORMES AOS - FLUJO TRANSVERSAL OBLIGATORIO\n');
  fprintf('====================================================\n');
  fprintf('Calculo finalizado correctamente.\n');
  fprintf('Modulo       : %s\n', contexto.tipo);
  fprintf('Tipo calculo : %s\n', contexto.tipo_calculo);
  fprintf('Solver       : %s\n', contexto.solver);
  fprintf('\n  1 - No generar informe\n');
  fprintf('  2 - Informe simple\n');
  fprintf('  3 - Informe enriquecido\n');
  fprintf('  4 - Generar ambos\n');

  if no_interactivo
    op = 2;
    if isfield(contexto, 'opcion_reporte'), op = contexto.opcion_reporte; end
  else
    op = input('Seleccione una opcion [2]: ');
    if isempty(op), op = 2; end
  end
  if ~isscalar(op) || ~isfinite(op) || ~any(round(op) == [1 2 3 4])
    fprintf('Opcion no valida. Se utilizara informe simple.\n');
    op = 2;
  else
    op = round(op);
  end
  salida.opcion = op;

  if op == 1
    salida.cancelado = true;
    fprintf('No se genero informe por decision del usuario.\n');
    return;
  end

  if no_interactivo
    incluir_contexto = true;
    if isfield(contexto, 'incluir_contexto')
      incluir_contexto = logical(contexto.incluir_contexto);
    end
  else
    r = input(['Incluir contexto del pozo (survey, tubing, punzados y ' ...
      'equipo de fondo)? (s/n) [s]: '], 's');
    incluir_contexto = isempty(r) || es_si_local(r);
  end
  salida.contexto_incluido = incluir_contexto;
  contexto.param.aosrpt_incluir_contexto_viewer = incluir_contexto;

  % HF3.5: inventariar y decidir una sola vez todas las tablas antes de
  % generar simple, enriquecido o ambos.
  extras = struct([]);
  if isfield(contexto,'report_tables') && isstruct(contexto.report_tables)
    extras = aos_report_append_tables(extras, contexto.report_tables);
  endif
  if exist('aos_report_build_punzados_distribution_table','file') == 2
    [tabla_punzados, resumen_punzados] = ...
      aos_report_build_punzados_distribution_table(contexto.Ql, contexto.param);
    extras = aos_report_append_tables(extras, tabla_punzados);
    contexto.param.aosrpt_punzados_resumen = resumen_punzados;
  endif
  opciones_tablas = struct('no_interactivo',no_interactivo);
  if isfield(contexto,'report_profile'), opciones_tablas.profile=contexto.report_profile; endif
  if isfield(contexto,'table_overrides'), opciones_tablas.overrides=contexto.table_overrides; endif
  if isfield(contexto,'prompt_each_table'), opciones_tablas.prompt_each=logical(contexto.prompt_each_table); endif
  [contexto.param, contexto.report_tables, contexto.report_composition] = ...
    aos_report_prepare_tables(contexto.param, contexto.tipo, extras, opciones_tablas);

  carpeta_defecto = fullfile('intercambio', 'reportes', 'enviados');
  if isfield(contexto, 'carpeta_defecto') && ischar(contexto.carpeta_defecto) && ...
      ~isempty(strtrim(contexto.carpeta_defecto))
    carpeta_defecto = contexto.carpeta_defecto;
  end

  if no_interactivo
    carpeta = carpeta_defecto;
    if isfield(contexto, 'carpeta_salida') && ischar(contexto.carpeta_salida) && ...
        ~isempty(strtrim(contexto.carpeta_salida))
      carpeta = contexto.carpeta_salida;
    end
    if exist(carpeta, 'dir') ~= 7
      [ok_mkdir, msg_mkdir] = mkdir(carpeta);
      if ~ok_mkdir, error('No se pudo crear %s: %s', carpeta, msg_mkdir); end
    end
  else
    carpeta = aos_report_choose_directory(carpeta_defecto);
  end

  nombre_defecto = nombre_base_local(contexto);
  if no_interactivo
    entrada = nombre_defecto;
    if isfield(contexto, 'nombre_base') && ischar(contexto.nombre_base) && ...
        ~isempty(strtrim(contexto.nombre_base))
      entrada = contexto.nombre_base;
    end
  else
    entrada = input(sprintf('Nombre base del informe [%s]: ', nombre_defecto), 's');
    entrada = strtrim(entrada);
    if isempty(entrada), entrada = nombre_defecto; end
  end
  nombre_base = limpiar_nombre_local(entrada);
  if isempty(nombre_base), nombre_base = nombre_defecto; end

  solicitudes = {};
  if op == 2 || op == 4, solicitudes{end+1} = 'simple'; end
  if op == 3 || op == 4, solicitudes{end+1} = 'enriquecido'; end

  for k = 1:numel(solicitudes)
    tipo = solicitudes{k};
    archivo = fullfile(carpeta, [nombre_base '_' tipo '.aosrpt']);
    archivo = resolver_colision_local(archivo);
    fprintf('\nGenerando informe %s...\n', upper(tipo));
    try
      archivo = invocar_exportador_local(contexto, tipo, archivo);
      verificar_archivo_local(archivo);

      codificado = false;
      preguntar_crypto = ~no_interactivo;
      if isfield(contexto, 'preguntar_crypto')
        preguntar_crypto = logical(contexto.preguntar_crypto);
      end
      if preguntar_crypto && exist('aos_finalizar_archivo_crypto', 'file') == 2
        fprintf('\nProteccion del informe %s:\n', upper(tipo));
        [codificado, archivo] = aos_finalizar_archivo_crypto(archivo, true);
        verificar_archivo_local(archivo);
      elseif preguntar_crypto
        fprintf(['ADVERTENCIA: no se encontro aos_finalizar_archivo_crypto. ' ...
          'El informe queda en texto plano.\n']);
      end

      salida.archivos{end+1} = archivo;
      salida.tipos{end+1} = tipo;
      salida.codificados(end+1) = codificado;
      info = dir(archivo);
      fprintf('Informe %s creado correctamente:\n  %s\n', upper(tipo), archivo);
      if ~isempty(info), fprintf('Tamano final: %.1f KB\n', info(1).bytes / 1024); end
    catch err
      salida.errores{end+1} = sprintf('%s: %s', tipo, err.message);
      fprintf(2, 'ERROR AL GENERAR INFORME %s: %s\n', upper(tipo), err.message);
      imprimir_stack_local(err);
    end
  end

  if isempty(salida.archivos)
    fprintf(2, ['No se pudo crear ningun informe. La simulacion permanece ' ...
      'disponible, pero la exportacion debe revisarse.\n']);
  else
    fprintf('\nResumen de informes generados:\n');
    for k = 1:numel(salida.archivos)
      proteccion = 'TEXTO_PLANO';
      if salida.codificados(k), proteccion = 'CODIFICADO'; end
      fprintf('  %-12s %s [%s]\n', upper(salida.tipos{k}), ...
        salida.archivos{k}, proteccion);
    end
  end
end

function contexto = normalizar_contexto_local(contexto)
  if ~isfield(contexto, 'tipo') || isempty(contexto.tipo), contexto.tipo = 'GENERAL'; end
  if ~isfield(contexto, 'tipo_calculo') || isempty(contexto.tipo_calculo)
    contexto.tipo_calculo = 'simulacion';
  end
  if ~isfield(contexto, 'solver') || isempty(contexto.solver)
    contexto.solver = 'no_especificado';
  end
  if ~isfield(contexto, 'param') || ~isstruct(contexto.param)
    contexto.param = struct();
  end
  if ~isfield(contexto, 'Ql') || ~isnumeric(contexto.Ql) || isempty(contexto.Ql)
    contexto.Ql = 0;
  end
  if ~isfield(contexto, 'Qo') || ~isnumeric(contexto.Qo) || isempty(contexto.Qo)
    contexto.Qo = 0;
  end
  if ~isfield(contexto, 'Qiny') || ~isnumeric(contexto.Qiny) || isempty(contexto.Qiny)
    contexto.Qiny = 0;
  end
end

function archivo = invocar_exportador_local(contexto, tipo, archivo)
  campo = ['exportador_' tipo];
  if isfield(contexto, campo) && ~isempty(contexto.(campo))
    exportador = contexto.(campo);
    if isa(exportador, 'function_handle') || ischar(exportador)
      archivo = feval(exportador, contexto, archivo);
    else
      error('El campo %s no contiene un exportador valido.', campo);
    end
    return;
  end

  if strcmp(tipo, 'simple')
    exportar_aosrpt(contexto.param, contexto.Ql, contexto.Qo, ...
      contexto.Qiny, contexto.tipo, archivo);
  else
    exportar_aosrpt_enriquecido(contexto.param, contexto.Ql, contexto.Qo, ...
      contexto.Qiny, contexto.tipo, archivo);
  end
end

function nombre = nombre_base_local(contexto)
  nombre = '';
  if isfield(contexto, 'nombre_caso') && ischar(contexto.nombre_caso)
    nombre = strtrim(contexto.nombre_caso);
  end
  if isempty(nombre) && isfield(contexto.param, 'nombre_pozo') && ...
      ischar(contexto.param.nombre_pozo)
    nombre = strtrim(contexto.param.nombre_pozo);
  end
  if isempty(nombre)
    global AOSDAT_ACTIVO
    if ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO)
      [~, nombre, ~] = fileparts(AOSDAT_ACTIVO);
    end
  end
  if isempty(nombre), nombre = contexto.tipo; end
  nombre = limpiar_nombre_local(nombre);
  sello = datestr(now(), 'yyyymmdd_HHMMSS');
  nombre = [nombre '_' sello];
end

function nombre = limpiar_nombre_local(nombre)
  if ~ischar(nombre), nombre = 'reporte'; end
  nombre = regexprep(strtrim(nombre), '[\\/:*?"<>|]', '_');
  nombre = regexprep(nombre, '[\r\n\t]+', '_');
  nombre = regexprep(nombre, '\s+', '_');
  nombre = regexprep(nombre, '_+', '_');
  nombre = regexprep(nombre, '^_+|_+$', '');
  partes = strsplit(nombre, '_');
  limpias = {};
  for i = 1:numel(partes)
    if isempty(limpias) || ~strcmpi(limpias{end}, partes{i})
      limpias{end+1} = partes{i};
    end
  end
  nombre = strjoin(limpias, '_');
end

function contexto = asegurar_nombre_pozo_local(contexto, no_interactivo)
  nombre = '';
  if isfield(contexto,'nombre_pozo') && ischar(contexto.nombre_pozo)
    nombre = strtrim(contexto.nombre_pozo);
  end
  if isempty(nombre) && isfield(contexto,'param') && isstruct(contexto.param) && ...
      isfield(contexto.param,'nombre_pozo') && ischar(contexto.param.nombre_pozo)
    nombre = strtrim(contexto.param.nombre_pozo);
  end
  desconocido = isempty(nombre) || strcmpi(nombre,'Pozo sin identificar') || ...
    strcmpi(nombre,'Pozo sin nombre') || strcmpi(nombre,'pozo') || strcmpi(nombre,'reporte');
  if desconocido && ~no_interactivo
    entrada = strtrim(input('Identificador del pozo/proyecto [Pozo sin identificar]: ','s'));
    if ~isempty(entrada), nombre = entrada; desconocido = false; end
  end
  if desconocido, nombre = 'Pozo sin identificar'; end
  contexto.nombre_pozo = nombre;
  contexto.param.nombre_pozo = nombre;
  if isfield(contexto,'nombre_caso') && ischar(contexto.nombre_caso)
    caso = limpiar_nombre_local(contexto.nombre_caso);
    if ~desconocido
      prefijos = {'reporte_','Pozo_sin_identificar_','Pozo_sin_nombre_'};
      for k=1:numel(prefijos)
        if strncmpi(caso,prefijos{k},numel(prefijos{k}))
          caso=[limpiar_nombre_local(nombre) '_' caso(numel(prefijos{k})+1:end)];
          break;
        end
      end
    end
    contexto.nombre_caso = limpiar_nombre_local(caso);
  end
end

function archivo = resolver_colision_local(archivo)
  if exist(archivo, 'file') ~= 2, return; end
  [ruta, nombre, ext] = fileparts(archivo);
  for k = 1:999
    candidato = fullfile(ruta, sprintf('%s_%03d%s', nombre, k, ext));
    if exist(candidato, 'file') ~= 2
      archivo = candidato;
      return;
    end
  end
  error('No se pudo obtener un nombre de informe libre.');
end

function verificar_archivo_local(archivo)
  if ~ischar(archivo) || isempty(archivo) || exist(archivo, 'file') ~= 2
    error('El exportador no creo el archivo esperado.');
  end
  info = dir(archivo);
  if isempty(info) || info(1).bytes <= 0
    error('El archivo creado esta vacio: %s', archivo);
  end
end

function tf = es_si_local(txt)
  txt = lower(strtrim(txt));
  tf = strcmp(txt, 's') || strcmp(txt, 'si') || strcmp(txt, 'yes') || ...
    strcmp(txt, 'y');
end

function imprimir_stack_local(err)
  if isfield(err, 'stack')
    for i = 1:numel(err.stack)
      fprintf(2, '  en %s, linea %d\n', err.stack(i).file, err.stack(i).line);
    end
  end
end

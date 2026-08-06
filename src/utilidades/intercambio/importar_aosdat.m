function param = importar_aosdat(archivo, opciones)
% IMPORTAR_AOSDAT Importa integralmente un caso AOS.
%
% AOS 0.0.11 Benchmark Ready:
% - Lee todos los campos de todas las secciones y los preserva en
%   param.aosdat_sections.
% - Mantiene compatibilidad plana para [CONFIG] y [BOMBEO_MECANICO].
% - Carga automaticamente survey, geologia, punzados, estado mecanico y
%   benchmarks sin requerir una segunda carga desde el menu.
% - La interfaz del archivo usa bar, m, m3/d y Sm3/d; el nucleo conserva
%   Pa y m3/s mediante aliases normalizados.

  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if islogical(opciones) || isnumeric(opciones)
      opciones = struct('activar_caso', logical(opciones));
  endif
  if ~isstruct(opciones), error('IMPORTAR_AOSDAT: opciones debe ser struct o logico.'); endif
  activar_caso = opcion_local(opciones, 'activar_caso', true);
  imprimir_resumen = opcion_local(opciones, 'imprimir_resumen', true);
  normalizar = opcion_local(opciones, 'normalizar', true);

  script_dir = fileparts(mfilename('fullpath'));
  AOS_root = fileparts(fileparts(fileparts(script_dir)));
  carpetas_busqueda = {
      fullfile(AOS_root, 'intercambio', 'pozos', 'recibidos')
      fullfile(AOS_root, 'datos', 'ejemplos', 'benchmarks')
      fullfile(AOS_root, 'datos', 'ejemplos')
      fullfile(AOS_root, 'datos', 'ejemplos', 'importados_legacy')
      fullfile(AOS_root, 'config', 'importados')
      fullfile(AOS_root, 'datos', 'ejemplos', 'catalogos')
      fullfile(AOS_root, 'datos_usuario', 'catalogos', 'aosdat')
      fullfile(AOS_root, 'intercambio', 'catalogos', 'recibidos')
  };

  if nargin < 1 || isempty(archivo)
      archivo = seleccionar_archivo_aosdat(carpetas_busqueda);
      if isempty(archivo)
          param = [];
          return;
      end
  end

  if exist(archivo, 'file') ~= 2
      error('No se encontro el archivo .aosdat: %s', archivo);
  end

  % --- Deteccion automatica de proteccion, independiente de globals ---
  archivo_descifrado = archivo;
  if aos_archivo_codificado(archivo)
      fprintf('Archivo codificado detectado.\n');
      id_remitente = pedir_id_importacion('ID del remitente (10 digitos): ');
      id_propio = pedir_id_importacion('Su ID AOS/receptor (10 digitos): ');
      archivo_descifrado = [tempname(), '.aosdat'];
      aos_decrypt(archivo, id_remitente, id_propio, archivo_descifrado);
      fprintf('Archivo descifrado temporalmente.\n');
  end

  if ~es_archivo_aosdat_valido(archivo_descifrado)
      error(['El archivo seleccionado no contiene secciones .aosdat reconocidas ', ...
             'o corresponde a un formato cifrado/legacy no compatible: %s'], archivo);
  end

  fid = fopen(archivo_descifrado, 'r');
  if fid == -1
      error('No se pudo abrir el archivo %s', archivo_descifrado);
  end

  param = struct();
  metadata = struct();
  geol = struct();
  geologia_en_archivo = false;
  estado_mecanico = struct();
  benchmark = struct();
  secciones = struct();
  survey_data = [];
  intervalos = struct('tramos', []);
  seccion = '';
  lineas_leidas = 0;

  while ~feof(fid)
      linea_original = fgetl(fid);
      if ~ischar(linea_original), continue; end
      lineas_leidas = lineas_leidas + 1;
      linea = limpiar_linea(linea_original);
      if isempty(linea), continue; end

      if linea(1) == '[' && linea(end) == ']'
          seccion = upper(strtrim(linea(2:end-1)));
          sec_id = lower(aos_sanitizar_campo(seccion));
          if ~isfield(secciones, sec_id), secciones.(sec_id) = struct(); end
          continue;
      end

      if strcmp(seccion, 'SURVEY')
          fila = parsear_fila_numerica(linea);
          if length(fila) >= 2
              fila = completar_fila_survey(fila, param);
              survey_data = [survey_data; fila(1:7)];
          end
          continue;
      elseif strcmp(seccion, 'PUNZADOS')
          fila = parsear_fila_numerica(linea);
          if length(fila) >= 2
              tramo = struct();
              tramo.MD_desde = fila(1);
              tramo.MD_hasta = fila(2);
              if length(fila) >= 3, tramo.densidad_tpm = round(fila(3)); else, tramo.densidad_tpm = 0; end
              if length(fila) >= 4, tramo.diametro_punzado_m = fila(4); else, tramo.diametro_punzado_m = 0.010; end
              if isempty(intervalos.tramos)
                  intervalos.tramos = tramo;
              else
                  intervalos.tramos(end+1) = tramo;
              end
          end
          continue;
      end

      [campo_original, valor_texto, es_par] = separar_campo_valor(linea);
      if ~es_par, continue; end
      campo = aos_sanitizar_campo(campo_original);
      valor = aos_parse_valor(valor_texto);
      sec_id = lower(aos_sanitizar_campo(seccion));
      if isempty(sec_id), sec_id = 'sin_seccion'; end
      if ~isfield(secciones, sec_id), secciones.(sec_id) = struct(); end
      secciones.(sec_id).(campo) = valor;

      switch seccion
          case 'AOS_DATA'
              metadata.(campo) = valor;
              if strcmpi(campo, 'pozo') || strcmpi(campo, 'nombre_pozo')
                  param.nombre_pozo = valor;
              elseif strcmpi(campo, 'nombre')
                  param.nombre = valor;
                  if ~isfield(param, 'nombre_pozo'), param.nombre_pozo = valor; end
              elseif any(strcmpi(campo, {'descripcion','version','fecha'}))
                  param.(campo) = valor;
              end
          case 'AOS_CATALOGO'
              if ~isfield(param,'catalogo_metadata') || ~isstruct(param.catalogo_metadata)
                  param.catalogo_metadata = struct();
              endif
              param.catalogo_metadata.(campo) = valor;
          case {'CONFIG','BOMBEO_MECANICO'}
              param.(campo) = valor;
          case 'GEOLOGIA'
              geol.(campo) = valor;
              geologia_en_archivo = true;
          case 'ESTADO_MECANICO'
              estado_mecanico.(campo) = valor;
          case 'BENCHMARK_PROSPER'
              benchmark.(campo) = valor;
          case {'POZO','TUBING','CASING','FLUIDOS','GL','JGL','BES','BES3','BM','INT1'}
              grupo = lower(aos_sanitizar_campo(seccion));
              if ~isfield(param, grupo) || ~isstruct(param.(grupo)), param.(grupo) = struct(); end
              param.(grupo).(campo) = valor;
          otherwise
              % Las secciones futuras quedan preservadas en aosdat_sections
              % y se publican tambien como subestructuras al finalizar.
      end
  end
  fclose(fid);

  if ~strcmp(archivo_descifrado, archivo) && exist(archivo_descifrado, 'file') == 2
      delete(archivo_descifrado);
  end

  % Reconstruir el contrato completo de punzados. [PUNZADOS] mantiene la
  % compatibilidad historica y [PUNZADOS_META] conserva los campos HF3.
  meta_punzados=struct();
  if isfield(secciones,'punzados_meta') && isstruct(secciones.punzados_meta)
      meta_punzados=secciones.punzados_meta;
  endif
  if ~isempty(intervalos.tramos) || ~isempty(fieldnames(meta_punzados))
      [intervalos,avisos_punzados]=aos_punzados_desde_aosdat(intervalos,meta_punzados);
      param.aosdat_avisos_punzados=avisos_punzados;
  endif

  param.aosdat_metadata = metadata;
  param.aosdat_sections = secciones;
  param.aosdat_archivo = archivo;
  param.archivo_aosdat = archivo; % alias historico usado por sensibilidades/reportes
  param.aosdat_lineas_leidas = lineas_leidas;

  % Publicar secciones futuras como subestructuras sin perder el repositorio
  % completo param.aosdat_sections.
  reservadas = {'aos_data','config','geologia','survey','punzados','punzados_meta','estado_mecanico','benchmark_prosper','bombeo_mecanico'};
  nombres_sec = fieldnames(secciones);
  for isec = 1:length(nombres_sec)
      sec_id = nombres_sec{isec};
      if any(strcmp(sec_id, reservadas)), continue; end
      if ~isfield(param, sec_id) || ~isstruct(param.(sec_id))
          param.(sec_id) = secciones.(sec_id);
      end
  end
  if ~isempty(fieldnames(estado_mecanico)), param.estado_mecanico = estado_mecanico; end
  if ~isempty(fieldnames(benchmark)), param.benchmark_prosper = benchmark; end

  % Despacho automatico e indiferenciado de secciones actuales y futuras.
  % No solicita decisiones al usuario: el archivo define su propio contenido.
  param = aos_despachar_aosdat_secciones(param);

  % --- Survey completo ---
  if ~isempty(survey_data)
      [~, orden] = sort(survey_data(:,1));
      survey_data = survey_data(orden,:);
      param.survey = construir_survey(survey_data, archivo);
  end

  % --- Punzados y geologia ---
  if ~isempty(intervalos.tramos)
      intervalos = ordenar_intervalos(intervalos);
      param.punzados = intervalos;
  end
  % Solo se crea/normaliza geologia cuando la seccion [GEOLOGIA] existe.
  % Un archivo con [PUNZADOS] solamente conserva sus intervalos sin inventar
  % propiedades petrofisicas o geomecanicas.
  if geologia_en_archivo
      if ~isempty(intervalos.tramos), geol.intervalos = intervalos; end
      [geol, avisos_geol] = aos_normalizar_geologia(geol, param);
      param.geologia = geol;
      param.aosdat_avisos_geologia = avisos_geol;
  end

  % --- Unidades, aliases y estructuras comunes ---
  param.aosdat_tipo = clasificar_documento_local(secciones);
  param = aos_aplicar_aliases_aosdat(param);
  if normalizar && ~strcmp(param.aosdat_tipo,'CATALOGO')
      try
          param = aos_normalizar_config(param, 'GENERAL');
          aos_validar_config_modulo(param, 'GENERAL', true);
      catch err
          if imprimir_resumen
              fprintf('ADVERTENCIA AOS: normalizacion parcial del .aosdat: %s\n', err.message);
          endif
      end
  endif

  % Reaplicar geologia despues del normalizador para no perder intervalos.
  if isfield(param, 'geologia') && isstruct(param.geologia) && ~isempty(fieldnames(param.geologia))
      [param.geologia, avisos_geol2] = aos_normalizar_geologia(param.geologia, param);
      if isfield(param.geologia, 'intervalos')
          param.punzados = param.geologia.intervalos;
      end
      if ~isempty(avisos_geol2), param.aosdat_avisos_geologia = avisos_geol2; end
  end

  % --- Dejar caso activo y sincronizar geologia global ---
  resumen_geo = struct('geologia_cargada',false,'n_punzados',0);
  if isfield(param,'punzados') && isstruct(param.punzados) && isfield(param.punzados,'tramos')
      resumen_geo.n_punzados = numel(param.punzados.tramos);
  endif
  if activar_caso && ~strcmp(param.aosdat_tipo,'CATALOGO')
      global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
      CONFIG_ACTIVA = param;
      geologia = []; % nunca heredar geologia/punzados de un pozo anterior
      [~, nombre_base] = fileparts(archivo);
      AOSDAT_ACTIVO = nombre_base;
      resumen_geo = aos_sincronizar_geologia_activa();
      param = CONFIG_ACTIVA;
      if resumen_geo.geologia_cargada, geologia = CONFIG_ACTIVA.geologia; endif
  endif

  % --- Resumen de carga ---
  if imprimir_resumen
      if strcmp(param.aosdat_tipo,'CATALOGO')
          fprintf('Catalogo .aosdat importado: %s\n', archivo);
      else
          fprintf('Configuracion importada: %s\n', archivo);
      endif
      fprintf('   Tipo de documento     : %s\n', param.aosdat_tipo);
      fprintf('   Campos principales    : %d\n', length(fieldnames(param)));
      fprintf('   Secciones preservadas : %d\n', length(fieldnames(secciones)));
      if isfield(param, 'survey') && isfield(param.survey, 'n_puntos')
          fprintf('   Survey                : %d puntos\n', param.survey.n_puntos);
      else
          fprintf('   Survey                : no incluido\n');
      endif
      if resumen_geo.geologia_cargada
          fprintf('   Geologia              : cargada automaticamente\n');
      else
          fprintf('   Geologia              : no incluida\n');
      endif
      fprintf('   Punzados              : %d tramos\n', resumen_geo.n_punzados);
      if isfield(param, 'benchmark_prosper')
          fprintf('   Benchmark PROSPER     : cargado como referencia\n');
      endif
      if isfield(param, 'Q_iny')
          fprintf('   Qiny configurado      : %s\n', aos_formato_caudal_gas(param.Q_iny));
      endif
      if activar_caso && ~strcmp(param.aosdat_tipo,'CATALOGO')
          fprintf('   El caso queda activo para todos los modulos.\n');
      else
          fprintf('   Importacion sin reemplazar el caso activo.\n');
      endif
  endif

end

function archivo = seleccionar_archivo_aosdat(carpetas)
  archivo = '';
  fprintf('\n--- SELECCION DE ARCHIVO .aosdat ---\n');
  fprintf(' 1 - Buscar en carpetas estandar\n');
  fprintf(' 2 - Navegar manualmente\n');
  opcion = input('Seleccione una opcion (1-2) [1]: ');
  if isempty(opcion), opcion = 1; end

  if opcion == 2
      if isunix
          [status, ~] = system('which zenity');
          if status == 0
              [status, ruta_arch] = system('zenity --file-selection --title="Seleccione un archivo .aosdat" --file-filter="*.aosdat" 2>/dev/null');
              if status == 0 && ~isempty(ruta_arch), archivo = strtrim(ruta_arch); end
          end
      end
      if isempty(archivo)
          try
              [nombre, ruta] = uigetfile('*.aosdat', 'Seleccione un archivo .aosdat');
              if ischar(nombre) && ~isempty(nombre) && ~strcmp(nombre, '0')
                  archivo = fullfile(ruta, nombre);
              end
          catch
              fprintf('Selector grafico no disponible; se usara la busqueda estandar.\n');
          end
      end
      if ~isempty(archivo)
          fprintf('Archivo seleccionado: %s\n', archivo);
          return;
      end
  end

  encontrados = {};
  for c = 1:length(carpetas)
      if exist(carpetas{c}, 'dir') == 7
          lista = dir(fullfile(carpetas{c}, '*.aosdat'));
          for k = 1:length(lista)
              candidato = fullfile(carpetas{c}, lista(k).name);
              if es_archivo_aosdat_valido(candidato)
                  encontrados{end+1} = candidato;
              end
          end
      end
  end
  if isempty(encontrados)
      fprintf('No se encontraron archivos .aosdat.\n');
      return;
  end
  fprintf('\n--- ARCHIVOS .aosdat DISPONIBLES ---\n');
  for k = 1:length(encontrados), fprintf(' %2d - %s\n', k, encontrados{k}); end
  fprintf('  0 - Cancelar\n');
  op = input('Seleccione un archivo: ');
  if ~isempty(op) && op >= 1 && op <= length(encontrados)
      archivo = encontrados{op};
  end
end

function ok = es_archivo_aosdat_valido(archivo)
  ok = false;
  if aos_archivo_codificado(archivo)
      ok = true;
      return;
  end
  fid = fopen(archivo, 'r');
  if fid == -1, return; end
  bytes = fread(fid, 4096, 'uint8=>uint8');
  fclose(fid);
  if isempty(bytes), return; end
  if length(bytes) >= 8 && strcmp(char(bytes(1:8))', 'Salted__')
      return;
  end
  % Rechazar binarios con NUL o demasiados caracteres de control.
  if any(bytes == 0), return; end
  controles = sum(bytes < 9 | (bytes > 13 & bytes < 32));
  if controles > max(2, round(0.02 * length(bytes))), return; end
  txt = char(bytes(:))';
  secciones = {'[AOS_DATA]','[AOS_CATALOGO]','[CONFIG]','[POZO]','[FLUIDOS]','[TUBING]', ...
               '[CASING]','[GL]','[JGL]','[BES]','[BES3]','[BM]','[INT1]', ...
               '[BOMBEO_MECANICO]','[GEOLOGIA]','[SURVEY]','[PUNZADOS]','[PUNZADOS_META]', ...
               '[ESTADO_MECANICO]','[BENCHMARK_PROSPER]','[CATALOGO]','[CATALOGOS]', ...
               '[BOMBAS]','[VALVULAS]','[VARILLAS]','[UNIDADES_BM]', ...
               '[MANDRILES_GALERIA]','[GALERIA]','[GALERIAS]', ...
               '[COMPONENTES]','[MATERIALES]','[PROVEEDORES]', ...
               '[BES_CATALOGO]','[BM_CATALOGO]','[GL_CATALOGO]','[PCP_CATALOGO]','[LDL_CATALOGO]'};
  txt_up = upper(txt);
  for i = 1:length(secciones)
      if ~isempty(strfind(txt_up, secciones{i}))
          ok = true;
          return;
      end
  end
end

function linea = limpiar_linea(linea)
  linea = strtrim(linea);
  if isempty(linea), return; end
  pos = strfind(linea, '#');
  if ~isempty(pos), linea = strtrim(linea(1:pos(1)-1)); end
  if isempty(linea), return; end
  if linea(1) == '%', linea = ''; end
end

function [campo, valor, ok] = separar_campo_valor(linea)
  campo = ''; valor = ''; ok = false;
  pos = strfind(linea, '=');
  if isempty(pos), return; end
  p = pos(1);
  campo = strtrim(linea(1:p-1));
  valor = strtrim(linea(p+1:end));
  ok = ~isempty(campo);
end

function fila = parsear_fila_numerica(linea)
  partes = strsplit(linea, ',');
  fila = [];
  for i = 1:length(partes)
      v = str2double(strtrim(partes{i}));
      if isnan(v), fila = []; return; end
      fila(end+1) = v;
  end
end

function fila = completar_fila_survey(fila, param)
  diam = 0.062; csg = 0.100; rug = 4.57e-5;
  if isfield(param, 'diam_tbg') && isnumeric(param.diam_tbg), diam = param.diam_tbg;
  elseif isfield(param, 'ID_tubing_m') && isnumeric(param.ID_tubing_m), diam = param.ID_tubing_m; end
  if isfield(param, 'ID_csg') && isnumeric(param.ID_csg), csg = param.ID_csg;
  elseif isfield(param, 'ID_casing_m') && isnumeric(param.ID_casing_m), csg = param.ID_casing_m; end
  if isfield(param, 'rugosidad') && isnumeric(param.rugosidad), rug = param.rugosidad;
  elseif isfield(param, 'rugosidad_m') && isnumeric(param.rugosidad_m), rug = param.rugosidad_m; end
  defaults = [0, 0, 0, 0, diam, csg, rug];
  n = length(fila);
  defaults(1:n) = fila;
  fila = defaults;
end

function survey = construir_survey(datos, archivo)
  survey = struct();
  survey.MD = datos(:,1);
  survey.TVD = datos(:,2);
  survey.inclinacion = datos(:,3);
  survey.azimut = datos(:,4);
  survey.ID_tubing = datos(:,5);
  survey.ID_casing = datos(:,6);
  survey.rugosidad = datos(:,7);
  survey.origen = archivo;
  survey.n_puntos = size(datos,1);
  MD = survey.MD; TVD = survey.TVD; inc = survey.inclinacion; ID = survey.ID_tubing;
  survey.get_TVD = @(md) interp1(MD, TVD, md, 'linear', 'extrap');
  survey.get_ID = @(md) interp1(MD, ID, md, 'linear', 'extrap');
  survey.get_inclinacion = @(md) interp1(MD, inc, md, 'linear', 'extrap');
end

function intervalos = ordenar_intervalos(intervalos)
  if isempty(intervalos.tramos), return; end
  desde = [intervalos.tramos.MD_desde];
  [~, idx] = sort(desde);
  intervalos.tramos = intervalos.tramos(idx);
  total_m = 0; total_tiros = 0;
  for i = 1:length(intervalos.tramos)
      L = max(intervalos.tramos(i).MD_hasta - intervalos.tramos(i).MD_desde, 0);
      total_m = total_m + L;
      total_tiros = total_tiros + L * intervalos.tramos(i).densidad_tpm;
  end
  intervalos.longitud_total_m = total_m;
  intervalos.tiros_totales_estimados = round(total_tiros);
end

function id = pedir_id_importacion(mensaje)
  while true
      id = strtrim(input(mensaje, 's'));
      if length(id) == 10 && all(id >= '0') && all(id <= '9'), return; end
      fprintf('El ID debe contener exactamente 10 digitos.\n');
  end
end

function valor = opcion_local(opciones, campo, defecto)
  valor = defecto;
  if isfield(opciones,campo) && ~isempty(opciones.(campo))
      valor = logical(opciones.(campo));
  endif
endfunction

function tipo = clasificar_documento_local(secciones)
  tipo = 'CASO';
  fn = fieldnames(secciones);
  for i=1:numel(fn), fn{i}=lower(fn{i}); endfor
  catalogos = {'aos_catalogo','catalogo','catalogos','bombas','valvulas','varillas', ...
    'unidades_bm','mandriles_galeria','galeria','galerias','componentes','materiales', ...
    'proveedores','bes_catalogo','bm_catalogo','gl_catalogo','pcp_catalogo','ldl_catalogo'};
  caso_fisico = {'pozo','fluidos','tubing','casing','gl','jgl','bes','bes3','bm','int1', ...
    'bombeo_mecanico','geologia','survey','punzados','punzados_meta','estado_mecanico','benchmark_prosper'};
  tiene_catalogo = any(ismember(fn,catalogos));
  tiene_caso_fisico = any(ismember(fn,caso_fisico));
  if tiene_catalogo && ~tiene_caso_fisico
      % Una biblioteca puede incluir [CONFIG] como plantilla y sigue siendo
      % catalogo: no debe reemplazar el caso activo al importarse directamente.
      tipo='CATALOGO';
  elseif tiene_catalogo && tiene_caso_fisico
      tipo='CASO_CON_CATALOGOS';
  endif
endfunction


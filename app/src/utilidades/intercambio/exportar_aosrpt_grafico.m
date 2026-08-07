function exportar_aosrpt_grafico(datos, tipo_modulo, nombre_archivo)
% EXPORTAR_AOSRPT_GRAFICO Exportador grafico con tablas transversales HF3.5.

  interactiva = (nargin < 3 || isempty(nombre_archivo));
  carpeta = fullfile('intercambio','reportes','enviados');
  if exist(carpeta,'dir') ~= 7, mkdir(carpeta); endif

  if interactiva
    defecto = [lower(regexprep(tipo_modulo,'[^A-Za-z0-9]+','_')) '_' ...
      datestr(now(),'yyyymmdd_HHMMSS') '.aosrpt'];
    nombre_archivo = aos_elegir_nombre_reporte(carpeta,defecto);
  else
    [ruta,nombre,ext] = fileparts(nombre_archivo);
    if isempty(ext), ext = '.aosrpt'; endif
    if isempty(ruta), nombre_archivo = fullfile(carpeta,[nombre ext]); endif
  endif

  param = param_local(datos);
  nombre_pozo = pozo_local(datos,param);
  extra = tabla_vectores_local(datos,tipo_modulo);
  opciones = struct('no_interactivo',~interactiva);
  [param, tablas, composicion] = aos_report_prepare_tables(param,tipo_modulo,extra,opciones);

  graficos = generar_graficos_local(param,tipo_modulo,carpeta);
  fid = fopen(nombre_archivo,'w');
  if fid < 0, error('No se pudo crear %s',nombre_archivo); endif
  cerrado = false;
  try
    fprintf(fid,'[AOS_REPORT]\n');
    fprintf(fid,'version=1.5\nviewer_schema=AOS_VIEWER_CONTEXT_1.1\n');
    fprintf(fid,'fecha=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid,'sistema=%s\nmodulo=GRAFICO\nnombre_pozo=%s\n',tipo_modulo,nombre_pozo);
    [~,rid,~] = fileparts(nombre_archivo);
    info = struct('report_id',rid,'report_type',[limpiar_estado_local(tipo_modulo) '_GRAPHIC_REPORT'], ...
      'module',tipo_modulo,'workbench','AOS_SIM', ...
      'viewer_schema','AOS_VIEWER_CONTEXT_1.1','graphics_count',numel(graficos));
    aos_report_write_manifest(fid,info,composicion);
    fprintf(fid,'\n[MODULE_SUMMARY]\ntipo=%s\n',tipo_modulo);
    serializar_campos_simples_local(fid,datos);
    aos_rpt_escribir_tablas(fid,tablas,composicion);
    if exist('aos_exportar_contexto_viewer','file') == 2
      aos_exportar_contexto_viewer(fid,param,tipo_modulo,true);
    endif
    if exist('aos_rpt_escribir_graficos','file') == 2
      aos_rpt_escribir_graficos(fid,graficos);
    endif
    fclose(fid);
    cerrado = true;
  catch err
    if ~cerrado, try, fclose(fid); catch, end_try_catch, endif
    if exist(nombre_archivo,'file') == 2, try, delete(nombre_archivo); catch, end_try_catch, endif
    rethrow(err);
  end_try_catch

  if exist('aos_finalizar_archivo_crypto','file') == 2
    aos_finalizar_archivo_crypto(nombre_archivo,interactiva);
  endif
  fprintf('\nReporte enriquecido exportado: %s\n',nombre_archivo);
endfunction

function tabla = tabla_vectores_local(datos,tipo_modulo)
  tabla = struct([]);
  if ~isstruct(datos), return; endif
  campos = fieldnames(datos);
  nombres = {};
  n = 0;
  for i = 1:numel(campos)
    v = datos.(campos{i});
    if (isnumeric(v) || islogical(v) || iscell(v)) && isvector(v) && numel(v) > 1
      if n == 0, n = numel(v); endif
      if numel(v) == n, nombres{end+1} = campos{i}; endif
    endif
  endfor
  if n == 0 || isempty(nombres), return; endif
  rows = cell(n,numel(nombres));
  for j = 1:numel(nombres)
    v = datos.(nombres{j});
    for i = 1:n
      if iscell(v), rows{i,j} = v{i}; else, rows{i,j} = v(i); endif
    endfor
  endfor
  tabla = struct('id',['graphic_data_' lower(regexprep(tipo_modulo,'[^A-Za-z0-9]+','_'))], ...
    'title',['Datos del grafico ' tipo_modulo],'section','GRAFICO', ...
    'role','RESULT_TABLE','source','AOS_GRAPHIC_MODULE','category','RESULTS', ...
    'priority','PRIMARY','columns',{nombres},'labels',{nombres}, ...
    'units',{repmat({''},1,numel(nombres))},'rows',{rows}, ...
    'default_mode','FULL_BODY','archive_full',true);
endfunction

function graficos = generar_graficos_local(param,tipo_modulo,carpeta)
  graficos = struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  fig = get(0,'CurrentFigure');
  if ~isempty(fig) && ishandle(fig)
    tmp = [tempname(carpeta) '.png'];
    estado = 'NO_DISPONIBLE';
    try, print(fig,'-dpng','-r150',tmp); estado = 'OK';
    catch err, estado = ['ERROR_' limpiar_estado_local(err.message)]; end_try_catch
    graficos(end+1) = entrada_local('principal','Grafico principal',upper(tipo_modulo),estado,tmp);
    borrar_local(tmp);
  endif
  generadores = {'aos_generar_imagen_tuberia','aos_generar_imagen_survey','aos_generar_imagen_punzados'};
  ids = {'taitel_tuberia','survey','punzados'};
  titulos = {'Diagnostico Taitel, Turner y erosion','Survey del pozo','Geometria de punzados'};
  secciones = {'DIAGNOSTICO_TUBERIA','SURVEY','PUNZADOS'};
  for i = 1:numel(generadores)
    ruta = ''; estado = 'NO_DISPONIBLE';
    try
      if strcmp(generadores{i},'aos_generar_imagen_tuberia')
        [ruta,estado] = aos_generar_imagen_tuberia(param,tipo_modulo,0,0,carpeta);
      else
        [ruta,estado] = feval(generadores{i},param,tipo_modulo,carpeta);
      endif
    catch err
      estado = ['ERROR_' limpiar_estado_local(err.message)];
    end_try_catch
    graficos(end+1) = entrada_local(ids{i},titulos{i},secciones{i},estado,ruta);
    borrar_local(ruta);
  endfor
endfunction

function serializar_campos_simples_local(fid,d)
  if ~isstruct(d), return; endif
  campos = fieldnames(d);
  for i = 1:numel(campos)
    k = campos{i}; v = d.(k);
    if isnumeric(v) && isscalar(v) && isfinite(v)
      fprintf(fid,'%s=%.12g\n',k,v);
    elseif ischar(v)
      fprintf(fid,'%s=%s\n',k,limpiar_txt_local(v));
    endif
  endfor
endfunction

function p = param_local(d)
  p = struct();
  if isstruct(d) && isfield(d,'param') && isstruct(d.param)
    p = d.param;
  else
    global CONFIG_ACTIVA;
    if isstruct(CONFIG_ACTIVA), p = CONFIG_ACTIVA; endif
  endif
endfunction

function n = pozo_local(d,p)
  n = 'pozo';
  if isstruct(d) && isfield(d,'nombre_pozo') && ischar(d.nombre_pozo)
    n = d.nombre_pozo;
  elseif isstruct(p) && isfield(p,'nombre_pozo') && ischar(p.nombre_pozo)
    n = p.nombre_pozo;
  else
    global AOSDAT_ACTIVO;
    if ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO), n = AOSDAT_ACTIVO; endif
  endif
  n = regexprep(n,'[^A-Za-z0-9_-]','_');
endfunction

function g = entrada_local(id,titulo,seccion,estado,ruta)
  g = struct('id',id,'titulo',titulo,'seccion',seccion,'estado',estado,'base64','');
  if ischar(ruta) && ~isempty(ruta) && exist(ruta,'file') == 2 && strcmpi(estado,'OK')
    g.base64 = base64_local(ruta);
    if isempty(g.base64), g.estado = 'ERROR_BASE64'; endif
  endif
endfunction
function s = base64_local(ruta)
  s = ''; fid = fopen(ruta,'rb'); if fid < 0, return; endif
  bytes = fread(fid,Inf,'uint8=>uint8'); fclose(fid);
  try, s = base64_encode(bytes); catch, s = ''; end_try_catch
endfunction
function borrar_local(ruta)
  if ischar(ruta) && ~isempty(ruta) && exist(ruta,'file') == 2, delete(ruta); endif
endfunction
function s = limpiar_txt_local(x)
  if ~ischar(x), x = ''; endif
  s = regexprep(x,'[\r\n=]',' ');
endfunction
function s = limpiar_estado_local(x)
  if ~ischar(x), x = 'DESCONOCIDO'; endif
  s = regexprep(x,'[^A-Za-z0-9]+','_');
endfunction

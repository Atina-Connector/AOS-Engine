function resumen = aos_catalogos_fusionar_desde_aosdat(archivo, modo, opciones)
% AOS_CATALOGOS_FUSIONAR_DESDE_AOSDAT Registra y fusiona catalogos .aosdat.
% El .aosdat sigue siendo la fuente de verdad; no convierte catalogos a un
% formato paralelo. Las secciones reconocidas se copian a la configuracion
% activa y el archivo se registra en datos_usuario/catalogos/aosdat.
  if nargin < 1, archivo=[]; endif
  if nargin < 2 || isempty(modo), modo='EXTERNO'; endif
  if nargin < 3 || isempty(opciones), opciones=struct(); endif
  if ~isstruct(opciones), error('AOS catalogos: opciones debe ser struct.'); endif
  [modo, ok_modo] = aos_texto_seguro(modo, 'EXTERNO');
  if ~ok_modo, modo = 'EXTERNO'; endif
  modo = upper(strtrim(modo));
  registrar=opcion_logica_local(opciones,'registrar',true);
  invalidar=opcion_logica_local(opciones,'invalidar_resultados',true);
  carpeta_registro=opcion_texto_local(opciones,'directorio_registro','');
  resumen=struct('ok',false,'archivo','','secciones',{{}},'registrado','','fusionado',false);

  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  cfg_previa=CONFIG_ACTIVA; aos_previo=AOSDAT_ACTIVO; geo_previa=geologia;
  tiene_previa=~isempty(cfg_previa)&&isstruct(cfg_previa);

  if strcmp(modo,'ACTIVO')
    if ~tiene_previa
      fprintf('No hay un .aosdat activo del cual extraer catalogos.\n'); return;
    endif
    cfg_fuente=cfg_previa;
    archivo=archivo_fuente_local(cfg_previa);
  else
    if isempty(archivo), archivo=seleccionar_local(); endif
    if isempty(archivo), fprintf('Operacion cancelada.\n'); return; endif
    try
      cfg_fuente=importar_aosdat(archivo,struct('activar_caso',false,'imprimir_resumen',false,'normalizar',false));
    catch err
      CONFIG_ACTIVA=cfg_previa; AOSDAT_ACTIVO=aos_previo; geologia=geo_previa;
      fprintf(2,'No se pudo leer el catalogo .aosdat: %s\n',err.message); return;
    end_try_catch
    % Restaurar inmediatamente el caso previo. El catalogo no reemplaza al pozo.
    CONFIG_ACTIVA=cfg_previa; AOSDAT_ACTIVO=aos_previo; geologia=geo_previa;
  endif

  [secciones,nombres]=extraer_local(cfg_fuente);
  if isempty(nombres)
    fprintf('El .aosdat no contiene secciones de catalogo o galeria reconocidas.\n');
    return;
  endif

  destino='';
  if registrar
    destino=registrar_local(archivo,secciones,cfg_fuente,carpeta_registro);
  endif
  resumen.archivo=archivo; resumen.secciones=nombres; resumen.registrado=destino;

  if tiene_previa
    cfg=cfg_previa;
    if ~isfield(cfg,'aosdat_sections')||~isstruct(cfg.aosdat_sections),cfg.aosdat_sections=struct();endif
    for i=1:numel(nombres)
      n=nombres{i};
      cfg.aosdat_sections.(n)=secciones.(n);
      cfg.(n)=secciones.(n);
    endfor
    cfg.catalogos_embebidos_origen=archivo;
    cfg.catalogos_embebidos_fecha=datestr(now,'yyyy-mm-dd HH:MM:SS');
    CONFIG_ACTIVA=cfg;
    resumen.fusionado=true;
    if invalidar, invalidar_resultados_local(); endif
    fprintf('Catalogo fusionado con el caso activo sin reemplazar su configuracion.\n');
  else
    fprintf('Catalogo registrado. No habia un caso activo; se aplicara al abrir o fusionar con un caso.\n');
  endif

  fprintf('Secciones reconocidas: %s\n',strjoin(nombres,', '));
  if registrar
    fprintf('Registro permanente  : %s\n',destino);
  else
    fprintf('Registro permanente  : OMITIDO POR OPCION\n');
  endif
  resumen.ok=true;
endfunction

function [out,nombres]=extraer_local(cfg)
  out=struct(); nombres={};
  if isfield(cfg,'aosdat_sections')&&isstruct(cfg.aosdat_sections)
    secs=cfg.aosdat_sections;
  else
    secs=cfg;
  endif
  fn=fieldnames(secs);
  conocidos={'catalogo','catalogos','mandriles_galeria','galeria','galerias', ...
    'bombas','valvulas','varillas','unidades_bm','unidades_bombeo', ...
    'bes_catalogo','bm_catalogo','gl_catalogo','pcp_catalogo','ldl_catalogo', ...
    'componentes','materiales','proveedores'};
  for i=1:numel(fn)
    n=lower(fn{i});
    es=any(strcmp(n,conocidos)) || ~isempty(strfind(n,'catalog')) || ~isempty(strfind(n,'galeria'));
    if es && isstruct(secs.(fn{i}))
      out.(n)=secs.(fn{i}); nombres{end+1}=n; %#ok<AGROW>
    endif
  endfor
endfunction

function destino=registrar_local(archivo,secciones,cfg,carpeta_override)
  root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
  if nargin>=4 && ~isempty(carpeta_override)
    [carpeta, ok_carpeta] = aos_texto_seguro(carpeta_override, '');
    if ~ok_carpeta || isempty(carpeta)
      error('Directorio de registro invalido.');
    endif
  else
    carpeta=fullfile(root,'datos_usuario','catalogos','aosdat');
  endif
  if exist(carpeta,'dir')~=7,mkdir(carpeta);endif
  if ~isempty(archivo)&&exist(archivo,'file')==2
    [~,base,ext]=fileparts(archivo); if isempty(ext),ext='.aosdat';endif
    destino=fullfile(carpeta,[base ext]);
    if ~strcmp(canon_local(archivo),canon_local(destino)), copyfile(archivo,destino,'f'); endif
  else
    nombre=obtener_texto_local(cfg,{'nombre','nombre_pozo'},['catalogo_' datestr(now,'yyyymmdd_HHMMSS')]);
    nombre=regexprep(nombre,'[^A-Za-z0-9_-]','_');
    destino=fullfile(carpeta,[nombre '.aosdat']);
    escribir_local(destino,secciones,nombre);
  endif
  manifiesto=fullfile(carpeta,'catalogos_registrados.txt');
  fid=fopen(manifiesto,'a');
  if fid~=-1
    fprintf(fid,'%s | %s | %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),destino,strjoin(fieldnames(secciones),','));
    fclose(fid);
  endif
endfunction

function escribir_local(destino,secciones,nombre)
  fid=fopen(destino,'w'); if fid==-1,error('No se pudo crear %s',destino);endif
  fprintf(fid,'[AOS_DATA]\nversion=0.1.9-R2-catalogo\nnombre=%s\nfecha=%s\nsecciones=%s\n\n', ...
    nombre,datestr(now,'yyyy-mm-dd'),upper(strjoin(fieldnames(secciones),',')));
  fn=fieldnames(secciones);
  for i=1:numel(fn)
    fprintf(fid,'[%s]\n',upper(fn{i}));
    escribir_struct_local(fid,secciones.(fn{i}));
    fprintf(fid,'\n');
  endfor
  fclose(fid);
endfunction

function escribir_struct_local(fid,s)
  fn=fieldnames(s);
  for i=1:numel(fn)
    v=s.(fn{i});
    if ischar(v), txt=v;
    elseif isnumeric(v)||islogical(v), txt=mat2str(v);
    else, continue;
    endif
    fprintf(fid,'%s=%s\n',fn{i},txt);
  endfor
endfunction

function archivo=seleccionar_local()
  archivo='';
  try
    [n,r]=uigetfile('*.aosdat','Seleccione catalogo o galeria .aosdat');
    if ischar(n)&&~strcmp(n,'0'),archivo=fullfile(r,n);return;endif
  catch
  end_try_catch
  root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
  carpetas={fullfile(root,'datos','ejemplos','catalogos'),fullfile(root,'datos_usuario','catalogos','aosdat'), ...
    fullfile(root,'intercambio','catalogos','recibidos'),pwd};
  lista={};
  for c=1:numel(carpetas)
    if exist(carpetas{c},'dir')~=7,continue;endif
    d=dir(fullfile(carpetas{c},'*.aosdat'));
    for i=1:numel(d),lista{end+1}=fullfile(carpetas{c},d(i).name);endfor %#ok<AGROW>
  endfor
  if isempty(lista)
    txt=strtrim(input('Ruta completa del catalogo .aosdat (Enter cancela): ','s'));
    if ~isempty(txt),archivo=txt;endif
    return;
  endif
  fprintf('\n--- CATALOGOS/GALERIAS .AOSDAT ---\n');
  for i=1:numel(lista),fprintf('%2d - %s\n',i,lista{i});endfor
  fprintf(' 0 - Cancelar\n');
  op=aos_leer_opcion('Seleccione: ',0);
  if op>=1&&op<=numel(lista),archivo=lista{op};endif
endfunction

function a=archivo_fuente_local(cfg)
  a='';
  campos={'aosdat_archivo','archivo_aosdat'};
  for i=1:numel(campos),if isfield(cfg,campos{i})&&ischar(cfg.(campos{i})),a=cfg.(campos{i});return;endif,endfor
endfunction

function invalidar_resultados_local()
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  ULTIMO_QL=[];ULTIMO_QO=[];ULTIMO_QINY=[];ULTIMO_TIPO=[];ULTIMO_PARAM=[];
  fprintf('Resultados anteriores invalidados por cambio de catalogo/galeria.\n');
endfunction

function txt=obtener_texto_local(s,campos,def)
  txt=def;
  if ~isstruct(s),return;endif
  for i=1:numel(campos)
    campo=campos{i};
    if isfield(s,campo)&&~isempty(s.(campo))
      [candidato,encontrado]=aos_texto_seguro(s.(campo),'');
      if encontrado,txt=candidato;return;endif
    endif
  endfor
endfunction

function v=opcion_logica_local(s,campo,defecto)
  v=defecto;
  if isstruct(s) && isfield(s,campo) && ~isempty(s.(campo))
    [candidato, ok] = aos_logico_seguro(s.(campo), defecto);
    if ok, v = candidato; endif
  endif
endfunction

function v=opcion_texto_local(s,campo,defecto)
  v=defecto;
  if isstruct(s) && isfield(s,campo) && ~isempty(s.(campo))
    [candidato, ok] = aos_texto_seguro(s.(campo), defecto);
    if ok, v = candidato; endif
  endif
endfunction

function p=canon_local(p)
  [p, ok] = aos_texto_seguro(p, '');
  if ~ok, p = ''; return; endif
  p = strrep(p, '\\', '/');
endfunction

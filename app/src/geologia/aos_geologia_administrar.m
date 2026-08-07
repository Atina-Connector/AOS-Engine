function aos_geologia_administrar()
% AOS_GEOLOGIA_ADMINISTRAR Gestion explicita, transaccional y no ambigua.
  global geologia CONFIG_ACTIVA;
  if exist('aos_sincronizar_geologia_activa','file')==2
    try,aos_sincronizar_geologia_activa();catch,end_try_catch
  endif

  while true
    actual=obtener_actual_local(geologia,CONFIG_ACTIVA);
    fprintf('\n--- ADMINISTRAR GEOLOGIA ---\n');
    mostrar_resumen_local(actual,'Geologia activa');
    if isempty(fieldnames(actual))
      fprintf(' 1 - Crear geologia desde configuracion base AOS\n');
      fprintf(' 2 - Cargar geologia desde archivo\n');
      fprintf(' 3 - Administrar / generar punzados sin crear geologia\n');
      fprintf(' 0 - Volver\n');
      op=aos_leer_opcion('Seleccione [0-3]: ',0);
      switch op
        case 1, reemplazar_local(actual,ruta_default_local(),'DEFAULT_AOS');
        case 2, reemplazar_local(actual,'','ARCHIVO_USUARIO');
        case 3, punzados_local(actual);
        case 0, break;
        otherwise,fprintf('Opcion no valida.\n');
      endswitch
    else
      fprintf(' 1 - Ver geologia actual\n');
      fprintf(' 2 - Editar geologia actual\n');
      fprintf(' 3 - Reemplazar geologia desde archivo\n');
      fprintf(' 4 - Reemplazar por configuracion base AOS\n');
      fprintf(' 5 - Administrar / generar intervalos de punzados\n');
      fprintf(' 6 - Exportar geologia y punzados en .aosdat\n');
      fprintf(' 0 - Volver sin cambios\n');
      op=aos_leer_opcion('Seleccione [0-6]: ',0);
      switch op
        case 1,mostrar_detalle_local(actual);
        case 2,editar_local(actual);
        case 3,reemplazar_local(actual,'','ARCHIVO_USUARIO');
        case 4,reemplazar_local(actual,ruta_default_local(),'DEFAULT_AOS');
        case 5,punzados_local(actual);
        case 6,exportar_local();
        case 0,break;
        otherwise,fprintf('Opcion no valida.\n');
      endswitch
    endif
  endwhile
endfunction

function editar_local(actual)
  opciones=struct('modo','EDITAR','geologia_base',actual,'guardar_global',false);
  [candidata,info]=cargar_geologia_interactivo(opciones);
  if ~info.guardado,fprintf('Edicion cancelada; la geologia activa no cambio.\n');return;endif
  aos_geologia_commit(candidata,'EDICION_MANUAL');
  fprintf('Geologia activa actualizada.\n');
endfunction

function reemplazar_local(actual,ruta,origen)
  if isempty(ruta)
    ruta=strtrim(input('Ruta del archivo geologico (Enter cancela): ','s'));
    if isempty(ruta),fprintf('Operacion cancelada.\n');return;endif
  endif
  if exist(ruta,'file')~=2,fprintf(2,'No existe el archivo: %s\n',ruta);return;endif
  try
    candidata=cargar_geologia(ruta);
  catch err
    fprintf(2,'No se pudo cargar la geologia candidata: %s\n',err.message);return;
  end_try_catch
  candidata.archivo=ruta;
  [candidata,continuar]=resolver_punzados_interactivo_local(actual,candidata);
  if ~continuar,fprintf('Reemplazo cancelado; la geologia activa no cambio.\n');return;endif
  fprintf('\nCOMPARACION ANTES DE CONFIRMAR\n');
  mostrar_resumen_local(actual,'Actual');mostrar_resumen_local(candidata,'Candidata');
  if ~aos_preguntar_sn('Confirmar reemplazo de la geologia activa? (s/n) [n]: ',false)
    fprintf('Reemplazo cancelado; la geologia activa no cambio.\n');return;
  endif
  aos_geologia_commit(candidata,origen);
  fprintf('Geologia reemplazada y sincronizada con el caso activo.\n');
endfunction

function [candidata,continuar]=resolver_punzados_interactivo_local(actual,candidata)
  continuar=true;na=n_punzados_local(actual);nn=n_punzados_local(candidata);
  if na==0&&nn==0,return;endif
  fprintf('\nPunzados actuales: %d | punzados de la candidata: %d\n',na,nn);
  fprintf(' 1 - Conservar los punzados activos\n');
  fprintf(' 2 - Usar los punzados de la nueva geologia\n');
  fprintf(' 3 - Fusionar ambos conjuntos y eliminar duplicados\n');
  fprintf(' 0 - Cancelar el reemplazo\n');
  op=aos_leer_opcion('Seleccione [0-3]: ',0);
  switch op
    case 1,modo='CONSERVAR_ACTUALES';
    case 2,modo='USAR_NUEVOS';
    case 3,modo='FUSIONAR';
    otherwise,continuar=false;return;
  endswitch
  [candidata,~]=aos_geologia_resolver_punzados(actual,candidata,modo);
endfunction

function punzados_local(actual)
  opciones=struct('origen','GEOLOGIA');
  if isstruct(actual)&&isfield(actual,'intervalos')
    opciones.punzados_base=actual.intervalos;
    opciones.origen_actual='GEOLOGIA_ACTIVA';
  endif
  [~,info]=aos_punzados_administrar(opciones);
  if info.guardado
    fprintf('Punzados actualizados. La geologia se sincronizo solo si existe.\n');
  elseif info.cancelado
    fprintf('Administracion de punzados cerrada sin modificar el caso.\n');
  endif
endfunction

function exportar_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA)
    fprintf('No hay configuracion activa para exportar.\n');return;
  endif
  try,exportar_aosdat(CONFIG_ACTIVA,[],{'CONFIG','GEOLOGIA','PUNZADOS'});
  catch err,fprintf(2,'No se pudo exportar: %s\n',err.message);end_try_catch
endfunction

function actual=obtener_actual_local(g,cfg)
  actual=struct();
  if isstruct(g)&&~isempty(fieldnames(g)),actual=g;return;endif
  if isstruct(cfg)&&isfield(cfg,'geologia')&&isstruct(cfg.geologia)&&~isempty(fieldnames(cfg.geologia)),actual=cfg.geologia;endif
endfunction

function ruta=ruta_default_local()
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  ruta=fullfile(root,'config','geologia','config_geologia.txt');
endfunction

function mostrar_resumen_local(g,titulo)
  if nargin<2,titulo='Geologia';endif
  if ~isstruct(g)||isempty(fieldnames(g)),fprintf('%s: NO CARGADA\n',titulo);return;endif
  fprintf('%s: tipo=%s | UCS=%s MPa | porosidad=%s | punzados=%d\n',titulo, ...
    valor_local(g,'tipo_formacion','-'),valor_mpa_local(g,'UCS'), ...
    valor_local(g,'porosidad','-'),n_punzados_local(g));
  if isfield(g,'aos_origen_geologia'),fprintf('Origen: %s\n',valor_local(g,'aos_origen_geologia','-'));endif
endfunction

function mostrar_detalle_local(g)
  fprintf('\n--- GEOLOGIA ACTIVA (DETALLE) ---\n');
  fn=fieldnames(g);
  for i=1:numel(fn)
    if strcmp(fn{i},'intervalos'),continue;endif
    [txt,ok]=aos_texto_seguro(g.(fn{i}),'');
    if ok,fprintf('  %-30s = %s\n',fn{i},txt);endif
  endfor
  fprintf('  %-30s = %d tramo(s)\n','intervalos_punzados',n_punzados_local(g));
endfunction
function s=valor_local(g,c,d),s=d;if isfield(g,c),[x,ok]=aos_texto_seguro(g.(c),d);if ok,s=x;endif,endif,endfunction
function s=valor_mpa_local(g,c),s='-';if isfield(g,c),[x,ok]=aos_numero_seguro(g.(c),NaN);if ok&&isfinite(x),s=sprintf('%.3g',x/1e6);endif,endif,endfunction
function n=n_punzados_local(g),n=0;if isstruct(g)&&isfield(g,'intervalos')&&isstruct(g.intervalos)&&isfield(g.intervalos,'tramos'),n=numel(g.intervalos.tramos);endif,endfunction

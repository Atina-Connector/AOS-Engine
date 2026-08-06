function [geol, info] = cargar_geologia_interactivo(opciones)
% CARGAR_GEOLOGIA_INTERACTIVO Editor transaccional de geologia.
% La geologia activa no se modifica hasta elegir Guardar. Sin argumentos,
% edita la geologia activa si existe; de lo contrario carga la base AOS.

  if nargin<1||~isstruct(opciones),opciones=struct();endif
  global geologia CONFIG_ACTIVA;
  guardar_global=opcion_logica_local(opciones,'guardar_global',true);
  base=struct();
  if isfield(opciones,'geologia_base')&&isstruct(opciones.geologia_base)&&~isempty(fieldnames(opciones.geologia_base))
    base=opciones.geologia_base;
  elseif isstruct(geologia)&&~isempty(fieldnames(geologia))
    base=geologia;
  elseif isstruct(CONFIG_ACTIVA)&&isfield(CONFIG_ACTIVA,'geologia')&&isstruct(CONFIG_ACTIVA.geologia)&&~isempty(fieldnames(CONFIG_ACTIVA.geologia))
    base=CONFIG_ACTIVA.geologia;
  endif
  modo=opcion_texto_local(opciones,'modo',ternario_local(isempty(fieldnames(base)),'NUEVA','EDITAR'));
  modo=upper(strtrim(modo));
  ruta=opcion_texto_local(opciones,'ruta','');
  origen='EDICION_MANUAL';

  if strcmp(modo,'EDITAR')&&~isempty(fieldnames(base))
    geol=base;
  else
    if isempty(ruta)
      ruta_default=ruta_default_local();
      fprintf('\n--- CARGA DE GEOLOGIA ---\n');
      ruta=strtrim(input(sprintf('Archivo de configuracion [%s]: ',ruta_default),'s'));
      if isempty(ruta),ruta=ruta_default;endif
    endif
    if exist(ruta,'file')~=2,error('No se encontro el archivo: %s',ruta);endif
    geol=cargar_geologia(ruta);
    geol.archivo=ruta;
    origen='ARCHIVO_GEOLOGIA';
  endif

  info=struct('guardado',false,'cancelado',false,'modo',modo,'origen',origen);
  campos=campos_local();
  while true
    fprintf('\n--- EDITOR GEOLOGICO TRANSACCIONAL ---\n');
    mostrar_resumen_local(geol,campos);
    fprintf(' 1 - Modificar parametros geomecanicos y petrofisicos\n');
    fprintf(' 2 - Administrar intervalos de punzados\n');
    fprintf(' 3 - Ver detalle completo\n');
    fprintf(' 4 - Guardar cambios\n');
    fprintf(' 0 - Cancelar sin modificar la geologia activa\n');
    op=aos_leer_opcion('Seleccione [0-4]: ',0);
    switch op
      case 1,geol=editar_campos_local(geol,campos);
      case 2,geol=editar_punzados_local(geol);
      case 3,mostrar_detalle_local(geol,campos);
      case 4
        info.guardado=true;break;
      case 0
        info.cancelado=true;geol=base;break;
      otherwise,fprintf('Opcion no valida.\n');
    endswitch
  endwhile

  if info.guardado&&guardar_global
    aos_geologia_commit(geol,origen);
  endif
endfunction

function geol=editar_campos_local(geol,campos)
  fprintf('\nEnter conserva el valor actual. Solo se aceptan escalares numericos.\n');
  for i=1:rows(campos)
    campo=campos{i,1};desc=campos{i,2};unidad=campos{i,3};factor_lec=campos{i,4};factor_esc=campos{i,5};
    if ~isfield(geol,campo),continue;endif
    [actual,ok]=aos_numero_seguro(geol.(campo),NaN);if ~ok,continue;endif
    visible=actual*factor_lec;
    if isempty(unidad),prompt=sprintf('  %s [%.12g]: ',desc,visible);
    else,prompt=sprintf('  %s (%s) [%.12g]: ',desc,unidad,visible);endif
    while true
      txt=input(prompt,'s');
      if isempty(strtrim(txt)),break;endif
      [v,valido]=aos_numero_seguro(txt,NaN);
      if valido&&isfinite(v)
        if strcmp(campo,'tipo_formacion')&&(v<1||v>3||abs(v-round(v))>1e-9)
          fprintf('  Valor no valido: tipo_formacion debe ser 1, 2 o 3.\n');continue;
        endif
        geol.(campo)=v*factor_esc;
        if strcmp(campo,'angulo_friccion'),geol.angulo_friccion_rad=v*pi/180;endif
        break;
      endif
      fprintf('  Valor no valido. Ingrese un numero escalar o Enter.\n');
    endwhile
  endfor
endfunction

function geol=editar_punzados_local(geol)
  base=struct('tramos',struct([]));
  if isstruct(geol)&&isfield(geol,'intervalos'),base=geol.intervalos;endif
  opciones=struct('punzados_base',base,'guardar_global',false, ...
    'origen','EDICION_GEOLOGICA','origen_actual','GEOLOGIA_CANDIDATA');
  [candidato,info]=aos_punzados_administrar(opciones);
  if info.guardado
    geol.intervalos=candidato;
  else
    fprintf('Los punzados de la geologia candidata no cambiaron.\n');
  endif
endfunction

function mostrar_resumen_local(geol,campos)
  fprintf('Modo de trabajo: candidato en memoria; activo sin cambios hasta Guardar.\n');
  for i=1:rows(campos)
    campo=campos{i,1};desc=campos{i,2};unidad=campos{i,3};factor=campos{i,4};
    if ~isfield(geol,campo),continue;endif
    [v,ok]=aos_numero_seguro(geol.(campo),NaN);if ~ok,continue;endif
    if isempty(unidad),fprintf('  %-31s: %.6g\n',desc,v*factor);
    else,fprintf('  %-31s: %.6g %s\n',desc,v*factor,unidad);endif
  endfor
  fprintf('  %-31s: %d tramo(s)\n','Intervalos de punzados',n_punzados_local(geol));
endfunction

function mostrar_detalle_local(geol,campos)
  fprintf('\n--- DETALLE DE LA GEOLOGIA CANDIDATA ---\n');
  mostrar_resumen_local(geol,campos);
  fn=fieldnames(geol);
  conocidos=campos(:,1);
  for i=1:numel(fn)
    if any(strcmp(fn{i},conocidos))||strcmp(fn{i},'intervalos'),continue;endif
    [txt,ok]=aos_texto_seguro(geol.(fn{i}),'');if ok,fprintf('  %-31s: %s\n',fn{i},txt);endif
  endfor
endfunction

function campos=campos_local()
  campos={ ...
    'tipo_formacion','Tipo de formacion (1-3)','',1,1; ...
    'UCS','UCS','MPa',1e-6,1e6; ...
    'angulo_friccion','Angulo de friccion','deg',1,1; ...
    'cohesion','Cohesion','MPa',1e-6,1e6; ...
    'modulo_young','Modulo de Young','GPa',1e-9,1e9; ...
    'relacion_poisson','Relacion de Poisson','',1,1; ...
    'esfuerzo_vertical','Esfuerzo vertical (Sv)','MPa',1e-6,1e6; ...
    'esfuerzo_h_min','Esfuerzo horizontal minimo','MPa',1e-6,1e6; ...
    'esfuerzo_H_max','Esfuerzo horizontal maximo','MPa',1e-6,1e6; ...
    'porosidad','Porosidad','',1,1; ...
    'permeabilidad_h','Permeabilidad horizontal','mD',1/9.869233e-16,9.869233e-16; ...
    'permeabilidad_v','Permeabilidad vertical','mD',1/9.869233e-16,9.869233e-16; ...
    'radio_poro','Radio de poro','mm',1,1; ...
    'diametro_grano_medio','Diametro de grano medio','mm',1,1; ...
    'espesor_zona_petrolera','Espesor zona petrolera','m',1,1; ...
    'altura_perforados','Altura de perforados','m',1,1; ...
    'radio_drenaje','Radio de drenaje','m',1,1; ...
    'radio_pozo','Radio del pozo','m',1,1; ...
    'skin_factor','Skin factor','',1,1; ...
    'rho_petroleo','Densidad del petroleo','kg/m3',1,1; ...
    'rho_agua','Densidad del agua','kg/m3',1,1; ...
    'mu_petroleo','Viscosidad del petroleo','Pa.s',1,1; ...
    'B_o','Factor volumetrico B_o','',1,1; ...
    'factor_seguridad','Factor de seguridad','',1,1};
endfunction

function ruta=ruta_default_local()
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  ruta=fullfile(root,'config','geologia','config_geologia.txt');
endfunction
function v=opcion_logica_local(s,c,d),v=d;if isfield(s,c),[x,ok]=aos_logico_seguro(s.(c),d);if ok,v=x;endif,endif,endfunction
function v=opcion_texto_local(s,c,d),v=d;if isfield(s,c),[x,ok]=aos_texto_seguro(s.(c),d);if ok,v=x;endif,endif,endfunction
function n=n_punzados_local(g),n=0;if isstruct(g)&&isfield(g,'intervalos')&&isstruct(g.intervalos)&&isfield(g.intervalos,'tramos'),n=numel(g.intervalos.tramos);endif,endfunction
function out=ternario_local(c,a,b),if c,out=a;else,out=b;endif,endfunction

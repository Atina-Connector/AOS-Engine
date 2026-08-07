function AOS_menu_catalogos()
% AOS_MENU_CATALOGOS Catalogos base, usuario y embebidos en .aosdat.
  while true
    fprintf('\n--- ADMINISTRACION DE CATALOGOS ---\n');
    fprintf(' 1 - Importar/registrar catalogo desde archivo .aosdat\n');
    fprintf(' 2 - Extraer y registrar catalogos del .aosdat activo\n');
    fprintf(' 3 - Catalogos base AOS (solo lectura)\n');
    fprintf(' 4 - Catalogos permanentes del usuario\n');
    fprintf(' 5 - Catalogos embebidos en el .aosdat activo\n');
    fprintf(' 6 - Galerias de mandriles y galerias CAD\n');
    fprintf(' 7 - Catalogos GL / JGL / mandriles\n');
    fprintf(' 8 - Catalogos BES V1 / V2\n');
    fprintf(' 9 - Catalogos BM\n');
    fprintf('10 - Catalogos CGF / EGF\n');
    fprintf('11 - Catalogos PCP / LDL\n');
    fprintf('12 - Validar estructura de catalogos\n');
    fprintf('13 - Ejecutar round-trip de catalogos R2\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, aos_catalogos_fusionar_desde_aosdat([], 'EXTERNO');
      case 2, aos_catalogos_fusionar_desde_aosdat([], 'ACTIVO');
      case 3, AOS_catalogos_listar_tipo('TODOS');
      case 4, listar_usuario_local();
      case 5, aos_mostrar_seccion_activa({'catalogos','catalogo','mandriles_galeria','galeria','galerias','bombas','valvulas','varillas','unidades_bm'},'CATALOGOS EMBEBIDOS EN AOSDAT');
      case 6, AOS_menu_galerias();
      case 7, AOS_catalogos_listar_tipo('GL');
      case 8, AOS_catalogos_listar_tipo('BES'); listar_local(fullfile('config','BES_V2','catalogo'));
      case 9, AOS_catalogos_listar_tipo('BM');
      case 10, fprintf('CGF:\n');listar_local(fullfile('config','CGF','catalogo'));fprintf('EGF:\n');listar_local(fullfile('config','EGF','catalogo'));
      case 11, listar_local(fullfile('config','PCP','catalogo')); listar_local(fullfile('config','LDL','catalogo'));
      case 12, validar_local();
      case 13, ejecutar_roundtrip_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function listar_usuario_local()
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  c=fullfile(root,'datos_usuario','catalogos');
  if exist(c,'dir')~=7,mkdir(c);endif
  fprintf('Catalogos permanentes: %s\n',c);
  listar_recursivo_local(c);
endfunction

function listar_local(c)
  if exist(c,'dir')~=7,fprintf('  (carpeta aun no creada: %s)\n',c);return;endif
  d=dir(fullfile(c,'*'));d=d(~[d.isdir]);
  if isempty(d),fprintf('  (sin catalogos)\n');return;endif
  for i=1:numel(d),fprintf('  - %s\n',d(i).name);endfor
endfunction

function listar_recursivo_local(c)
  d=dir(c);n=0;
  for i=1:numel(d)
    if strcmp(d(i).name,'.')||strcmp(d(i).name,'..'),continue;endif
    p=fullfile(c,d(i).name);
    if d(i).isdir,listar_recursivo_local(p);else,fprintf('  - %s\n',p);n=n+1;endif
  endfor
  if n==0,fprintf('  (sin archivos en este nivel)\n');endif
endfunction

function validar_local()
  carpetas={fullfile('config','GL'),fullfile('config','BES'),fullfile('config','BES_V2'), ...
            fullfile('config','BM'),fullfile('config','CGF'),fullfile('config','EGF'), ...
            fullfile('config','PCP'),fullfile('config','LDL'),fullfile('datos_usuario','catalogos')};
  fprintf('\nVALIDACION DE CATALOGOS\n');
  for i=1:numel(carpetas)
    if exist(carpetas{i},'dir')==7,fprintf('OK      %s\n',carpetas{i});else,fprintf('FALTA   %s\n',carpetas{i});endif
  endfor
  funciones={'importar_aosdat','exportar_aosdat','aos_catalogos_fusionar_desde_aosdat','mandriles_cargar_galeria'};
  for i=1:numel(funciones)
    if exist(funciones{i},'file')==2,e='OK';else,e='FALTA';endif
    fprintf('%-7s %s\n',e,funciones{i});
  endfor
endfunction

function ejecutar_roundtrip_local()
  if exist('test_aos_catalogos_roundtrip_r2','file')~=2
    fprintf('Selftest R2 no disponible. Ejecute iniciar_aos(true).\n');
    return;
  endif
  try
    test_aos_catalogos_roundtrip_r2();
  catch err
    fprintf(2,'FALLO catalogos R2: %s\n',err.message);
  end_try_catch
endfunction

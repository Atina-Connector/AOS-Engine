function AOS_menu_galerias()
% AOS_MENU_GALERIAS Galerias de componentes y galerias fisicas CAD.
  while true
    imprimir_estado_local();
    fprintf('\n--- GALERIAS AOS ---\n');
    fprintf(' 1 - Importar/registrar galeria de mandriles desde .aosdat\n');
    fprintf(' 2 - Fusionar al caso activo o registrar galeria completa incluida\n');
    fprintf(' 3 - Ver galeria de mandriles efectiva del caso activo\n');
    fprintf(' 4 - Ver secciones de galeria/catalogo embebidas en el .aosdat\n');
    fprintf(' 5 - Importar plano DXF de galerias, camaras, ramales y accesos\n');
    fprintf(' 6 - Cargar ejemplo AOS de galerias CAD\n');
    fprintf(' 7 - Ver tablas de galerias CAD activas\n');
    fprintf(' 8 - Ejecutar selftest de galerias CAD\n');
    fprintf(' 9 - Ejecutar selftest de galeria de mandriles .aosdat\n');
    fprintf('10 - Ejecutar todos los selftests de galerias\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, aos_catalogos_fusionar_desde_aosdat([], 'EXTERNO');
      case 2, cargar_ejemplo_mandriles_local();
      case 3, mostrar_mandriles_local();
      case 4, aos_mostrar_seccion_activa({'mandriles_galeria','galeria','galerias','catalogo','catalogos'},'GALERIAS Y CATALOGOS EMBEBIDOS');
      case 5, try_local(@() aos_cad_importar_dxf());
      case 6, cargar_ejemplo_cad_local();
      case 7, aos_mostrar_seccion_activa({'galerias','camaras','ramales','accesos','cad_topologia','modelo_aoscad'},'GALERIAS CAD ACTIVAS');
      case 8, ejecutar_test_cad_local();
      case 9, ejecutar_test_mandriles_local();
      case 10, ejecutar_test_cad_local(); ejecutar_test_mandriles_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function imprimir_estado_local()
  global CONFIG_ACTIVA;
  n=0; fuente='SIN CASO ACTIVO';
  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA)
    try
      [g,fuente]=mandriles_cargar_galeria(CONFIG_ACTIVA);
      n=numel(g);
    catch
      n=0; fuente='NO EVALUADA';
    end_try_catch
  endif
  fprintf('\nGaleria mandriles : %s | elementos=%d\n',fuente,n);
endfunction

function cargar_ejemplo_mandriles_local()
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  archivo=fullfile(root,'datos','ejemplos','catalogos','AOS_GALERIA_MANDRILES_COMPLETA.aosdat');
  if exist(archivo,'file')~=2
    fprintf('No se encontro el ejemplo: %s\n',archivo); return;
  endif
  aos_catalogos_fusionar_desde_aosdat(archivo,'EXTERNO');
endfunction

function mostrar_mandriles_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA)
    fprintf('No hay caso activo. Importe primero un .aosdat de pozo o caso.\n'); return;
  endif
  try
    [g,fuente,avisos]=mandriles_cargar_galeria(CONFIG_ACTIVA);
    fprintf('\nFuente: %s | elementos: %d\n',fuente,numel(g));
    fprintf('%-4s %-26s %-18s %-10s %-10s %-8s\n','N','ID','VALVULA','RATING','QMAX','STOCK');
    for i=1:numel(g)
      fprintf('%-4d %-26s %-18s %-10.1f %-10.0f %-8.0f\n',i,g(i).id,g(i).valvula,g(i).rating_bar,g(i).Qmax_Sm3_d,g(i).stock);
    endfor
    for i=1:numel(avisos), fprintf('AVISO: %s\n',avisos{i}); endfor
  catch err
    fprintf(2,'No se pudo leer la galeria: %s\n',err.message);
  end_try_catch
endfunction

function cargar_ejemplo_cad_local()
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  archivo=fullfile(root,'datos','ejemplos','cad','demo_aos_galerias.dxf');
  if exist(archivo,'file')~=2, fprintf('No se encontro %s\n',archivo); return; endif
  try_local(@() aos_cad_importar_dxf(archivo,false));
endfunction

function ejecutar_test_cad_local()
  if exist('test_aos_cad_galerias','file')==2
    try_local(@() test_aos_cad_galerias());
  else
    fprintf('Selftest de galerias CAD no disponible.\n');
  endif
endfunction

function ejecutar_test_mandriles_local()
  if exist('test_aos_galeria_mandriles_r2','file')==2
    try_local(@() test_aos_galeria_mandriles_r2());
  else
    fprintf('Selftest de galeria de mandriles R2 no disponible. Ejecute iniciar_aos(true).\n');
  endif
endfunction

function try_local(fn)
  try, fn(); catch err, fprintf(2,'Error de galerias: %s\n',err.message); end_try_catch
endfunction

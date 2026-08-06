function ok = test_menu_geometria_visible_r1()
% Prueba no grafica del menu y utilidades de geometria.
  global CONFIG_ACTIVA geologia AOSDAT_ACTIVO;
  respaldo_cfg = CONFIG_ACTIVA;
  respaldo_geo = geologia;
  respaldo_aosdat = AOSDAT_ACTIVO;
  limpiar = onCleanup(@() restaurar_local(respaldo_cfg, respaldo_geo, respaldo_aosdat));

  CONFIG_ACTIVA = struct();
  CONFIG_ACTIVA.nombre_pozo = 'POZO_PRUEBA';
  CONFIG_ACTIVA.survey = struct('MD', [0; 1000; 2000], ...
                                'TVD', [0; 995; 1950], ...
                                'inclinacion', [0; 8; 15], ...
                                'azimut', [0; 45; 60], ...
                                'ID_tubing', 0.062 * ones(3,1));
  CONFIG_ACTIVA.punzados = struct('tramos', ...
    struct('MD_desde', 1800, 'MD_hasta', 1850, 'densidad_tpm', 13, ...
           'nombre', 'Zona A', 'activo', true));
  geologia = [];
  AOSDAT_ACTIVO = 'prueba.aosdat';

  [s, p, info] = aos_obtener_geometria_activa();
  assert(numel(s.MD) == 3);
  assert(numel(p.tramos) == 1);
  assert(strcmp(info.pozo, 'POZO_PRUEBA'));

  r = aos_validar_geometria_pozo(s, p, false);
  assert(r.ok);

  carpeta = tempname();
  mkdir(carpeta);
  archivos = aos_exportar_geometria_pozo(s, p, info, carpeta, 'prueba');
  assert(numel(archivos) == 3);
  for i = 1:numel(archivos)
    assert(exist(archivos{i}, 'file') == 2);
  endfor
  aos_rmdir_seguro(carpeta, tempdir());

  root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  menu = fileread(fullfile(root, 'src', 'menu', 'AOS_menu_importar_exportar.m'));
  submenu = fileread(fullfile(root, 'src', 'menu', 'AOS_menu_datos_pozo.m'));
  assert(~isempty(strfind(menu, 'Pozo: survey, punzados y completacion')));
  assert(~isempty(strfind(submenu, 'Visualizar survey 2D')));
  assert(~isempty(strfind(submenu, 'Ver tabla de punzados')));

  ok = true;
  fprintf('TEST MENU GEOMETRIA R1: OK.\n');
endfunction

function restaurar_local(cfg, geo, aosdat)
  global CONFIG_ACTIVA geologia AOSDAT_ACTIVO;
  CONFIG_ACTIVA = cfg;
  geologia = geo;
  AOSDAT_ACTIVO = aosdat;
endfunction

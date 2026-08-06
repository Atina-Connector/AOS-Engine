function ok = test_aos_environmental_runtime_shell_env02()
% TEST_AOS_ENVIRONMENTAL_RUNTIME_SHELL_ENV02 Verifica alta runtime del banco.
  ok = false;
  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));

  assert(exist('AOS_menu_environmental', 'file') == 2);
  assert(exist('AOS_menu_gestion_ambiental', 'file') == 2);

  productos = aos_suite_registro_productos();
  ids = {productos.id};
  i_scada = find(strcmp(ids, 'SCADA'), 1);
  i_env = find(strcmp(ids, 'ENVIRONMENTAL'), 1);
  i_maint = find(strcmp(ids, 'MAINTENANCE'), 1);
  i_viewer = find(strcmp(ids, 'VIEWER'), 1);
  assert(numel(productos) == 15);
  assert(~isempty(i_scada) && ~isempty(i_env) && ~isempty(i_maint));
  assert(i_scada < i_env && i_env < i_maint);
  assert(i_viewer == numel(productos));
  assert(productos(i_env).disponible);

  app = fileread(fullfile(raiz, 'src', 'menu', 'AOS_app.m'));
  assert(~isempty(strfind(app, '11 - AOS ENVIRONMENTAL')));
  assert(~isempty(strfind(app, 'case 11, AOS_menu_environmental();')));
  assert(~isempty(strfind(app, 'Seleccione [0-19]')));

  menu_env = fileread(fullfile(raiz, 'src', 'menu', 'AOS_menu_environmental.m'));
  assert(~isempty(strfind(menu_env, 'aos_menu_abrir_contextual(''ENVIRONMENTAL'')')));
  assert(~isempty(strfind(menu_env, 'AOS_menu_cad_topologia')));
  assert(~isempty(strfind(menu_env, 'AOS_menu_scada')));
  assert(~isempty(strfind(menu_env, 'AOS_menu_maintenance')));

  legacy = fileread(fullfile(raiz, 'src', 'menu', 'AOS_menu_gestion_ambiental.m'));
  assert(~isempty(strfind(legacy, 'AOS_menu_environmental')));

  maintenance = fileread(fullfile(raiz, 'src', 'menu', 'AOS_menu_maintenance.m'));
  assert(~isempty(strfind(maintenance, 'BANCO INDEPENDIENTE')));
  assert(~isempty(strfind(maintenance, 'AOS_menu_environmental')));

  ok = true;
  fprintf('RESULTADO: test_aos_environmental_runtime_shell_env02 APROBADO\n');
endfunction

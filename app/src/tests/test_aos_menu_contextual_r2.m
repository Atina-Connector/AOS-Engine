function ok = test_aos_menu_contextual_r2()
% TEST_AOS_MENU_CONTEXTUAL_R2 Verifica acceso universal y contextual.
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));ok=true;
  menu=fileread(fullfile(root,'src','menu','AOS_app.m'));
  requeridos={'NUEVO / ABRIR / IMPORTAR / CONFIGURAR CASO','AOS_menu_gestion_caso', ...
    'AOS SLA','AOS FLUIDS','AOS SOLVERS','ROADMAP GENERAL','AOS VIEWER'};
  for i=1:numel(requeridos),assert(~isempty(strfind(upper(menu),upper(requeridos{i}))));endfor
  menus={'AOS_menu_SLA.m','AOS_menu_BM.m','AOS_menu_GL_JGL.m','AOS_menu_BES.m', ...
    'AOS_menu_PCP.m','AOS_menu_CGF.m','AOS_menu_EGF.m','AOS_menu_networks.m', ...
    'AOS_menu_electrical.m','AOS_menu_facilities.m','AOS_menu_geology.m', ...
    'AOS_menu_fluidos.m','AOS_menu_wells.m','AOS_menu_scada.m','AOS_menu_maintenance.m'};
  for i=1:numel(menus)
    t=fileread(fullfile(root,'src','menu',menus{i}));
    assert(~isempty(strfind(t,'aos_menu_abrir_contextual')));
  endfor
  bes=fileread(fullfile(root,'src','menu','AOS_menu_BES.m'));
  assert(~isempty(strfind(bes,'BES3_menu')));
  assert(~isempty(strfind(bes,'bes3_comparar_v1_v2_v3')));
  fprintf('RESULTADO: test_aos_menu_contextual_r2 APROBADO\n');
endfunction

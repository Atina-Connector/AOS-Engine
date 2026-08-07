function aos_menu_abrir_contextual(contexto)
% AOS_MENU_ABRIR_CONTEXTUAL Apertura/importacion segun banco o modulo.
  if nargin<1||isempty(contexto),contexto='GENERAL';endif
  contexto=upper(char(contexto));
  if any(strcmp(contexto,{'BM','BES','GL','JGL','GL_JGL','PCP','LDL','CGF','EGF','SLA'}))
    menu_sla_local(contexto);
  elseif any(strcmp(contexto,{'CAD','NETWORKS','FACILITIES','ELECTRICAL'}))
    menu_cad_local(contexto);
  elseif any(strcmp(contexto,{'WELLS','GEOLOGY'}))
    menu_pozo_local(contexto);
  elseif strcmp(contexto,'FLUIDS')
    menu_fluidos_local();
  else
    AOS_menu_gestion_caso(contexto);
  endif
endfunction

function menu_sla_local(contexto)
  while true
    fprintf('\n--- ABRIR / IMPORTAR CASO %s ---\n',contexto);
    fprintf(' 1 - Abrir modelo .aosdat y dejarlo activo\n');
    fprintf(' 2 - Abrir reporte .aosrpt / reconstruir caso\n');
    fprintf(' 3 - Ver o editar configuracion efectiva\n');
    fprintf(' 4 - Survey, punzados, geologia y estado mecanico\n');
    fprintf(' 5 - Catalogos y galerias .aosdat\n');
    fprintf(' 6 - Historiales y datos AOS SCADA\n');
    fprintf(' 7 - Gestion completa del caso\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, ejecutar_local(@() importar_aosdat());
      case 2, ejecutar_local(@() importar_aosrpt());
      case 3, AOS_menu_configuracion();
      case 4, AOS_menu_datos_pozo();
      case 5, AOS_menu_catalogos();
      case 6, AOS_menu_scada();
      case 7, AOS_menu_gestion_caso(contexto);
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_cad_local(contexto)
  while true
    fprintf('\n--- ABRIR / IMPORTAR %s ---\n',contexto);
    fprintf(' 1 - Abrir proyecto .aoscad\n');
    fprintf(' 2 - Importar DXF\n');
    fprintf(' 3 - Importar STEP\n');
    fprintf(' 4 - Abrir / crear componente .aosbck\n');
    fprintf(' 5 - Abrir reporte .aosrpt\n');
    fprintf(' 6 - Abrir modelo/configuracion .aosdat\n');
    fprintf(' 7 - Galerias CAD / DXF\n');
    fprintf(' 8 - Gestion completa del caso\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, ejecutar_local(@() aos_aoscad_abrir_en_suite([],false));
      case 2, ejecutar_local(@() aos_cad_importar_dxf());
      case 3, ejecutar_local(@() aos_cad_importar_step());
      case 4, AOS_menu_aosbck(contexto);
      case 5, ejecutar_local(@() importar_aosrpt());
      case 6, ejecutar_local(@() importar_aosdat());
      case 7, AOS_menu_galerias();
      case 8, AOS_menu_gestion_caso(contexto);
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_pozo_local(contexto)
  while true
    fprintf('\n--- ABRIR / IMPORTAR %s ---\n',contexto);
    fprintf(' 1 - Abrir .aosdat completo\n');
    fprintf(' 2 - Abrir .aosrpt\n');
    fprintf(' 3 - Survey, punzados y estado mecanico\n');
    fprintf(' 4 - Componentes AOSBCK por Survey\n');
    fprintf(' 5 - Catalogos y galerias\n');
    fprintf(' 6 - Gestion completa del caso\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, ejecutar_local(@() importar_aosdat());
      case 2, ejecutar_local(@() importar_aosrpt());
      case 3, AOS_menu_datos_pozo();
      case 4, AOS_menu_aosbck('WELLS');
      case 5, AOS_menu_catalogos();
      case 6, AOS_menu_gestion_caso(contexto);
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_fluidos_local()
  while true
    fprintf('\n--- ABRIR / IMPORTAR AOS FLUIDS ---\n');
    fprintf(' 1 - Abrir modelo .aosdat / fluido embebido\n');
    fprintf(' 2 - Abrir .aosrpt y recuperar parametros efectivos\n');
    fprintf(' 3 - Importar datos de laboratorio o planilla\n');
    fprintf(' 4 - Ver catalogos/modelos de fluidos\n');
    fprintf(' 5 - Gestion completa del caso\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, ejecutar_local(@() importar_aosdat());
      case 2, ejecutar_local(@() importar_aosrpt());
      case 3, AOS_menu_formatos_externos();
      case 4, AOS_menu_catalogos();
      case 5, AOS_menu_gestion_caso('FLUIDS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function ejecutar_local(f)
  try,f();catch err,fprintf(2,'ERROR: %s\n',err.message);end_try_catch
endfunction

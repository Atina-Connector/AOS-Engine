function AOS_app()
% AOS_APP Lanzador modular de AOS Suite 0.2.0 DEV1.
% R2 consolida gestion universal de casos, catalogos y galerias.
  clc;
  iniciar_aos();
  AOS_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  cd(AOS_root);

  while true
    imprimir_estado_local();
    fprintf('\n================================================================\n');
    fprintf(' AOS SUITE 0.2.0 DEV1 - DESARROLLO MODULAR DISTRIBUIDO\n');
    fprintf(' AESIR Oilfield Systems | Plataforma modular GNU Octave\n');
    fprintf('================================================================\n');
    fprintf(' 1 - NUEVO / ABRIR / IMPORTAR / CONFIGURAR CASO [TRANSVERSAL]\n');
    fprintf(' 2 - AOS SLA          %s\n', aos_suite_etiqueta_producto('SLA'));
    fprintf(' 3 - AOS WELLS        %s\n', aos_suite_etiqueta_producto('WELLS'));
    fprintf(' 4 - AOS CAD          %s\n', aos_suite_etiqueta_producto('CAD'));
    fprintf(' 5 - AOS NETWORKS     %s\n', aos_suite_etiqueta_producto('NETWORKS'));
    fprintf(' 6 - AOS ELECTRICAL   %s\n', aos_suite_etiqueta_producto('ELECTRICAL'));
    fprintf(' 7 - AOS FACILITIES   %s\n', aos_suite_etiqueta_producto('FACILITIES'));
    fprintf(' 8 - AOS GEOLOGY      %s\n', aos_suite_etiqueta_producto('GEOLOGY'));
    fprintf(' 9 - AOS FLUIDS       %s\n', aos_suite_etiqueta_producto('FLUIDS'));
    fprintf('10 - AOS SCADA        %s\n', aos_suite_etiqueta_producto('SCADA'));
    fprintf('11 - AOS ENVIRONMENTAL %s\n', aos_suite_etiqueta_producto('ENVIRONMENTAL'));
    fprintf('12 - AOS MAINTENANCE  %s\n', aos_suite_etiqueta_producto('MAINTENANCE'));
    fprintf('13 - AOS DATA         %s\n', aos_suite_etiqueta_producto('DATA'));
    fprintf('14 - AOS SOLVERS      %s\n', aos_suite_etiqueta_producto('SOLVERS'));
    fprintf('15 - AOS GLOBAL       %s\n', aos_suite_etiqueta_producto('GLOBAL'));
    fprintf('16 - ROADMAP GENERAL DE AOS\n');
    fprintf('17 - Configuracion, versiones y diagnosticos\n');
    fprintf('18 - AOS VIEWER       %s\n', aos_suite_etiqueta_producto('VIEWER'));
    fprintf('19 - Menu AOS 0.1.9 historico [COMPATIBILIDAD]\n');
    fprintf(' 0 - Salir\n');

    op = aos_leer_opcion('Seleccione [0-19]: ', []);
    switch op
      case 1, AOS_menu_gestion_caso('SUITE');
      case 2, AOS_menu_SLA();
      case 3, AOS_menu_wells();
      case 4, AOS_menu_cad_topologia();
      case 5, AOS_menu_networks();
      case 6, AOS_menu_electrical();
      case 7, AOS_menu_facilities();
      case 8, AOS_menu_geology();
      case 9, AOS_menu_fluidos();
      case 10, AOS_menu_scada();
      case 11, AOS_menu_environmental();
      case 12, AOS_menu_maintenance();
      case 13, AOS_menu_data();
      case 14, AOS_menu_solvers();
      case 15, AOS_menu_global();
      case 16, AOS_menu_roadmap();
      case 17, AOS_menu_suite_config_diag();
      case 18, AOS_menu_viewer();
      case 19, AOS_menu_suite_compat_r1();
      case 0
        if confirmar_salida_local(), break; endif
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function imprimir_estado_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('\nCaso activo: NINGUNO | Use opcion 1 para abrir/importar.\n');
  else
    try
      CONFIG_ACTIVA = aos_normalizar_config(CONFIG_ACTIVA, 'GENERAL');
      aos_sincronizar_geologia_activa();
    catch err
      fprintf('ADVERTENCIA AOS: %s\n', err.message);
    end_try_catch
    try
      aos_menu_imprimir_resumen_config(CONFIG_ACTIVA, AOSDAT_ACTIVO, geologia);
    catch
    end_try_catch
  endif
  if ~isempty(ULTIMO_QL) && isstruct(ULTIMO_PARAM)
    try
      aos_menu_imprimir_ultima_corrida(ULTIMO_PARAM, ULTIMO_QL, ULTIMO_QO, ...
        ULTIMO_QINY, ULTIMO_TIPO);
    catch
    end_try_catch
  endif
endfunction

function salir = confirmar_salida_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  salir = false;
  if ~aos_preguntar_sn('Salir de AOS Suite? (s/n) [n]: ', false), return; endif
  limpiar = aos_preguntar_sn('Eliminar la configuracion activa de memoria? (s/n) [n]: ', false);
  if limpiar
    CONFIG_ACTIVA = []; AOSDAT_ACTIVO = ''; geologia = [];
    ULTIMO_QL = []; ULTIMO_QO = []; ULTIMO_QINY = [];
    ULTIMO_TIPO = []; ULTIMO_PARAM = [];
  endif
  fprintf('Saliendo de AOS Suite...\n');
  salir = true;
endfunction

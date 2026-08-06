function AOS_menu_wells()
% AOS_MENU_WELLS Banco de trabajo de pozos y completacion.
  while true
    fprintf('\n--- AOS WELLS [BETA / ROADMAP] ---\n');
    fprintf(' 1 - Survey, punzados y completacion [ACTIVO]\n');
    fprintf(' 2 - Trayectoria y estado mecanico 3D\n');
    fprintf(' 3 - Integridad, barreras y estado mecanico [ROADMAP]\n');
    fprintf(' 4 - Componentes de completacion AOSBCK por Survey [BETA R1]\n');
    fprintf(' 5 - Dominios hidraulicos dentro del pozo [ROADMAP]\n');
    fprintf(' 6 - Abrir AOS SLA\n');
    fprintf(' 7 - Consultar AOS SCADA\n');
    fprintf(' 8 - Consultar AOS Maintenance\n');
    fprintf(' 9 - Estado y roadmap de AOS Wells\n');
    fprintf('10 - Abrir / importar / configurar pozo, survey o .aosdat\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, AOS_menu_datos_pozo();
      case 2, AOS_menu_3d_core('WELLS');
      case 3, aos_modulo_no_disponible('INTEGRIDAD', 'Integridad y barreras del pozo');
      case 4, AOS_menu_aosbck('WELLS');
      case 5, aos_modulo_no_disponible('WELLS', 'Dominio hidraulico de completacion');
      case 6, AOS_menu_SLA();
      case 7, AOS_menu_scada();
      case 8, AOS_menu_maintenance();
      case 9, aos_workbench_mostrar_ficha('WELLS');
      case 10, aos_menu_abrir_contextual('WELLS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

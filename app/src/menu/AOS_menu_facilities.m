function AOS_menu_facilities()
% AOS_MENU_FACILITIES Instalaciones de superficie y procesos.
  while true
    fprintf('\n--- AOS FACILITIES [ROADMAP] ---\n');
    fprintf(' 1 - Baterias e instalaciones\n');
    fprintf(' 2 - Redes hidraulicas de superficie\n');
    fprintf(' 3 - Sistemas electricos de superficie\n');
    fprintf(' 4 - Fluidos y aseguramiento de flujo\n');
    fprintf(' 5 - CAD y modelo 3D de instalaciones\n');
    fprintf(' 6 - Historiales y operacion SCADA\n');
    fprintf(' 7 - Balances de masa y energia [ROADMAP]\n');
    fprintf(' 8 - Capacidad y restricciones [ROADMAP]\n');
    fprintf(' 9 - Estado y roadmap de AOS Facilities\n');
    fprintf('10 - Componentes AOSBCK y visualizacion 3D [BETA R1]\n');
    fprintf('11 - Abrir / importar / configurar instalacion\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, AOS_menu_baterias();
      case 2, AOS_menu_networks();
      case 3, AOS_menu_electrical();
      case 4, AOS_menu_fluidos();
      case 5, AOS_menu_3d_core('FACILITIES');
      case 6, AOS_menu_scada();
      case 7, aos_modulo_no_disponible('BATERIAS', 'Balance de masa y energia');
      case 8, aos_modulo_no_disponible('BATERIAS', 'Capacidad y restricciones');
      case 9, aos_workbench_mostrar_ficha('FACILITIES');
      case 10, AOS_menu_aosbck('FACILITIES');
      case 11, aos_menu_abrir_contextual('FACILITIES');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

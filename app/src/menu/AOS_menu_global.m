function AOS_menu_global()
% AOS_MENU_GLOBAL Orquestador conceptual; no duplica solvers.
  while true
    fprintf('\n--- AOS GLOBAL [CONCEPTUAL] ---\n');
    fprintf('AOS Global orquestara workbenches, servicios y solvers versionados.\n');
    fprintf(' 1 - Pozos y AOS SLA\n');
    fprintf(' 2 - Redes e infraestructura\n');
    fprintf(' 3 - Electricidad e instalaciones\n');
    fprintf(' 4 - Geologia y reservorio\n');
    fprintf(' 5 - Fluidos\n');
    fprintf(' 6 - SCADA y operacion\n');
    fprintf(' 7 - Maintenance, economia y HSE\n');
    fprintf(' 8 - AOS 3D Core federado\n');
    fprintf(' 9 - AOS Solvers\n');
    fprintf('10 - Analisis integral heredado\n');
    fprintf('11 - Estado y roadmap de AOS Global\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_wells();
      case 2, AOS_menu_networks();
      case 3, AOS_menu_facilities();
      case 4, AOS_menu_geology();
      case 5, AOS_menu_fluidos();
      case 6, AOS_menu_scada();
      case 7, AOS_menu_maintenance();
      case 8, AOS_menu_3d_core('GLOBAL');
      case 9, AOS_menu_solvers();
      case 10, AOS_menu_analisis_integral();
      case 11, aos_workbench_mostrar_ficha('GLOBAL');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

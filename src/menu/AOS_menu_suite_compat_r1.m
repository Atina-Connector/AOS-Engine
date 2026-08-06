function AOS_menu_suite_compat_r1()
% Mapeo exacto del menu principal AOS 0.1.9 R1 antes de R1.1.
  while true
    fprintf('\n--- MENU AOS 0.1.9 R1 [COMPATIBILIDAD] ---\n');
    fprintf(' 1 - AOS SLA\n 2 - AOS WELLS\n 3 - AOS CAD\n 4 - AOS NETWORKS\n');
    fprintf(' 5 - AOS ELECTRICAL\n 6 - AOS FACILITIES\n 7 - AOS GEOLOGY\n 8 - AOS FLUIDS\n');
    fprintf(' 9 - AOS SCADA\n10 - AOS MAINTENANCE\n11 - AOS DATA\n12 - AOS SOLVERS\n');
    fprintf('13 - AOS GLOBAL\n14 - ROADMAP\n15 - Configuracion/diagnosticos\n16 - AOS VIEWER\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_SLA(); case 2, AOS_menu_wells(); case 3, AOS_menu_cad_topologia();
      case 4, AOS_menu_networks(); case 5, AOS_menu_electrical(); case 6, AOS_menu_facilities();
      case 7, AOS_menu_geology(); case 8, AOS_menu_fluidos(); case 9, AOS_menu_scada();
      case 10, AOS_menu_maintenance(); case 11, AOS_menu_data(); case 12, AOS_menu_solvers();
      case 13, AOS_menu_global(); case 14, AOS_menu_roadmap(); case 15, AOS_menu_suite_config_diag();
      case 16, AOS_menu_viewer(); case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function AOS_menu_networks()
% AOS_MENU_NETWORKS Banco de redes, separado del editor CAD.
  while true
    fprintf('\n--- AOS NETWORKS [BETA] ---\n');
    fprintf(' 1 - Red hidraulica desde DXF [ACTIVO]\n');
    fprintf(' 2 - Seleccionar dominio: inicio, fin, camino o anillo [ACTIVO]\n');
    fprintf(' 3 - Abrir ingenieria completa en AOS CAD\n');
    fprintf(' 4 - Visualizacion 3D transversal\n');
    fprintf(' 5 - Registro de solvers hidraulicos\n');
    fprintf(' 6 - Red abierta y ramificada [BETA]\n');
    fprintf(' 7 - Anillos y lazos tipo Kirchhoff [ROADMAP]\n');
    fprintf(' 8 - Redes de gas y recoleccion [ROADMAP]\n');
    fprintf(' 9 - Redes de agua e inyeccion [ROADMAP]\n');
    fprintf('10 - Ver datos y resultados de red\n');
    fprintf('11 - Estado y roadmap de AOS Networks\n');
    fprintf('12 - Componentes AOSBCK y visualizacion 3D [BETA R1]\n');
    fprintf('13 - Abrir / importar / configurar red, .aoscad o .aosdat\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, aos_cad_hidraulica_menu();
      case 2, aos_cad_hidraulica_dominio_menu();
      case 3, AOS_menu_cad_topologia();
      case 4, AOS_menu_3d_core('NETWORKS');
      case 5, aos_solvers_menu_disciplina('HYDRAULIC');
      case 6, aos_cad_hidraulica_menu();
      case 7, aos_modulo_no_disponible('NETWORKS', 'Solver de anillos tipo Kirchhoff');
      case 8, aos_modulo_no_disponible('NETWORKS', 'Redes de gas y recoleccion');
      case 9, aos_modulo_no_disponible('NETWORKS', 'Redes de agua e inyeccion');
      case 10, aos_cad_hidraulica_mostrar_resultados('TODO');
      case 11, aos_workbench_mostrar_ficha('NETWORKS');
      case 12, AOS_menu_aosbck('NETWORKS');
      case 13, aos_menu_abrir_contextual('NETWORKS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

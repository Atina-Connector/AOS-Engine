function AOS_menu_electrical()
% AOS_MENU_ELECTRICAL Banco de trabajo electrico.
  while true
    fprintf('\n--- AOS ELECTRICAL [ROADMAP | NUCLEO ACTIVO] ---\n');
    fprintf(' 1 - Red electrica y activos\n');
    fprintf(' 2 - Nucleo electrico de fondo: motor, cable, VSD y termica [ACTIVO]\n');
    fprintf(' 3 - Bombeo Electrosumergible\n');
    fprintf(' 4 - Compresion de Gas en Fondo\n');
    fprintf(' 5 - CAD y visualizacion 3D electrica\n');
    fprintf(' 6 - Registro de solvers electricos\n');
    fprintf(' 7 - Ver datos electricos importados\n');
    fprintf(' 8 - Estado y roadmap de AOS Electrical\n');
    fprintf(' 9 - Componentes AOSBCK y visualizacion 3D [BETA R1]\n');
    fprintf('10 - Abrir / importar / configurar caso electrico\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, AOS_menu_redes_electricas();
      case 2, mostrar_core_local();
      case 3, AOS_menu_BES();
      case 4, AOS_menu_CGF();
      case 5, AOS_menu_3d_core('ELECTRICAL');
      case 6, aos_solvers_menu_disciplina('ELECTRICAL');
      case 7, aos_mostrar_seccion_activa({'red_electrica','redes_electricas','electrico'}, 'DATOS ELECTRICOS IMPORTADOS');
      case 8, aos_workbench_mostrar_ficha('ELECTRICAL');
      case 9, AOS_menu_aosbck('ELECTRICAL');
      case 10, aos_menu_abrir_contextual('ELECTRICAL');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_core_local()
  fprintf('\nNUCLEO ELECTRICO COMUN DISPONIBLE\n');
  funciones = {'aos_motor_pm_evaluar','aos_cable_evaluar','aos_vsd_evaluar', ...
    'aos_termica_fondo','aos_electrico_fondo_evaluar'};
  for i = 1:numel(funciones)
    if exist(funciones{i}, 'file') == 2, estado='OK'; else, estado='FALTA'; endif
    fprintf('  %-34s %s\n', funciones{i}, estado);
  endfor
  fprintf('Este nucleo es consumido actualmente por BES y CGF.\n');
endfunction

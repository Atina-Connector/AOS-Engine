function AOS_menu_maintenance()
% AOS_MENU_MAINTENANCE Mantenimiento, confiabilidad y acciones correctivas.
  while true
    fprintf('\n--- AOS MAINTENANCE [ROADMAP] ---\n');
    fprintf(' 1 - Mantenimiento y Pulling Intelligence %s\n', aos_etiqueta_modulo('PULLING'));
    fprintf(' 2 - Integridad y confiabilidad %s\n', aos_etiqueta_modulo('INTEGRIDAD'));
    fprintf(' 3 - Abrir AOS Environmental [BANCO INDEPENDIENTE] %s\n', ...
      aos_suite_etiqueta_producto('ENVIRONMENTAL'));
    fprintf(' 4 - Economia y optimizacion %s\n', aos_etiqueta_modulo('ECONOMIA'));
    fprintf(' 5 - Consultar AOS SCADA\n');
    fprintf(' 6 - Reportes de mantenimiento y activos\n');
    fprintf(' 7 - Activos y componentes AOSBCK [BETA R1]\n');
    fprintf(' 8 - Abrir / importar caso, reporte o historial\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, AOS_menu_mantenimiento_pulling();
      case 2, AOS_menu_integridad_confiabilidad();
      case 3, AOS_menu_environmental();
      case 4, AOS_menu_economia_optimizacion();
      case 5, AOS_menu_scada();
      case 6, AOS_menu_reportes();
      case 7, AOS_menu_aosbck('MAINTENANCE');
      case 8, aos_menu_abrir_contextual('MAINTENANCE');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

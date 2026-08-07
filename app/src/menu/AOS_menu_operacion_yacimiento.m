function AOS_menu_operacion_yacimiento()
  while true
    fprintf('\n--- MENU HISTORICO DE OPERACION [COMPATIBILIDAD] ---\n');
    fprintf(' 1 - Sistemas de Levantamiento Artificial - SLA\n');
    fprintf(' 2 - Pozos inyectores %s\n', aos_etiqueta_modulo('INYECTORES'));
    fprintf(' 3 - Mallas y niveles %s\n', aos_etiqueta_modulo('MALLAS'));
    fprintf(' 4 - Baterias e instalaciones %s\n', aos_etiqueta_modulo('BATERIAS'));
    fprintf(' 5 - Fluidos y aseguramiento de flujo %s\n', aos_etiqueta_modulo('FLUIDOS'));
    fprintf(' 6 - Redes electricas %s\n', aos_etiqueta_modulo('RED_ELECTRICA'));
    fprintf(' 7 - Secuencia de arranque del yacimiento %s\n', aos_etiqueta_modulo('ARRANQUE'));
    fprintf(' 8 - SCADA y operacion en tiempo real %s\n', aos_etiqueta_modulo('SCADA'));
    fprintf(' 9 - Analisis integral del yacimiento %s\n', aos_etiqueta_modulo('INTEGRAL'));
    fprintf('10 - Herramientas y utilidades generales [OPERATIVO]\n');
    fprintf('11 - CAD, topografia y topologia %s\n', aos_etiqueta_modulo('CAD_TOPO'));
    fprintf('12 - Gestion ambiental %s\n', aos_etiqueta_modulo('AMBIENTAL'));
    fprintf('13 - Integridad y confiabilidad %s\n', aos_etiqueta_modulo('INTEGRIDAD'));
    fprintf('14 - Mantenimiento y Pulling Intelligence %s\n', aos_etiqueta_modulo('PULLING'));
    fprintf('15 - Economia y optimizacion %s\n', aos_etiqueta_modulo('ECONOMIA'));
    fprintf(' 0 - Volver al menu principal\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, AOS_menu_SLA();
      case 2, AOS_menu_pozos_inyectores();
      case 3, AOS_menu_mallas_niveles();
      case 4, AOS_menu_baterias();
      case 5, AOS_menu_fluidos();
      case 6, AOS_menu_redes_electricas();
      case 7, AOS_menu_secuencia_arranque();
      case 8, AOS_menu_scada();
      case 9, AOS_menu_analisis_integral();
      case 10, AOS_menu_herramientas();
      case 11, AOS_menu_cad_topologia();
      case 12, AOS_menu_gestion_ambiental();
      case 13, AOS_menu_integridad_confiabilidad();
      case 14, AOS_menu_mantenimiento_pulling();
      case 15, AOS_menu_economia_optimizacion();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

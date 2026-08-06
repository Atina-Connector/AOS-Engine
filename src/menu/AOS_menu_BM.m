function AOS_menu_BM()
% Menu del sistema de Bombeo Mecanico; preserva el nucleo Gibbs vigente.
  while true
    fprintf('\n--- BOMBEO MECANICO (BM) %s ---\n',aos_etiqueta_modulo('BM'));
    fprintf('1 - Simulacion BM / Gibbs\n');
    fprintf('2 - Sensibilidades BM [DESARROLLO]\n');
    fprintf('3 - Diseno de sarta [DESARROLLO]\n');
    fprintf('4 - Cartas de superficie y fondo\n');
    fprintf('5 - Diagnostico operativo\n');
    fprintf('6 - Analisis energetico y economico [DESARROLLO]\n');
    fprintf('7 - Catalogos BM\n');
    fprintf('8 - Reportes BM y AOS Viewer\n');
    fprintf('9 - Exportar ultima corrida BM\n');
    fprintf('10 - Abrir / importar / configurar caso BM\n');
    fprintf('0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        aos_preparar_config_activa('BM'); BM_menu;
      case 2
        aos_modulo_no_disponible('BM','Sensibilidades BM consolidadas');
      case 3
        aos_modulo_no_disponible('BM','Diseno de sarta BM');
      case {4,5}
        aos_preparar_config_activa('BM'); BM_menu;
      case 6
        aos_modulo_no_disponible('BM','Analisis energetico y economico BM');
      case 7
        AOS_catalogos_listar_tipo('BM');
      case 8
        AOS_menu_reportes();
      case 9
        AOS_exportar_ultima_corrida({'BM'});
      case 10
        aos_menu_abrir_contextual('BM');
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

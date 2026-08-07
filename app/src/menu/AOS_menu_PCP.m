function AOS_menu_PCP()
  while true
    fprintf('\n--- PCP - BOMBEO POR CAVIDADES PROGRESIVAS %s ---\n',aos_etiqueta_modulo('PCP'));
    fprintf('1 - Simulacion PCP\n');
    fprintf('2 - Sensibilidades\n');
    fprintf('3 - Seleccion y diseno del sistema\n');
    fprintf('4 - LDL - Presion y temperatura de fondo sin sensores %s\n',aos_etiqueta_modulo('LDL'));
    fprintf('5 - Calibracion\n');
    fprintf('6 - Diagnostico operativo\n');
    fprintf('7 - Analisis energetico\n');
    fprintf('8 - Analisis economico\n');
    fprintf('9 - Reportes PCP / LDL\n');
    fprintf('10 - Ver datos PCP importados\n');
    fprintf('11 - Abrir / importar / configurar caso PCP/LDL\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, aos_modulo_no_disponible('PCP','Simulacion PCP');
      case 2, aos_modulo_no_disponible('PCP','Sensibilidades PCP');
      case 3, aos_modulo_no_disponible('PCP','Seleccion y diseno PCP');
      case 4, AOS_menu_LDL();
      case 5, aos_modulo_no_disponible('PCP','Calibracion PCP');
      case 6, aos_modulo_no_disponible('PCP','Diagnostico operativo PCP');
      case 7, aos_modulo_no_disponible('PCP','Analisis energetico PCP');
      case 8, aos_modulo_no_disponible('PCP','Analisis economico PCP');
      case 9, AOS_menu_reportes();
      case 10, aos_mostrar_seccion_activa({'pcp'},'DATOS PCP IMPORTADOS');
      case 11, aos_menu_abrir_contextual('PCP');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

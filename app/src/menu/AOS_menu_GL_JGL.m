function AOS_menu_GL_JGL()
% Menu consolidado GL/JGL. No duplica calculos: deriva a los modulos vigentes.
  while true
    fprintf('\n--- GAS LIFT / JET GAS LIFT %s ---\n',aos_etiqueta_modulo('GL_JGL'));
    fprintf('1 - Simular Jet Gas Lift\n');
    fprintf('2 - Simular Gas Lift convencional\n');
    fprintf('3 - Sensibilidades GL / JGL\n');
    fprintf('4 - Diseno automatico de mandriles V2\n');
    fprintf('5 - Calibracion GL / JGL\n');
    fprintf('6 - Analisis energetico y economico de inyeccion\n');
    fprintf('7 - Comparacion GL vs JGL\n');
    fprintf('8 - Reportes GL / JGL y AOS Viewer\n');
    fprintf('9 - Exportar ultima corrida GL / JGL\n');
    fprintf('10 - Abrir / importar / configurar caso GL/JGL y galerias\n');
    fprintf('0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        aos_preparar_config_activa('JGL'); JGL_menu;
      case 2
        aos_preparar_config_activa('GL'); GL_puro_menu;
      case 3
        aos_preparar_config_activa('SENSIBILIDAD'); menu_sensibilidad;
      case 4
        aos_preparar_config_activa('GL'); diseno_mandriles;
      case 5
        aos_preparar_config_activa('CALIBRACION'); calibrar;
      case 6
        aos_preparar_config_activa('SENSIBILIDAD'); sens_balance_energetico;
      case 7
        aos_preparar_config_activa('SENSIBILIDAD'); sens_Qiny;
      case 8
        AOS_menu_reportes();
      case 9
        AOS_exportar_ultima_corrida({'GL','JGL'});
      case 10
        aos_menu_abrir_contextual('GL_JGL');
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function AOS_menu_LDL()
% LDL es una tecnologia propietaria AESIR dentro de PCP.
  while true
    fprintf('\n--- LDL - SISTEMA PROPIETARIO AESIR %s ---\n',aos_etiqueta_modulo('LDL'));
    fprintf('1 - Configurar modelo LDL\n');
    fprintf('2 - Calcular presion y temperatura de fondo\n');
    fprintf('3 - Importar variables de superficie\n');
    fprintf('4 - Recibir variables desde SCADA\n');
    fprintf('5 - Calibrar con mediciones de fondo\n');
    fprintf('6 - Comparar estimacion y sensor real\n');
    fprintf('7 - Historicos y tendencias\n');
    fprintf('8 - Calidad e incertidumbre de la estimacion\n');
    fprintf('9 - Diagnostico PCP basado en LDL\n');
    fprintf('10 - Exportar resultados\n');
    fprintf('11 - Ver bloque LDL importado\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case {1,2,3,5,6,7,8,9}
        acciones={'Configurar modelo LDL','Calcular P/T de fondo','Importar variables de superficie','', ...
                  'Calibrar LDL','Comparar LDL con sensor','Historicos LDL','Incertidumbre LDL','Diagnostico PCP con LDL'};
        aos_modulo_no_disponible('LDL',acciones{op});
      case 4, AOS_menu_scada();
      case 10, AOS_exportar_ultima_corrida({'PCP','LDL'});
      case 11, aos_mostrar_seccion_activa({'ldl','pcp_ldl'},'DATOS LDL IMPORTADOS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

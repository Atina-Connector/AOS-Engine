function AOS_menu_comparacion_sla()
  while true
    fprintf('\n--- COMPARACION DE SISTEMAS SLA ---\n');
    fprintf('1 - Comparacion JGL vs GL por Qiny\n');
    fprintf('2 - Balance energetico JGL vs GL\n');
    fprintf('3 - Comparar flujo natural / CGF / EGF\n');
    fprintf('4 - Comparacion integral de todos los SLA [PLANIFICADO]\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, sens_Qiny;
      case 2, sens_balance_energetico;
      case 3, aos_comparar_gas_fondo();
      case 4, aos_modulo_no_disponible('INTEGRAL','Comparacion integral de SLA');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

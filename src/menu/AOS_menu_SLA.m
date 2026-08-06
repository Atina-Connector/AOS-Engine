function AOS_menu_SLA()
% AOS_MENU_SLA Producto AOS SLA de AOS Suite 0.1.9.
  while true
    fprintf('\n--- AOS SLA - SISTEMAS DE LEVANTAMIENTO ARTIFICIAL ---\n');
    fprintf(' 1 - Gas Lift / JGL %s\n', aos_etiqueta_modulo('GL_JGL'));
    fprintf(' 2 - BES %s\n', aos_etiqueta_modulo('BES'));
    fprintf(' 3 - Bombeo Mecanico %s\n', aos_etiqueta_modulo('BM'));
    fprintf(' 4 - PCP %s\n', aos_etiqueta_modulo('PCP'));
    fprintf(' 5 - CGF - Compresion de Gas en Fondo %s\n', aos_etiqueta_modulo('CGF'));
    fprintf(' 6 - EGF - Eductor Gas-Gas de Fondo %s\n', aos_etiqueta_modulo('EGF'));
    fprintf(' 7 - Comparacion de sistemas [BETA]\n');
    fprintf(' 8 - Herramientas comunes de SLA [OPERATIVO]\n');
    fprintf(' 9 - Abrir / importar / configurar caso SLA [TRANSVERSAL]\n');
    fprintf(' 0 - Volver a AOS Suite\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, AOS_menu_GL_JGL();
      case 2, AOS_menu_BES();
      case 3, AOS_menu_BM();
      case 4, AOS_menu_PCP();
      case 5, AOS_menu_CGF();
      case 6, AOS_menu_EGF();
      case 7, AOS_menu_comparacion_sla();
      case 8, AOS_menu_herramientas_sla();
      case 9, aos_menu_abrir_contextual('SLA');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

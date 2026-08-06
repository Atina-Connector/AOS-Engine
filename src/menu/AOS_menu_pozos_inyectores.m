function AOS_menu_pozos_inyectores()
  while true
    fprintf('\n--- POZOS INYECTORES %s ---\n',aos_etiqueta_modulo('INYECTORES'));
    fprintf('1 - Inyeccion de agua\n');
    fprintf('2 - Inyeccion de gas\n');
    fprintf('3 - Inyeccion de polimeros\n');
    fprintf('4 - Sensibilidades de inyeccion\n');
    fprintf('5 - Capacidad e inyectividad\n');
    fprintf('6 - Perfil de inyeccion\n');
    fprintf('7 - Compatibilidad pozo-red\n');
    fprintf('8 - Energia y costos de inyeccion\n');
    fprintf('9 - Diagnostico del inyector\n');
    fprintf('10 - Ver datos importados\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    if op==0,break;endif
    if op==10
      aos_mostrar_seccion_activa({'inyectores','pozos_inyectores','inyeccion_agua','inyeccion_gas','inyeccion_polimeros'},'DATOS DE INYECCION IMPORTADOS');
    elseif op>=1 && op<=9
      nombres={'Inyeccion de agua','Inyeccion de gas','Inyeccion de polimeros','Sensibilidades de inyeccion', ...
               'Capacidad e inyectividad','Perfil de inyeccion','Compatibilidad pozo-red', ...
               'Energia y costos de inyeccion','Diagnostico del inyector'};
      aos_modulo_no_disponible('INYECTORES',nombres{op});
    else
      fprintf('Opcion no valida.\n');
    endif
  endwhile
endfunction

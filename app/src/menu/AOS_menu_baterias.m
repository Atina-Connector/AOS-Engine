function AOS_menu_baterias()
  while true
    fprintf('\n--- BATERIAS E INSTALACIONES %s ---\n',aos_etiqueta_modulo('BATERIAS'));
    opciones={'Separadores','Tanques','Bombas de transferencia','Compresores','Tratamiento de petroleo', ...
              'Tratamiento de agua','Sistema de gas','Capacidad de bateria','Balance de masa', ...
              'Restricciones operativas','Sensibilidades','Ver datos importados'};
    for i=1:numel(opciones),fprintf('%d - %s\n',i,opciones{i});endfor
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    if op==0,break;endif
    if op==12,aos_mostrar_seccion_activa({'baterias','instalaciones'},'DATOS DE BATERIAS IMPORTADOS');
    elseif op>=1 && op<=11,aos_modulo_no_disponible('BATERIAS',opciones{op});
    else,fprintf('Opcion no valida.\n');endif
  endwhile
endfunction

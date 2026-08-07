function AOS_menu_secuencia_arranque()
  while true
    fprintf('\n--- SECUENCIA DE ARRANQUE DEL YACIMIENTO %s ---\n',aos_etiqueta_modulo('ARRANQUE'));
    opciones={'Configurar escenario de corte','Estado posterior al corte','Inventario de equipos disponibles', ...
              'Prioridades de arranque','Restricciones electricas','Restricciones hidraulicas', ...
              'Restricciones termicas y de fluidos','Generar secuencia automatica','Simular secuencia', ...
              'Comparar alternativas','Emitir procedimiento operativo','Ver datos importados'};
    for i=1:numel(opciones),fprintf('%d - %s\n',i,opciones{i});endfor
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    if op==0,break;endif
    if op==12,aos_mostrar_seccion_activa({'arranque','secuencia_arranque'},'DATOS DE ARRANQUE IMPORTADOS');
    elseif op>=1 && op<=11,aos_modulo_no_disponible('ARRANQUE',opciones{op});
    else,fprintf('Opcion no valida.\n');endif
  endwhile
endfunction

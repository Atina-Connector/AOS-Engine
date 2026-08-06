function AOS_menu_redes_electricas()
  while true
    fprintf('\n--- REDES ELECTRICAS %s ---\n',aos_etiqueta_modulo('RED_ELECTRICA'));
    opciones={'Fuentes y generacion','Subestaciones','Transformadores','Alimentadores','Cargas','Motores', ...
              'VSD','Protecciones','Flujo de carga','Caidas de tension','Capacidad disponible', ...
              'Contingencias','Priorizacion de cargas','Ver datos importados'};
    for i=1:numel(opciones),fprintf('%d - %s\n',i,opciones{i});endfor
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    if op==0,break;endif
    if op==14,aos_mostrar_seccion_activa({'red_electrica','redes_electricas'},'DATOS ELECTRICOS IMPORTADOS');
    elseif op>=1 && op<=13,aos_modulo_no_disponible('RED_ELECTRICA',opciones{op});
    else,fprintf('Opcion no valida.\n');endif
  endwhile
endfunction

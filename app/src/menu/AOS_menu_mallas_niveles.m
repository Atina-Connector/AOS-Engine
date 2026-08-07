function AOS_menu_mallas_niveles()
  while true
    fprintf('\n--- MALLAS Y NIVELES %s ---\n',aos_etiqueta_modulo('MALLAS'));
    opciones={'Definir nodos','Definir conexiones','Importar elevaciones y coordenadas','Visualizar malla', ...
              'Calcular diferencias de nivel','Propagar presiones','Identificar restricciones', ...
              'Escenarios de operacion','Validar conectividad','Ver datos importados'};
    for i=1:numel(opciones),fprintf('%d - %s\n',i,opciones{i});endfor
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    if op==0,break;endif
    if op==10,aos_mostrar_seccion_activa({'mallas','malla','niveles'},'DATOS DE MALLA IMPORTADOS');
    elseif op>=1 && op<=9,aos_modulo_no_disponible('MALLAS',opciones{op});
    else,fprintf('Opcion no valida.\n');endif
  endwhile
endfunction

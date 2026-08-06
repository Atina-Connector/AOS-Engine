function AOS_menu_economia_optimizacion()
  opciones={'Parametros economicos del caso','CAPEX y OPEX','Ingreso incremental','Payback', ...
            'VAN y TIR','Costo de energia e inyeccion','Optimizacion tecnico-economica', ...
            'Comparacion de sistemas de levantamiento','Campanas y priorizacion', ...
            'Escenarios y sensibilidades economicas','Reportes economicos', ...
            'Ver datos economicos importados'};
  while true
    fprintf('\n--- ECONOMIA Y OPTIMIZACION %s ---\n',aos_etiqueta_modulo('ECONOMIA'));
    for i=1:numel(opciones), fprintf('%2d - %s\n',i,opciones{i}); endfor
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_configuracion();
      case 8, AOS_menu_comparacion_sla();
      case 11, AOS_menu_reportes();
      case 12, aos_mostrar_seccion_activa({'economia','optimizacion','capex_opex'},'DATOS ECONOMICOS IMPORTADOS');
      case 0, break;
      otherwise
        if op>=2 && op<=10, aos_modulo_no_disponible('ECONOMIA',opciones{op});
        else, fprintf('Opcion no valida.\n'); endif
    endswitch
  endwhile
endfunction

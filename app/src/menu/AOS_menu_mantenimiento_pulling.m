function AOS_menu_mantenimiento_pulling()
  opciones={'Inventario de activos y equipos','Ordenes e historial de mantenimiento','Score productivo', ...
            'Score mecanico','Score de confiabilidad','Score economico','Score ambiental y HSE', ...
            'Pulling Priority Score 0-100','Recomendacion operativa trazable', ...
            'Planificar campana de pulling','Comparar alternativas de intervencion', ...
            'Consultar historial SCADA','Reportes de mantenimiento y pulling', ...
            'Ver datos de mantenimiento importados'};
  while true
    fprintf('\n--- MANTENIMIENTO Y PULLING INTELLIGENCE %s ---\n',aos_etiqueta_modulo('PULLING'));
    fprintf('Tecnologia de priorizacion y decision propietaria AESIR.\n');
    for i=1:numel(opciones), fprintf('%2d - %s\n',i,opciones{i}); endfor
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 12, AOS_menu_scada();
      case 13, AOS_menu_reportes();
      case 14, aos_mostrar_seccion_activa({'mantenimiento','pulling','intervenciones','workover'},'DATOS DE MANTENIMIENTO IMPORTADOS');
      case 0, break;
      otherwise
        if op>=1 && op<=11, aos_modulo_no_disponible('PULLING',opciones{op});
        else, fprintf('Opcion no valida.\n'); endif
    endswitch
  endwhile
endfunction

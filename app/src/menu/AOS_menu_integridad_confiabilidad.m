function AOS_menu_integridad_confiabilidad()
  opciones={'Corrosion y erosion','Integridad mecanica','Riesgo de falla','Confiabilidad y criticidad', ...
            'Inspecciones y mediciones','Historial de intervenciones','Vida remanente', ...
            'Matriz de riesgo','Plan de mitigacion','Reportes de integridad', ...
            'Consultar historial SCADA','Ver datos de integridad importados'};
  while true
    fprintf('\n--- INTEGRIDAD Y CONFIABILIDAD %s ---\n',aos_etiqueta_modulo('INTEGRIDAD'));
    for i=1:numel(opciones), fprintf('%2d - %s\n',i,opciones{i}); endfor
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 11, AOS_menu_scada();
      case 12, aos_mostrar_seccion_activa({'integridad','confiabilidad','corrosion','inspecciones'},'DATOS DE INTEGRIDAD IMPORTADOS');
      case 0, break;
      otherwise
        if op>=1 && op<=10, aos_modulo_no_disponible('INTEGRIDAD',opciones{op});
        else, fprintf('Opcion no valida.\n'); endif
    endswitch
  endwhile
endfunction

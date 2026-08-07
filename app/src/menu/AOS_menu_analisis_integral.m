function AOS_menu_analisis_integral()
  while true
    fprintf('\n--- ANALISIS INTEGRAL DEL YACIMIENTO %s ---\n',aos_etiqueta_modulo('INTEGRAL'));
    fprintf('1 - Estado integrado del caso activo\n');
    fprintf('2 - Balance de produccion e inyeccion\n');
    fprintf('3 - Restricciones del sistema\n');
    fprintf('4 - Escenarios integrales\n');
    fprintf('5 - Recomendaciones operativas\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, imprimir_estado_integral_local();
      case {2,3,4,5}, aos_modulo_no_disponible('INTEGRAL','Analisis integral solicitado');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function imprimir_estado_integral_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO;
  fprintf('\nCaso activo: %s\n',AOSDAT_ACTIVO);
  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA),fprintf('No hay datos cargados.\n');return;endif
  secciones={};
  if isfield(CONFIG_ACTIVA,'aosdat_sections')&&isstruct(CONFIG_ACTIVA.aosdat_sections)
    secciones=fieldnames(CONFIG_ACTIVA.aosdat_sections);
  endif
  fprintf('Secciones AOSDAT: %s\n',strjoin(secciones,', '));
  fprintf('El solver integral se encuentra en estado PLANIFICADO.\n');
endfunction

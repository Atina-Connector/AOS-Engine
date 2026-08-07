function AOS_menu_herramientas()
  while true
    fprintf('\n--- HERRAMIENTAS Y UTILIDADES GENERALES ---\n');
    fprintf('1 - Datos y geometria del pozo\n');
    fprintf('2 - Diagnostico de rutas y archivos\n');
    fprintf('3 - Mostrar registro de modulos\n');
    fprintf('4 - Ejecutar verificador AOS 0.1.9\n');
    fprintf('5 - Mostrar mapa de dependencias existente\n');
    fprintf('6 - Verificar requisitos de plataforma\n');
    fprintf('7 - Roadmap y arquitectura\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_datos_pozo();
      case 2, diagnosticar_rutas_archivos;
      case 3, mostrar_registro_local();
      case 4
        if exist('VERIFICAR_AOS_0_1_9','file')==2, VERIFICAR_AOS_0_1_9(false);
        else, fprintf('Verificador AOS 0.1.9 no encontrado.\n'); endif
      case 5
        if exist('generar_mapa_dependencias','file')==2,generar_mapa_dependencias;else,fprintf('No disponible.\n');endif
      case 6, aos_verificar_requisitos_plataforma(true);
      case 7, AOS_menu_roadmap();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_registro_local()
  m=aos_registro_modulos();
  for i=1:numel(m),fprintf('%-18s %-12s %-9s %s\n',m(i).id,m(i).estado,m(i).fase_objetivo,m(i).nombre);endfor
endfunction

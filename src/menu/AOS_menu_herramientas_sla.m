function AOS_menu_herramientas_sla()
  while true
    fprintf('\n--- HERRAMIENTAS COMUNES DE SLA ---\n');
    fprintf('1 - Datos y geometria del pozo\n');
    fprintf('2 - Analisis de tuberia y diagnosticos\n');
    fprintf('3 - Calibracion GL / JGL\n');
    fprintf('4 - Exportar ultima corrida SLA\n');
    fprintf('5 - Registro de modulos y estados\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_datos_pozo();
      case 2, ejecutar_diagnostico_local();
      case 3, aos_preparar_config_activa('CALIBRACION'); calibrar;
      case 4, AOS_exportar_ultima_corrida({});
      case 5, imprimir_registro_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function ejecutar_diagnostico_local()
  if exist('diagnosticar_rutas_archivos','file')==2
    diagnosticar_rutas_archivos;
  else
    fprintf('Diagnostico de rutas no disponible.\n');
  endif
endfunction

function imprimir_registro_local()
  m=aos_registro_modulos();
  fprintf('\nID                ESTADO       PROPIETARIO  MODULO\n');
  for i=1:numel(m)
    fprintf('%-17s %-12s %-12s %s\n',m(i).id,m(i).estado,si_no_local(m(i).propietario),m(i).nombre);
  endfor
endfunction

function s=si_no_local(v)
  if v,s='SI';else,s='NO';endif
endfunction

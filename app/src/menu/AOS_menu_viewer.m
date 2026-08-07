function AOS_menu_viewer()
% AOS_MENU_VIEWER Entrada de producto para reportes y visualizacion.
  while true
    fprintf('\n--- AOS VIEWER [ALPHA] ---\n');
    fprintf(' 1 - Reportes .aosrpt y ultima corrida\n');
    fprintf(' 2 - Abrir / importar reporte .aosrpt\n');
    fprintf(' 3 - Abrir .aoscad en AOS Suite\n');
    fprintf(' 4 - Diagnosticar registro de graficos\n');
    fprintf(' 5 - Ver contratos de reportes y Viewer\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        AOS_menu_reportes();
      case 2
        importar_aosrpt();
      case 3
        if exist('aos_aoscad_abrir_en_suite', 'file') == 2
          try
            aos_aoscad_abrir_en_suite([], false);
          catch err
            fprintf(2, 'Error al abrir .aoscad: %s\n', err.message);
          end_try_catch
        else
          fprintf('El lector .aoscad no esta disponible en esta instalacion.\n');
        endif
      case 4
        diagnosticar_graficos_local();
      case 5
        mostrar_contratos_local();
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function diagnosticar_graficos_local()
  try
    a = aos_registro_graficos('audit');
    disp(a);
  catch err
    fprintf('No fue posible consultar el registro de graficos: %s\n', err.message);
  end_try_catch
endfunction

function mostrar_contratos_local()
  fprintf('\n.aosdat : modelo editable de simulacion AOS SLA.\n');
  fprintf('.aosrpt : fotografia de resultados y configuracion efectiva.\n');
  fprintf('DXF/STEP: entradas geometricas de AOS CAD.\n');
  fprintf('.aoscad : modelo CAD, topologia, dominio y resultados recalculables.\n');
  fprintf('Simple   : datos, tablas, modelo y resultados.\n');
  fprintf('Enriquecido: mismo contrato mas visuales embebidos.\n');
endfunction

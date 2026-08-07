function AOS_menu_importar_exportar()
% Entrada unica para intercambio. La importacion .aosdat es indiferenciada.
  while true
    global CONFIG_ACTIVA;
    fprintf('\n--- IMPORTAR / EXPORTAR ---\n');
    fprintf('1 - Importar archivo AOS (.aosdat) [AUTOMATICO / INDIFERENCIADO]\n');
    fprintf('2 - Exportar archivo AOS (.aosdat)\n');
    fprintf('3 - Pozo: survey, punzados y completacion\n');
    fprintf('4 - Formatos externos y planillas\n');
    fprintf('5 - Administracion de catalogos\n');
    fprintf('6 - Reportes y AOS Viewer\n');
    fprintf('7 - Diagnostico de archivos y rutas\n');
    fprintf('8 - Bandejas SCADA AOSDAT\n');
    fprintf('0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        importar_aosdat();
      case 2
        if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
          fprintf('No hay configuracion activa.\n');
        else
          exportar_aosdat(CONFIG_ACTIVA);
        endif
      case 3
        AOS_menu_datos_pozo();
      case 4
        AOS_menu_formatos_externos();
      case 5
        AOS_menu_catalogos();
      case 6
        AOS_menu_reportes();
      case 7
        diagnostico_local();
      case 8
        AOS_menu_scada();
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function diagnostico_local()
  if exist('diagnosticar_rutas_archivos', 'file') == 2
    diagnosticar_rutas_archivos;
  else
    fprintf('Diagnostico de rutas no encontrado.\n');
  endif
endfunction

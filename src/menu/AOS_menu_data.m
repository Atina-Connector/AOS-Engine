function AOS_menu_data()
% AOS_MENU_DATA Contratos, catalogos e interoperabilidad.
  while true
    fprintf('\n--- AOS DATA [BETA] ---\n');
    fprintf(' 1 - Importar / exportar archivos AOS\n');
    fprintf(' 2 - Datos, survey, punzados y completacion del pozo\n');
    fprintf(' 3 - Formatos externos y planillas\n');
    fprintf(' 4 - Administracion de catalogos\n');
    fprintf(' 5 - Intercambio y bandejas SCADA\n');
    fprintf(' 6 - Contratos .aosdat, .aosrpt y .aoscad\n');
    fprintf(' 7 - Modelos de fluido y referencias fluid_id\n');
    fprintf(' 8 - Contratos para workbenches, servicios y solvers\n');
    fprintf(' 9 - Diagnostico de rutas y archivos\n');
    fprintf('10 - Estado y roadmap de AOS Data\n');
    fprintf('11 - Componentes .aosbck, partes e instancias 3D [BETA R1]\n');
    fprintf('12 - Gestion universal del caso y archivos\n');
    fprintf('13 - Galerias AOS: mandriles y CAD\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_importar_exportar();
      case 2, AOS_menu_datos_pozo();
      case 3, AOS_menu_formatos_externos();
      case 4, AOS_menu_catalogos();
      case 5, AOS_menu_scada();
      case 6, contratos_local();
      case 7, AOS_menu_fluidos();
      case 8, contratos_frame_local();
      case 9
        if exist('diagnosticar_rutas_archivos','file')==2, diagnosticar_rutas_archivos;
        else, fprintf('Diagnostico de rutas no disponible.\n'); endif
      case 10, aos_workbench_mostrar_ficha('DATA');
      case 11, AOS_menu_aosbck('DATA');
      case 12, AOS_menu_gestion_caso('DATA');
      case 13, AOS_menu_galerias();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function contratos_local()
  fprintf('\n.aosdat : modelo editable de simulacion AOS SLA.\n');
  fprintf('.aosrpt : reporte de configuracion efectiva y resultados.\n');
  fprintf('DXF/STEP: entradas geometricas de AOS CAD y AOS 3D Core.\n');
  fprintf('.aoscad : modelo CAD, topologia, dominios y resultados recalculables.\n');
  fprintf('fluid_id: referencia persistente al modelo oficial de AOS Fluids.\n');
  fprintf('.aosbck : componente 3D reutilizable con una geometria STEP y multiples instancias.\n');
endfunction

function contratos_frame_local()
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  fprintf('%s\n',fullfile(raiz,'src','roadmap','aos_frame_ribbon_contract_0_2_0.json'));
  fprintf('%s\n',fullfile(raiz,'src','roadmap','aos_workbenches_0_2_0_dev1.json'));
  fprintf('%s\n',fullfile(raiz,'src','roadmap','aos_solvers_0_2_0_dev1.json'));
endfunction

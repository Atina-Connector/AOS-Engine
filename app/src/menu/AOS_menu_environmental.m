function AOS_menu_environmental()
% AOS_MENU_ENVIRONMENTAL Banco independiente de gestion ambiental y HSE.
% ENV-02 publica el entrypoint y la navegacion. Los contratos detallados,
% calculos, factores e importadores ambientales permanecen en roadmap.
  while true
    fprintf('\n--- AOS ENVIRONMENTAL %s ---\n', ...
      aos_suite_etiqueta_producto('ENVIRONMENTAL'));
    fprintf(' Banco independiente y transversal | Runtime shell ENV-02\n');
    fprintf(' Identidad y ubicacion: AOS CAD / AOS 3D Core mediante asset_id\n');
    fprintf(' 1 - Abrir / importar / configurar caso y datos ambientales\n');
    fprintf(' 2 - Localizar activos y eventos en AOS CAD / 3D Core\n');
    fprintf(' 3 - Inventario de fuentes de emision\n');
    fprintf(' 4 - Emisiones fugitivas CH4 / CO2 y campanas LDAR\n');
    fprintf(' 5 - Venteo, flare y emisiones operativas directas\n');
    fprintf(' 6 - H2S y liberaciones de gases toxicos\n');
    fprintf(' 7 - Derrames y perdidas liquidas\n');
    fprintf(' 8 - Agua producida, residuos y sustancias quimicas\n');
    fprintf(' 9 - Actividad energetica y emisiones indirectas de CO2e\n');
    fprintf('10 - Estado mecanico, integridad y riesgo ambiental\n');
    fprintf('11 - SCADA, sensores, alarmas e historicos\n');
    fprintf('12 - Escenarios de mitigacion\n');
    fprintf('13 - Acciones correctivas y vinculo con Maintenance\n');
    fprintf('14 - Indicadores, inventarios y cumplimiento\n');
    fprintf('15 - Reportes ambientales y AOS Viewer\n');
    fprintf('16 - Importar / exportar datos ambientales mediante AOS Data\n');
    fprintf('17 - Factores, catalogos y configuracion ambiental\n');
    fprintf('18 - Estado, validacion y roadmap del banco\n');
    fprintf(' 0 - Volver\n');

    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        aos_menu_abrir_contextual('ENVIRONMENTAL');
      case 2
        AOS_menu_cad_topologia();
      case {3,4,5,6,7,8,9,12,14,17}
        acciones = acciones_planificadas_local();
        aos_modulo_no_disponible('ENVIRONMENTAL', acciones{op});
      case 10
        AOS_menu_integridad_confiabilidad();
      case 11
        AOS_menu_scada();
      case 13
        AOS_menu_maintenance();
      case 15
        AOS_menu_reportes();
      case 16
        AOS_menu_data();
      case 18
        aos_workbench_mostrar_ficha('ENVIRONMENTAL');
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function acciones = acciones_planificadas_local()
  acciones = repmat({''}, 1, 18);
  acciones{3}  = 'Inventario de fuentes de emision';
  acciones{4}  = 'Emisiones fugitivas CH4 / CO2 y campanas LDAR';
  acciones{5}  = 'Venteo, flare y emisiones operativas directas';
  acciones{6}  = 'H2S y liberaciones de gases toxicos';
  acciones{7}  = 'Derrames y perdidas liquidas';
  acciones{8}  = 'Agua producida, residuos y sustancias quimicas';
  acciones{9}  = 'Actividad energetica y emisiones indirectas de CO2e';
  acciones{12} = 'Escenarios de mitigacion';
  acciones{14} = 'Indicadores, inventarios y cumplimiento';
  acciones{17} = 'Factores, catalogos y configuracion ambiental';
endfunction

function AOS_menu_suite_config_diag()
% AOS_MENU_SUITE_CONFIG_DIAG Configuracion, versiones y compatibilidad AOS 0.2.0 DEV1.
  while true
    fprintf('\n--- AOS SUITE: CONFIGURACION, VERSIONES Y DIAGNOSTICOS ---\n');
    fprintf(' 1 - Configuracion general\n');
    fprintf(' 2 - Matriz de workbenches, versiones y servicios\n');
    fprintf(' 3 - Verificar AOS 0.2.0 DEV1\n');
    fprintf(' 4 - Verificar AOS CAD DEV1 R16\n');
    fprintf(' 5 - Verificar compatibilidad historica R1 / AOSBCK\n');
    fprintf(' 6 - Requisitos de plataforma y editores CAD\n');
    fprintf(' 7 - Diagnosticar rutas y archivos\n');
    fprintf(' 8 - Herramientas generales\n');
    fprintf(' 9 - Contratos para el frame AOS 0.2.0\n');
    fprintf('10 - Menu historico de operacion [COMPATIBILIDAD]\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, AOS_menu_configuracion();
      case 2, aos_suite_mostrar_versiones();
      case 3, VERIFICAR_AOS_0_2_0_DEV1(false);
      case 4, verificar_cad_local();
      case 5, VERIFICAR_AOS_0_1_9_R1(false);
      case 6, plataforma_local();
      case 7
        if exist('diagnosticar_rutas_archivos','file')==2, diagnosticar_rutas_archivos;
        else, fprintf('Diagnostico de rutas no disponible.\n'); endif
      case 8, AOS_menu_herramientas();
      case 9, contratos_local();
      case 10, AOS_menu_operacion_yacimiento();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function verificar_cad_local()
  if exist('VERIFICAR_AOSCAD_0_0_1_DEV1','file')==2
    VERIFICAR_AOSCAD_0_0_1_DEV1(false);
  elseif exist('VERIFICAR_AOSCAD_DOMINIO_HIDRAULICO_R9','file')==2
    VERIFICAR_AOSCAD_DOMINIO_HIDRAULICO_R9(false);
  else
    fprintf('Verificador AOSCAD no disponible.\n');
  endif
endfunction

function plataforma_local()
  aos_verificar_requisitos_plataforma(true);
  if exist('DIAGNOSTICAR_EDITORES_AOSCAD','file')==2
    DIAGNOSTICAR_EDITORES_AOSCAD();
  endif
endfunction

function contratos_local()
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  archivos={'aos_workbenches_0_2_0_dev1.json','aos_solvers_0_2_0_dev1.json', ...
    'aos_services_0_2_0_dev1.json','aosbck_contract_0_1_9_r1.json', ...
    'aos_roadmap_0_2_0_dev1.json','aos_frame_ribbon_contract_0_2_0.json', ...
    'aos_report_tables_contract_hf3_5.json'};
  for i=1:numel(archivos)
    fprintf('%s\n',fullfile(raiz,'src','roadmap',archivos{i}));
  endfor
endfunction

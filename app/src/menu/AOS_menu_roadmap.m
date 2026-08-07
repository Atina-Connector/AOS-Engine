function AOS_menu_roadmap()
% AOS_MENU_ROADMAP Roadmap como parte estructural de la Suite.
  while true
    fprintf('\n--- ROADMAP GENERAL AOS 0.2.0 DEV1 ---\n');
    fprintf(' 1 - Matriz completa de bancos de trabajo\n');
    fprintf(' 2 - Fases evolutivas de la Suite\n');
    fprintf(' 3 - Arquitectura bancos-servicios-solvers\n');
    fprintf(' 4 - AOS 3D Core transversal\n');
    fprintf(' 5 - Registro completo de capacidades\n');
    fprintf(' 6 - Dependencias y requisitos de plataforma\n');
    fprintf(' 7 - Visualizar mapa grafico historico\n');
    fprintf(' 8 - Contratos JSON para el frame y la cinta\n');
    fprintf(' 9 - Regenerar mapa de menus y dependencias\n');
    fprintf('10 - Ver documento de contexto y arquitectura 0.2.0 DEV1\n');
    fprintf('11 - AOSBCK: componentes 3D reutilizables [BETA R1]\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, matriz_local();
      case 2, fases_local();
      case 3, arquitectura_local();
      case 4, AOS_menu_3d_core('ROADMAP');
      case 5, modulos_local();
      case 6, aos_verificar_requisitos_plataforma(true);
      case 7, aos_visualizar_roadmap();
      case 8, contratos_local();
      case 9, regenerar_local();
      case 10, documento_local();
      case 11, AOS_menu_aosbck('ROADMAP');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function matriz_local()
  lista=aos_suite_registro_productos();
  fprintf('\n%-3s %-14s %-22s %-22s %-20s\n','#','ID','WORKBENCH','ESTADO','VERSION');
  fprintf('%s\n',repmat('-',1,88));
  for i=1:numel(lista)
    fprintf('%-3d %-14s %-22s %-22s %-20s\n',i,lista(i).id,lista(i).nombre,lista(i).estado,lista(i).version);
  endfor
  fprintf('\nViewer permanece ultimo. Todos los modulos roadmap son visibles para el frame.\n');
endfunction

function fases_local()
  fprintf('\nAOS 0.1.9 - BASELINE HISTORICA DE TRANSICION\n');
  fprintf('  Separacion de bancos de trabajo, servicios y solvers.\n');
  fprintf('AOS 0.2.0 DEV1 - BASELINE MODULAR Y CONTRATOS EN CONSOLIDACION\n');
  fprintf('  Cinta de workbenches, proyecto comun y AOS 3D Core transversal.\n');
  fprintf('AOS 0.2.x - INTEGRACION DE INFRAESTRUCTURA\n');
  fprintf('  Networks, Electrical, Facilities, SCADA y contratos Environmental.\n');
  fprintf('AOS 0.3.x - INTELIGENCIA OPERATIVA\n');
  fprintf('  Environmental, Maintenance, Pulling Intelligence, economia y confiabilidad.\n');
  fprintf('AOS GLOBAL\n');
  fprintf('  Orquestacion de reservorio, pozo, red, energia, planta y mantenimiento.\n');
endfunction

function arquitectura_local()
  fprintf('\nWORKBENCHES\n');
  fprintf('  Definen el problema de ingenieria y la experiencia de usuario.\n');
  fprintf('SERVICIOS\n');
  fprintf('  Fluids, 3D Core, AOSBCK, unidades, catalogos, validacion y reportes.\n');
  fprintf('  AOS Environmental consume servicios comunes y no duplica geometria ni SCADA.\n');
  fprintf('SOLVERS\n');
  fprintf('  Resuelven sistemas matematicos por disciplina sin contener menus.\n');
  fprintf('AOS GLOBAL\n');
  fprintf('  Orquesta workbenches, servicios y solvers; no duplica la fisica.\n');
endfunction

function modulos_local()
  m=aos_registro_modulos();
  fprintf('\n%-15s %-38s %-14s %-14s %-10s\n','ID','MODULO','GRUPO','ESTADO','FASE');
  fprintf('%s\n',repmat('-',1,96));
  for i=1:numel(m)
    fprintf('%-15s %-38s %-14s %-14s %-10s\n',m(i).id,m(i).nombre,m(i).grupo,m(i).estado,m(i).fase_objetivo);
  endfor
endfunction

function contratos_local()
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  d=fullfile(raiz,'src','roadmap');
  fprintf('%s\n',fullfile(d,'aos_workbenches_0_2_0_dev1.json'));
  fprintf('%s\n',fullfile(d,'aos_services_0_2_0_dev1.json'));
  fprintf('%s\n',fullfile(d,'aosbck_contract_0_1_9_r1.json'));
  fprintf('%s\n',fullfile(d,'aos_solvers_0_2_0_dev1.json'));
  fprintf('%s\n',fullfile(d,'aos_roadmap_0_2_0_dev1.json'));
  fprintf('%s\n',fullfile(d,'aos_frame_ribbon_contract_0_2_0.json'));
endfunction

function regenerar_local()
  if exist('GENERAR_MAPA_DEPENDENCIAS_MENUS','file')==2
    GENERAR_MAPA_DEPENDENCIAS_MENUS;
  elseif exist('aos_generar_mapa_menus','file')==2
    aos_generar_mapa_menus;
  else
    fprintf('Generador de mapa no encontrado.\n');
  endif
endfunction

function documento_local()
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  ruta=fullfile(raiz,'AOS_0_2_0_DEV1_CONTEXTO_COMPLETO.md');
  fprintf('%s\n',ruta);
  if exist(ruta,'file')==2
    fprintf('%s\n',fileread(ruta));
  endif
endfunction

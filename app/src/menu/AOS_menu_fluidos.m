function AOS_menu_fluidos()
% AOS_MENU_FLUIDOS Banco transversal de propiedades de fluidos.
  while true
    fprintf('\n--- AOS FLUIDS [BETA / TRANSVERSAL] ---\n');
    fprintf(' 1 - Ver modelo de fluido activo\n');
    fprintf(' 2 - PVT Black Oil y propiedades basicas [ACTIVO]\n');
    fprintf(' 3 - Propiedades del petroleo\n');
    fprintf(' 4 - Propiedades del gas\n');
    fprintf(' 5 - Propiedades del agua y salmuera\n');
    fprintf(' 6 - Fluido multifasico y mezcla\n');
    fprintf(' 7 - Composicion y cromatografia [ROADMAP]\n');
    fprintf(' 8 - Propiedades en funcion de P y T [BETA]\n');
    fprintf(' 9 - Envolvente de fases [ROADMAP]\n');
    fprintf('10 - Viscosidad, reologia y emulsiones [ROADMAP]\n');
    fprintf('11 - Parafinas, asfaltenos, hidratos y sales [ROADMAP]\n');
    fprintf('12 - CO2, H2S, corrosion y compatibilidad [ROADMAP]\n');
    fprintf('13 - Importar datos de laboratorio [ROADMAP]\n');
    fprintf('14 - Calibrar y comparar correlaciones [ROADMAP]\n');
    fprintf('15 - Exportar o catalogar modelo de fluido [ROADMAP]\n');
    fprintf('16 - Registro de solvers y servicios de fluidos\n');
    fprintf('17 - Estado y roadmap de AOS Fluids\n');
    fprintf('18 - Abrir / importar / configurar fluido o .aosdat\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, aos_mostrar_seccion_activa({'fluidos','aseguramiento_flujo','pvt'}, 'MODELO DE FLUIDO ACTIVO');
      case 2, mostrar_pvt_local();
      case {3,4,5,6,8}, mostrar_componentes_local(op);
      case {7,9,10,11,12,13,14,15}, aos_modulo_no_disponible('FLUIDOS', 'Funcion seleccionada de AOS Fluids');
      case 16, aos_solvers_menu_disciplina('FLUIDS');
      case 17, aos_workbench_mostrar_ficha('FLUIDS');
      case 18, aos_menu_abrir_contextual('FLUIDS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_pvt_local()
  fprintf('\nSERVICIOS PVT DISPONIBLES\n');
  funciones = {'pvt_calcular','pvt_tension_superficial','aos_gas_props','aos_vlp_propiedades_locales'};
  for i=1:numel(funciones)
    if exist(funciones{i},'file')==2, e='OK'; else, e='FALTA'; endif
    fprintf('  %-34s %s\n',funciones{i},e);
  endfor
  fprintf('AOS Fluids sera la fuente oficial de propiedades para todos los workbenches.\n');
endfunction

function mostrar_componentes_local(op)
  nombres = {'','','Petroleo','Gas','Agua y salmuera','Fluido multifasico','','Propiedades P-T'};
  fprintf('\n%s\n', upper(nombres{op}));
  aos_mostrar_seccion_activa({'fluidos','pvt','aseguramiento_flujo'}, 'DATOS DE FLUIDOS IMPORTADOS');
endfunction

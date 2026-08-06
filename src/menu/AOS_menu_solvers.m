function AOS_menu_solvers()
% AOS_MENU_SOLVERS Espacio cientifico transversal de la Suite.
  while true
    fprintf('\n--- AOS SOLVERS [TRANSVERSAL] ---\n');
    fprintf(' 1 - Solvers hidraulicos\n');
    fprintf(' 2 - Solvers electricos\n');
    fprintf(' 3 - Solvers mecanicos\n');
    fprintf(' 4 - Solvers termicos\n');
    fprintf(' 5 - Solvers geologicos\n');
    fprintf(' 6 - Solvers de reservorio\n');
    fprintf(' 7 - Solvers de produccion y SLA\n');
    fprintf(' 8 - Solvers multifisicos\n');
    fprintf(' 9 - Solvers de redes y grafos\n');
    fprintf('10 - Solvers de optimizacion\n');
    fprintf('11 - Solvers economicos\n');
    fprintf('12 - Solvers de confiabilidad y riesgo\n');
    fprintf('13 - Solvers y servicios de fluidos\n');
    fprintf('14 - Registro general de solvers\n');
    fprintf('15 - Ejecutar benchmarks publicados\n');
    fprintf('16 - Validacion, regresiones y dependencias\n');
    fprintf('17 - Configuracion numerica [ROADMAP]\n');
    fprintf('18 - Estado y roadmap de AOS Solvers\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, aos_solvers_menu_disciplina('HYDRAULIC');
      case 2, aos_solvers_menu_disciplina('ELECTRICAL');
      case 3, aos_solvers_menu_disciplina('MECHANICAL');
      case 4, aos_solvers_menu_disciplina('THERMAL');
      case 5, aos_solvers_menu_disciplina('GEOLOGICAL');
      case 6, aos_solvers_menu_disciplina('RESERVOIR');
      case 7, aos_solvers_menu_disciplina('PRODUCTION');
      case 8, aos_solvers_menu_disciplina('MULTIPHYSICS');
      case 9, aos_solvers_menu_disciplina('NETWORK_GRAPH');
      case 10, aos_solvers_menu_disciplina('OPTIMIZATION');
      case 11, aos_solvers_menu_disciplina('ECONOMICS');
      case 12, aos_solvers_menu_disciplina('RELIABILITY');
      case 13, aos_solvers_menu_disciplina('FLUIDS');
      case 14, registro_local();
      case 15, benchmarks_local();
      case 16, validacion_local();
      case 17, aos_modulo_no_disponible('SOLVERS','Configuracion numerica central');
      case 18, aos_workbench_mostrar_ficha('SOLVERS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function registro_local()
  s=aos_solvers_registro();
  fprintf('\n%-16s %-34s %-15s %-14s %-10s\n','ID','SOLVER','DISCIPLINA','ESTADO','DISP.');
  fprintf('%s\n',repmat('-',1,96));
  for i=1:numel(s)
    if s(i).disponible,d='SI';else,d='NO';endif
    fprintf('%-16s %-34s %-15s %-14s %-10s\n',s(i).id,s(i).nombre,s(i).disciplina,s(i).estado,d);
  endfor
endfunction

function benchmarks_local()
  s=aos_solvers_registro();
  ejecutados=0;
  vistos={};
  for i=1:numel(s)
    t=s(i).selftest;
    if isempty(t) || any(strcmp(vistos,t)),continue;endif
    vistos{end+1}=t; ejecutados=ejecutados+1;
    fprintf('\nBenchmark %s...\n',t);
    try
      r=feval(t);
      if isempty(r)||logical(r),fprintf('OK %s\n',t);else,fprintf(2,'NO APROBADO %s\n',t);endif
    catch err
      fprintf(2,'ERROR %s: %s\n',t,err.message);
    end_try_catch
  endfor
  if ejecutados==0,fprintf('No se encontraron benchmarks publicados.\n');endif
endfunction

function validacion_local()
  fprintf('\nPrincipios de gobierno de solvers:\n');
  fprintf('  - Entradas y salidas versionadas.\n');
  fprintf('  - Solver separado del workbench y de la visualizacion.\n');
  fprintf('  - Unidades, origen de datos, convergencia y advertencias obligatorias.\n');
  fprintf('  - Benchmark y regresion antes de promover estado.\n');
  fprintf('  - GNU Octave es el motor cientifico oficial.\n');
  fprintf('Registro JSON: src/roadmap/aos_solvers_0_2_0_dev1.json\n');
endfunction

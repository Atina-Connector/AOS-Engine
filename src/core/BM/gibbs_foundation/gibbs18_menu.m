function resultado = gibbs18_menu()
% gibbs18_menu.m - BM Gibbs Solver Foundation v18.3 (Octave-first)
% Opcion experimental independiente. No modifica BM_core ni Gibbs Lab.

  fprintf('\n====================================================\n');
  fprintf(' BM - GIBBS SOLVER FOUNDATION v18.3 / OCTAVE\n');
  fprintf('====================================================\n');
  fprintf('Objetivo: fundacion fisica para BM, no calibracion comercial.\n');
  fprintf('Decisiones: PR impuesto, sarta elastica distribuida, bomba borde inferior.\n');
  fprintf('v18.3: promedio por fase, modo cuasiestatico estable, diametro bomba editable.\n\n');

  try
      [param, origen] = aos_config_base('BM');
  catch
      param = struct();
      origen = 'defaults locales v18.3';
  end
  fprintf('Configuracion base: %s\n', origen);
  param = gibbs18_defaults(param);

  fprintf('\n--- CASOS v18.3 ---\n');
  fprintf('  1 - Caso base: bomba llena ideal\n');
  fprintf('  2 - Bomba con llenado parcial\n');
  fprintf('  3 - Parametros editables\n');
  fprintf('  4 - Solo cambiar cantidad de ciclos\n');
  fprintf('  5 - Solo cambiar diametro de bomba\n');
  fprintf('  6 - Revision de cargas de superficie\n');
  fprintf('  7 - Cambiar modo solver (automatico/cuasiestatico/dinamico)\n');
  fprintf('  0 - Volver\n');
  op = input('Seleccione caso [1]: ');
  if isempty(op), op = 1; end
  if op == 0
      resultado = [];
      return;
  end

  if op == 2
      val = input(sprintf('Llenado bomba fraccion [%.2f]: ', param.gibbs18_llenado_bomba));
      if isempty(val), val = 0.75; end
      param.gibbs18_llenado_bomba = min(max(val, 0.05), 1.2);
      param = gibbs18_editar_ciclos(param);
  elseif op == 3
      param = gibbs18_editar_parametros(param);
  elseif op == 4
      param = gibbs18_editar_ciclos(param);
  elseif op == 5
      param = gibbs18_editar_diametro_bomba(param);
      param = gibbs18_editar_ciclos(param);
  elseif op == 6
      param = gibbs18_editar_cargas_superficie(param);
      param = gibbs18_editar_ciclos(param);
  elseif op == 7
      param = gibbs18_editar_modo_solver(param);
      param = gibbs18_editar_ciclos(param);
  end

  opciones = struct();
  opciones.graficar = true;
  opciones.imprimir = true;
  resultado = gibbs18_run_case(param, opciones);
  assignin('base', 'ULTIMO_GIBBS18', resultado);
  fprintf('\nResultado guardado en workspace como ULTIMO_GIBBS18.\n');
  fprintf('====================================================\n');
end

function param = gibbs18_editar_parametros(param)
  fprintf('\n--- PARAMETROS EDITABLES v18.3 ---\n');
  val = input(sprintf('Carrera polished rod (m) [%.3f]: ', param.S_carrera));
  if ~isempty(val), param.S_carrera = val; end
  val = input(sprintf('Velocidad (golpes/min) [%.2f]: ', param.N_velocidad));
  if ~isempty(val), param.N_velocidad = val; end
  val = input(sprintf('Profundidad bomba (m) [%.1f]: ', param.D_bomba));
  if ~isempty(val), param.D_bomba = val; end
  param = gibbs18_editar_diametro_bomba(param);
  val = input(sprintf('N nodos sarta [%d]: ', param.gibbs18_n_nodos));
  if ~isempty(val), param.gibbs18_n_nodos = max(8, round(val)); end
  param = gibbs18_editar_ciclos(param);
  val = input(sprintf('Amortiguamiento modal (1/s) [%.4f]: ', param.gibbs18_amortiguamiento));
  if ~isempty(val), param.gibbs18_amortiguamiento = max(val, 0); end
  val = input(sprintf('Llenado bomba fraccion [%.2f]: ', param.gibbs18_llenado_bomba));
  if ~isempty(val), param.gibbs18_llenado_bomba = min(max(val, 0.05), 1.2); end
  param = gibbs18_editar_cargas_superficie(param);
end

function param = gibbs18_editar_ciclos(param)
  fprintf('\n--- CICLOS DE SIMULACION v18.3 ---\n');
  fprintf('Default historico: 5 ciclos. Si hay 2 o mas, normalmente se descarta el primero.\n');
  val = input(sprintf('Ciclos a simular [%d]: ', param.gibbs18_n_ciclos));
  if ~isempty(val), param.gibbs18_n_ciclos = max(1, round(val)); end
  if param.gibbs18_n_ciclos <= 1
      param.gibbs18_descartar_ciclos = 0;
  else
      val = input(sprintf('Ciclos iniciales a descartar [%d]: ', param.gibbs18_descartar_ciclos));
      if ~isempty(val), param.gibbs18_descartar_ciclos = max(0, round(val)); end
      param.gibbs18_descartar_ciclos = min(param.gibbs18_descartar_ciclos, param.gibbs18_n_ciclos-1);
  end
end

function param = gibbs18_editar_diametro_bomba(param)
  fprintf('\n--- DIAMETRO DE BOMBA v18.3 ---\n');
  fprintf('El diametro afecta area de piston, carga de fluido y caudal teorico.\n');
  val = input(sprintf('Diametro bomba (mm) [%.1f]: ', param.D_bomba_mm));
  if ~isempty(val)
      param.D_bomba_mm = max(1, val);
  end
end

function param = gibbs18_editar_cargas_superficie(param)
  fprintf('\n--- REVISION DE CARGAS DE SUPERFICIE v18.3 ---\n');
  fprintf('El solver calcula primero carga dinamica relativa.\n');
  fprintf('Para carta operativa se suma offset estatico estimado.\n');
  fprintf('Offset actual: ');
  if isfinite(param.gibbs18_surface_offset_manual_N)
      fprintf('manual %.1f kN\n', param.gibbs18_surface_offset_manual_N/1000);
  else
      fprintf('automatico\n');
  end
  aplicar = aos_preguntar_sn(sprintf('Aplicar offset estatico? (s/n) [%s]: ', ...
      aos_sn_local(param.gibbs18_aplicar_offset_estatico)), ...
      logical(param.gibbs18_aplicar_offset_estatico));
  param.gibbs18_aplicar_offset_estatico = double(aplicar);
  val = input('Offset manual superficie (kN, vacio = automatico): ');
  if isempty(val)
      param.gibbs18_surface_offset_manual_N = NaN;
  else
      param.gibbs18_surface_offset_manual_N = val*1000;
  end
end


function param = gibbs18_editar_modo_solver(param)
  fprintf('\n--- MODO SOLVER v18.3 ---\n');
  fprintf('automatico: baja velocidad => cuasiestatico; el resto => dinamico foundation.\n');
  fprintf('cuasiestatico: recomendado para validar paralelogramo, cargas y diametro.\n');
  fprintf('dinamico_foundation: conserva propagacion preliminar de v18.\n');
  actual = param.gibbs18_modo_solver;
  fprintf('Modo actual: %s\n', actual);
  fprintf('  1 - automatico\n');
  fprintf('  2 - cuasiestatico\n');
  fprintf('  3 - dinamico_foundation\n');
  opm = input('Seleccione modo [1]: ');
  if isempty(opm), opm = 1; end
  if opm == 2
      param.gibbs18_modo_solver = 'cuasiestatico';
  elseif opm == 3
      param.gibbs18_modo_solver = 'dinamico_foundation';
  else
      param.gibbs18_modo_solver = 'automatico';
  end
end

function txt = aos_sn_local(v)
  if v
      txt = 's';
  else
      txt = 'n';
  end
end

function resultado = gibbs_lab_menu()
% gibbs_lab_menu.m - Laboratorio Gibbs experimental AOS v17
% Usa configuracion AOS/BM activa, pero NO modifica el BM operativo.
%
% v17 agrega dos caminos separados:
%   1) Solver de onda forward desde polished rod: sin oscilaciones hardcodeadas.
%   2) Benchmark visual v16 auditado: forma util, pero con oscilacion declarada
%      y desactivada por defecto.

  fprintf('\n====================================================\n');
  fprintf(' LABORATORIO GIBBS - EXPERIMENTAL / NO OPERATIVO\n');
  fprintf('====================================================\n');
  fprintf('Este laboratorio NO reemplaza BM_core ni QROD/SROD.\n');
  fprintf('Regla v17: no agregar oscilaciones esteticas ocultas.\n\n');

  try
      [param, origen] = aos_config_base('BM');
  catch
      param = struct();
      origen = 'configuracion minima local';
  end
  fprintf('Base de datos usada: %s\n', origen);
  param = gibbs_lab_defaults(param);

  fprintf('\n--- MODO DE LABORATORIO ---\n');
  fprintf('  1 - Gibbs Solver Lab v17: polished rod -> sarta -> cargas (sin hardcodeo)\n');
  fprintf('  2 - Benchmark visual v16 auditado (heuristico, oscilacion desactivada)\n');
  fprintf('  0 - Volver\n');
  modo = input('Seleccione modo [1]: ');
  if isempty(modo), modo = 1; end
  if modo == 0
      resultado = [];
      return;
  end

  if modo == 1
      resultado = gibbs_lab_menu_v17_solver(param);
  else
      resultado = gibbs_lab_menu_v16_benchmark(param);
  end

  assignin('base', 'ULTIMO_GIBBS_LAB', resultado);
  fprintf('\nResultado guardado en el workspace como ULTIMO_GIBBS_LAB.\n');
  fprintf('====================================================\n');
end

function resultado = gibbs_lab_menu_v17_solver(param)
  fprintf('\n--- Gibbs Solver Lab v17 ---\n');
  fprintf('Modelo: movimiento impuesto en polished rod y ecuacion de onda amortiguada.\n');
  fprintf('Las ondas/reflexiones, si aparecen, salen del solver numerico.\n');

  fprintf('\nCondicion inferior de prueba:\n');
  fprintf('  1 - Extremo libre\n');
  fprintf('  2 - Extremo fijo\n');
  fprintf('  3 - Carga de fluido constante en bomba\n');
  fprintf('  4 - Bomba ideal llena: carga en subida / descarga en bajada\n');
  op = input('Seleccione condicion inferior [4]: ');
  if isempty(op), op = 4; end
  switch op
      case 1
          param.gibbs_lab_bc = 'libre';
      case 2
          param.gibbs_lab_bc = 'fijo';
      case 3
          param.gibbs_lab_bc = 'carga_constante';
      otherwise
          param.gibbs_lab_bc = 'bomba_ideal_llena';
  end

  fprintf('\n--- Parametros principales ---\n');
  fprintf('Carrera superficie     : %.3f m\n', param.S_carrera);
  fprintf('Velocidad              : %.2f golpes/min\n', param.N_velocidad);
  fprintf('Profundidad bomba      : %.1f m\n', param.D_bomba);
  fprintf('Diametro bomba         : %.1f mm\n', param.D_bomba_mm);
  fprintf('Condicion inferior     : %s\n', param.gibbs_lab_bc);
  fprintf('N nodos sarta          : %d\n', param.gibbs_lab_nx);
  fprintf('Ciclos simulados       : %.1f\n', param.gibbs_lab_ciclos);
  if aos_preguntar_sn('Modificar parametros basicos? (s/n) [n]: ', false)
      val = input(sprintf('  Carrera superficie (m) [%.3f]: ', param.S_carrera));
      if ~isempty(val), param.S_carrera = val; end
      val = input(sprintf('  Velocidad (golpes/min) [%.2f]: ', param.N_velocidad));
      if ~isempty(val), param.N_velocidad = val; end
      val = input(sprintf('  Profundidad bomba (m) [%.1f]: ', param.D_bomba));
      if ~isempty(val), param.D_bomba = val; end
      val = input(sprintf('  Diametro bomba (mm) [%.1f]: ', param.D_bomba_mm));
      if ~isempty(val), param.D_bomba_mm = val; end
      val = input(sprintf('  N nodos sarta [%d]: ', param.gibbs_lab_nx));
      if ~isempty(val), param.gibbs_lab_nx = max(8, round(val)); end
      val = input(sprintf('  Amortiguamiento c (1/s) [%.3f]: ', param.gibbs_lab_c_damp));
      if ~isempty(val), param.gibbs_lab_c_damp = val; end
  end

  resultado = gibbs_lab_solver_forward(param);
  gibbs_lab_imprimir(resultado);
  gibbs_lab_plot(resultado);
end

function resultado = gibbs_lab_menu_v16_benchmark(param)
  fprintf('\n--- Benchmark visual v16 auditado ---\n');
  fprintf('Este modo NO es solver Gibbs. Es una forma de referencia visual.\n');
  fprintf('Auditoria: v16 tenia una oscilacion/reflexion heuristica.\n');
  fprintf('En v17 queda desactivada por defecto y solo se activa si se pide.\n');

  fprintf('\n--- Caso de bomba impuesto ---\n');
  fprintf('  1 - Bomba normal, 100%% llenado\n');
  fprintf('  2 - Bomba normal, 75%% llenado\n');
  fprintf('  3 - Bomba normal, 50%% llenado\n');
  fprintf('  4 - Bomba normal, 25%% llenado\n');
  fprintf('  5 - Personalizado\n');
  op = input('Seleccione caso [1]: ');
  if isempty(op), op = 1; end

  switch op
      case 1
          param.llenado_bomba = 1.00;
          caso = 'normal_100';
      case 2
          param.llenado_bomba = 0.75;
          caso = 'normal_75';
      case 3
          param.llenado_bomba = 0.50;
          caso = 'normal_50';
      case 4
          param.llenado_bomba = 0.25;
          caso = 'normal_25';
      otherwise
          caso = 'personalizado';
          val = input(sprintf('Llenado de bomba fraccion [%.2f]: ', param.llenado_bomba));
          if ~isempty(val), param.llenado_bomba = min(max(val,0),1.2); end
  end
  param.gibbs_lab_caso = caso;
  param.gibbs_lab_osc_frac_Wf = 0.0;
  usar_osc = aos_preguntar_sn('Activar perturbacion heuristica de onda? (s/n) [n]: ', false);
  if usar_osc
      fprintf('Aviso: perturbacion declarada, no es solucion de ecuacion de onda.\n');
      val = input('  Amplitud perturbacion / Wf [0.035]: ');
      if isempty(val), val = 0.035; end
      param.gibbs_lab_osc_frac_Wf = max(val,0);
  end
  resultado = gibbs_lab_correr(param);
  gibbs_lab_imprimir(resultado);
  gibbs_lab_plot(resultado);
end

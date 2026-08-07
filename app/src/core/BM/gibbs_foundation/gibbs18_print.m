function gibbs18_print(res)
  fprintf('\n===== BM GIBBS SOLVER FOUNDATION v18.3 =====\n');
  fprintf('Version              : %s\n', res.version);
  fprintf('Modelo               : %s\n', res.modelo);
  if isfield(res,'modo_solver_resuelto'), fprintf('Modo solver          : %s\n', res.modo_solver_resuelto); end
  fprintf('Nodos sarta          : %d\n', res.malla.n);
  fprintf('Longitud sarta       : %.1f m\n', res.malla.L);
  fprintf('Velocidad onda       : %.0f m/s\n', res.malla.c_onda);
  fprintf('Diametro bomba       : %.1f mm\n', res.param.D_bomba_mm);
  fprintf('Ciclos simulados     : %d\n', res.ciclos_simulados);
  fprintf('Ciclos descartados   : %d\n', res.ciclos_descartados);
  fprintf('Ciclos promediados   : ');
  fprintf('%d ', res.metricas.ciclos_promediados);
  fprintf('\n');
  fprintf('Promedio cartas      : punto a punto, fase de ciclo normalizada\n');
  fprintf('Carrera superficie   : %.3f m\n', res.metricas.stroke_superficie_m);
  fprintf('Carrera fondo        : %.3f m\n', res.metricas.stroke_fondo_m);
  fprintf('Q teorico fondo      : %.2f m3/d\n', res.metricas.Q_teorico_fondo_m3d);
  fprintf('Carga sup max/min    : %.0f / %.0f N\n', res.metricas.carga_sup_max_N, res.metricas.carga_sup_min_N);
  fprintf('Carga sup dinamica   : %.0f / %.0f N\n', res.metricas.carga_sup_dinamica_max_N, res.metricas.carga_sup_dinamica_min_N);
  if isfield(res,'diagnostico_cargas')
      fprintf('Offset superficie    : %.0f N (%s)\n', res.diagnostico_cargas.offset_superficie_N, res.diagnostico_cargas.modo);
      fprintf('  Peso varillas flot.: %.0f N\n', res.diagnostico_cargas.peso_varillas_flotado_N);
      fprintf('  Carga bomba media  : %.0f N\n', res.diagnostico_cargas.carga_bomba_media_N);
  end
  fprintf('Carga bomba max/min  : %.0f / %.0f N\n', res.metricas.carga_bomba_max_N, res.metricas.carga_bomba_min_N);
  fprintf('Nota cargas          : carga dinamica puede ser negativa si falta offset estatico.\n');
  fprintf('Nota                 : %s\n', res.nota);
end

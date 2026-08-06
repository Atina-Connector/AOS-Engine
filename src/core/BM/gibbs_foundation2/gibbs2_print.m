function gibbs2_print(res)
  fprintf('\n===== GF2 RESULTADOS =====\n');
  fprintf('Versión: %s\n', res.version);
  fprintf('Modelo: %s\n', res.modelo);
  fprintf('Modo: %s\n', res.modo_solver_resuelto);
  fprintf('Ciclos simulados/descartados: %d/%d\n', res.ciclos_simulados, res.ciclos_descartados);
  m = res.metricas;
  fprintf('Carrera sup: %.3f m\n', m.stroke_superficie_m);
  fprintf('Carrera fondo: %.3f m\n', m.stroke_fondo_m);
  fprintf('Carga sup max/min: %.1f / %.1f kN\n', m.carga_sup_max_N/1000, m.carga_sup_min_N/1000);
  fprintf('Carga fondo max/min: %.1f / %.1f kN\n', m.carga_fondo_max_N/1000, m.carga_fondo_min_N/1000);
  fprintf('Q teórico fondo: %.2f m³/d\n', m.Q_teorico_fondo_m3s*86400);
  fprintf('===========================\n');
end

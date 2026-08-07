function gibbs_resumen_texto(res)
  % Imprime resumen del motor Gibbs BM v10.
  fprintf('\n--- MOTOR GIBBS BM v10 ---\n');
  fprintf('Modo                  : %s\n', res.modo);
  fprintf('Modelo                : %s\n', res.modelo);
  if isfield(res, 'malla')
      fprintf('Profundidad sarta     : %.1f m\n', res.malla.L);
      fprintf('Nodos de onda         : %d\n', res.malla.n_nodos);
      fprintf('Vel. onda             : %.0f - %.0f m/s\n', res.malla.c_min, res.malla.c_max);
      fprintf('Rigidez equivalente   : %.3e N/m\n', res.malla.K_eq_N_m);
  end
  m = res.metricas;
  fprintf('Carrera superficie    : %.3f m\n', m.stroke_superficie_m);
  fprintf('Carrera fondo         : %.3f m\n', m.stroke_fondo_m);
  fprintf('Relacion fondo/sup    : %.3f\n', m.relacion_stroke_fondo);
  fprintf('Llenado efectivo      : %.3f\n', m.llenado_efectivo);
  fprintf('Q teorico fondo       : %.2f m3/d\n', m.Q_teorico_fondo_m3s * 86400);
  fprintf('Q efectivo Gibbs      : %.2f m3/d\n', m.Q_efectivo_m3d);
  fprintf('Carga sup max/min     : %.1f / %.1f kN\n', m.carga_sup_max_N/1000, m.carga_sup_min_N/1000);
  fprintf('Carga fondo max/min   : %.1f / %.1f kN\n', m.carga_fondo_max_N/1000, m.carga_fondo_min_N/1000);
  if isfield(res, 'espaciamiento')
      fprintf('Espaciamiento sug.    : %.2f m (%s)\n', res.espaciamiento.recomendacion_m, res.espaciamiento.criterio);
  end
  if isfield(res, 'info') && isfield(res.info, 'aviso')
      fprintf('Aviso                 : %s\n', res.info.aviso);
  end
  fprintf('--------------------------\n');
end

function gibbs_lab_imprimir(r)
  fprintf('\n--- RESULTADOS LABORATORIO GIBBS v17 ---\n');
  fprintf('Modelo                  : %s\n', r.modelo);
  fprintf('Advertencia             : %s\n', r.advertencia);
  if isfield(r,'sin_hardcode_onda')
      if r.sin_hardcode_onda
          fprintf('Ondas hardcodeadas      : NO\n');
      else
          fprintf('Ondas hardcodeadas      : revisar\n');
      end
  end
  if isfield(r,'condicion_inferior')
      fprintf('Condicion inferior      : %s\n', r.condicion_inferior);
  end
  fprintf('Periodo                 : %.2f s\n', r.T);
  fprintf('Velocidad onda aprox.   : %.0f m/s\n', r.a_onda);
  fprintf('Retardo fondo-superf.   : %.3f s\n', r.tau);
  fprintf('Periodo onda ida/vuelta : %.3f s\n', r.periodo_onda_ida_vuelta);
  fprintf('S superficie            : %.3f m\n', r.S_sup);
  fprintf('S fondo                 : %.3f m\n', r.S_fondo);
  fprintf('Transmision S fondo/sup : %.2f\n', r.transmision);
  fprintf('Carga fluido Wf         : %.2f kN\n', r.Wf_kN);
  fprintf('Peso varillas aparente  : %.2f kN\n', r.Wb_kN);
  fprintf('Llenado                 : %.0f %%\n', r.llenado*100);
  fprintf('Q teorico fondo         : %.2f m3/d\n', r.Q_teorico_fondo_m3d);
  fprintf('Q efectivo estimado     : %.2f m3/d\n', r.Q_efectivo_m3d);
  fprintf('-----------------------------------------\n');
end

function gibbs_lab_plot(r)
% gibbs_lab_plot.m - Figura de laboratorio Gibbs v17.
  figure('Name','AOS Laboratorio Gibbs v17');

  subplot(2,3,1);
  plot(r.x_fondo, r.carga_fondo_kN, 'LineWidth', 1.2);
  grid on;
  title('Carta fondo');
  xlabel('Posicion piston/fondo (m)');
  ylabel('Carga fondo (kN)');

  subplot(2,3,2);
  plot(r.x_sup, r.carga_sup_kN, 'LineWidth', 1.2);
  grid on;
  title('Carta superficie');
  xlabel('Posicion polished rod (m)');
  ylabel('Carga superficie (kN)');

  subplot(2,3,3);
  plot(r.t, r.x_sup, 'LineWidth', 1.1); hold on;
  plot(r.t, r.x_fondo, 'LineWidth', 1.1); hold off;
  grid on;
  title('Transmision de carrera');
  xlabel('Tiempo (s)');
  ylabel('Posicion (m)');
  legend('Superficie','Fondo');

  subplot(2,3,4);
  plot(r.t, r.carga_sup_kN, 'LineWidth', 1.1); hold on;
  plot(r.t, r.carga_fondo_kN, 'LineWidth', 1.1); hold off;
  grid on;
  title('Transmision de carga');
  xlabel('Tiempo (s)');
  ylabel('Carga (kN)');
  legend('Superficie','Fondo');

  subplot(2,3,5);
  plot(r.t, r.estado_bomba, 'LineWidth', 1.2); hold on;
  if isfield(r,'estado_superficie')
      plot(r.t, r.estado_superficie, '--', 'LineWidth', 1.0);
      legend('Fondo','Superficie');
  end
  hold off;
  ylim([-0.1, 1.1]); grid on;
  title('Estado de carga');
  xlabel('Tiempo (s)');
  ylabel('0 descargada / 1 cargada');

  subplot(2,3,6);
  axis off;
  extra = '';
  if isfield(r,'sin_hardcode_onda') && r.sin_hardcode_onda
      extra = sprintf('\nSin hardcode de onda: SI\nCondicion inferior: %s', r.condicion_inferior);
  elseif isfield(r,'param') && isfield(r.param,'gibbs_lab_osc_frac_Wf')
      extra = sprintf('\nBenchmark v16 auditado\nPerturbacion heuristica/Wf: %.3f', r.param.gibbs_lab_osc_frac_Wf);
  end
  texto = sprintf(['Resumen Gibbs Lab v17\n\n' ...
      'S sup: %.3f m\nS fondo: %.3f m\nTransmision: %.2f\n' ...
      'Retardo: %.3f s\nT onda ida/vuelta: %.3f s\nWf: %.2f kN\nWb: %.2f kN\n' ...
      'Llenado: %.0f %%\nQ efectivo: %.2f m3/d\n%s'], ...
      r.S_sup, r.S_fondo, r.transmision, r.tau, r.periodo_onda_ida_vuelta, ...
      r.Wf_kN, r.Wb_kN, r.llenado*100, r.Q_efectivo_m3d, extra);
  text(0.02,0.95,texto,'VerticalAlignment','top','FontName','monospace');
  drawnow;
end

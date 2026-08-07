function ok = test_plot_survey_punzados_001()
% Smoke test opcional del plot de survey y punzados.
% Se ejecuta con figuras invisibles y se cierra inmediatamente.

  root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  iniciar_aos(true);
  archivo = fullfile(root, 'datos', 'ejemplos', 'benchmarks', ...
                     'SUPATI_X1_ST_BENCHMARK_AOS_001.aosdat');
  cfg = importar_aosdat(archivo);

  vis_anterior = get(0, 'defaultfigurevisible');
  set(0, 'defaultfigurevisible', 'off');
  try
      plot_survey(cfg.survey, cfg.punzados, false);
      close(gcf);
      ok = true;
      fprintf('TEST PLOT SURVEY/PUNZADOS: OK.\n');
  catch err
      ok = false;
      fprintf('AVISO PLOT SURVEY/PUNZADOS: no se pudo probar el grafico en este entorno: %s\n', err.message);
  end
  set(0, 'defaultfigurevisible', vis_anterior);
end

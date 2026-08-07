function ok = test_aosdat_supati_001()
% Prueba de regresion del importador AOS 0.0.11 Benchmark Ready.
  root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  iniciar_aos(true);
  archivo = fullfile(root, 'datos', 'ejemplos', 'benchmarks', 'SUPATI_X1_ST_BENCHMARK_AOS_001.aosdat');
  cfg = importar_aosdat(archivo);
  assert(isstruct(cfg));
  assert(isfield(cfg, 'survey') && length(cfg.survey.MD) == 13);
  assert(isfield(cfg, 'punzados') && length(cfg.punzados.tramos) == 5);
  assert(isfield(cfg, 'geologia') && isstruct(cfg.geologia));
  assert(isfield(cfg.geologia, 'intervalos') && length(cfg.geologia.intervalos.tramos) == 5);
  assert(abs(cfg.P_res/1e5 - 380.797) < 1e-3);
  assert(abs(cfg.P_b/1e5 - 21.40) < 1e-3);
  assert(abs(cfg.P_wh/1e5 - 29.971) < 1e-3);
  assert(abs(cfg.P_iny_sup/1e5 - 135.461) < 1e-3);
  assert(abs(cfg.IP*86400*1e5 - 0.09454) < 1e-6);
  assert(abs(cfg.D_iny - 1945.40) < 1e-6);
  assert(abs(aos_m3s_a_sm3d(cfg.Q_iny) - 19333.610) < 1e-3);
  assert(strcmpi(cfg.modelo_IPR, 'Vogel'));
  assert(strcmpi(cfg.modelo_VLP, 'DR'));
  global geologia CONFIG_ACTIVA;
  assert(isstruct(geologia) && isfield(geologia, 'intervalos'));
  assert(isstruct(CONFIG_ACTIVA) && isfield(CONFIG_ACTIVA, 'benchmark_prosper'));
  ok = true;
  fprintf('TEST SUPATI AOS-001: OK. Survey 13 puntos, geologia y 5 tramos de punzados cargados.\n');
end

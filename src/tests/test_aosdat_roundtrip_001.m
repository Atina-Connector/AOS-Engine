function ok = test_aosdat_roundtrip_001()
% Prueba de ida y vuelta del formato .aosdat AOS 0.0.11.
% Verifica que los parametros metricos, survey, geologia y punzados no se
% pierdan al exportar e importar nuevamente el pozo testigo.

  root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  iniciar_aos(true);
  origen = fullfile(root, 'datos', 'ejemplos', 'benchmarks', ...
                    'SUPATI_X1_ST_BENCHMARK_AOS_001.aosdat');
  temporal = [tempname(), '.aosdat'];

  cfg1 = importar_aosdat(origen);
  secciones = {'CONFIG','GEOLOGIA','SURVEY','PUNZADOS', ...
               'ESTADO_MECANICO','BENCHMARK_PROSPER'};
  exportar_aosdat(cfg1, temporal, secciones);
  cfg2 = importar_aosdat(temporal);

  assert(abs(cfg2.P_res/1e5 - cfg1.P_res/1e5) < 1e-5);
  assert(abs(cfg2.P_b/1e5 - cfg1.P_b/1e5) < 1e-5);
  assert(abs(cfg2.P_wh/1e5 - cfg1.P_wh/1e5) < 1e-5);
  assert(abs(cfg2.P_iny_sup/1e5 - cfg1.P_iny_sup/1e5) < 1e-5);
  assert(abs(cfg2.IP*86400*1e5 - cfg1.IP*86400*1e5) < 1e-8);
  assert(abs(cfg2.D_iny - cfg1.D_iny) < 1e-6);
  assert(abs(aos_m3s_a_sm3d(cfg2.Q_iny) - aos_m3s_a_sm3d(cfg1.Q_iny)) < 1e-4);
  assert(isfield(cfg2, 'survey') && length(cfg2.survey.MD) == 13);
  assert(isfield(cfg2, 'punzados') && length(cfg2.punzados.tramos) == 5);
  assert(isfield(cfg2, 'geologia') && isfield(cfg2.geologia, 'intervalos'));
  assert(length(cfg2.geologia.intervalos.tramos) == 5);
  assert(isfield(cfg2, 'benchmark_prosper'));

  if exist(temporal, 'file') == 2, delete(temporal); end
  ok = true;
  fprintf('TEST ROUNDTRIP AOSDAT: OK. No se perdieron unidades, survey, geologia ni punzados.\n');
end

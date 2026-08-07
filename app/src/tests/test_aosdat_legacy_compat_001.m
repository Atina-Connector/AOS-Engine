function ok = test_aosdat_legacy_compat_001()
% Comprueba que archivos .aosdat historicos sigan cargando sin perder sus
% parametros canonicos mientras AOS migra a la interfaz metrica.

  root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  iniciar_aos(true);

  casos = {
    fullfile(root, 'datos', 'ejemplos', 'MB01_15pts_2tercios_vertical.aosdat'), 15;
    fullfile(root, 'datos', 'ejemplos', 'test_bm_completo.aosdat'), 0;
    fullfile(root, 'datos', 'ejemplos', 'importados_legacy', 'geologia_MB.aosdat'), 0;
    fullfile(root, 'datos', 'ejemplos', 'importados_legacy', 'survey_MB1.aosdat'), 2
  };

  for i = 1:size(casos,1)
      archivo = casos{i,1};
      n_survey = casos{i,2};
      cfg = importar_aosdat(archivo);
      assert(isstruct(cfg));
      assert(isfield(cfg, 'aosdat_sections'));
      if n_survey > 0
          assert(isfield(cfg, 'survey'));
          assert(length(cfg.survey.MD) == n_survey);
      end
  end

  cfg = importar_aosdat(casos{1,1});
  assert(abs(cfg.P_res - 18470000) < 1e-3);
  assert(abs(cfg.P_wh - 1280000) < 1e-3);
  assert(abs(cfg.D_iny - 1890.6) < 1e-6);
  assert(strcmpi(cfg.modelo_IPR, 'Vogel'));
  assert(strcmpi(cfg.modelo_VLP, 'DR'));

  cfg_bm = importar_aosdat(casos{2,1});
  assert(abs(cfg_bm.D_bomba_mm - 32) < 1e-12);
  assert(abs(cfg_bm.S_carrera - 1.5) < 1e-12);
  assert(strcmp(cfg_bm.tipo_unidad, 'Convencional'));

  cfg_geo = importar_aosdat(casos{3,1});
  assert(isfield(cfg_geo, 'geologia') && isstruct(cfg_geo.geologia));
  assert(abs(cfg_geo.geologia.porosidad - 0.20) < 1e-12);

  ok = true;
  fprintf('TEST COMPATIBILIDAD AOSDAT: OK. Casos historicos cargados.\n');
end

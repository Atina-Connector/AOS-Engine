function ok = test_unidades_aos_001()
% Verifica la convencion metrica de AOS y las referencias imperiales.

  assert(abs(aos_sm3d_a_m3s(86400) - 1.0) < 1e-12);
  assert(abs(aos_m3s_a_sm3d(1.0) - 86400) < 1e-9);
  assert(abs(aos_mmscfd_a_m3s(1.0) - (1e6*0.028316846592/86400)) < 1e-12);
  assert(abs(aos_m3s_a_mmscfd(aos_mmscfd_a_m3s(0.68)) - 0.68) < 1e-10);

  txt = aos_formato_presion(1e5, 1);
  assert(~isempty(strfind(txt, '1.0 bar')));
  assert(~isempty(strfind(txt, 'psi')));

  txt = aos_formato_longitud(1.0, 2);
  assert(~isempty(strfind(txt, '1.00 m')));
  assert(~isempty(strfind(txt, 'ft')));

  txt = aos_formato_caudal_liquido(1/86400, 2);
  assert(~isempty(strfind(txt, '1.00 m3/d')));
  assert(~isempty(strfind(txt, 'bpd')));

  txt = aos_formato_caudal_gas(1/86400, 0);
  assert(~isempty(strfind(txt, '1 Sm3/d')));
  assert(~isempty(strfind(txt, 'MMscf/d')));

  % Compatibilidad: bar es prioritario; psi se acepta solo como alias.
  cfg = struct('P_wh_bar', 30, 'P_wh_psig', 999, 'P_b_psi', 311, ...
               'Qiny_ref_MMscfd', 0.68, 'ID_tubing', 0.062, ...
               'factor_declinacion', 0.91);
  cfg = aos_aplicar_aliases_aosdat(cfg);
  assert(abs(cfg.P_wh/1e5 - 30) < 1e-9);
  assert(abs(cfg.P_b/6894.757293168 - 311) < 1e-6);
  assert(abs(aos_m3s_a_mmscfd(cfg.Q_iny) - 0.68) < 1e-10);
  assert(abs(cfg.diam_tbg - 0.062) < 1e-12);
  assert(abs(cfg.factor_IP_residual - 0.91) < 1e-12);

  ok = true;
  fprintf('TEST UNIDADES AOS: OK. Metrico principal e imperial de referencia.\n');
end

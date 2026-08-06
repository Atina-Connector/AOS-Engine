function ok = test_parche_0_0_11c_profundidad_punzados()
% Verifica propagacion de profundidad y reparto de produccion por punzados.
  ok = false;

  cfg = struct('D_iny',1945.4,'D_iny_m',1945.4,'D_bomba',1945.4, ...
               'D_res',3766.75,'P_res',380e5,'IP',1e-10,'WC',0.77, ...
               'GLR',30.8,'P_wh',30e5,'P_iny_sup',135e5);
  cfg = aos_set_profundidad(cfg, 'GL', 3600);
  cfg = aos_normalizar_config(cfg, 'GL');
  assert(abs(cfg.D_iny - 3600) < 1e-9);
  assert(abs(cfg.D_iny_m - 3600) < 1e-9);
  assert(abs(cfg.gl.D_valvula - 3600) < 1e-9);

  t(1)=struct('MD_desde',3752.5,'MD_hasta',3754.5,'densidad_tpm',15,'diametro_punzado_m',0.010);
  t(2)=struct('MD_desde',3757.5,'MD_hasta',3764.0,'densidad_tpm',15,'diametro_punzado_m',0.010);
  t(3)=struct('MD_desde',3766.5,'MD_hasta',3768.5,'densidad_tpm',15,'diametro_punzado_m',0.010);
  t(4)=struct('MD_desde',3770.0,'MD_hasta',3771.0,'densidad_tpm',15,'diametro_punzado_m',0.010);
  t(5)=struct('MD_desde',3778.0,'MD_hasta',3781.0,'densidad_tpm',15,'diametro_punzado_m',0.010);
  ints=struct('tramos',t);
  geol=struct('permeabilidad_mD',0.5,'skin_factor',0);
  dist=aos_distribuir_produccion_punzados(16/86400,geol,ints,cfg);
  assert(dist.n_tramos == 5);
  assert(dist.n_tiros_total == 218);
  assert(abs(sum([dist.tramos.Ql_m3d]) - 16) < 1e-8);
  assert(abs(sum([dist.tramos.fraccion_aporte]) - 1) < 1e-10);

  fprintf('TEST 0.0.11c: OK. Profundidad 3600 m preservada y 218 tiros distribuidos.\n');
  ok = true;
end

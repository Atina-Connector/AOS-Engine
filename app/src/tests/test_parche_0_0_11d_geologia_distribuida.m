function ok = test_parche_0_0_11d_geologia_distribuida()
% Prueba sin graficos del reparto Supati: 5 tramos y 218 tiros.
  tramos = repmat(struct(),1,5);
  datos=[3752.5 3754.5 15;3757.5 3764.0 15;3766.5 3768.5 15;3770.0 3771.0 15;3778.0 3781.0 15];
  for i=1:5
    tramos(i).MD_desde=datos(i,1); tramos(i).MD_hasta=datos(i,2);
    tramos(i).densidad_tpm=datos(i,3); tramos(i).diametro_punzado_m=0.010;
  end
  intervalos.tramos=tramos;
  geol=struct('WC',0.77,'permeabilidad_mD',0.5,'skin_factor',0,'rho_petroleo',806);
  param=struct('WC',0.77);
  dist=aos_distribuir_produccion_punzados(15/86400,geol,intervalos,param);
  assert(dist.n_tramos==5);
  assert(dist.n_tiros_total==218);
  assert(abs(sum([dist.tramos.Ql_m3d])-15)<1e-8);
  assert(all([dist.tramos.Ql_m3d]>0));
  assert(max([dist.tramos.Ql_m3d])<15);
  ok=true;
  fprintf('OK 0.0.11d: 15 m3/d distribuidos en 5 tramos y 218 tiros.\n');
end

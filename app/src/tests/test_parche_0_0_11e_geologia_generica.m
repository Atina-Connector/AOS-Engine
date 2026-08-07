function ok=test_parche_0_0_11e_geologia_generica()
  ok=false;
  geol=struct();
  geol.angulo_friccion_rad=35*pi/180; geol.cohesion=2e6;
  geol.esfuerzo_vertical=85e6; geol.esfuerzo_h_min=61e6;
  geol.permeabilidad_h=0.5*9.869233e-16; geol.permeabilidad_v=0.05*9.869233e-16;
  geol.espesor_zona_petrolera=28.5; geol.altura_perforados=14.5;
  geol.mu_petroleo=1.5e-3; geol.B_o=1.05; geol.radio_drenaje=250; geol.radio_pozo=0.108;
  geol.rho_petroleo=806; geol.rho_agua=1020; geol.factor_seguridad=1.2;
  geol.tipo_dato='SINTETICO_ANALOGO'; geol.aos_campos_estimados={'permeabilidad_v','skin_factor','contacto_agua'};
  tr=struct('MD_desde',{},'MD_hasta',{},'tiros_por_m',{},'diametro_punzado_m',{});
  vals=[3752.5 3754.5;3757.5 3764;3766.5 3768.5;3770 3771;3778 3781];
  for i=1:5
      tr(i).MD_desde=vals(i,1); tr(i).MD_hasta=vals(i,2); tr(i).tiros_por_m=15; tr(i).diametro_punzado_m=0.010;
  end
  intervalos=struct('tramos',tr);
  geol.intervalos=intervalos;
  p=struct('P_res',380.8e5,'IP',0.095/86400/1e5,'WC',0.77,'rho_o',806,'rho_w',1020);
  q=27.054/86400;
  c=calcular_caudales_criticos(geol,q,p,intervalos);
  assert(~c.conificacion_vinculante);
  assert(isnan(c.Q_conifica));
  assert(c.Q_seguro>0);
  assert(~c.recomendar_choke);
  assert(isfield(c,'conificacion_generica'));
  assert(isfield(c,'distribucion_punzados'));
  assert(abs(c.distribucion_punzados.Ql_total_m3d-27.054)<1e-6);
  ok=true;
  fprintf('OK 0.0.11e: geologia generica no fuerza conificacion ni choke.\n');
end

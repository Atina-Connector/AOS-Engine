function ok = bes3_selftest()
% Pruebas bottom-up BES3 DEV5 sin requerir un caso de campo.
  ok=false;fprintf('\n=== SELFTEST BES3 DEV5 ===\n');
  pv=struct('bes3_etapas_candidatas','[2,3]','bes3_capilar_ID_candidatos_m','[0.0020,0.0030,0.0040,0.0050]');pv=bes3_defaults(pv);
  check_local(strcmp(pv.bes3_version,'BES3_0_1_3_R1_1'),'version BES3 0.1.3R1.1');
  check_local(abs(pv.bes3_limite_recirculacion_pct_nominal-10)<1e-12,'limite por defecto 10 por ciento del Q nominal');
  check_local(isnumeric(pv.bes3_etapas_candidatas)&&isequal(pv.bes3_etapas_candidatas,[2 3]),'normalizacion de etapas desde texto aosdat');
  check_local(isnumeric(pv.bes3_capilar_ID_candidatos_m)&&numel(pv.bes3_capilar_ID_candidatos_m)==4,'normalizacion de diametros desde texto aosdat');
  pm=bes3_defaults(struct('modelo_IPR','Vogel','modelo_VLP','HB'));check_local(strcmpi(pm.modelo_IPR,'Vogel')&&strcmpi(pm.modelo_VLP,'HB'),'preservacion de modelos IPR y VLP');
  cv=bes3_capillary_catalog(pv);check_local(isnumeric(cv(1).ID_m)&&abs(cv(1).ID_m-0.002)<1e-12,'catalogo capilar numerico');

  p=struct('D_bomba',2200,'D_res',2500,'P_res',180e5,'P_wh',10e5,'IP',10/86400/1e5,'P_b',100e5, ...
    'WC',0.2,'GLR',20,'API',35,'gamma_g',0.7,'rho_o',850,'rho_w',1000,'rho_g_std',0.8, ...
    'T_sup',298.15,'T_fondo',363.15,'diam_tbg',0.062,'rugosidad',4.6e-5, ...
    'modelo_IPR','Linear','modelo_VLP','DR','frecuencia',60,'num_etapas',100);
  tr=struct('MD_desde',1800,'MD_hasta',1850,'activo',true);p.punzados=struct('tramos',tr);p=bes3_defaults(p);
  g=bes3_completion_geometry(p);check_local(strcmp(g.posicion_estado,'CONJUNTO_TOTALMENTE_DEBAJO_PUNZADOS'),'deteccion de BES bajo punzados');
  caps=bes3_capillary_catalog(p);q=15/86400;
  a=bes3_capillary_loss(q,900,0.001,caps(2),p);b=bes3_capillary_loss(q,900,0.050,caps(2),p);check_local(b.dP_total_Pa>a.dP_total_Pa,'viscosidad incrementa perdida capilar');
  c=bes3_capillary_loss(q,900,0.005,caps(1),p);d=bes3_capillary_loss(q,900,0.005,caps(end),p);check_local(c.dP_total_Pa>d.dP_total_Pa,'diametro menor incrementa perdida capilar');
  flow=bes3_capillary_flow(@(x) 2.5e5,caps(3),900,0.005,p);check_local(flow.Q_m3_d>0,'solver de caudal capilar');
  curva=struct('Q_m3_d',[0 100 200 300 400],'Q_m3_s',[0 100 200 300 400]/86400,'head_m',[1200 1100 900 600 100], ...
    'eta',[0.2 0.6 0.8 0.65 0.2],'Q_BEP_m3_d',200,'Q_min_rec_m3_d',120,'Q_max_rec_m3_d',300,'frecuencia_Hz',60,'num_etapas',100);
  st=bes3_stage_performance(150/86400,0.02,curva,p);check_local(st.valido&&st.head_m>0,'rendimiento por etapa');
  fl=struct('Ql_local_m3_s',20/86400,'gvf_bomba',0.01,'rho_l_kg_m3',900,'mu_o_Pa_s',0.005,'Qg_free_local_m3_s',0);
  rec=bes3_recirculation(fl.Ql_local_m3_s,fl,g,curva,p);check_local(rec.cumple&&rec.etapa_toma==2,'segunda etapa suficiente con viscosidad moderada');
  check_local(rec.cumple_diseno&&rec.Q_recirc_pct_nominal<10,'seleccion automatica moderada dentro del limite de diseno');
  fl_visc=fl;fl_visc.mu_o_Pa_s=0.020;rec_visc=bes3_recirculation(fl_visc.Ql_local_m3_s,fl_visc,g,curva,p);check_local(rec_visc.cumple&&rec_visc.etapa_toma==3,'tercera etapa seleccionada por alta perdida viscosa');
  check_local(~rec_visc.cumple_diseno&&~isempty(strfind(rec_visc.estado,'EXCESIVA')),'alta viscosidad puede refrigerar pero revelar mal diseno');

  flsec=fl;flsec.Ql_local_m3_s=100/86400;flsec.gvf_bomba=0;
  rec_ok=struct('Q_recirc_m3_d',15,'Q_recirc_m3_s',15/86400,'etapa_toma',2,'dP_disponible_Pa',2e5,'dP_capilar_Pa',1.5e5,'margen_presion',0.25);
  pump_ok=bes3_pump_sections(100/86400,15/86400,2,flsec,curva,p);
  dg_ok=bes3_diagnostico_recirculacion(curva,pump_ok,rec_ok,p,95);
  check_local(abs(dg_ok.Q_recirc_pct_nominal-7.5)<1e-9&&dg_ok.cumple_diseno,'recirculacion menor al 10 por ciento aceptada');
  rec_bad=rec_ok;rec_bad.Q_recirc_m3_d=25;rec_bad.Q_recirc_m3_s=25/86400;
  pump_bad=bes3_pump_sections(100/86400,25/86400,2,flsec,curva,p);
  dg_bad=bes3_diagnostico_recirculacion(curva,pump_bad,rec_bad,p,95);
  check_local(strcmp(dg_bad.estado_diseno,'RECIRCULACION_ALTA_MAL_DISENO')&&~dg_bad.cumple_diseno,'recirculacion igual o mayor al limite se marca mal diseno');
  dg_zero=bes3_diagnostico_recirculacion(curva,pump_ok,rec_ok,p,0);
  check_local(strcmp(dg_zero.estado_operativo,'RECIRCULACION_INTERNA_SIN_PRODUCCION'),'recirculacion sin produccion tiene estado explicito');
  check_local(dg_ok.num_etapas_total==100&&dg_ok.n_etapas_inferiores==2&&dg_ok.n_etapas_superiores==98,'cantidad de etapas y secciones informada');

  poff=p;poff.frecuencia=0;poff.bes3_estado_bomba='apagada';poff=bes3_defaults(poff);
  check_local(poff.frecuencia==0&&strcmp(poff.bes3_estado_bomba,'apagada'),'normalizacion de bomba apagada a 0 Hz');
  eo=bes3_electrico_apagado(poff,80);check_local(eo.P_superficie_kW==0&&eo.corriente_A==0&&eo.motor.rpm==0,'estado electrico nulo a 0 Hz');
  ro=bes3_recirculacion_apagada();check_local(ro.Q_recirc_m3_d==0&&ro.etapa_toma==0&&ro.cumple,'capilar inactivo con bomba apagada');
  li=bes3_bomba_apagada_loss(100/86400,fl,poff);check_local(li.dP_Pa==0,'modo ideal sin perdida pasiva');
  pins=poff;pins.frecuencia=0;pins.bes3_estado_bomba='apagada';pins.bes3_bomba_apagada_modelo='instalada';pins.bes3_bomba_apagada_K=10;pins=bes3_defaults(pins);
  lp=bes3_bomba_apagada_loss(100/86400,fl,pins);check_local(lp.dP_Pa>0,'modelo BES apagada instalada con perdida positiva');
  fprintf('SELFTEST BES3 DEV5: APROBADO\n');ok=true;
endfunction
function check_local(tf,msg),if ~tf,error('SELFTEST BES3 fallo: %s',msg);else,fprintf('  OK - %s\n',msg);endif,endfunction

function e = bes3_evaluar_punto(Ql,param,curva,Pwf_fun)
% Evalua caudal neto de superficie con recirculacion acoplada.
  p=bes3_defaults(param);e=struct('Ql',Ql,'valido',false,'estado','NO_EVALUADO','residuo',NaN);
  if Ql<0||~isfinite(Ql),e.estado='CAUDAL_INVALIDO';return;endif
  Pwf=Pwf_fun(Ql);geom=bes3_completion_geometry(p);
  [Pint,succ]=bes3_presion_intake(Ql,p,Pwf,geom);fl=bes2_pvt_intake(Ql,Pint,p);
  Qnet_pump=fl.Ql_local_m3_s;
  rec=bes3_recirculation(Qnet_pump,fl,geom,curva,p);
  etapa=rec.etapa_toma;if etapa<=0,etapa=0;endif
  pump=bes3_pump_sections(Qnet_pump,rec.Q_recirc_m3_s,etapa,fl,curva,p);
  if ~pump.valido,e.estado=pump.estado;return;endif
  Qg_total=Ql*p.GLR;[Pdesc_req,vlpdet]=compute_P_req(p,Ql,Qg_total,p.D_bomba);
  residuo=Pint+pump.dP_total_Pa-Pdesc_req;
  rpm=3600*p.frecuencia/max(p.frecuencia_base,1e-6);
  try
    b=bes2_cargar_bomba(p);rpm=b.rpm_base*p.frecuencia/max(b.frecuencia_base,1e-6);
  catch
  end_try_catch
  Tamb=aos_temperatura_at_md(p,p.D_bomba)-273.15;
  elec=aos_electrico_fondo_evaluar(pump.P_eje_kW,rpm,rec.velocidad_total_m_s,Tamb,p);
  e=struct('Ql',Ql,'Q_m3_d',Ql*86400,'Q_pump_neto_m3_d',Qnet_pump*86400, ...
    'Pwf_Pa',Pwf,'Pintake_Pa',Pint,'Pdesc_req_Pa',Pdesc_req,'Pdesc_disponible_Pa',Pint+pump.dP_total_Pa, ...
    'dP_bomba_Pa',pump.dP_total_Pa,'dP_bomba_apagada_Pa',0, ...
    'head_m',pump.head_total_m,'P_eje_kW',pump.P_eje_kW,'residuo',residuo,'fluido',fl, ...
    'succion',succ,'geometria',geom,'recirculacion',rec,'bomba_secciones',pump, ...
    'electrico',elec,'vlp_detalle',vlpdet,'valido',true,'estado','OK');
endfunction

function e = bes3_evaluar_punto_natural(Ql,param,Pwf_fun)
% Evalua un punto del pozo con BES apagada: head, potencia y recirculacion iguales a cero.
  p=bes3_defaults(param);e=struct('Ql',Ql,'valido',false,'estado','NO_EVALUADO','residuo',NaN);
  if Ql<0||~isfinite(Ql),e.estado='CAUDAL_INVALIDO';return;endif
  Pwf=Pwf_fun(Ql);geom=bes3_completion_geometry(p);
  [Pint,succ]=bes3_presion_intake(Ql,p,Pwf,geom);fl=bes2_pvt_intake(Ql,Pint,p);
  perdida=bes3_bomba_apagada_loss(Ql,fl,p);
  Qg_total=Ql*p.GLR;[Pdesc_req,vlpdet]=compute_P_req(p,Ql,Qg_total,p.D_bomba);
  if isinf(perdida.dP_Pa)
    Pdisp=-Inf;residuo=-Inf;
  else
    Pdisp=Pint-perdida.dP_Pa;residuo=Pdisp-Pdesc_req;
  endif
  Tamb=aos_temperatura_at_md(p,p.D_bomba)-273.15;
  elec=bes3_electrico_apagado(p,Tamb);rec=bes3_recirculacion_apagada();
  pump=struct('valido',true,'estado','BOMBA_APAGADA','dP_total_Pa',0,'head_total_m',0, ...
    'P_eje_kW',0,'eta_inferior',NaN,'eta_superior',NaN);
  e=struct('Ql',Ql,'Q_m3_d',Ql*86400,'Q_pump_neto_m3_d',fl.Ql_local_m3_s*86400, ...
    'Pwf_Pa',Pwf,'Pintake_Pa',Pint,'Pdesc_req_Pa',Pdesc_req,'Pdesc_disponible_Pa',Pdisp, ...
    'dP_bomba_Pa',0,'dP_bomba_apagada_Pa',perdida.dP_Pa,'head_m',0,'P_eje_kW',0, ...
    'residuo',residuo,'fluido',fl,'succion',succ,'geometria',geom,'recirculacion',rec, ...
    'bomba_secciones',pump,'bomba_apagada_loss',perdida,'electrico',elec, ...
    'vlp_detalle',vlpdet,'valido',isfinite(residuo),'estado',perdida.estado);
endfunction

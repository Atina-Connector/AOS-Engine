function e = bes2_evaluar_punto(Ql,param,curva,Pwf_fun)
% Evalúa un caudal candidato sin extrapolar la curva de bomba.
  e=struct();e.Ql=Ql;e.valido=false;e.estado='NO_EVALUADO';e.residuo=NaN;
  if Ql<0||~isfinite(Ql),e.estado='CAUDAL_INVALIDO';return;endif
  qd=Ql*86400;
  qmin=min(curva.Q_m3_d);qmax=max(curva.Q_m3_d);
  if qd<qmin-1e-9,e.estado='FUERA_RANGO_BAJO';return;endif
  if qd>qmax+1e-9,e.estado='FUERA_RANGO_ALTO';return;endif
  Pwf=Pwf_fun(Ql);
  [Pint,succ]=bes2_presion_intake(Ql,param,Pwf);
  fl=bes2_pvt_intake(Ql,Pint,param);
  H=interp1(curva.Q_m3_s,curva.head_m,Ql,'pchip');
  eta=interp1(curva.Q_m3_s,curva.eta,Ql,'pchip');
  gvf=fl.gvf_bomba;
  fgH=max(0,1-param.bes2_head_gas_a*gvf-param.bes2_head_gas_b*gvf^2);
  fgE=max(0.15,1-param.bes2_eta_gas_a*gvf);
  Hgas=H*fgH;etag=max(eta*fgE,0.05);
  dP=fl.rho_l_kg_m3*9.80665*Hgas;
  Qg_total=Ql*param.GLR;
  [Pdesc_req,vlpdet]=compute_P_req(param,Ql,Qg_total,param.D_bomba);
  residuo=Pint+dP-Pdesc_req;
  P_hid_kW=Ql*dP/1000;
  P_eje_kW=P_hid_kW/etag;
  e=struct('Ql',Ql,'Q_m3_d',qd,'Pwf_Pa',Pwf,'Pintake_Pa',Pint,'Pdesc_req_Pa',Pdesc_req, ...
    'dP_bomba_Pa',dP,'head_m',Hgas,'head_sin_gas_m',H,'eta_bomba',etag,'eta_sin_gas',eta, ...
    'P_hid_kW',P_hid_kW,'P_eje_kW',P_eje_kW,'residuo',residuo,'fluido',fl,'succion',succ, ...
    'vlp_detalle',vlpdet,'valido',true,'estado','OK','factor_head_gas',fgH,'factor_eta_gas',fgE);
endfunction

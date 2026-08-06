function m = cgf_mapa_evaluar(Qstd,Ps,Ts,param,comp)
% Evalua mapa corregido a rpm actual. Qstd [m3/s standard].
  s=param.cgf_rpm/max(comp.rpm_base,1);
  gp=aos_gas_props(Ps,Ts,param);
  Qcorr=Qstd*86400*sqrt(Ts/gp.Tstd)/(Ps/gp.Pstd)*gp.Z;
  Qbase=Qcorr/max(s,1e-6);
  m=struct('valido',false,'estado','FUERA_MAPA','Qcorr_Sm3_d',Qcorr,'Qbase_Sm3_d',Qbase,'PR',NaN,'eta_p',NaN,'margen_surge_pct',NaN,'margen_choke_pct',NaN);
  if param.cgf_rpm<comp.rpm_min||param.cgf_rpm>comp.rpm_max,m.estado='RPM_FUERA_RANGO';return;endif
  if Qbase<min(comp.Qcorr_Sm3_d)||Qbase>max(comp.Qcorr_Sm3_d),return;endif
  PR0=interp1(comp.Qcorr_Sm3_d,comp.PR_base,Qbase,'pchip');eta=interp1(comp.Qcorr_Sm3_d,comp.eta_p,Qbase,'pchip');
  PR=exp(log(max(PR0,1.0001))*s^2);eta=min(max(eta,0.10),0.90);
  surge=comp.Q_surge*s;choke=comp.Q_choke*s;
  ms=100*(Qcorr-surge)/max(surge,1);mc=100*(choke-Qcorr)/max(choke,1);
  if Qcorr<surge,m.estado='SURGE';elseif Qcorr<1.10*surge,m.estado='CERCA_SURGE';elseif Qcorr>choke,m.estado='CHOKE';elseif Qcorr>0.95*choke,m.estado='CERCA_CHOKE';else,m.estado='ESTABLE';endif
  m.valido=Qcorr>=0.85*surge&&Qcorr<=1.05*choke;m.PR=PR;m.eta_p=eta;m.margen_surge_pct=ms;m.margen_choke_pct=mc;m.Q_surge=surge;m.Q_choke=choke;
endfunction

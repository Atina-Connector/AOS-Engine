function s = bes3_stage_performance(Q_liq_m3_s,gvf,curva,param)
% Rendimiento por etapa a caudal volumetrico real en intake.
  p=bes3_defaults(param);qd=max(Q_liq_m3_s,0)*86400;
  qmin=min(curva.Q_m3_d);qmax=max(curva.Q_m3_d);
  if qd<qmin-1e-9 || qd>qmax+1e-9
    s=struct('valido',false,'estado','FUERA_RANGO_CURVA','Q_m3_d',qd,'head_m',NaN,'eta',NaN,'fgH',NaN,'fgE',NaN);return;
  endif
  htot=interp1(curva.Q_m3_d,curva.head_m,qd,'pchip');
  eta0=interp1(curva.Q_m3_d,curva.eta,qd,'pchip');
  h0=htot/max(curva.num_etapas,1);
  g=min(max(gvf,0),0.95);
  fgH=max(0,1-p.bes2_head_gas_a*g-p.bes2_head_gas_b*g^2);
  fgE=max(0.15,1-p.bes2_eta_gas_a*g);
  s=struct('valido',true,'estado','OK','Q_m3_d',qd,'head_sin_gas_m',h0, ...
    'head_m',h0*fgH,'eta_sin_gas',eta0,'eta',max(eta0*fgE,0.05),'fgH',fgH,'fgE',fgE,'gvf',g);
endfunction

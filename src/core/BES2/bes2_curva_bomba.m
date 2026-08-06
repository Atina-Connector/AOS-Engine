function curva = bes2_curva_bomba(param,bomba)
% Aplica afinidad, etapas y corrección de viscosidad de screening.
  param=bes2_defaults(param);
  fr=param.frecuencia./max(bomba.frecuencia_base,1e-6);
  Q=bomba.Q_m3_d.*fr;
  H=bomba.head_m_etapa.*param.num_etapas.*fr.^2;
  eta=bomba.eta;
  nu=viscosidad_cSt_local(param);
  Cq=1;Ch=1;Ce=1;
  if param.bes2_visc_screening && nu>1
    L=max(log10(nu),0);
    Cq=max(0.72,1-0.018.*L.^1.7);
    Ch=max(0.68,1-0.028.*L.^1.7);
    Ce=max(0.52,1-0.055.*L.^1.7);
  endif
  Q=Q.*Cq;H=H.*Ch;eta=min(max(eta.*Ce,0.08),0.90);
  curva=struct('Q_m3_d',Q,'Q_m3_s',Q./86400,'head_m',H,'eta',eta, ...
    'Q_BEP_m3_d',bomba.Q_BEP_m3_d.*fr.*Cq,'Q_min_rec_m3_d',bomba.Q_min_rec_m3_d.*fr.*Cq, ...
    'Q_max_rec_m3_d',bomba.Q_max_rec_m3_d.*fr.*Cq,'frecuencia_Hz',param.frecuencia, ...
    'num_etapas',param.num_etapas,'Cq_visc',Cq,'Ch_visc',Ch,'Ceta_visc',Ce,'nu_cSt',nu);
endfunction

function nu=viscosidad_cSt_local(p)
  if isfield(p,'mu_o')&&isfinite(p.mu_o),mu=p.mu_o;else
    pv=pvt_calcular(p.P_res,max(p.T_fondo-273.15,0),p.API,p.gamma_g);mu=pv.mu_o;endif
  rho=max(p.rho_o,500);nu=mu./rho.*1e6;
endfunction

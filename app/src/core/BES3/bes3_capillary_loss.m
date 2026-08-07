function r = bes3_capillary_loss(Q_m3_s,rho,mu,cap,param)
% Darcy-Weisbach para capilar: laminar, transicion y turbulento.
  p=bes3_defaults(param);Q=max(Q_m3_s,0);D=max(cap.ID_m,1e-6);
  A=pi*D^2/4;v=Q/max(A,1e-16);rho=max(rho,1);mu=max(mu,1e-7);
  Re=rho*abs(v)*D/mu;rr=max(p.bes3_capilar_rugosidad_m,0)/D;
  if Re<=1e-12
    ff=0;reg='SIN_FLUJO';
  elseif Re<2300
    ff=64/Re;reg='LAMINAR';
  elseif Re<4000
    fl=64/2300;ft=0.25/(log10(max(rr/3.7+5.74/4000^0.9,1e-12)))^2;
    w=(Re-2300)/(4000-2300);ff=(1-w)*fl+w*ft;reg='TRANSICIONAL';
  else
    ff=0.25/(log10(max(rr/3.7+5.74/Re^0.9,1e-12)))^2;reg='TURBULENTO';
  endif
  K=p.bes3_capilar_K_entrada+p.bes3_capilar_K_salida+p.bes3_capilar_K_accesorios;
  dyn=0.5*rho*v^2;
  dP_major=ff*p.bes3_capilar_longitud_m/D*dyn;
  dP_minor=K*dyn;
  r=struct('Q_m3_s',Q,'Q_m3_d',Q*86400,'velocidad_m_s',v,'Re',Re,'factor_friccion',ff, ...
    'regimen',reg,'dP_friccion_Pa',dP_major,'dP_menores_Pa',dP_minor, ...
    'dP_total_Pa',dP_major+dP_minor,'longitud_m',p.bes3_capilar_longitud_m, ...
    'ID_m',D,'OD_m',cap.OD_m);
endfunction

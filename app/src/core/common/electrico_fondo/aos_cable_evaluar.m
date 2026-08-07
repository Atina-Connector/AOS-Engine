function r = aos_cable_evaluar(P_motor_kW,param)
% Cable trifásico, caída de tensión y pérdidas. Screening estacionario.
  param=aos_electrico_defaults(param);
  Vsup=max(param.voltaje_superficie_V,100);
  pf=min(max(param.motor_pm_factor_potencia,0.2),1);
  L=param.cable_longitud_m;
  if ~isfinite(L)
    if isfield(param,'D_bomba')&&isfinite(param.D_bomba),L=param.D_bomba;
    elseif isfield(param,'D_cgf')&&isfinite(param.D_cgf),L=param.D_cgf;
    else,L=2000;endif
  endif
  R20=max(param.cable_resistencia_ohm_km_20C,1e-5);
  Rkm=R20.*(1+param.cable_alpha_C.*(param.cable_T_C-20));
  Rfase=Rkm.*L./1000;
  Vfond=Vsup;
  I=0;
  for k=1:8
    I=max(P_motor_kW,0).*1000./max(sqrt(3).*Vfond.*pf,1);
    dV=sqrt(3).*I.*Rfase;
    Vnew=max(Vsup-dV,0.25.*Vsup);
    Vfond=0.5.*Vfond+0.5.*Vnew;
  endfor
  Pperd_kW=3.*I.^2.*Rfase./1000;
  caida_pct=100.*(Vsup-Vfond)./Vsup;
  if caida_pct>param.cable_caida_max_pct
    estado='CAIDA_TENSION_ALTA';
  else
    estado='OK';
  endif
  r=struct('V_superficie_V',Vsup,'V_fondo_V',Vfond,'corriente_A',I,'R_fase_ohm',Rfase, ...
           'perdidas_kW',Pperd_kW,'caida_pct',caida_pct,'estado',estado,'longitud_m',L);
endfunction

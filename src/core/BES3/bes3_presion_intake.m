function [Pint,detalle] = bes3_presion_intake(Ql,param,Pwf,geom)
% Presion en intake usando geometria anular de completacion, no tubing.
  p=bes3_defaults(param);if nargin<4||isempty(geom),geom=bes3_completion_geometry(p);endif
  Dres=p.D_res;Db=p.D_bomba;
  tvdr=aos_gas_tvd_at_md(p,Dres);tvdb=aos_gas_tvd_at_md(p,Db);
  dz=tvdr-tvdb;L=abs(Dres-Db);
  rho_liq=p.rho_o*(1-p.WC)+p.rho_w*p.WC;
  Pint=max(Pwf-rho_liq*9.80665*dz,1e5);
  dPfr=0;Hl=1;rho_mix=rho_liq;Re=0;ff=0;
  A=max(geom.area_succion_m2,1e-8);Dh=max(geom.Dh_succion_m,1e-4);
  for it=1:10
    Pavg=max(0.5*(Pwf+Pint),1e5);
    fl=bes2_pvt_intake(Ql,Pavg,p);
    qg=fl.Qg_free_local_m3_s;ql=fl.Ql_local_m3_s;
    vsl=ql/A;vsg=qg/A;vm=vsl+vsg;
    Hl=1-vsg/max(1.20*max(vm,1e-8)+0.25,1e-8);Hl=min(max(Hl,0.02),1);
    rho_mix=fl.rho_l_kg_m3*Hl+fl.gas_props.rho*(1-Hl);
    mu_mix=fl.mu_o_Pa_s*Hl+fl.gas_props.mu*(1-Hl);
    Re=rho_mix*abs(vm)*Dh/max(mu_mix,1e-7);
    ff=fric_local(Re,p.bes3_rugosidad_succion_m/Dh);
    dPfr=ff*L/Dh*0.5*rho_mix*vm^2;
    Pnew=max(Pwf-rho_mix*9.80665*dz-dPfr,1e5);
    Pint=0.45*Pint+0.55*Pnew;
  endfor
  detalle=struct('Pwf_Pa',Pwf,'Pintake_Pa',Pint,'deltaTVD_res_menos_intake_m',dz,'longitud_MD_m',L, ...
    'rho_mezcla_kg_m3',rho_mix,'holdup_liquido',Hl,'dP_friccion_Pa',dPfr, ...
    'area_flujo_m2',A,'diametro_hidraulico_m',Dh,'Re',Re,'factor_friccion',ff, ...
    'modelo','BES3_SUCCION_ANULAR_COMPLETACION');
endfunction
function ff=fric_local(Re,rr)
  if Re<=0,ff=0;elseif Re<2300,ff=64/max(Re,1);else,ff=0.25/(log10(max(rr/3.7+5.74/Re^0.9,1e-12)))^2;endif
endfunction

function [Pint,detalle] = bes2_presion_intake(Ql,param,Pwf)
% Presión disponible en intake usando exclusivamente D_bomba.
  Dres=param.D_res;Db=param.D_bomba;
  tvdr=aos_gas_tvd_at_md(param,Dres);tvdb=aos_gas_tvd_at_md(param,Db);
  dz=max(tvdr-tvdb,0);L=max(Dres-Db,0);
  rho_liq=param.rho_o*(1-param.WC)+param.rho_w*param.WC;
  Pint=max(Pwf-rho_liq*9.80665*dz,1e5);
  dPfr=0;Hl=1;rho_mix=rho_liq;
  for it=1:8
    Pavg=max(0.5*(Pwf+Pint),1e5);
    fl=bes2_pvt_intake(Ql,Pavg,param);
    qg=fl.Qg_free_local_m3_s;ql=fl.Ql_local_m3_s;
    A=pi*max(param.diam_tbg,1e-3)^2/4;
    vsl=ql/A;vsg=qg/A;vm=vsl+vsg;
    Hl=1-vsg./max(1.20*max(vm,1e-8)+0.25,1e-8);Hl=min(max(Hl,0.02),1);
    rho_mix=fl.rho_l_kg_m3*Hl+fl.gas_props.rho*(1-Hl);
    v=vm;Re=rho_mix*abs(v)*param.diam_tbg/max(fl.mu_o_Pa_s*Hl+fl.gas_props.mu*(1-Hl),1e-6);
    ff=fric_local(Re,getnum_local(param,{'rugosidad'},4.6e-5)/param.diam_tbg);
    dPfr=ff*L/param.diam_tbg*0.5*rho_mix*v^2;
    Pnew=max(Pwf-rho_mix*9.80665*dz-dPfr,1e5);
    Pint=0.45*Pint+0.55*Pnew;
  endfor
  detalle=struct('Pwf_Pa',Pwf,'Pintake_Pa',Pint,'deltaTVD_m',dz,'longitud_MD_m',L, ...
    'rho_mezcla_kg_m3',rho_mix,'holdup_liquido',Hl,'dP_friccion_Pa',dPfr,'modelo','BES2_SUCCION_ESPECIFICA');
endfunction

function ff=fric_local(Re,rr)
  if Re<=0,ff=0;elseif Re<2300,ff=64/max(Re,1);else,ff=0.25/(log10(max(rr/3.7+5.74/Re^0.9,1e-12)))^2;endif
endfunction
function v=getnum_local(s,campos,defecto)
  v=defecto;for k=1:numel(campos),if isfield(s,campos{k})&&isnumeric(s.(campos{k}))&&~isempty(s.(campos{k}))&&isfinite(s.(campos{k})(1)),v=s.(campos{k})(1);return;endif,endfor
endfunction

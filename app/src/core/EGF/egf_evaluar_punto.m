function e=egf_evaluar_punto(Qs,param,geom,Pwf_fun)
  Pwf=Pwf_fun(Qs);D=param.D_egf;Ts=aos_temperatura_at_md(param,D);
  [Ps,lower]=aos_gas_profile(Pwf,Qs,param.D_res,D,param.diam_tbg,param,'FOLLOW');
  [Pd0,~]=aos_gas_profile(param.P_wh,Qs,0,D,param.diam_tbg,param,'OPPOSE');
  dev=jet_gas_gas_operar(param.P_motriz_sup,Ps,Ts,Qs,Pd0,D,param,geom);
  if ~dev.valido,e=struct('valido',false,'estado',dev.estado,'residuo',NaN,'Qs',Qs);return;endif
  gp=aos_gas_props(Ps,Ts,param);Psrc=max(param.egf_P_fuente_sup,1e5);PR=max(param.P_motriz_sup/Psrc,1);work=gp.Z*gp.R*param.T_sup*gp.k/(gp.k-1)*(PR^((gp.k-1)/(gp.k*param.egf_eta_comp_superficie))-1);P_eq=dev.mp*work/1000;
  e=dev;e.Pwf=Pwf;e.Ps=Ps;e.lower_profile=lower;e.P_equiv_superficie_kW=P_eq;e.valido=true;e.estado=dev.regimen;
endfunction

function f = bes2_pvt_intake(Ql,P_intake,param)
% Propiedades locales y gas libre en intake.
  T=aos_temperatura_at_md(param,param.D_bomba);
  pv=pvt_calcular(max(P_intake,1e5),T-273.15,param.API,param.gamma_g);
  rho_o_local=param.rho_o./max(pv.Bo,0.5);
  rho_l=rho_o_local.*(1-param.WC)+param.rho_w.*param.WC;
  Rs=min(max(pv.Rs,0),max(param.GLR,0));
  Qg_free_std=max(param.GLR-Rs,0).*max(Ql,0);
  gp=aos_gas_props(max(P_intake,1e5),T,param);
  Qg_local=Qg_free_std.*(gp.Pstd./max(P_intake,1e5)).*(T./gp.Tstd).*gp.Z;
  Ql_local=max(Ql,0).*max(pv.Bo,0.5);
  gvf_free=Qg_local./max(Qg_local+Ql_local,1e-12);
  eta_sep=min(max(param.bes2_eta_separador,0),1);
  Qg_pump_local=Qg_local.*(1-eta_sep);
  gvf_pump=Qg_pump_local./max(Qg_pump_local+Ql_local,1e-12);
  f=struct('T_K',T,'P_Pa',P_intake,'Rs_Sm3_m3',Rs,'Bo',pv.Bo,'mu_o_Pa_s',pv.mu_o, ...
    'rho_l_kg_m3',rho_l,'Qg_free_std_m3_s',Qg_free_std,'Qg_free_local_m3_s',Qg_local, ...
    'Ql_local_m3_s',Ql_local,'gvf_free',gvf_free,'gvf_bomba',gvf_pump,'eta_separador',eta_sep, ...
    'gas_props',gp);
endfunction

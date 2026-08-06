function e = cgf_evaluar_punto(Qstd,param,comp,Pwf_fun)
  e=struct('Qstd',Qstd,'valido',false,'estado','NO_EVALUADO','residuo',NaN);
  Pwf=Pwf_fun(Qstd);Dres=param.D_res;D=param.D_cgf;Ts=aos_temperatura_at_md(param,D);
  [Ps,lower]=aos_gas_profile(Pwf,Qstd,Dres,D,param.diam_tbg,param,'FOLLOW');
  [Pd_req,upper_inv]=aos_gas_profile(param.P_wh,Qstd,0,D,param.diam_tbg,param,'OPPOSE');
  map=cgf_mapa_evaluar(Qstd,Ps,Ts,param,comp);if ~map.valido&&(~isfield(map,'PR')||~isfinite(map.PR)),e.estado=map.estado;return;endif
  Pd=Ps*map.PR;res=Pd-Pd_req;gp=aos_gas_props(Ps,Ts,param);mdot=Qstd*gp.rho_std;k=gp.k;R=gp.R;Z=gp.Z;
  work=Z*R*Ts*k/(k-1)*(map.PR^((k-1)/(k*map.eta_p))-1);Pgas=mdot*work/1000;Peje=Pgas/0.97;
  Td=Ts*map.PR^((k-1)/(k*map.eta_p));
  e=struct('Qstd',Qstd,'Q_Sm3_d',Qstd*86400,'Pwf_Pa',Pwf,'Ps_Pa',Ps,'Pd_req_Pa',Pd_req,'Pd_Pa',Pd,'residuo',res, ...
    'mapa',map,'P_gas_kW',Pgas,'P_eje_kW',Peje,'T_s_K',Ts,'T_d_K',Td,'m_dot_kg_s',mdot,'lower_profile',lower,'upper_profile',upper_inv, ...
    'valido',true,'estado',map.estado);
endfunction

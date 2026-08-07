function r = jet_gas_gas_operar(Pm_sup, Ps, Ts, Qs_std, Pd_req_in, D, param, geom)
% Eyector gas-gas cuasi-1D. Resuelve Pmix por compatibilidad de caudal secundario.
% Incluye gas motriz por anular, choking y recuperación compresible en difusor.

  gp_s=aos_gas_props(Ps,Ts,param);ms_req=max(Qs_std,0)*gp_s.rho_std;
  Pmix_min=max(0.12*Ps,1.0e4);Pmix_max=0.995*Ps;
  Pd_req=Pd_req_in;best=[];
  for outer=1:6
    [cand,ok]=resolver_pmix_local(Pmix_min,Pmix_max,ms_req,Pm_sup,Ps,Ts,D,param,geom);
    if ~ok
      r=struct('valido',false,'estado','SIN_CAPACIDAD_ASPIRACION','residuo',NaN,'Qm_std',0);return;
    endif
    Qt=Qs_std+cand.Qm_std;
    [Pd_new,upper]=aos_gas_profile(param.P_wh,Qt,0,D,param.diam_tbg,param,'OPPOSE');
    Pd_req=0.45*Pd_req+0.55*Pd_new;cand.upper_profile=upper;best=cand;
  endfor
  best.Pd_req=Pd_req;best.residuo=best.Pd_pred-Pd_req;
  best.entrainment=ms_req/max(best.mp,1e-12);best.Qs_std=Qs_std;best.Qtotal_std=Qs_std+best.Qm_std;
  if best.primary.choked&&best.secondary.choked,best.regimen='DOBLE_ESTRANGULAMIENTO';
  elseif best.primary.choked,best.regimen='PRIMARIO_ESTRANGULADO';
  elseif best.secondary.choked,best.regimen='SECUNDARIO_ESTRANGULADO';
  else,best.regimen='SUBCRITICO';endif
  best.valido=true;best.estado='OK';r=best;
endfunction

function [best,ok]=resolver_pmix_local(a,b,ms_req,Pm_sup,Ps,Ts,D,param,g)
  n=45;pv=linspace(a,b,n);F=NaN(n,1);C=cell(n,1);
  for i=1:n,[C{i},F(i)]=eval_pmix_local(pv(i),ms_req,Pm_sup,Ps,Ts,D,param,g);endfor
  ok=false;best=[];
  for i=1:n-1
    if isfinite(F(i))&&F(i)*F(i+1)<=0
      lo=pv(i);hi=pv(i+1);ca=C{i};fa=F(i);
      for k=1:50
        m=0.5*(lo+hi);[cm,fm]=eval_pmix_local(m,ms_req,Pm_sup,Ps,Ts,D,param,g);ca=cm;
        if abs(fm)<=max(ms_req,1e-6)*1e-4,break;endif
        if fa*fm<=0,hi=m;else,lo=m;fa=fm;endif
      endfor
      best=ca;ok=true;return;
    endif
  endfor
  idx=find(isfinite(F));if ~isempty(idx),[v,j]=min(abs(F(idx)));if v<=max(ms_req,1e-6)*0.05,best=C{idx(j)};ok=true;endif,endif
endfunction

function [c,F]=eval_pmix_local(Pmix,ms_req,Pm_sup,Ps,Ts,D,param,g)
  Qm=0;Pm=Pm_sup;prof=[];primary=[];
  for it=1:7
    IDc=getnum_local(param,{'ID_casing','diam_casing'},0.14);ODt=getnum_local(param,{'OD_tubing'},0.073);pa=param;pa.gas_profile_area_m2=pi/4*max(IDc^2-ODt^2,1e-6);Dh=max(IDc-ODt,0.01);
    [Pm_new,prof]=aos_gas_profile(Pm_sup,Qm,0,D,Dh,pa,'FOLLOW');
    primary=aos_gas_flow_nozzle(Pm_new,aos_temperatura_at_md(param,D),Pmix,g.A_nozzle,g.Cd_primary,param);
    Qcalc=min(primary.Qstd,g.Qm_max_Sm3_d/86400);Qm=0.45*Qm+0.55*Qcalc;Pm=Pm_new;
  endfor
  secondary=aos_gas_flow_nozzle(Ps,Ts,Pmix,max(g.A_throat-g.A_nozzle,1e-9),g.Cd_secondary,param);
  F=secondary.m_dot-ms_req;
  mp=min(primary.m_dot,Qm*primary.props_up.rho_std);ms=ms_req;
  vp=mp/max(primary.props_down.rho*g.A_nozzle,1e-12);vs=ms/max(secondary.props_down.rho*max(g.A_throat-g.A_nozzle,1e-9),1e-12);
  Tm=aos_temperatura_at_md(param,D);Tmix=(mp*Tm+ms*Ts)/max(mp+ms,1e-12);gm=aos_gas_props(Pmix,Tmix,param);
  vmix=(mp*vp+ms*vs)/max(mp+ms,1e-12);a=sqrt(gm.k*gm.R*Tmix*gm.Z);Mach=abs(vmix)/max(a,1);
  P0mix=Pmix*(1+(gm.k-1)/2*Mach^2)^(gm.k/(gm.k-1));Pcap=(mp*Pm+ms*Ps)/max(mp+ms,1e-12);
  Pd_pred=min(Pmix+g.eta_diffuser*(P0mix-Pmix),Pcap);
  c=struct('Pmix',Pmix,'Pm_fondo',Pm,'Pd_pred',Pd_pred,'mp',mp,'ms',ms,'Qm_std',Qm, ...
    'vp',vp,'vs',vs,'vmix',vmix,'Mach_mix',Mach,'Tmix_K',Tmix,'primary',primary,'secondary',secondary,'motive_profile',prof);
endfunction

function v=getnum_local(s,c,d),v=d;for i=1:numel(c),if isfield(s,c{i})&&isnumeric(s.(c{i}))&&~isempty(s.(c{i}))&&isfinite(s.(c{i})(1)),v=s.(c{i})(1);return;endif,endfor,endfunction

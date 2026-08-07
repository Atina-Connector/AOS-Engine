function sol = cgf_solver(param)
  p=cgf_defaults(param);comp=cgf_cargar_compresor(p);p.motor_pm_potencia_nominal_kW=comp.motor_pm_potencia_nominal_kW;p.motor_pm_eta_nominal=comp.motor_pm_eta_nominal;p.motor_pm_rpm_nominal=comp.motor_pm_rpm_nominal;
  [Qmax,pwf,iprmeta]=aos_gas_ipr(p);q=linspace(max(Qmax*1e-4,1/86400),Qmax,max(81,round(p.cgf_n_puntos_solver)));R=NaN(size(q));E=cell(size(q));
  for i=1:numel(q),E{i}=cgf_evaluar_punto(q(i),p,comp,pwf);if E{i}.valido,R(i)=E{i}.residuo;endif,endfor
  roots=[];ers={};for i=1:numel(q)-1,if isfinite(R(i))&&isfinite(R(i+1))&&R(i)*R(i+1)<0,[qr,er]=bisect_local(q(i),q(i+1),p,comp,pwf);roots(end+1)=qr;ers{end+1}=er;endif,endfor
  if isempty(roots)
    idx=find(isfinite(R));if isempty(idx),sol=empty_local(p,comp,iprmeta,'SIN_PUNTOS_VALIDOS');return;endif
    [~,j]=min(abs(R(idx)));best=E{idx(j)};sol=armar_local(p,comp,iprmeta,best,roots,q,R,'SIN_CRUCE_VALIDADO',false);return;
  endif
  score=zeros(numel(roots),1);for k=1:numel(roots),score(k)=abs(ers{k}.mapa.Qcorr_Sm3_d-0.5*(ers{k}.mapa.Q_surge+ers{k}.mapa.Q_choke))/max(ers{k}.mapa.Q_choke,1);if ~strcmp(ers{k}.mapa.estado,'ESTABLE'),score(k)=score(k)+2;endif,endfor
  [~,j]=min(score);sol=armar_local(p,comp,iprmeta,ers{j},roots,q,R,'CONVERGIDO',true);
endfunction
function [qr,er]=bisect_local(a,b,p,c,pwf),ea=cgf_evaluar_punto(a,p,c,pwf);fa=ea.residuo;qr=a;er=ea;for k=1:p.cgf_max_biseccion,m=0.5*(a+b);em=cgf_evaluar_punto(m,p,c,pwf);fm=em.residuo;qr=m;er=em;if abs(fm)<=p.cgf_tol_P_bar*1e5,break;endif;if fa*fm<=0,b=m;else,a=m;fa=fm;endif,endfor,endfunction
function sol=armar_local(p,c,im,e,roots,q,R,estado,conv)
  gp=aos_gas_props(e.Ps_Pa,e.T_s_K,p);ql=p.cgf_Qliq_m3_d/86400;A=pi*p.diam_tbg^2/4;qlo=e.Qstd*(gp.Pstd/e.Ps_Pa)*(e.T_s_K/gp.Tstd)*gp.Z;v=qlo/A;liqfrac=ql/max(ql+qlo,1e-12);
  Aann=pi/4*max(p.ID_casing^2-p.OD_motor^2,0);vref=qlo/max(Aann,1e-12);elec=aos_electrico_fondo_evaluar(e.P_eje_kW,p.cgf_rpm,vref,e.T_s_K-273.15,p);
  liquid_state='GAS_SECO';if liqfrac>c.fraccion_liquida_max,liquid_state='FUERA_ENVOLVENTE_LIQUIDA';elseif liqfrac>0.5*c.fraccion_liquida_max,liquid_state='GAS_HUMEDO_ADMISIBLE';endif
  accepted=conv&&strcmp(e.mapa.estado,'ESTABLE')&&strcmp(elec.estado,'OK')&&~strcmp(liquid_state,'FUERA_ENVOLVENTE_LIQUIDA')&&e.Pd_Pa/1e5<c.presion_max_bar&&e.T_d_K-273.15<c.temperatura_max_C;
  sol=struct('version','CGF_V1_0_1_1_ALPHA1','estado',estado,'convergido',conv,'aceptado',accepted,'param',p,'compresor',c,'ipr',im,'punto',e, ...
    'Qg_Sm3_d',e.Q_Sm3_d,'liquid_fraction',liqfrac,'liquid_state',liquid_state,'electrico',elec,'raices_Sm3_d',roots*86400,'n_raices',numel(roots), ...
    'barrido_Q_Sm3_d',q*86400,'barrido_residuo_bar',R/1e5,'diagnostico',sprintf('Mapa=%s | Liquidos=%s | Electrico=%s | Aceptado=%d',e.mapa.estado,liquid_state,elec.estado,accepted));
endfunction
function s=empty_local(p,c,i,e),s=struct('version','CGF_V1_0_1_1_ALPHA1','estado',e,'convergido',false,'aceptado',false,'param',p,'compresor',c,'ipr',i,'Qg_Sm3_d',0,'n_raices',0,'barrido_Q_Sm3_d',[],'barrido_residuo_bar',[],'diagnostico',e);endfunction

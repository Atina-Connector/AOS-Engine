function sol=egf_solver(param)
  p=egf_defaults(param);g=egf_cargar_eyector(p);[Qmax,pwf,im]=aos_gas_ipr(p);q=linspace(max(Qmax*1e-4,1/86400),Qmax,max(61,round(p.egf_n_puntos_solver)));R=NaN(size(q));E=cell(size(q));
  for i=1:numel(q),E{i}=egf_evaluar_punto(q(i),p,g,pwf);if E{i}.valido,R(i)=E{i}.residuo;endif,endfor
  roots=[];ers={};for i=1:numel(q)-1,if isfinite(R(i))&&isfinite(R(i+1))&&R(i)*R(i+1)<0,[qr,er]=bisect_local(q(i),q(i+1),p,g,pwf);roots(end+1)=qr;ers{end+1}=er;endif,endfor
  if isempty(roots),idx=find(isfinite(R));if isempty(idx),sol=empty_local(p,g,im,'SIN_PUNTOS_VALIDOS');return;endif;[~,j]=min(abs(R(idx)));sol=armar_local(p,g,im,E{idx(j)},roots,q,R,'SIN_CRUCE_VALIDADO',false);return;endif
  score=zeros(numel(roots),1);for k=1:numel(roots),score(k)=abs(ers{k}.residuo)/1e5;if strcmp(ers{k}.regimen,'SUBCRITICO'),score(k)=score(k)+0.2;endif,endfor;[~,j]=min(score);sol=armar_local(p,g,im,ers{j},roots,q,R,'CONVERGIDO',true);
endfunction
function [qr,er]=bisect_local(a,b,p,g,pwf),ea=egf_evaluar_punto(a,p,g,pwf);fa=ea.residuo;qr=a;er=ea;for k=1:p.egf_max_biseccion,m=0.5*(a+b);em=egf_evaluar_punto(m,p,g,pwf);fm=em.residuo;qr=m;er=em;if abs(fm)<=p.egf_tol_P_bar*1e5,break;endif;if fa*fm<=0,b=m;else,a=m;fa=fm;endif,endfor,endfunction
function s=armar_local(p,g,im,e,roots,q,R,est,conv)
  net=e.Qs_std*86400;e.Qm_Sm3_d=e.Qm_std*86400;e.Qs_Sm3_d=net;e.Qtotal_Sm3_d=e.Qtotal_std*86400;
  accepted=conv&&e.Pd_pred<=g.presion_max_bar*1e5&&e.Tmix_K-273.15<=g.temperatura_max_C&&e.entrainment>0;
  s=struct('version','EGF_V1_0_1_1_ALPHA1','estado',est,'convergido',conv,'aceptado',accepted,'param',p,'eyector',g,'ipr',im,'punto',e, ...
    'Qg_aspirado_Sm3_d',net,'Qg_motriz_Sm3_d',e.Qm_Sm3_d,'Qg_total_Sm3_d',e.Qtotal_Sm3_d,'ganancia_neta_Sm3_d',net, ...
    'n_raices',numel(roots),'raices_Sm3_d',roots*86400,'barrido_Qs_Sm3_d',q*86400,'barrido_residuo_bar',R/1e5, ...
    'diagnostico',sprintf('Regimen=%s | Entrainment=%.3f | Potencia equivalente=%.2f kW | Aceptado=%d',e.regimen,e.entrainment,e.P_equiv_superficie_kW,accepted));
endfunction
function s=empty_local(p,g,i,e),s=struct('version','EGF_V1_0_1_1_ALPHA1','estado',e,'convergido',false,'aceptado',false,'param',p,'eyector',g,'ipr',i,'Qg_aspirado_Sm3_d',0,'Qg_motriz_Sm3_d',0,'Qg_total_Sm3_d',0,'n_raices',0,'barrido_Qs_Sm3_d',[],'barrido_residuo_bar',[],'diagnostico',e);endfunction

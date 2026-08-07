function sol = bes2_solver(param)
% Solver único BES V2: barrido completo, todas las raíces y selección física.
  param=bes2_defaults(param);bomba=bes2_cargar_bomba(param);curva=bes2_curva_bomba(param,bomba);
  [Qipr,Pwf_fun]=ipr(param,param.modelo_IPR);
  qlo=max(min(curva.Q_m3_s),0);qhi=min(max(curva.Q_m3_s),Qipr);
  n=max(round(param.bes2_n_puntos_solver),61);
  if qhi<=qlo
    sol=sol_vacia_local(param,bomba,curva,'DOMINIO_VACIO');return;
  endif
  q=linspace(qlo,qhi,n);R=NaN(size(q));evals=cell(size(q));
  for i=1:numel(q),evals{i}=bes2_evaluar_punto(q(i),param,curva,Pwf_fun);if evals{i}.valido,R(i)=evals{i}.residuo;endif,endfor
  roots=[];root_eval={};
  for i=1:numel(q)-1
    if isfinite(R(i))&&abs(R(i))<=param.bes2_tol_P_bar*1e5
      roots(end+1)=q(i);root_eval{end+1}=evals{i};
    elseif isfinite(R(i))&&isfinite(R(i+1))&&R(i)*R(i+1)<0
      [qr,er]=bisect_local(q(i),q(i+1),param,curva,Pwf_fun);roots(end+1)=qr;root_eval{end+1}=er;
    endif
  endfor
  if isempty(roots)
    idx=find(isfinite(R));
    if isempty(idx),sol=sol_vacia_local(param,bomba,curva,'SIN_PUNTOS_VALIDOS');return;endif
    [~,jj]=min(abs(R(idx)));best=evals{idx(jj)};
    if all(R(idx)>0),estado='LIMITADO_POR_RESERVORIO_O_CURVA';else,estado='SIN_CAPACIDAD_BOMBA';endif
    sol=armar_local(param,bomba,curva,best,roots,root_eval,q,R,estado,false);return;
  endif
  scores=zeros(numel(roots),1);
  for k=1:numel(roots)
    qd=roots(k)*86400;dist=abs(qd-curva.Q_BEP_m3_d)/max(curva.Q_BEP_m3_d,1);
    fuera=double(qd<curva.Q_min_rec_m3_d||qd>curva.Q_max_rec_m3_d);
    scores(k)=dist+2*fuera;
  endfor
  [~,ib]=min(scores);best=root_eval{ib};
  sol=armar_local(param,bomba,curva,best,roots,root_eval,q,R,'CONVERGIDO',true);
endfunction

function [qr,er]=bisect_local(a,b,p,c,pwf)
  ea=bes2_evaluar_punto(a,p,c,pwf);fa=ea.residuo;er=ea;qr=a;
  for k=1:p.bes2_max_biseccion
    m=0.5*(a+b);em=bes2_evaluar_punto(m,p,c,pwf);fm=em.residuo;qr=m;er=em;
    if abs(fm)<=p.bes2_tol_P_bar*1e5,break;endif
    if fa*fm<=0,b=m;else,a=m;fa=fm;endif
  endfor
endfunction

function sol=armar_local(p,b,c,e,roots,revals,q,R,estado,conv)
  if isempty(e)||~isstruct(e)||~isfield(e,'Ql'),sol=sol_vacia_local(p,b,c,estado);return;endif
  Aann=pi/4*max(p.ID_casing^2-p.OD_motor^2,0);
  vref=e.Ql/max(Aann,1e-12);
  Tamb=aos_temperatura_at_md(p,p.D_bomba)-273.15;
  rpm=b.rpm_base*(p.frecuencia/b.frecuencia_base);
  elec=aos_electrico_fondo_evaluar(e.P_eje_kW,rpm,vref,Tamb,p);
  qd=e.Q_m3_d;percent_bep=100*qd/max(c.Q_BEP_m3_d,1e-12);
  if e.fluido.gvf_bomba>=p.bes2_gvf_lock,gas_state='RIESGO_GAS_LOCK';
  elseif e.fluido.gvf_bomba>=p.bes2_gvf_interferencia,gas_state='INTERFERENCIA_GAS';
  else,gas_state='GAS_ADMISIBLE';endif
  if qd<c.Q_min_rec_m3_d,range='BAJO_RANGO_RECOMENDADO';elseif qd>c.Q_max_rec_m3_d,range='ALTO_RANGO_RECOMENDADO';else,range='DENTRO_RANGO_RECOMENDADO';endif
  aceptado=conv&&strcmp(range,'DENTRO_RANGO_RECOMENDADO')&&~strcmp(gas_state,'RIESGO_GAS_LOCK')&&strcmp(elec.estado,'OK');
  sol=struct('version','BES_V2_0_1_1_ALPHA1','estado',estado,'convergido',conv,'aceptado',aceptado, ...
    'param',p,'bomba',b,'curva',c,'punto',e,'Ql_m3_d',qd,'Qo_m3_d',qd*(1-p.WC), ...
    'Qg_total_Sm3_d',e.Ql*p.GLR*86400,'percent_BEP',percent_bep,'rango_estado',range,'gas_estado',gas_state, ...
    'electrico',elec,'raices_m3_d',roots*86400,'n_raices',numel(roots), ...
    'barrido_Q_m3_d',q*86400,'barrido_residuo_bar',R/1e5,'diagnostico',diagnostico_local(estado,range,gas_state,elec.estado,aceptado));
endfunction

function s=diagnostico_local(a,b,c,d,ok)
  s=sprintf('Solver=%s | Curva=%s | Gas=%s | Electrico=%s | Aceptado=%d',a,b,c,d,ok);
endfunction
function sol=sol_vacia_local(p,b,c,e)
  sol=struct('version','BES_V2_0_1_1_ALPHA1','estado',e,'convergido',false,'aceptado',false,'param',p,'bomba',b,'curva',c, ...
    'Ql_m3_d',0,'Qo_m3_d',0,'Qg_total_Sm3_d',0,'n_raices',0,'raices_m3_d',[],'barrido_Q_m3_d',[],'barrido_residuo_bar',[], ...
    'diagnostico',['BES V2: ' e]);
endfunction

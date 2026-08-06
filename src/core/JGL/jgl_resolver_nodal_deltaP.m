function [Q,det] = jgl_resolver_nodal_deltaP(p,Qiny,dP)
% Cruce nodal con incremento de presion del eductor fijo durante una iteracion.
  [Qmax,~]=ipr(p,p.modelo_IPR); hi=max(Qmax*0.99,0); det=struct('estado','SIN_CRUCE','mensaje','');
  if hi<=1e-12,Q=0;det.estado='LIMITADO_POR_RESERVORIO';return;end
  nq=120; if isfield(p,'sens_jgl_n_puntos') && isnumeric(p.sens_jgl_n_puntos) && isfinite(p.sens_jgl_n_puntos), nq=max(31,min(1001,round(p.sens_jgl_n_puntos))); end
  q=linspace(max(1e-10,hi*1e-7),hi,nq); f=NaN(size(q));
  for k=1:length(q), f(k)=res(q(k),p,Qiny,dP); end
  ix=find(isfinite(f(1:end-1))&isfinite(f(2:end))&f(1:end-1).*f(2:end)<=0);
  if isempty(ix)
    ok=find(f>=0 & isfinite(f));
    if isempty(ok),Q=0;det.estado='LIMITADO_POR_VLP';else,Q=q(ok(end));det.estado='LIMITADO_POR_RESERVORIO';end
    return;
  end
  a=q(ix(end)); b=q(ix(end)+1); fa=res(a,p,Qiny,dP);
  for n=1:60
    c=(a+b)/2; fc=res(c,p,Qiny,dP);
    if abs(fc)<1e3||abs(b-a)<max(1e-10,1e-6*c),break;end
    if fa*fc<=0,b=c;else,a=c;fa=fc;end
  end
  Q=(a+b)/2; det.estado='CONVERGIDO_NODAL';
end
function r=res(Q,p,Qiny,dP)
  Ps=calcular_columna_succion(Q,p); D=aos_profundidad_inyeccion(p,p.D_iny);
  [Preq,~]=compute_P_req(p,Q,Qiny+Q*max(p.GLR,0),D); r=Ps+dP-Preq;
end

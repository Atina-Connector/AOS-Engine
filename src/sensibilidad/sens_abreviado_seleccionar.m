function A = sens_abreviado_seleccionar(x,y)
% SENS_ABREVIADO_SELECCIONAR Ajuste polinomico controlado y seleccion.
% El polinomio no reemplaza resultados del solver: solo elige verificaciones.
  x=x(:)'; y=y(:)'; n=numel(x);
  A=struct('grado',0,'coef',[],'estimado',NaN(size(y)),'residuo',NaN(size(y)), ...
    'seleccion',false(size(y)),'rms',NaN,'estado','SIN_DATOS');
  ok=isfinite(x)&isfinite(y);
  if sum(ok)<4, A.seleccion(ok)=true; A.estado='DATOS_INSUFICIENTES'; return; end
  xmin=min(x(ok)); xmax=max(x(ok));
  if xmax<=xmin, A.seleccion(ok)=true; A.estado='EJE_DEGENERADO'; return; end
  xn=2*(x-xmin)/(xmax-xmin)-1;
  grados=unique([min(4,sum(ok)-2),min(5,sum(ok)-2)]);
  best=[]; bestscore=Inf;
  for g=grados
    if g<2, continue; end
    c=polyfit(xn(ok),y(ok),g); yh=polyval(c,xn); r=y-yh;
    rms=sqrt(mean(r(ok).^2));
    % Penalizacion leve al grado mayor para evitar oscilacion gratuita.
    score=rms*(1+0.03*g);
    if score<bestscore, bestscore=score; best={g,c,yh,r,rms}; end
  end
  if isempty(best), A.seleccion(ok)=true; A.estado='AJUSTE_FALLIDO'; return; end
  A.grado=best{1}; A.coef=best{2}; A.estimado=best{3}; A.residuo=best{4}; A.rms=best{5};
  sel=false(1,n); valid=find(ok); sel(valid(1))=true; sel(valid(end))=true;
  [~,imx]=max(y(ok)); [~,imn]=min(y(ok)); sel(valid(imx))=true; sel(valid(imn))=true;
  escala=max(0.5,0.005*max(abs(y(ok)))); umbral=max(escala,2.5*max(A.rms,eps));
  sel(ok & abs(A.residuo)>umbral)=true;
  % Maxima curvatura discreta y cambios de pendiente.
  curv=zeros(1,n);
  for i=2:n-1
    if all(ok(i-1:i+1))
      curv(i)=abs(y(i+1)-2*y(i)+y(i-1))/max(abs(y(i)),1e-12);
      d1=y(i)-y(i-1); d2=y(i+1)-y(i);
      if d1*d2<=0, sel(i)=true; end
    end
  end
  [~,ord]=sort(curv,'descend');
  for k=1:min(2,n), if curv(ord(k))>0, sel(ord(k))=true; end; end
  % Estacionarios del polinomio, proyectados sobre la malla.
  dc=polyder(A.coef); rr=roots(dc);
  for k=1:numel(rr)
    if isreal(rr(k)) && rr(k)>=-1 && rr(k)<=1
      [~,j]=min(abs(xn-real(rr(k)))); sel(j)=true;
    end
  end
  % Limitar verificaciones: extremos + hasta 6 puntos relevantes.
  idx=find(sel); maxv=min(n,max(4,min(6,ceil(n/3))));
  if numel(idx)>maxv
    score=zeros(size(idx));
    for k=1:numel(idx)
      j=idx(k); score(k)=abs(A.residuo(j))/max(umbral,eps)+curv(j);
      if j==valid(1)||j==valid(end), score(k)=score(k)+100; end
    end
    [~,o]=sort(score,'descend'); sel(:)=false; sel(idx(o(1:maxv)))=true;
  end
  A.seleccion=sel; A.estado='OK';
end

function [D,detalle] = mandriles_buscar_profundidad(casing,tubing,dP_bar,Dmin,Dmax)
% Busca el cruce más profundo Pc-Pt-dP=0, con interpolación lineal.
  md=casing.MD(:); m=(md>=Dmin & md<=Dmax);
  x=md(m); f=casing.P(m)-tubing.P(m)-dP_bar*1e5;
  D=NaN; detalle=struct('estado','SIN_CRUCE','margen_bar',NaN);
  if numel(x)<2, return; end
  idx=find(f(1:end-1).*f(2:end)<=0);
  if isempty(idx)
    pos=find(f>=0);
    if isempty(pos), return; end
    D=x(pos(end));
  else
    j=idx(end); x1=x(j); x2=x(j+1); y1=f(j); y2=f(j+1);
    if abs(y2-y1)<eps, D=(x1+x2)/2; else, D=x1-y1*(x2-x1)/(y2-y1); end
  end
  Pc=interp1(casing.MD,casing.P,D,'linear'); Pt=interp1(tubing.MD,tubing.P,D,'linear');
  detalle=struct('estado','CRUCE','Pc_bar',Pc/1e5,'Pt_bar',Pt/1e5, ...
      'margen_bar',(Pc-Pt)/1e5-dP_bar);
end

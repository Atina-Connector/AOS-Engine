function [plana,detalle]=sens_detectar_curva_plana(y)
% Detecta cuando el maximo es solo ruido numerico y no un optimo ingenieril.
  yf=y(isfinite(y));
  detalle=struct('rango',NaN,'umbral',NaN,'relativo',NaN);
  if isempty(yf), plana=true; return; end
  rango=max(yf)-min(yf); base=max(abs(mean(yf)),1e-12);
  umbral=max(0.5,0.005*base); % 0.5 m3/d o 0.5 %, el mayor
  plana=rango<umbral; detalle.rango=rango; detalle.umbral=umbral; detalle.relativo=rango/base;
end

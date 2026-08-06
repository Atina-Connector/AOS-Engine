function info = sens_clasificar_curva(x,y)
% Clasifica una curva antes de declarar un optimo ingenieril.
  info=struct('tipo','SIN_DATOS','plana',true,'optimo_x',NaN,'optimo_y',NaN, ...
    'indice',NaN,'rango',NaN,'umbral',NaN,'mensaje','Sin datos validos.');
  ok=isfinite(x)&isfinite(y);x=x(ok);y=y(ok);
  if numel(y)<2,return;end
  [pl,det]=sens_detectar_curva_plana(y);info.plana=pl;info.rango=det.rango;info.umbral=det.umbral;
  if pl
    info.tipo='PLANA';info.mensaje=sprintf('Curva plana: rango %.3g menor que umbral %.3g.',det.rango,det.umbral);return;
  end
  dy=diff(y);tol=max(det.umbral/max(numel(y)-1,1),eps);
  if all(dy>=-tol)
    info.tipo='MONOTONA_CRECENTE';info.mensaje='Curva monotona creciente; el maximo esta en el limite superior, no es un optimo interior.';
  elseif all(dy<=tol)
    info.tipo='MONOTONA_DECRECIENTE';info.mensaje='Curva monotona decreciente; el maximo esta en el limite inferior, no es un optimo interior.';
  else
    [ym,idx]=max(y);info.tipo='OPTIMO_INTERIOR';info.optimo_x=x(idx);info.optimo_y=ym;info.indice=idx;info.mensaje='Se detecta maximo interior significativo.';
  end
end

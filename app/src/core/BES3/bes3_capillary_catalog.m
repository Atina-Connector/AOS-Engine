function caps = bes3_capillary_catalog(param)
% Catalogo geometrico generado desde los ID candidatos.
% bes3_defaults normaliza listas numericas recibidas como texto desde .aosdat.
  p=bes3_defaults(param);ids=p.bes3_capilar_ID_candidatos_m(:);
  if ~isnumeric(ids) || isempty(ids) || any(~isfinite(ids)) || any(ids<=0)
    error('BES3: lista de diametros internos de capilar invalida despues de normalizar.');
  endif
  caps=repmat(struct('id','','ID_m',0,'OD_m',0,'espesor_m',0,'material',''),numel(ids),1);
  for i=1:numel(ids)
    caps(i).id=sprintf('CAP_%0.1fmm',1000*ids(i));
    caps(i).ID_m=double(ids(i));
    caps(i).espesor_m=p.bes3_capilar_espesor_m;
    caps(i).OD_m=ids(i)+2*p.bes3_capilar_espesor_m;
    caps(i).material=p.bes3_capilar_material;
  endfor
endfunction

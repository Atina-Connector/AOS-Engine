function r = bes3_capillary_fit(cap,geom,param)
% Verificacion conservadora de envolvente lateral en casing.
  p=bes3_defaults(param);
  gap=max((geom.ID_casing_m-geom.equipo_OD_m)/2,0);
  accesorio=max(p.bes3_OD_cable_m,cap.OD_m);
  requerido=accesorio+p.bes3_tolerancia_corrida_m;
  circ=pi*max(geom.equipo_OD_m,1e-6);
  ocupacion=p.bes3_OD_cable_m+cap.OD_m+2*p.bes3_tolerancia_corrida_m;
  radial_ok=gap+1e-12>=requerido;
  circ_ok=ocupacion<=0.35*circ;
  dogleg_ok=p.bes3_dogleg_deg_30m<=p.bes3_dogleg_max_deg_30m;
  r=struct('instalable',radial_ok&&circ_ok&&dogleg_ok,'gap_radial_m',gap, ...
    'requerido_radial_m',requerido,'ocupacion_circunferencial_m',ocupacion, ...
    'circunferencia_m',circ,'radial_ok',radial_ok,'circunferencia_ok',circ_ok, ...
    'dogleg_ok',dogleg_ok,'estado',estado_local(radial_ok,circ_ok,dogleg_ok));
endfunction
function s=estado_local(a,b,c)
  if ~a,s='NO_CABE_RADIALMENTE';elseif ~b,s='ENVOLVENTE_CIRCUNFERENCIAL_INSUFICIENTE';elseif ~c,s='DOGLEG_EXCESIVO';else,s='INSTALABLE';endif
endfunction

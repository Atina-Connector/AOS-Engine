function r = aos_electrico_fondo_evaluar(P_eje_kW,rpm,velocidad_refrig,T_amb_C,param)
% Cadena común: eje -> motor PM -> cable -> VSD -> térmica.
  param=aos_electrico_defaults(param);
  mot=aos_motor_pm_evaluar(P_eje_kW,rpm,param);
  cab=aos_cable_evaluar(mot.P_motor_kW,param);
  vsd=aos_vsd_evaluar(mot.P_motor_kW+cab.perdidas_kW,param);
  term=aos_termica_fondo(mot.P_motor_kW-P_eje_kW,velocidad_refrig,T_amb_C,param);
  estados={mot.estado,cab.estado,vsd.estado,term.estado};
  estado='OK';
  for i=1:numel(estados)
    if ~strcmp(estados{i},'OK'),estado=estados{i};break;endif
  endfor
  r=struct('motor',mot,'cable',cab,'vsd',vsd,'termica',term, ...
           'P_superficie_kW',vsd.P_entrada_kW,'corriente_A',cab.corriente_A, ...
           'estado',estado,'modelo','AOS_ELECTRICO_FONDO_SCREENING_0_1_1');
endfunction

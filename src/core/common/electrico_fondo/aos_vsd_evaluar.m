function r = aos_vsd_evaluar(P_salida_kW,param)
  param=aos_electrico_defaults(param);
  eta=min(max(param.vsd_eta,0.70),0.995);
  Pentrada=max(P_salida_kW,0)./eta;
  r=struct('P_salida_kW',P_salida_kW,'P_entrada_kW',Pentrada,'eta',eta, ...
           'perdidas_kW',Pentrada-P_salida_kW,'estado','OK');
endfunction

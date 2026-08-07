function r = aos_motor_pm_evaluar(P_eje_kW,rpm,param)
% Modelo de screening de motor PM.
  param=aos_electrico_defaults(param);
  Pr=max(param.motor_pm_potencia_nominal_kW,0.1);
  carga=max(P_eje_kW,0)./Pr;
  eta=param.motor_pm_eta_nominal - 0.035.*(carga-0.80).^2 - 0.025.*max(0,0.25-carga);
  eta=min(max(eta,0.70),0.98);
  P_motor_kW=max(P_eje_kW,0)./eta;
  torque_Nm=max(P_eje_kW,0).*1000./max(2*pi.*rpm./60,1e-6);
  if carga>1.05
    estado='SOBRECARGA';
  elseif carga<0.25
    estado='SUBCARGA';
  else
    estado='OK';
  endif
  r=struct('P_eje_kW',P_eje_kW,'P_motor_kW',P_motor_kW,'eta',eta,'carga',carga, ...
           'rpm',rpm,'torque_Nm',torque_Nm,'estado',estado,'potencia_nominal_kW',Pr);
endfunction

function r = aos_termica_fondo(perdidas_motor_kW,velocidad_refrig,T_amb_C,param)
% Balance térmico lumped para screening.
  param=aos_electrico_defaults(param);
  if nargin<3||~isfinite(T_amb_C),T_amb_C=param.termica_T_ambiente_C;endif
  v=max(velocidad_refrig,0);
  h=param.termica_h_base_W_K+param.termica_h_vel_W_K_ms.*v;
  dT=max(perdidas_motor_kW,0).*1000./max(h,1);
  Tmotor=T_amb_C+dT;
  margen=param.motor_pm_Tmax_C-Tmotor;
  if margen<0,estado='TEMPERATURA_ALTA';
  elseif margen<10,estado='MARGEN_TERMICO_BAJO';
  else,estado='OK';endif
  r=struct('T_ambiente_C',T_amb_C,'T_motor_C',Tmotor,'deltaT_C',dT,'margen_C',margen, ...
           'velocidad_refrigeracion_m_s',v,'h_equiv_W_K',h,'estado',estado);
endfunction

function p = aos_electrico_defaults(p)
% Defaults comunes para motores PM, cable, VSD y térmica.
  if nargin<1||~isstruct(p),p=struct();endif
  p=setdef(p,'motor_pm_potencia_nominal_kW',150);
  p=setdef(p,'motor_pm_rpm_nominal',3600);
  p=setdef(p,'motor_pm_eta_nominal',0.93);
  p=setdef(p,'motor_pm_factor_potencia',0.92);
  p=setdef(p,'motor_pm_Tmax_C',150);
  p=setdef(p,'voltaje_superficie_V',4160);
  p=setdef(p,'vsd_eta',0.97);
  p=setdef(p,'cable_resistencia_ohm_km_20C',0.45);
  p=setdef(p,'cable_longitud_m',NaN);
  p=setdef(p,'cable_alpha_C',0.00393);
  p=setdef(p,'cable_T_C',80);
  p=setdef(p,'cable_caida_max_pct',8);
  p=setdef(p,'termica_h_base_W_K',250);
  p=setdef(p,'termica_h_vel_W_K_ms',800);
  p=setdef(p,'termica_T_ambiente_C',80);
endfunction

function s=setdef(s,f,v)
  if ~isfield(s,f)||isempty(s.(f)),s.(f)=v;endif
endfunction

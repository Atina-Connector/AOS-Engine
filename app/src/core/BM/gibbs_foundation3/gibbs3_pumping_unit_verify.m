function ver = gibbs3_pumping_unit_verify(res)
% GIBBS3_PUMPING_UNIT_VERIFY Verifica cargas, torque y potencia.
% El torque se obtiene por trabajo virtual en el eje de manivela:
% T = F_PR * dx_PR/dtheta. El contrabalanceo se resta cuando fue definido.

  p = res.param;
  c = res.promedio.aparato;
  F = res.promedio.F_superficie_N(:);
  omega = 2*pi*p.N_velocidad/60;
  if omega <= 0, error('Velocidad del aparato invalida.'); end

  dx_dtheta = c.velocidad_m_s / omega;
  Tload_Nm = F .* dx_dtheta;
  Tcb_Nm = zeros(size(Tload_Nm));
  if isfinite(p.pumping_unit_counterbalance_torque_kNm)
    Tcb_Nm = p.pumping_unit_counterbalance_torque_kNm*1000 .* ...
      sin(c.angulo_rad + p.pumping_unit_counterbalance_phase_rad);
  end
  Tnet_Nm = Tload_Nm - Tcb_Nm;
  Ppr_W = F .* c.velocidad_m_s;
  Pmotor_W = Ppr_W;
  Pmotor_W(Pmotor_W < 0) = 0;
  Pmotor_W = Pmotor_W / max(p.pumping_unit_mechanical_efficiency, eps);

  [cb_amp_Nm, cb_phase] = contrabalanceo_recomendado(Tload_Nm, c.angulo_rad);

  ver = struct();
  ver.fabricante = p.pumping_unit_manufacturer;
  ver.modelo = p.pumping_unit_model;
  ver.tipo = p.pumping_unit_type;
  ver.modelo_cinematico = p.pumping_unit_kinematic_model;
  ver.carrera_operativa_m = max(c.posicion_m)-min(c.posicion_m);
  ver.spm = p.N_velocidad;
  ver.carga_pr_max_kN = max(F)/1000;
  ver.carga_pr_min_kN = min(F)/1000;
  ver.torque_carga_kNm = Tload_Nm/1000;
  ver.torque_contrabalanceo_kNm = Tcb_Nm/1000;
  ver.torque_neto_kNm = Tnet_Nm/1000;
  ver.torque_max_abs_kNm = max(abs(Tnet_Nm))/1000;
  ver.torque_rms_kNm = sqrt(mean(Tnet_Nm.^2))/1000;
  ver.potencia_pr_kW = Ppr_W/1000;
  ver.potencia_motor_kW = Pmotor_W/1000;
  ver.potencia_motor_max_kW = max(Pmotor_W)/1000;
  ver.potencia_motor_media_kW = mean(Pmotor_W)/1000;
  ver.contrabalanceo_recomendado_kNm = cb_amp_Nm/1000;
  ver.contrabalanceo_fase_recomendada_rad = cb_phase;

  ver.utilizacion_carrera = razon(ver.carrera_operativa_m, p.pumping_unit_stroke_max_m);
  ver.utilizacion_spm = razon(p.N_velocidad, p.pumping_unit_spm_max);
  ver.utilizacion_carga_pr = razon(ver.carga_pr_max_kN, p.pumping_unit_max_pr_load_kN);
  ver.utilizacion_torque = razon(ver.torque_max_abs_kNm, p.pumping_unit_gearbox_torque_kNm);
  ver.utilizacion_potencia = razon(ver.potencia_motor_max_kW, p.pumping_unit_motor_power_kW);

  u = [ver.utilizacion_carrera, ver.utilizacion_spm, ver.utilizacion_carga_pr, ...
       ver.utilizacion_torque, ver.utilizacion_potencia];
  uf = u(isfinite(u));
  ver.capacidad_carga_evaluada = isfinite(p.pumping_unit_max_pr_load_kN);
  ver.capacidad_torque_evaluada = isfinite(p.pumping_unit_gearbox_torque_kNm);
  ver.capacidad_potencia_evaluada = isfinite(p.pumping_unit_motor_power_kW);
  ver.evaluacion_completa = ver.capacidad_carga_evaluada && ...
    ver.capacidad_torque_evaluada && ver.capacidad_potencia_evaluada;
  if isempty(uf)
    ver.utilizacion_max = NaN;
    ver.estado = 'NO_EVALUADO';
  else
    ver.utilizacion_max = max(uf);
    ver.estado = estado_utilizacion(ver.utilizacion_max);
    if ~ver.evaluacion_completa && strcmp(ver.estado,'VERDE')
      ver.estado = 'VERDE_PARCIAL';
    end
  end
end

function r = razon(valor, limite)
  if ~isfinite(limite) || limite <= 0
    r = NaN;
  else
    r = valor/limite;
  end
end

function s = estado_utilizacion(u)
  if u <= 0.80
    s = 'VERDE';
  elseif u <= 1.00
    s = 'AMARILLO';
  else
    s = 'ROJO';
  end
end

function [amp, fase] = contrabalanceo_recomendado(T, theta)
  X = [sin(theta(:)), cos(theta(:))];
  coef = X \ T(:);
  amp = hypot(coef(1), coef(2));
  fase = atan2(coef(2), coef(1));
end

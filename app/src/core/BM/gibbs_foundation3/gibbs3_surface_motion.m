function [u, v, a] = gibbs3_surface_motion(t, param)
% GIBBS3_SURFACE_MOTION Movimiento impuesto del polished rod.

  if isfield(param,'pumping_unit_configured') && ...
      logical(param.pumping_unit_configured)
    [u,v,a] = gibbs3_pumping_unit_kinematics(t,param);
    return;
  end

  T = 60.0 / param.N_velocidad;
  omega = 2*pi/T;
  fase = param.gibbs3_fase_inicial_rad;
  theta = omega*t + fase;
  u = 0.5*param.S_carrera*(1-cos(theta));
  v = 0.5*param.S_carrera*omega*sin(theta);
  a = 0.5*param.S_carrera*omega^2*cos(theta);
end

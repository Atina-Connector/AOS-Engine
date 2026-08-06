function ciclo = gibbs3_pumping_unit_cycle(p, t)
% GIBBS3_PUMPING_UNIT_CYCLE Evalua posicion, velocidad y aceleracion.

  t = t(:);
  n = numel(t);
  u = zeros(n,1); v = zeros(n,1); a = zeros(n,1); th = zeros(n,1);
  for k = 1:n
    [u(k), v(k), a(k), th(k)] = gibbs3_pumping_unit_kinematics(t(k), p);
  end
  ciclo = struct('t_s', t, 'posicion_m', u, 'velocidad_m_s', v, ...
    'aceleracion_m_s2', a, 'angulo_rad', th);
end

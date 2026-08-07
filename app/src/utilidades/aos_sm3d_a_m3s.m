function q_m3s = aos_sm3d_a_m3s(q_sm3d)
% Convierte caudal estandar de Sm3/d a m3/s.
  q_m3s = q_sm3d ./ 86400;
end

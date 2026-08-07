function q_mmscfd = aos_m3s_a_mmscfd(q_m3s)
% Convierte caudal estandar de m3/s a MMscf/d.
  q_mmscfd = q_m3s .* 86400 ./ 0.028316846592 ./ 1e6;
end

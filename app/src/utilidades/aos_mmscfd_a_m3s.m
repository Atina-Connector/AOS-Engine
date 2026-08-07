function q_m3s = aos_mmscfd_a_m3s(q_mmscfd)
% Convierte caudal estandar de MMscf/d a m3/s.
  q_m3s = q_mmscfd .* 1e6 .* 0.028316846592 ./ 86400;
end

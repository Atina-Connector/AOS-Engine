function [HL, modelo_usado] = calcular_holdup(vsl, vsg, d, rho_l, rho_g, sigma_l, mu_l, inclinacion_grados, P_avg)
  % calcular_holdup.m - Compatibilidad AOS
  % Redirige el cálculo anterior hacia el nuevo holdup HB estabilizado.
  % Mantiene la firma original para no romper dependencias existentes.

  if nargin < 9
    P_avg = 101325;
  end

  [HL, info] = aos_vlp_holdup_HB(vsl, vsg, d, rho_l, rho_g, sigma_l, mu_l, inclinacion_grados, P_avg);
  modelo_usado = info.modelo;
end

function [HL, info] = aos_vlp_holdup_drift_flux(vsl, vsg, d, rho_l, rho_g, inclinacion_grados)
  % aos_vlp_holdup_drift_flux.m
  % Modelo drift-flux simple para estabilizar bajo gas.
  % Convención: inclinacion_grados desde vertical.

  g = 9.81;
  eps_num = 1e-12;
  vm = max(vsl + vsg, eps_num);
  lambda_l = vsl / vm;

  C0 = 1.20;
  delta_rho = max(rho_l - rho_g, 0);

  % Drift vertical máximo; reducido al desviarse de vertical.
  orient = max(cosd(aos_vlp_clamp(inclinacion_grados, 0, 90)), 0.10);
  Vd = 0.35 * sqrt(max(g * d * delta_rho / max(rho_l, eps_num), 0)) * orient;

  alpha_g = vsg / max(C0 * vm + Vd, eps_num);
  alpha_g = aos_vlp_clamp(alpha_g, 0, 0.98);
  HL = 1 - alpha_g;

  % En flujo ascendente con slip, el holdup líquido no debe caer por debajo
  % de la fracción no-slip salvo régimen niebla/anular muy gasificado.
  HL = max(HL, lambda_l);
  HL = aos_vlp_clamp(HL, 0.01, 0.995);

  info.C0 = C0;
  info.Vd = Vd;
  info.alpha_g = alpha_g;
  info.lambda_l = lambda_l;
end

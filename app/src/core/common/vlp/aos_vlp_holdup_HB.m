function [HL, info] = aos_vlp_holdup_HB(vsl, vsg, d, rho_l, rho_g, sigma_l, mu_l, inclinacion_grados, P_avg)
  % aos_vlp_holdup_HB.m
  % Holdup Hagedorn-Brown simplificado y estabilizado para AOS.
  %
  % Correcciones frente a la versión anterior:
  %   - mantiene convención angular AOS: inclinación desde vertical;
  %   - impone comportamiento físico HL -> 1 cuando vsg -> 0;
  %   - no usa el ángulo para integrar hidrostática/fricción; solo corrige holdup;
  %   - devuelve INFO para auditoría.

  g = 9.81;
  eps_num = 1e-12;

  vsl = max(vsl, eps_num);
  vsg = max(vsg, 0);
  d = max(d, 1e-4);
  rho_l = max(rho_l, 50);
  rho_g = max(rho_g, 0.01);
  sigma_l = max(sigma_l, 0.001);
  mu_l = max(mu_l, 1e-6);
  P_avg = max(P_avg, 101325);

  % Unidades pseudo-HB heredadas de AOS.
  vsl_ft = vsl * 3.28084;
  vsg_ft = max(vsg, eps_num) * 3.28084;
  rho_l_lbm = rho_l * 0.062428;
  sigma_dyn = sigma_l * 1000;        % N/m -> dyn/cm
  mu_l_cp = mu_l * 1000;             % Pa.s -> cP
  d_ft = d * 3.28084;

  Nvl = max(1.938 * vsl_ft * (rho_l_lbm / sigma_dyn)^0.25, eps_num);
  Nvg = max(1.938 * vsg_ft * (rho_l_lbm / sigma_dyn)^0.25, eps_num);
  Nd  = max(120.872 * d_ft * sqrt(rho_l_lbm / sigma_dyn), eps_num);
  NL  = max(0.15726 * mu_l_cp * (1 / (rho_l_lbm * sigma_dyn^3))^0.25, eps_num);

  % CNL aproximado, conservador.
  if NL <= 0.002
    CNL = 0.0026;
  elseif NL <= 0.01
    CNL = 0.0019 + 0.0026 * NL;
  else
    CNL = 0.0062;
  end

  phi = (Nvl / max(Nvg^0.575, eps_num)) * (P_avg / 101325)^0.1 * (CNL / max(Nd, eps_num));
  phi = max(phi, eps_num);

  % Tabla simplificada de holdup HB.
  if phi < 0.001
    HL_tabla = 0.01;
  elseif phi > 0.1
    HL_tabla = 0.90;
  else
    phi_vals = [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1];
    HL_vals  = [0.02,  0.04,  0.10,  0.18, 0.30, 0.55, 0.80];
    HL_tabla = interp1(phi_vals, HL_vals, phi, 'pchip');
  end

  NB = max(Nvg^0.38 * Nd^2.14 / max(Nvl, eps_num), eps_num);
  if NB < 0.01
    psi = 1.0;
  elseif NB <= 100
    psi = 1.0 + 0.2 * log10(NB);
  else
    psi = 1.8;
  end
  psi = aos_vlp_clamp(psi, 0.8, 1.8);

  HL_HB = aos_vlp_clamp(HL_tabla * psi, 0.01, 0.99);

  % Corrección de inclinación suave: en AOS el ángulo es desde vertical.
  % No intenta ser Lawson-Brill completo; solo ajusta holdup en tramos desviados.
  theta = aos_vlp_clamp(inclinacion_grados, 0, 90);
  Fr_m = (vsl + vsg)^2 / max(g * d, eps_num);
  desviacion = sind(theta);
  corr_inc = 1.0 + 0.15 * desviacion * exp(-Fr_m);
  HL_HB_inc = aos_vlp_clamp(HL_HB * corr_inc, 0.01, 0.99);

  % Estabilizador físico de bajo gas: HL debe tender a 1 cuando vsg -> 0.
  [HL_df, info_df] = aos_vlp_holdup_drift_flux(vsl, vsg, d, rho_l, rho_g, theta);
  lambda_g = vsg / max(vsl + vsg, eps_num);

  % Con poco gas, domina drift-flux; con gas suficiente, domina HB.
  gas_ref = 0.03;  % fracción superficial de gas para transición suave
  w_HB = aos_vlp_clamp(lambda_g / gas_ref, 0, 1);
  HL = (1 - w_HB) * HL_df + w_HB * max(HL_HB_inc, info_df.lambda_l);
  HL = aos_vlp_clamp(HL, 0.01, 0.995);

  info.modelo = 'HB_simplificado_estabilizado';
  info.Nvl = Nvl;
  info.Nvg = Nvg;
  info.Nd = Nd;
  info.NL = NL;
  info.CNL = CNL;
  info.phi = phi;
  info.NB = NB;
  info.psi = psi;
  info.corr_inc = corr_inc;
  info.HL_HB = HL_HB;
  info.HL_HB_inc = HL_HB_inc;
  info.HL_drift = HL_df;
  info.w_HB = w_HB;
end

function [HL, regimen, info] = aos_vlp_holdup_duns_ros(vsl, vsg, d, rho_l, rho_g, sigma, mu_l, inclinacion_grados)
  % aos_vlp_holdup_duns_ros.m
  % Duns & Ros simplificado/corregido para AOS.
  %
  % Correcciones principales:
  %   - transición acotada 0..1;
  %   - bajo gas estabilizado con drift-flux;
  %   - niebla/anular sin HL fijo 0.005;
  %   - holdup nunca menor que fracción no-slip salvo límites explícitos;
  %   - convención angular AOS: grados desde vertical.

  g = 9.81;
  eps_num = 1e-12;

  vsl = max(vsl, eps_num);
  vsg = max(vsg, 0);
  d = max(d, 1e-4);
  rho_l = max(rho_l, 50);
  rho_g = max(rho_g, 0.01);
  sigma = max(sigma, 0.001);
  mu_l = max(mu_l, 1e-6);
  theta = aos_vlp_clamp(inclinacion_grados, 0, 90);

  vm = max(vsl + vsg, eps_num);
  lambda_l = vsl / vm;

  Nvl = vsl * (rho_l / (g * sigma))^0.25;
  Nvg = max(vsg * (rho_l / (g * sigma))^0.25, eps_num);
  Nd  = d * sqrt(rho_l * g / sigma);
  Nl  = mu_l * (g / (rho_l * sigma^3))^0.25;

  % Límites heredados de la versión AOS. Se estabilizan para evitar
  % potencias y divisiones problemáticas en Nvl muy bajo.
  Nvl_s = max(Nvl, eps_num);
  L1 = 316 * Nvl_s^0.302;
  L2 = 0.0009252 * Nvl_s^-2.468;
  Ls = 50 + 36 * Nvl_s;
  Lm = 75 + 84 * Nvl_s^0.75;

  F1 = 0.98 * Nvl_s^0.484;

  % --- Holdup base segregado ---
  HL_seg = F1 / max(1 + F1 * Nvg, eps_num);
  % Corrección suave por desviación, no por integración geométrica.
  psi_seg = 1 + 0.10 * sind(theta) * exp(-vm);
  HL_seg = aos_vlp_clamp(HL_seg * psi_seg, 0.01, 0.995);
  HL_seg = max(HL_seg, lambda_l);

  % --- Holdup slug con drift-flux y Taylor bubble simplificado ---
  [HL_df, info_df] = aos_vlp_holdup_drift_flux(vsl, vsg, d, rho_l, rho_g, theta);
  v_d = 0.35 * sqrt(max(g * d * (rho_l - rho_g) / max(rho_l, eps_num), 0));
  v_d = v_d * max(cosd(theta), 0.10);
  HL_taylor = 1.0 - vsg / max(1.20 * vm + v_d, eps_num);
  HL_taylor = aos_vlp_clamp(HL_taylor, 0.01, 0.995);
  Hls = 1.0 / (1.0 + (vm / 8.66)^1.39);
  HL_slug_base = 0.50 * Hls + 0.50 * HL_taylor;
  HL_slug_base = max(HL_slug_base, lambda_l);

  % Bajo gas: drift-flux domina. A mayor vsg, se mezcla con slug base.
  vsg_ref = 0.08;
  w_slug = aos_vlp_clamp(vsg / vsg_ref, 0, 1);
  HL_slug = (1 - w_slug) * HL_df + w_slug * HL_slug_base;
  HL_slug = aos_vlp_clamp(HL_slug, 0.01, 0.995);

  % --- Holdup niebla/anular corregido ---
  % Evita HL fijo irreal. Conserva al menos fracción no-slip y un mínimo
  % de película/entrainment. Capado para no convertir niebla en slug.
  entrainment_min = 0.005 + 0.03 * Nvl_s / max(Nvl_s + Nvg, eps_num);
  HL_mist = max(lambda_l, entrainment_min);
  HL_mist = aos_vlp_clamp(HL_mist, 0.005, 0.35);

  % --- Clasificación de régimen y transición acotada ---
  if Nvg <= L1
    if Nvg <= L2
      regimen = 'segregado';
      HL = HL_seg;
    else
      regimen = 'transicion';
      denom = max(L1 - L2, eps_num);
      w = aos_vlp_clamp((Nvg - L2) / denom, 0, 1);
      HL = (1 - w) * HL_seg + w * HL_slug;
    end
  else
    if Nvg <= Ls
      regimen = 'slug';
      HL = HL_slug;
    elseif Nvg <= Lm
      regimen = 'transicion_slug_niebla';
      denom = max(Lm - Ls, eps_num);
      w = aos_vlp_clamp((Nvg - Ls) / denom, 0, 1);
      HL = (1 - w) * HL_slug + w * HL_mist;
    else
      regimen = 'niebla';
      HL = HL_mist;
    end
  end

  HL = max(HL, lambda_l);
  HL = aos_vlp_clamp(HL, 0.005, 0.995);

  info.Nvl = Nvl;
  info.Nvg = Nvg;
  info.Nd = Nd;
  info.Nl = Nl;
  info.L1 = L1;
  info.L2 = L2;
  info.Ls = Ls;
  info.Lm = Lm;
  info.lambda_l = lambda_l;
  info.HL_seg = HL_seg;
  info.HL_slug = HL_slug;
  info.HL_mist = HL_mist;
  info.HL_drift = HL_df;
  info.drift = info_df;
end

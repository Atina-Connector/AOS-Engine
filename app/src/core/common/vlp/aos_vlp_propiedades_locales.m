function fl = aos_vlp_propiedades_locales(p, P_avg, T_avg, Ql_std, Qg_std)
  % aos_vlp_propiedades_locales.m
  % Propiedades locales para VLP multifásico.
  % AOS 0.0.11f:
  %   - Qg_std se interpreta como gas total estándar en tubing.
  %   - Qiny se conserva como gas libre.
  %   - el gas de formación se reduce por Rs para evitar doble conteo.

  eps_num = 1e-12;
  R = 8.314462618;
  M_air = 0.028967;
  M_g = max(p.gamma_g * M_air, 0.002);

  P_avg = max(P_avg, p.P_std);
  T_avg = max(T_avg, 250);

  Z = aos_vlp_z_factor(P_avg, T_avg, p.gamma_g, p.Z_gas);
  Z_std = 1.0;

  pvt = pvt_calcular(P_avg, T_avg - 273.15, p.API, p.gamma_g);
  Bo = max(pvt.Bo, 0.5);
  mu_o = max(pvt.mu_o, 1e-5);

  Qo_std = max(Ql_std * (1 - p.WC), 0);
  Qw_std = max(Ql_std * p.WC, 0);

  Qo_local = Qo_std * Bo;
  Qw_local = Qw_std;
  Ql_local = max(Qo_local + Qw_local, eps_num);

  fo_local = Qo_local / Ql_local;
  fw_local = Qw_local / Ql_local;

  mliq = p.rho_o * Qo_std + p.rho_w * Qw_std;
  rho_l = max(mliq / Ql_local, 50);
  mu_l = max(mu_o * fo_local + p.mu_w * fw_local, 1e-6);

  pgas = p;
  if ~isfield(pgas, 'Q_iny'), pgas.Q_iny = 0; end
  [Qg_free_std, det_gas] = aos_gas_libre_std(Ql_std, Qg_std, pgas, P_avg, T_avg);
  Qg_local = max(Qg_free_std * (p.P_std / P_avg) * (T_avg / p.T_std) * (Z / Z_std), 0);
  rho_g = max((P_avg * M_g) / (Z * R * T_avg), 0.01);

  [~, ~, sigma_dyn_cm] = pvt_tension_superficial(P_avg/1e5, T_avg - 273.15, p.API, p.WC);
  sigma = max(sigma_dyn_cm * 0.001, 0.001);

  fl.Qo_std = Qo_std;
  fl.Qw_std = Qw_std;
  fl.Qo_local = Qo_local;
  fl.Qw_local = Qw_local;
  fl.Ql_local = Ql_local;
  fl.Qg_local = Qg_local;
  fl.Qg_total_std = Qg_std;
  fl.Qg_free_std = Qg_free_std;
  fl.gas = det_gas;
  fl.fo_local = fo_local;
  fl.fw_local = fw_local;
  fl.rho_l = rho_l;
  fl.rho_g = rho_g;
  fl.mu_l = mu_l;
  fl.mu_g = p.mu_g;
  fl.sigma = sigma;
  fl.Z = Z;
  fl.M_g = M_g;
  fl.Bo = Bo;
  fl.Rs = pvt.Rs;
  fl.mu_o = mu_o;
end

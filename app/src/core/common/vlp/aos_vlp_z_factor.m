function Z = aos_vlp_z_factor(P, T_K, gamma_g, Z_forzado)
  % aos_vlp_z_factor.m
  % Factor Z simple para gas natural, compatible con Octave.
  % Usa Papay/Sutton como aproximación rápida. Si Z_forzado es válido,
  % respeta ese valor. No pretende reemplazar Standing-Katz completo.

  if nargin >= 4 && ~isnan(Z_forzado) && Z_forzado > 0
    Z = Z_forzado;
    return;
  end

  P_psia = P * 0.0001450377377;
  T_R = T_K * 9/5;

  gamma_g = max(gamma_g, 0.1);
  Tpc_R = 169.2 + 349.5 * gamma_g - 74.0 * gamma_g^2;
  Ppc_psia = 756.8 - 131.0 * gamma_g - 3.6 * gamma_g^2;

  Tpr = max(T_R / max(Tpc_R, 1e-9), 0.2);
  Ppr = max(P_psia / max(Ppc_psia, 1e-9), 0.0);

  Z = 1.0 - 3.52 * Ppr * exp(-2.26 * Tpr) + 0.274 * Ppr^2 * exp(-1.878 * Tpr);
  Z = aos_vlp_clamp(Z, 0.25, 1.50);
end

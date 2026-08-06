function q = jgl_calcular_qiny_automatico(p)
% Calcula Qiny motriz automatico JGL en m3/s estandar.
% Funcion publica para que simulacion y sensibilidades usen la misma formula.
  p = jgl_defaults(p);
  Pm = jgl_presion_motriz_fondo(p, 0);
  A = 12e-6; if isfield(p, 'A_n') && isfinite(p.A_n), A = max(p.A_n, 0); end
  eta = 0.98; if isfield(p, 'eta_n') && isfinite(p.eta_n), eta = max(p.eta_n, 0); end
  Rg = 519.6; if isfield(p, 'R_gas') && isfinite(p.R_gas), Rg = max(p.R_gas, 1e-9); end
  T = p.T_fondo; if T < 150, T = T + 273.15; end
  k = 1.30;
  if Pm <= 0 || A <= 0
      q = 0;
      return;
  end
  mdot = eta * A * Pm * sqrt(k/(Rg*T) * (2/(k+1))^((k+1)/(k-1)));
  q = max(mdot / max(p.rho_g_std, 1e-12), 0);
end

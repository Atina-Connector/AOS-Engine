function regimen = mapa_flujo(vsg, vsl, ID, rho_g, rho_l, sigma, mu_l, inclinacion)
  % Mapa de flujo completo de Taitel‑Dukler (1976) para flujo vertical/inclinado.
  % (código igual que mapa_flujo_taitel, pero con nombre corregido)
  g = 9.81;

  % Números adimensionales
  K = vsg * sqrt(rho_g / (g * sigma * (rho_l - rho_g)));
  F = vsl * sqrt(rho_l / (g * sigma * (rho_l - rho_g)));
  T_val = inclinacion / sqrt(g * (rho_l - rho_g) / sigma);

  % 1. Burbuja → Slug
  if vsg < 0.25 * vsl && vsg < 1.2 * vsl^(1/3)
      regimen = 'burbuja';
      return;
  end

  % 2. Slug severo (para inclinaciones > 0.1 rad)
  if inclinacion > 0.1
      if vsg < 1.0 - vsl
          regimen = 'slug_severo';
          return;
      end
  end

  % 3. Niebla
  if K > 40
      regimen = 'niebla';
      return;
  end

  % 4. Transición / Slug
  if vsg > 3.0
      regimen = 'transicion';
  else
      regimen = 'slug';
  end
end

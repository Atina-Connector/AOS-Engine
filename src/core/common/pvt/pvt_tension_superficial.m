function [sigma_o, sigma_w, sigma_mezcla] = pvt_tension_superficial(P_bar, T_C, API, WC)
  % pvt_tension_superficial.m - Propiedad PVT dinámica para AOS
  % Calcula la tensión superficial (dynes/cm) mediante Baker-Swerdloff (1956)

  T_F = T_C * 1.8 + 32; % Conversión a Fahrenheit requerida por el modelo

  % 1. Tensión superficial del Petróleo Muerto a 68°F y 100°F
  sigma_68 = 41.0 - 0.39 * API;
  sigma_100 = 38.0 - 0.36 * API;

  % Corrección por temperatura de reservorio/nodo (Interp. Lineal)
  if T_F <= 68
      sigma_dead = sigma_68;
  elseif T_F >= 100
      sigma_dead = sigma_100;
  else
      sigma_dead = sigma_68 - ((T_F - 68) / 32) * (sigma_68 - sigma_100);
  end

  % 2. Corrección por efectos del gas en solución (Presión saturada)
  % Factor de reducción de Baker-Swerdloff
  factor_corr_p = 1.0 - 0.025 * (P_bar * 14.5038)^0.25;
  if factor_corr_p < 0.2; factor_corr_p = 0.2; end

  sigma_o = sigma_dead * factor_corr_p; % Tensión superficial del crudo vivo (dynes/cm)

  % 3. Tensión superficial del Agua (Modelo clásico decreciente con T)
  sigma_w = 75.0 - 0.11 * T_C;

  % 4. Tensión superficial de la fase mixta multifásica en base al Corte de Agua (WC)
  sigma_mezcla = sigma_o * (1.0 - WC) + sigma_w * WC;
end

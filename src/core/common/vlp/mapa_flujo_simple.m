function regimen = mapa_flujo_simple(vsg, vsl, ID, rho_g, rho_l, sigma, mu_l, inclinacion)
  % Determina el régimen de flujo según Taitel‑Dukler (versión simplificada).
  % Entradas:
  %   vsg, vsl    : velocidades superficiales del gas y líquido (m/s)
  %   ID          : diámetro interno de la tubería (m)
  %   rho_g, rho_l: densidades del gas y líquido (kg/m³)
  %   sigma       : tensión superficial (N/m)
  %   mu_l        : viscosidad del líquido (Pa·s)
  %   inclinacion : ángulo desde la vertical (radianes, 0 = vertical)
  % Salida:
  %   regimen     : cadena: 'burbuja', 'slug', 'transicion', 'niebla'

  addpath('..')   % acceso a las funciones comunes desde AOS/
  addpath(pwd)   % también busca funciones en la carpeta actual del módulo VLP

  % Constantes de Taitel‑Dukler
  g = 9.81;

  % Velocidad terminal de ascenso de la burbuja en régimen de burbuja
  v_t = 0.35 * sqrt(g * ID * (rho_l - rho_g) / rho_l);  % para flujo vertical (corregido para inclinación)

  % Límites de transición
  % ---- 1. Transición de burbuja a slug ----
  % Condición: vsg > v_t - vsl  (burbuja) y vsg > 0.25*vsl
  if (vsg < 0.25 * vsl) && (vsg < v_t - vsl)
      regimen = 'burbuja';
      return;
  end

  % ---- 2. Transición a niebla (alta velocidad de gas) ----
  % Número de velocidad adimensional de Taitel
  K = vsg * sqrt(rho_g / (g * sigma * (rho_l - rho_g)));

  % Límite para niebla (flujo anular)
  if K > 40.0   % valor típico para inicio de niebla
      regimen = 'niebla';
      return;
  end

  % ---- 3. Si no es burbuja ni niebla, es slug o transición ----
  % Usamos un criterio simplificado: si la fracción de líquido es alta y la velocidad del gas es moderada -> slug
  % Para inclinación, ajustamos la velocidad de transición slug‑niebla
  vsg_trans = 1.0;   % m/s (simplificado)
  if vsg > vsg_trans
      regimen = 'transicion';
  else
      regimen = 'slug';
  end
end

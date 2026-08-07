function Q_g = thornhill_craver(P_up, P_down, T_up, diam_orificio, R_g, gamma, C_d)
  % Calcula el caudal masico de gas a traves de una valvula/orificio
  % usando Thornhill-Craver simplificado.
  %
  % AOS 0.0.11:
  %   gamma aqui es Cp/Cv. No debe confundirse con gamma_g, que es gravedad
  %   especifica del gas. Si por compatibilidad llega gamma_g (<1), se usa
  %   kappa = 1.30. La funcion devuelve cero si no hay diferencial fisico.

  Q_g = 0;
  if nargin < 7 || isempty(C_d), C_d = 0.85; end
  if nargin < 6 || isempty(gamma) || ~isfinite(gamma) || gamma <= 1
      gamma = 1.30;
  end
  if nargin < 5 || isempty(R_g) || ~isfinite(R_g) || R_g <= 0
      R_g = 519.6;
  end
  if nargin < 4 || isempty(diam_orificio) || ~isfinite(diam_orificio) || diam_orificio <= 0
      return;
  end
  if nargin < 3 || isempty(T_up) || ~isfinite(T_up) || T_up <= 0
      return;
  end
  if nargin < 2 || isempty(P_down) || ~isfinite(P_down)
      return;
  end
  if nargin < 1 || isempty(P_up) || ~isfinite(P_up)
      return;
  end
  if P_up <= 0 || P_down >= P_up || C_d <= 0
      return;
  end

  A_o = pi * (diam_orificio / 2)^2;
  r = max(P_down / P_up, 0);
  r = min(r, 0.999999);

  r_crit = (2 / (gamma + 1))^(gamma / (gamma - 1));

  if r < r_crit
      arg = gamma / (R_g * T_up) * (2/(gamma+1))^((gamma+1)/(gamma-1));
  else
      arg = (2 * gamma) / ((gamma - 1) * R_g * T_up) * (r^(2/gamma) - r^((gamma+1)/gamma));
  end

  if isfinite(arg) && arg > 0
      Q_g = C_d * A_o * P_up * sqrt(arg);
  else
      Q_g = 0;
  end
end

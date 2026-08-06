function [d_choke_mm, alerta] = dimensionar_choke(Q_seguro_m3d, param)
  % Calcula el diámetro de un choke de producción (orificio) para limitar
  % la producción a un caudal seguro, evitando daños en la formación.
  % Si el diámetro requerido es menor que el mínimo choke estándar disponible,
  % emite una alerta indicando que el sistema de levantamiento está
  % sobredimensionado y el choke no puede compensar.
  %
  % Entradas:
  %   Q_seguro_m3d : caudal máximo seguro de líquido (m³/d)
  %   param        : estructura de parámetros del pozo (debe contener
  %                  P_wh, diam_tbg, T_sup, gamma_g, R_gas, rho_g_std)
  %
  % Salidas:
  %   d_choke_mm   : diámetro recomendado del orificio (mm)
  %   alerta       : string con advertencia si el choke es insuficiente,
  %                  vacío en caso contrario

  alerta = '';

  % --- Caudal a condiciones estándar (m³/s) ---
  Q_seguro = Q_seguro_m3d / 86400;   % m³/s

  % --- Parámetros del gas y del choke ---
  P_up = param.P_wh;                    % presión aguas arriba (Pa)
  P_down = 2e5;                         % presión aguas abajo (Pa)
  T_up   = param.T_sup;                 % temperatura aguas arriba (K)
  gamma  = 1.30;                        % exponente adiabatico; gamma_g es gravedad especifica
  R_gas  = param.R_gas;                 % constante del gas (J/kg·K)
  rho_g_std = param.rho_g_std;          % densidad estándar del gas (kg/m³)
  C_d    = 0.85;                        % coeficiente de descarga típico

  % --- Ecuacion de Thornhill-Craver resuelta para A_o ---
  Q_masico = Q_seguro * rho_g_std;
  if P_up <= 0 || P_down >= P_up || T_up <= 0 || R_gas <= 0 || Q_masico <= 0
      d_choke_mm = NaN;
      alerta = 'No hay diferencial fisico suficiente para dimensionar choke con Thornhill-Craver.';
      return;
  end
  r = min(max(P_down / P_up, 0), 0.999999);
  r_crit = (2 / (gamma + 1))^(gamma / (gamma - 1));

  if r < r_crit
      arg = gamma / (R_gas * T_up) * (2/(gamma+1))^((gamma+1)/(gamma-1));
  else
      arg = (2*gamma) / ((gamma-1)*R_gas*T_up) * (r^(2/gamma) - r^((gamma+1)/gamma));
  end
  if ~isfinite(arg) || arg <= 0
      d_choke_mm = NaN;
      alerta = 'No se pudo resolver Thornhill-Craver para el choke con los datos actuales.';
      return;
  end
  A_o = Q_masico / (C_d * P_up * sqrt(arg));

  % --- Diámetro calculado (mm) ---
  d_choke_m = 2 * sqrt(A_o / pi);
  d_choke_mm = d_choke_m * 1000;

  % --- Seleccionar choke estándar más restrictivo ---
  chokes_file = 'config/GL/chokes_std.txt';
  if exist(chokes_file, 'file')
      chokes = load_config(chokes_file);
      d_std = chokes.d_choke_mm(:);
      % Elegir el mayor diámetro estándar que NO supere al calculado
      idx = find(d_std <= d_choke_mm, 1, 'last');
      if isempty(idx)
          % El diámetro requerido es menor que el mínimo choke disponible
          d_choke_mm = d_std(1);  % Se usa el más chico disponible
          alerta = sprintf(['⚠️  ALERTA: El diámetro de choke requerido (%.2f mm) es menor ' ...
              'que el mínimo choke comercial disponible (%.2f mm = %s").\n' ...
              '   Esto se debe a que el caudal seguro es extremadamente bajo (%.2f m³/d).\n' ...
              '   Verifique los parámetros geológicos (permeabilidad, espesor de arena, etc.)\n' ...
              '   y la densidad de punzados. Un pozo típico debería tener un caudal seguro\n' ...
              '   de al menos 30-50 m³/d. Con esos valores, el choke será realista.\n' ...
              '   Mientras tanto, se recomienda instalar el choke más pequeño disponible\n' ...
              '   (%.2f mm = %s") y monitorear la formación.'], ...
              d_choke_mm, d_std(1), pulgadas(d_std(1)), Q_seguro_m3d, d_std(1), pulgadas(d_std(1)));
      else
          d_choke_mm = d_std(idx);
      end
  end
end

function p = pulgadas(mm)
  % Convierte mm a fracción de pulgada (texto simple)
  p = sprintf('%.3f', mm/25.4);
end

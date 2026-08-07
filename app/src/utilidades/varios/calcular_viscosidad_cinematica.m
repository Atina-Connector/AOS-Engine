function nu_cSt = calcular_viscosidad_cinematica(param, mu_o, rho_l)
  % Calcula la viscosidad cinemática del fluido en centistokes (cSt).
  % Se puede llamar de dos formas:
  %   nu = calcular_viscosidad_cinematica(param)    % usando estructura
  %   nu = calcular_viscosidad_cinematica([], mu, rho) % con valores directos
  %
  % Entradas:
  %   param : estructura con campos mu_o (Pa·s), rho_o, rho_w, WC
  %           Si se usa esta forma, los otros argumentos deben ser [].
  %   mu_o  : viscosidad dinámica del petróleo (Pa·s) – opcional si se da param
  %   rho_l : densidad del líquido (kg/m³) – opcional si se da param
  %
  % Salida:
  %   nu_cSt : viscosidad cinemática (cSt, 1 cSt = 1e-6 m²/s)

  if nargin >= 1 && ~isempty(param) && isstruct(param)
      % Modo estructura: extraer propiedades
      if isfield(param, 'mu_o')
          mu_l = param.mu_o;
      else
          % Si no está definida, calcular con PVT
          if isfield(param, 'P_res') && isfield(param, 'T_fondo')
              pvt = pvt_calcular(param.P_res, param.T_fondo - 273.15, ...
                                 param.API, param.gamma_g);
              mu_l = pvt.mu_o;
          else
              mu_l = 0.001;   % valor por defecto (agua)
          end
      end
      % Densidad del líquido
      if isfield(param, 'rho_o') && isfield(param, 'rho_w') && isfield(param, 'WC')
          rho_l = param.rho_o * (1 - param.WC) + param.rho_w * param.WC;
      else
          rho_l = 1000;   % valor por defecto
      end
  else
      % Modo valores directos
      if nargin < 3, rho_l = 1000; end
      if nargin < 2 || isempty(mu_o), mu_o = 0.001; end
      mu_l = mu_o;
  end

  % Viscosidad cinemática (m²/s) -> cSt
  nu_m2s = mu_l / rho_l;
  nu_cSt = nu_m2s * 1e6;   % 1 cSt = 1e-6 m²/s
end

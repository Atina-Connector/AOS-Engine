function [Qiny_opt, Qo_opt] = encontrar_optimo(Qiny_vals, Qo_vals)
  % Encuentra el caudal de gas inyectado óptimo y la producción de petróleo correspondiente.
  % Busca picos locales (rodillas) primero; si no encuentra, devuelve el máximo global.
  %
  % Entradas:
  %   Qiny_vals : vector de caudal de gas inyectado (MMscf/d o m³/s)
  %   Qo_vals   : vector de producción de petróleo (m³/d o m³/s)
  % Salidas:
  %   Qiny_opt  : caudal de gas óptimo (mismas unidades que Qiny_vals)
  %   Qo_opt    : producción de petróleo óptima (mismas unidades que Qo_vals)

  % 1. Eliminar NaN y puntos no válidos
  validos = ~isnan(Qo_vals) & (Qo_vals > 0);
  if sum(validos) < 2
      Qiny_opt = NaN;
      Qo_opt = NaN;
      return;
  end

  x = Qiny_vals(validos);
  y = Qo_vals(validos);

  % 2. Buscar picos locales (rodillas) en la curva Qo vs Qiny
  dQo = diff(y);
  if length(dQo) < 2
      % Muy pocos puntos para buscar picos, tomamos el máximo global
      [Qo_opt, idx_max] = max(y);
      Qiny_opt = x(idx_max);
      return;
  end

  % Encontrar puntos donde la derivada cambia de positiva a negativa
  sign_d = sign(dQo);
  peaks = find(sign_d(1:end-1) > 0 & sign_d(2:end) < 0) + 1;

  if ~isempty(peaks)
      % Si hay picos, elegir el que tenga mayor Qo
      [Qo_opt, idx_peak] = max(y(peaks));
      Qiny_opt = x(peaks(idx_peak));
  else
      % Si no hay picos, el óptimo es el máximo global
      [Qo_opt, idx_max] = max(y);
      Qiny_opt = x(idx_max);
  end
end

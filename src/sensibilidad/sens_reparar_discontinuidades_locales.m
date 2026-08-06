function [y_proc, log_rep] = sens_reparar_discontinuidades_locales(x, y_raw, nombre, opts)
% sens_reparar_discontinuidades_locales.m
%
% Repara discontinuidades numericas locales en curvas de sensibilidad sin
% modificar la fisica del solver. Conserva la curva cruda fuera de esta
% funcion. Usa interpolacion polinomica local de grado 4 cuando hay puntos
% suficientes y fallback lineal si el polinomio sobreoscila.
%
% Criterios:
%   - No repara bordes.
%   - No repara Qiny = 0.
%   - No repara tramos de multiples puntos consecutivos.
%   - Repara solo puntos aislados con vecinos localmente coherentes.
%   - Registra valor original, valor corregido y metodo.

  if nargin < 3 || isempty(nombre), nombre = 'curva'; end
  if nargin < 4 || ~isstruct(opts), opts = struct(); end
  if ~isfield(opts, 'umbral_rel'), opts.umbral_rel = 0.35; end
  if ~isfield(opts, 'umbral_abs'), opts.umbral_abs = 0.5; end
  if ~isfield(opts, 'grado'), opts.grado = 4; end

  y_proc = y_raw;
  log_rep = struct();
  log_rep.nombre = nombre;
  log_rep.n_reparados = 0;
  log_rep.items = {};

  n = length(y_raw);
  if length(x) ~= n || n < 7
      return;
  end

  for i = 3:(n-2)
      if ~isfinite(y_raw(i)) || ~isfinite(x(i))
          continue;
      end
      if abs(x(i)) < 1e-14
          continue; % Qiny = 0 se conserva: puede ser resultado fisico real.
      end
      if ~isfinite(y_raw(i-1)) || ~isfinite(y_raw(i+1))
          continue;
      end

      ylin = y_raw(i-1) + (y_raw(i+1)-y_raw(i-1)) * (x(i)-x(i-1)) / max(x(i+1)-x(i-1), eps);
      salto = abs(y_raw(i) - ylin);
      escala = max([abs(y_raw(i-1)), abs(y_raw(i+1)), abs(ylin), 1]);
      if salto < max(opts.umbral_abs, opts.umbral_rel * escala)
          continue;
      end

      % No reparar si vecinos inmediatos tambien son anomalias fuertes.
      if i > 3 && isfinite(y_raw(i-2))
          s1 = y_raw(i-1) - y_raw(i-2);
          s2 = y_raw(i+1) - y_raw(i-1);
          if abs(s2) > 3 * max(abs(s1), opts.umbral_abs) && abs(s1) > opts.umbral_abs
              continue;
          end
      end
      if i < n-2 && isfinite(y_raw(i+2))
          s3 = y_raw(i+2) - y_raw(i+1);
          s2 = y_raw(i+1) - y_raw(i-1);
          if abs(s2) > 3 * max(abs(s3), opts.umbral_abs) && abs(s3) > opts.umbral_abs
              continue;
          end
      end

      idx_win = max(1, i-3):min(n, i+3);
      idx_win(idx_win == i) = [];
      valid = idx_win(isfinite(x(idx_win)) & isfinite(y_raw(idx_win)));
      metodo = 'lineal local';
      y_new = ylin;

      if length(valid) >= opts.grado + 1
          try
              coef = polyfit(x(valid), y_raw(valid), opts.grado);
              y_poly = polyval(coef, x(i));
              ymin = min([y_raw(i-1), y_raw(i+1), ylin]);
              ymax = max([y_raw(i-1), y_raw(i+1), ylin]);
              margen = max(opts.umbral_abs, 0.20 * max(abs(ymax-ymin), 1));
              if isfinite(y_poly) && y_poly >= ymin - margen && y_poly <= ymax + margen
                  y_new = y_poly;
                  metodo = sprintf('polinomio grado %d local', opts.grado);
              end
          catch
              y_new = ylin;
              metodo = 'lineal local';
          end
      end

      y_proc(i) = y_new;
      log_rep.n_reparados = log_rep.n_reparados + 1;
      item = struct();
      item.indice = i;
      item.x = x(i);
      item.original = y_raw(i);
      item.corregido = y_new;
      item.metodo = metodo;
      log_rep.items{end+1} = item;
  end
end

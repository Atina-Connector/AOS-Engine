function [y_proc, cambios] = aos_reparar_discontinuidad_local(x, y_raw, nombre, opciones)
% aos_reparar_discontinuidad_local.m
% Postproceso trazable de sensibilidades.
%
% Repara discontinuidades numericas locales pequenas usando interpolacion
% polinomica local de grado 4. Si el polinomio sobreoscila o rompe el rango
% local, usa una aproximacion lineal local.
%
% No modifica bordes ni Qiny = 0. Conserva la curva cruda fuera de esta funcion.

  if nargin < 3 || isempty(nombre), nombre = 'curva'; end
  if nargin < 4 || isempty(opciones) || ~isstruct(opciones), opciones = struct(); end

  y_proc = y_raw;
  cambios = struct('indice', {}, 'idx', {}, 'x', {}, 'original', {}, 'raw', {}, 'corregido', {}, 'proc', {}, 'metodo', {}, 'motivo', {}, 'nombre', {});

  if isempty(x) || isempty(y_raw), return; end
  x = x(:)';
  y = y_raw(:)';
  n = length(y);
  if length(x) ~= n || n < 7, return; end

  tol_qiny0 = max(1e-12, 1e-9 * max(abs(x)));
  if isfield(opciones, 'umbral_rel'), umbral_rel = opciones.umbral_rel; else umbral_rel = 0.20; end
  if isfield(opciones, 'umbral_abs'), umbral_abs = opciones.umbral_abs; else umbral_abs = 0.5; end

  for i = 3:(n-2)
      if abs(x(i)) <= tol_qiny0
          continue;
      end
      if ~isfinite(y(i)) || isnan(y(i))
          continue;
      end
      vecinos4 = [y(i-2), y(i-1), y(i+1), y(i+2)];
      if any(~isfinite(vecinos4)) || any(isnan(vecinos4))
          continue;
      end

      ylin = y(i-1) + (y(i+1)-y(i-1)) * (x(i)-x(i-1)) / max(x(i+1)-x(i-1), eps);
      rango_local = max(vecinos4) - min(vecinos4);
      umbral = max(umbral_abs, umbral_rel * max(rango_local, 1e-9));
      desv = abs(y(i) - ylin);

      % Monotonia razonable a ambos lados, ignorando el punto sospechoso.
      s1 = y(i-1) - y(i-2);
      s2 = y(i+2) - y(i+1);
      monotono_vecinos = (s1 == 0 || s2 == 0 || sign(s1) == sign(s2));

      % El punto debe ser una discontinuidad local: cae o sube fuera del rango
      % que sugieren los vecinos cercanos.
      fuera_rango = (y(i) < min(vecinos4) - umbral) || (y(i) > max(vecinos4) + umbral);
      if ~(monotono_vecinos && fuera_rango && desv > umbral)
          continue;
      end

      idx_win = max(1, i-3):min(n, i+3);
      idx_fit = idx_win(idx_win ~= i & isfinite(y(idx_win)) & ~isnan(y(idx_win)));
      metodo = 'lineal_local';
      ycorr = ylin;

      if length(idx_fit) >= 5
          try
              coef = polyfit(x(idx_fit), y(idx_fit), 4);
              ypoly = polyval(coef, x(i));
              ymin = min(y(idx_fit));
              ymax = max(y(idx_fit));
              margen = max(umbral, 0.05 * max(abs(ymax-ymin), 1e-9));
              if isfinite(ypoly) && ypoly >= ymin - margen && ypoly <= ymax + margen
                  ycorr = ypoly;
                  metodo = 'polinomio_grado_4_local';
              end
          catch
              ycorr = ylin;
              metodo = 'lineal_local';
          end
      end

      y_proc(i) = ycorr;
      c.indice = i;
      c.idx = i;
      c.x = x(i);
      c.original = y(i);
      c.raw = y(i);
      c.corregido = ycorr;
      c.proc = ycorr;
      c.metodo = metodo;
      c.motivo = sprintf('Discontinuidad numerica local detectada en %s.', nombre);
      c.nombre = nombre;
      cambios(end+1) = c;
  end
end

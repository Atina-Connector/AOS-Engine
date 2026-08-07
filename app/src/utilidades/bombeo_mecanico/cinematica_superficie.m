function cinematica = cinematica_superficie(tipo_unidad, S, N, t)
  % cinematica_superficie.m
  % Cinematica simplificada del punto pulido para BM.
  % Compatible con GNU Octave. Unidades: S en m, N en golpes/min, t en s.

  if nargin < 1 || isempty(tipo_unidad), tipo_unidad = 'Convencional'; end
  if nargin < 2 || isempty(S), S = 1.5; end
  if nargin < 3 || isempty(N), N = 6; end
  if nargin < 4 || isempty(t)
      T = 60 / max(N, 1e-6);
      t = linspace(0, T, 500);
  end

  S = max(S, 0);
  N = max(N, 1e-6);
  T = 60 / N;
  omega = 2 * pi / T;
  theta = omega * t;

  switch lower(strtrim(tipo_unidad))
      case 'convencional'
          pos = S/2 * (1 - cos(theta));
          vel = S/2 * omega * sin(theta);
          acc = S/2 * omega^2 * cos(theta);

      case 'markii'
          phi = 15 * pi / 180;
          pos = S/2 * (1 - cos(theta - phi));
          vel = S/2 * omega * sin(theta - phi);
          acc = S/2 * omega^2 * cos(theta - phi);

      case 'rotaflex'
          % Movimiento mas uniforme que una unidad convencional.
          pos = S/2 * (1 - cos(theta));
          vel = S/2 * omega * sin(theta);
          acc = 0.65 * S/2 * omega^2 * cos(theta);

      case 'hidraulico'
          [pos, vel, acc] = cinematica_hidraulica_trapezoidal(t, S, T);

      otherwise
          error('Tipo de unidad BM no reconocido: %s', tipo_unidad);
  end

  % Normalizar pequenios errores numericos para que la carrera sea exactamente S.
  pmin = min(pos);
  pmax = max(pos);
  if pmax > pmin
      pos = (pos - pmin) * S / (pmax - pmin);
      vel = gradiente_periodico(pos, t);
      acc = gradiente_periodico(vel, t);
  end

  cinematica.pos = pos;
  cinematica.vel = vel;
  cinematica.acc = acc;
  cinematica.tipo = tipo_unidad;
  cinematica.S = S;
  cinematica.N = N;
  cinematica.T = T;
end

function [pos, vel, acc] = cinematica_hidraulica_trapezoidal(t, S, T)
  t = t(:)';
  pos = zeros(size(t));
  vel = zeros(size(t));
  acc = zeros(size(t));
  tr = 0.12 * T;         % rampa por semiciclo
  th = T / 2;
  vc = S / max(th - tr, 1e-9);
  a = vc / max(tr, 1e-9);

  for i = 1:length(t)
      tau = mod(t(i), T);
      if tau < tr
          pos(i) = 0.5 * a * tau^2;
          vel(i) = a * tau;
          acc(i) = a;
      elseif tau < (th - tr)
          pos(i) = 0.5 * a * tr^2 + vc * (tau - tr);
          vel(i) = vc;
          acc(i) = 0;
      elseif tau < th
          dt = tau - (th - tr);
          pos_ini = 0.5 * a * tr^2 + vc * (th - 2*tr);
          pos(i) = pos_ini + vc * dt - 0.5 * a * dt^2;
          vel(i) = vc - a * dt;
          acc(i) = -a;
      elseif tau < (th + tr)
          dt = tau - th;
          pos(i) = S - 0.5 * a * dt^2;
          vel(i) = -a * dt;
          acc(i) = -a;
      elseif tau < (T - tr)
          dt = tau - (th + tr);
          pos(i) = S - 0.5 * a * tr^2 - vc * dt;
          vel(i) = -vc;
          acc(i) = 0;
      else
          dt = tau - (T - tr);
          pos_ini = 0.5 * a * tr^2;
          pos(i) = pos_ini - vc * dt + 0.5 * a * dt^2;
          vel(i) = -vc + a * dt;
          acc(i) = a;
      end
  end
end

function y = gradiente_periodico(x, t)
  x = x(:)';
  t = t(:)';
  n = length(x);
  y = zeros(size(x));
  if n < 2
      return;
  end
  dt = median(diff(t));
  if isempty(dt) || dt <= 0 || ~isfinite(dt)
      dt = 1;
  end
  for i = 1:n
      im = i - 1; if im < 1, im = n; end
      ip = i + 1; if ip > n, ip = 1; end
      y(i) = (x(ip) - x(im)) / (2 * dt);
  end
end

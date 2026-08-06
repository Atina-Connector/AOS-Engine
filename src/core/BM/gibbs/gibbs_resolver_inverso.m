function res = gibbs_resolver_inverso(param, varillas, malla, opciones)
  % Transformacion inversa tipo Gibbs: carta superficie -> carta fondo.
  % Requiere opciones.carta_superficie = [pos_m, carga_N].
  if ~isfield(opciones, 'carta_superficie') || isempty(opciones.carta_superficie)
      error('Modo inverso Gibbs requiere opciones.carta_superficie = [pos_m, carga_N].');
  end
  carta = opciones.carta_superficie;
  if size(carta,2) < 2
      error('La carta de superficie debe tener dos columnas: posicion_m, carga_N.');
  end

  n_t = max(round(leer_campo(opciones, 'n_t', 720)), 180);
  T = 60 / max(param.N_velocidad, 1e-6);
  t0 = (0:size(carta,1)-1) * T / max(size(carta,1),1);
  t = (0:n_t-1) * T / n_t;
  pos0 = interp1([t0, T], [carta(:,1)', carta(1,1)], t, 'linear');
  load0 = interp1([t0, T], [carta(:,2)', carta(1,2)], t, 'linear');

  % Normalizar posicion, conservar carga absoluta.
  pos0 = pos0 - min(pos0);
  Fdyn = load0 - malla.peso_flotado_N;

  nn = malla.n_nodos;
  u = zeros(nn, n_t);
  u(1,:) = pos0;
  dx1 = malla.dx(1);
  EA1 = malla.E_e(1) * malla.A_e(1);
  % Tension positiva estira la sarta: el fondo queda retrasado respecto de superficie.
  u(2,:) = u(1,:) - dx1 * Fdyn / max(EA1, 1);

  dt = T / n_t;
  alpha = max(leer_campo(opciones, 'amortiguamiento', 0.055), 0) * 2 * pi / T;

  for j = 2:nn-1
      c = malla.c_e(min(j, length(malla.c_e)));
      dx = 0.5 * (malla.dx(max(j-1,1)) + malla.dx(min(j,length(malla.dx))));
      ut = derivada_t(u(j,:), dt);
      utt = segunda_t(u(j,:), dt);
      u(j+1,:) = 2*u(j,:) - u(j-1,:) + (dx^2 / max(c^2,1)) * (utt + alpha*ut);
  end

  % Carga de fondo por deformacion del ultimo elemento.
  e = malla.n_elementos;
  Ff = max(-malla.E_e(e)*malla.A_e(e) * (u(end,:) - u(end-1,:)) / max(malla.dx(e),1e-9), 0);
  pos_fondo = u(end,:) - min(u(end,:));
  [metricas, cartas] = gibbs_calcular_metricas_bomba(param, pos0, load0, pos_fondo, Ff, t, [], []);
  espaciamiento = gibbs_estimacion_espaciamiento(param, metricas, cartas, malla);

  res = struct();
  res.modo = 'inverse';
  res.modelo = 'Gibbs_wave_inverse_AOS_v10';
  res.t = t(:);
  res.carta_sup = cartas.carta_sup;
  res.carta_fondo = cartas.carta_fondo;
  res.posicion_superficie_m = pos0(:);
  res.posicion_fondo_m = pos_fondo(:);
  res.carga_superficie_N = load0(:);
  res.carga_fondo_N = Ff(:);
  res.metricas = metricas;
  res.espaciamiento = espaciamiento;
  res.info = struct();
  res.info.vel_onda_min_m_s = malla.c_min;
  res.info.vel_onda_max_m_s = malla.c_max;
  res.info.K_eq_N_m = malla.K_eq_N_m;
  res.info.peso_flotado_N = malla.peso_flotado_N;
  res.info.aviso = 'Inverso Gibbs v10: revisar signo/calibracion contra carta medida conocida.';
end

function y = derivada_t(x, dt)
  x = x(:)'; n = length(x); y = zeros(size(x));
  for i=1:n
      im=i-1; if im<1, im=n; end
      ip=i+1; if ip>n, ip=1; end
      y(i) = (x(ip)-x(im))/(2*dt);
  end
end

function y = segunda_t(x, dt)
  x = x(:)'; n = length(x); y = zeros(size(x));
  for i=1:n
      im=i-1; if im<1, im=n; end
      ip=i+1; if ip>n, ip=1; end
      y(i) = (x(ip)-2*x(i)+x(im))/(dt^2);
  end
end

function v = leer_campo(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end

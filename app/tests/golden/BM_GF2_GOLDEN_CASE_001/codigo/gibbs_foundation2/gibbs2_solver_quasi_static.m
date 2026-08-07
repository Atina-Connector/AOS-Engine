function res = gibbs2_solver_quasi_static(param, malla)
  n = malla.n;
  spm = max(param.N_velocidad, 0.1);
  T = 60 / spm;
  ncy = max(1, round(param.gibbs2_n_ciclos));
  ppc = max(120, round(param.gibbs2_puntos_por_ciclo));
  nt = ncy * ppc + 1;
  t = (0:nt-1)' * (T / ppc);

  U = zeros(nt, n);
  Ftop = zeros(nt, 1);
  Fbot = zeros(nt, 1);

  % Peso flotado total de las varillas
  Wr = sum(malla.m) * 9.81 * param.gibbs2_buoyancy_factor_rods;

  % Rigidez total de la sarta (resorte equivalente)
  k_sarta = malla.k_equiv;

  % Cargas extremas de la bomba
  WC = min(max(param.WC, 0), 1);
  rho_l = param.rho_o * (1 - WC) + param.rho_w * WC;
  Dp = max(param.D_bomba_mm, 1) / 1000;
  Ap = pi * (Dp / 2)^2;
  Pb = max(param.P_wh, 0) + max(param.D_bomba, 0) * rho_l * 9.81;
  Pf = Pb * Ap;
  llenado = min(max(param.gibbs2_llenado_bomba, 0.05), 1.2);
  F_up = Pf * llenado;        % carga total en ascenso (válvula viajera cerrada, fija abierta)
  F_down = 0.02 * Pf;         % carga en descenso (viajera abierta, fija cerrada)

  % Transición suave de la carga: sigmoide centrada en velocidad cero
  v_thresh = 0.01;  % m/s, velocidad de transición

  for i = 1:nt
      [us, vs] = gibbs2_surface_motion(t(i), param);

      % Factor de válvula (0 a 1) basado en la velocidad del PR
      valve = 1 / (1 + exp(-vs / v_thresh));  % 0 para descenso rápido, 1 para ascenso rápido

      % Carga de bomba interpolada suavemente
      Fb = F_down + (F_up - F_down) * valve;

      % Estiramiento del resorte
      delta_L = Fb / k_sarta;

      % Posición del pistón
      ub = us - delta_L;

      % Perfil lineal de desplazamientos (resorte uniforme)
      u = linspace(us, ub, n)';

      U(i,:) = u';
      Fbot(i) = Fb;

      % Carga superficial: peso propio + carga de bomba (la sarta soporta ambas)
      Ftop(i) = Wr + Fb;
  end

  res = struct('version', param.gibbs2_version, ...
               'param', param, 'malla', malla, ...
               't', t, 'U', U, ...
               'V', zeros(nt, n), ...
               'F_superficie_N', Ftop, ...
               'F_bomba_N', Fbot, ...
               'ciclos_simulados', ncy, ...
               'ciclos_descartados', param.gibbs2_descartar_ciclos, ...
               'modelo', 'quasi_static_GF2_spring_valve');
end

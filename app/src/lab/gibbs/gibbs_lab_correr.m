function r = gibbs_lab_correr(param)
% gibbs_lab_correr.m - Banco de pruebas Gibbs v16.
% Laboratorio, NO solver operativo.
%
% Idea fisica v16:
%   - En fondo, bomba llena => carta casi rectangular. La bomba/jaula no se
%     comportan como resorte importante frente a la sarta.
%   - En superficie, el polished rod ve la transferencia de carga deformada
%     por elasticidad distribuida, retardo de onda, aceleracion distribuida y
%     reflexiones. Por eso aparece un paralelogramo rotado con ondulaciones.

  param = gibbs_lab_defaults(param);
  g = 9.80665;
  n = max(round(param.gibbs_lab_n), 360);
  spm = max(param.N_velocidad, 0.1);
  T = 60 / spm;
  t = linspace(0, T, n)';
  dt = t(2) - t(1);
  omega = 2*pi/T;

  S_sup = max(param.S_carrera, 0.01);
  S_fondo_imp = max(param.relacion_carrera_fondo * S_sup, 0.001);
  L = max(param.D_bomba, 1);
  WC = min(max(param.WC,0),1);
  rho_l = param.rho_o*(1-WC) + param.rho_w*WC;

  d_rod = max(param.diam_varilla_mm, 1) / 1000;
  A_rod = pi*(d_rod/2)^2;
  E = max(param.E_acero, 1e9);
  rho_rod = max(param.rho_acero, 1000);
  a_onda = sqrt(E / rho_rod);
  tau = param.gibbs_lab_retardo_factor * L / a_onda;

  % Movimiento superficie: arranca en PMI, sube hasta PMS y baja.
  fase = mod(t/T, 1);
  x_sup = 0.5*S_sup*(1 - cos(omega*t));
  v_sup = gradient(x_sup, dt);
  a_sup = gradient(v_sup, dt);

  % Movimiento de fondo impuesto: retardo de propagacion y posible amplitud distinta.
  tf = mod(t - tau, T);
  x_fondo = 0.5*S_fondo_imp*(1 - cos(omega*tf));
  v_fondo = gradient(x_fondo, dt);
  a_fondo = gradient(v_fondo, dt);

  % Cargas caracteristicas.
  Dp = max(param.D_bomba_mm, 1) / 1000;
  A_pump = pi*(Dp/2)^2;
  Wf = rho_l * g * max(L,1) * A_pump;
  Wb = rho_rod * g * A_rod * L * (1 - 0.12); % peso aparente aprox
  m_rod = rho_rod * A_rod * L;
  m_fluid_eff = rho_l * A_pump * L * min(max(param.llenado_bomba,0),1.2);

  % --- Fondo impuesto: casi rectangular para bomba llena.
  % Se suavizan apenas esquinas para evitar singularidades numericas, pero no se
  % curva artificialmente el tramo alto/bajo.
  estado_fondo = gibbs_lab_estado_rectangular(fase, param.llenado_bomba, param.gibbs_lab_fondo_esquina_frac);
  fric_fondo = 0.015 * max(Wf,1) .* sign(v_fondo + 1e-9);
  carga_fondo = estado_fondo .* Wf + 0.06*m_fluid_eff.*a_fondo + fric_fondo;
  carga_fondo = max(carga_fondo, 0);

  % --- Superficie estimada: transferencia elastica en distancia finita.
  % Esta es la correccion central de v16: la toma/descarga de carga vista desde
  % superficie no puede ser vertical en la carta, porque parte de la carrera se
  % invierte en estirar/relajar la sarta antes de que todo el esfuerzo se vea.
  estado_sup = gibbs_lab_estado_superficie_por_carrera(fase, x_sup, S_sup, ...
      param.llenado_bomba, param.gibbs_lab_toma_carga_frac_x, param.gibbs_lab_descarga_frac_x);

  % Dinamica distribuida: no usar masa total rigida. Se aplica una fraccion
  % efectiva para representar que la aceleracion se propaga en la sarta.
  F_dyn_rod = 0.22*m_rod.*a_sup;
  F_dyn_fluid = 0.08*m_fluid_eff.*a_sup.*estado_sup;
  F_fric_sup = param.gibbs_lab_friccion_frac*max(Wf,1).*sign(v_sup + 1e-9);

  % Ondulaciones por onda/reflexiones en lados cargados. Esto es una firma de
  % superficie, no una deformacion de la bomba de fondo.
  periodo_rt = max(2*L/a_onda, 0.15);
  osc = gibbs_lab_oscilacion_reflexion(t, estado_sup, T, periodo_rt, param.gibbs_lab_amort);
  F_osc = param.gibbs_lab_osc_frac_Wf * max(Wf,1) .* osc;

  % Carga superficie: peso aparente + carga de fluido transmitida + dinamica.
  carga_sup = Wb + estado_sup .* Wf + F_dyn_rod + F_dyn_fluid + F_fric_sup + F_osc;
  carga_sup = gibbs_lab_suavizar_periodico(carga_sup, max(3, round(0.004*n)));
  carga_sup = max(carga_sup, 0);

  r = struct();
  r.modelo = 'Gibbs_Lab_v16_fondo_rectangular_superficie_elastica';
  r.advertencia = 'LABORATORIO EXPERIMENTAL: no usar como resultado BM operativo.';
  r.param = param;
  r.t = t;
  r.T = T;
  r.fase = fase;
  r.x_sup = x_sup;
  r.x_fondo = x_fondo;
  r.v_sup = v_sup;
  r.v_fondo = v_fondo;
  r.a_sup = a_sup;
  r.a_fondo = a_fondo;
  r.carga_sup_kN = carga_sup / 1000;
  r.carga_fondo_kN = carga_fondo / 1000;
  r.estado_bomba = estado_fondo;
  r.estado_superficie = estado_sup;
  r.Wf_kN = Wf / 1000;
  r.Wb_kN = Wb / 1000;
  r.a_onda = a_onda;
  r.tau = tau;
  r.periodo_onda_ida_vuelta = periodo_rt;
  r.S_sup = max(x_sup)-min(x_sup);
  r.S_fondo = max(x_fondo)-min(x_fondo);
  r.transmision = r.S_fondo / max(r.S_sup, eps);
  r.llenado = param.llenado_bomba;
  r.Q_teorico_fondo_m3d = A_pump * r.S_fondo * (spm/60) * 86400;
  r.Q_efectivo_m3d = r.Q_teorico_fondo_m3d * min(max(param.llenado_bomba,0),1.2);
end

function y = gibbs_lab_estado_rectangular(fase, llenado, epsf)
  % Estado de carga en fondo. Para llenado total, casi rectangular.
  llenado = min(max(llenado,0),1.2);
  epsf = min(max(epsf,0.001),0.04);
  % Para llenado parcial, la descarga ocurre antes en la carrera descendente.
  descarga_inicio = 0.50 + 0.45*(1 - min(llenado,1));
  descarga_inicio = min(max(descarga_inicio, 0.50), 0.94);
  descarga_fin = min(descarga_inicio + epsf, 0.985);
  y = zeros(size(fase));
  for i=1:length(fase)
      f = fase(i);
      if f < epsf
          y(i) = smoothstep(f/epsf);
      elseif f < descarga_inicio
          y(i) = 1;
      elseif f < descarga_fin
          y(i) = 1 - smoothstep((f-descarga_inicio)/(descarga_fin-descarga_inicio));
      else
          y(i) = 0;
      end
  end
end

function y = gibbs_lab_estado_superficie_por_carrera(fase, x, S, llenado, frac_toma, frac_desc)
  % Estado de carga visto en superficie, usando distancia de carrera y no solo
  % tiempo. Esto evita pendientes infinitas en carga vs posicion.
  llenado = min(max(llenado,0),1.2);
  frac_toma = min(max(frac_toma,0.04),0.45);
  frac_desc = min(max(frac_desc,0.04),0.45);
  xnorm = min(max(x/max(S,eps),0),1);
  y = zeros(size(fase));
  x_toma_ini = 0.03;
  x_toma_fin = min(x_toma_ini + frac_toma, 0.55);
  x_desc_ini = 0.97;
  x_desc_fin = max(x_desc_ini - frac_desc, 0.45);
  % llenado parcial adelanta la descarga vista desde superficie.
  if llenado < 1
      adelanto = 0.25*(1-llenado);
      x_desc_ini = max(0.70, x_desc_ini - adelanto);
      x_desc_fin = max(0.35, x_desc_fin - adelanto);
  end
  for i=1:length(fase)
      f = fase(i);
      xn = xnorm(i);
      if f < 0.5
          % carrera ascendente: carga se toma durante desplazamiento finito
          if xn <= x_toma_ini
              y(i) = 0;
          elseif xn >= x_toma_fin
              y(i) = 1;
          else
              y(i) = smoothstep((xn-x_toma_ini)/(x_toma_fin-x_toma_ini));
          end
      else
          % carrera descendente: descarga durante desplazamiento finito
          if xn >= x_desc_ini
              y(i) = 1;
          elseif xn <= x_desc_fin
              y(i) = 0;
          else
              y(i) = smoothstep((xn-x_desc_fin)/(x_desc_ini-x_desc_fin));
          end
      end
  end
end

function osc = gibbs_lab_oscilacion_reflexion(t, estado, T, periodo_rt, amort)
  % Oscilacion periodica amortiguada aproximada activada por cambios de estado.
  dt = t(2)-t(1);
  de = [0; diff(estado)]/max(dt,eps);
  de = de / max(max(abs(de)), 1);
  w = 2*pi/max(periodo_rt,0.05);
  zeta = min(max(amort,0.03),0.60);
  osc = zeros(size(t));
  v = 0;
  x = 0;
  for i=2:length(t)
      % oscilador lineal forzado por derivada de la transferencia de carga
      acc = de(i) - 2*zeta*w*v - w*w*x;
      v = v + acc*dt;
      x = x + v*dt;
      osc(i) = x;
  end
  m = max(abs(osc));
  if m > 0
      osc = osc / m;
  end
  % Hacer periodico suave entre fin/inicio para un solo ciclo graficado.
  osc = gibbs_lab_suavizar_periodico(osc, max(3, round(0.004*length(t))));
end

function y = smoothstep(x)
  x = min(max(x,0),1);
  y = x*x*(3 - 2*x);
end

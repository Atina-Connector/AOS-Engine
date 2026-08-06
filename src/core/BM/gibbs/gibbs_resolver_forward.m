function res = gibbs_resolver_forward(param, varillas, malla, opciones)
  % Simulacion forward BM: cinematica superficial -> Gibbs -> fondo.
  %
  % v11:
  %   - El modo por defecto es ESTABLE: una formulacion tipo Gibbs liviana,
  %     retardada y suavizada, pensada para entregar cartas fisicamente
  %     reconocibles mientras se calibra el solver dinamico completo.
  %   - El solver dinamico explicito de v11 queda disponible como modo
  %     experimental: param.gibbs_metodo_forward = 'dinamico'.
  %
  % La razon del cambio es practica: el integrador dinamico explicito de v11
  % podia generar ruido numerico y cartas de fondo no representativas antes de
  % estar calibrado contra QROD/SROD o cartas reales.

  if nargin < 4 || ~isstruct(opciones), opciones = struct(); end

  metodo = leer_campo_texto(opciones, 'metodo_forward', '');
  if isempty(metodo)
      metodo = leer_campo_texto(param, 'gibbs_metodo_forward', 'estable');
  end
  metodo = lower(strtrim(metodo));

  if any(strcmp(metodo, {'gibbs1963','paper','sam_gibbs','onda_gibbs'}))
      res = gibbs_forward_gibbs1963(param, varillas, malla, opciones);
      return;
  end

  if ~strcmp(metodo, 'dinamico') && ~strcmp(metodo, 'explicito') && ~strcmp(metodo, 'experimental')
      res = gibbs_forward_estable(param, varillas, malla, opciones);
      return;
  end

  % -----------------------------------------------------------------------
  % Modo dinamico explicito experimental heredado de v11.
  % -----------------------------------------------------------------------
  T = 60 / max(param.N_velocidad, 1e-6);
  n_out = max(round(leer_campo(opciones, 'n_t', 720)), 180);

  dt_obj = T / n_out;
  dt_est = malla.dt_estable;
  sub = max(1, ceil(dt_obj / max(dt_est, 1e-6)));
  n_int = n_out * sub;
  dt = T / n_int;
  n_ciclos = max(round(leer_campo(opciones, 'n_ciclos', 8)), 3);
  n_total = n_int * n_ciclos;

  t_ciclo_int = (0:n_int-1) * dt;
  cin_int = cinematica_superficie(param.tipo_unidad, param.S_carrera, param.N_velocidad, t_ciclo_int);
  pos_top_ciclo = cin_int.pos(:)';
  vel_top_ciclo = cin_int.vel(:)';
  acc_top_ciclo = cin_int.acc(:)';

  nn = malla.n_nodos;
  u = zeros(nn, 1);
  v = zeros(nn, 1);
  a = zeros(nn, 1);

  u(:) = pos_top_ciclo(1);
  v(:) = vel_top_ciclo(1);

  zeta = max(leer_campo(opciones, 'amortiguamiento', 0.055), 0.0);
  c_ref = 2 * zeta * sqrt(max(malla.K_eq_N_m,1) * max(malla.masa_total_kg,1));
  c_n = c_ref * max(malla.m_n, 1) / max(sum(malla.m_n), 1);
  c_n = c_n(:);

  t_last = zeros(1, n_int);
  u_top_last = zeros(1, n_int);
  u_bot_last = zeros(1, n_int);
  v_bot_last = zeros(1, n_int);
  F_top_last = zeros(1, n_int);
  F_bot_last = zeros(1, n_int);
  valve_last = zeros(1, n_int);
  fill_last = zeros(1, n_int);

  bomba_estado = struct();
  bomba_estado.valvula = 0;

  for it = 1:n_total
      ic = mod(it-1, n_int) + 1;
      u_top = pos_top_ciclo(ic);
      v_top = vel_top_ciclo(ic);
      acc_top = acc_top_ciclo(ic);

      u(1) = u_top;
      v(1) = v_top;
      a(1) = acc_top;

      [F_bomba, bomba_estado, info_bomba] = gibbs_modelo_bomba(param, u(end), v(end), bomba_estado);

      F = zeros(nn, 1);
      for e = 1:malla.n_elementos
          fs = malla.k_e(e) * (u(e) - u(e+1));
          F(e) = F(e) - fs;
          F(e+1) = F(e+1) + fs;
      end

      F(end) = F(end) - F_bomba;
      F(2:end) = F(2:end) - c_n(2:end) .* v(2:end);

      for j = 2:nn
          a(j) = F(j) / max(malla.m_n(j), 1e-9);
      end
      v(2:end) = v(2:end) + dt * a(2:end);
      u(2:end) = u(2:end) + dt * v(2:end);

      if any(~isfinite(u)) || any(abs(u) > 20 * max(param.S_carrera, 0.1))
          warning('Gibbs dinamico explicito inestable. Se usa solucion estable.');
          res = gibbs_forward_estable(param, varillas, malla, opciones);
          return;
      end

      if it > (n_ciclos-1) * n_int
          il = ic;
          t_last(il) = (il-1) * dt;
          u_top_last(il) = u_top;
          u_bot_last(il) = u(end);
          v_bot_last(il) = v(end);
          F_bot_last(il) = F_bomba;
          valve_last(il) = info_bomba.valvula;
          fill_last(il) = info_bomba.llenado;
          F_top_last(il) = max(malla.k_e(1) * (u(1) - u(2)) + malla.peso_flotado_N, 0);
      end
  end

  idx = 1:sub:n_int;
  if length(idx) > n_out, idx = idx(1:n_out); end
  t = t_last(idx);
  pos_sup = u_top_last(idx);
  pos_fondo = u_bot_last(idx);
  vel_fondo = v_bot_last(idx);
  carga_sup = F_top_last(idx);
  carga_fondo = F_bot_last(idx);
  valvula = valve_last(idx);
  llenado = fill_last(idx);

  carga_sup = suavizar_periodico(carga_sup, max(5, round(0.02*length(carga_sup))));
  carga_fondo = suavizar_periodico(carga_fondo, max(5, round(0.02*length(carga_fondo))));

  [metricas, cartas] = gibbs_calcular_metricas_bomba(param, pos_sup, carga_sup, pos_fondo, carga_fondo, t, valvula, llenado);
  espaciamiento = gibbs_estimacion_espaciamiento(param, metricas, cartas, malla);

  res = struct();
  res.modo = 'forward';
  res.modelo = 'Gibbs_wave_forward_dinamico_EXPERIMENTAL_AOS_v11';
  res.t = t(:);
  res.carta_sup = cartas.carta_sup;
  res.carta_fondo = cartas.carta_fondo;
  res.posicion_superficie_m = pos_sup(:);
  res.posicion_fondo_m = pos_fondo(:);
  res.velocidad_fondo_m_s = vel_fondo(:);
  res.carga_superficie_N = carga_sup(:);
  res.carga_fondo_N = carga_fondo(:);
  res.valvula_factor = valvula(:);
  res.llenado_inst = llenado(:);
  res.metricas = metricas;
  res.espaciamiento = espaciamiento;
  res.info = struct();
  res.info.vel_onda_min_m_s = malla.c_min;
  res.info.vel_onda_max_m_s = malla.c_max;
  res.info.dt_s = dt;
  res.info.subpasos = sub;
  res.info.n_ciclos = n_ciclos;
  res.info.K_eq_N_m = malla.K_eq_N_m;
  res.info.peso_flotado_N = malla.peso_flotado_N;
  res.info.aviso = 'Modo dinamico explicito experimental. Usar solo para desarrollo/calibracion.';
end

function res = gibbs_forward_estable(param, varillas, malla, opciones)
  % Formulacion estable tipo Gibbs para uso operativo inicial.
  %
  % v13 corrige la forma grafica/fisica de v11/v12:
  %   - La carga no cambia instantaneamente sin desplazamiento.
  %   - La carrera de fondo NO se limita contra la carrera de superficie.
  %     La sarta se trata como sistema oscilatorio forzado: puede haber
  %     amplificacion dinamica de amplitud en fondo.
  %   - Las cartas quedan mas apaisadas y continuas, como cartas BM esperables.
  %
  % Nota: sigue siendo un modelo operativo estable, no una validacion QROD/SROD.

  n_out = max(round(leer_campo(opciones, 'n_t', 720)), 240);
  T = 60 / max(param.N_velocidad, 1e-6);
  t = (0:n_out-1) * T / n_out;
  fase = t / T;

  cin = cinematica_superficie(param.tipo_unidad, param.S_carrera, param.N_velocidad, t);
  pos_sup = cin.pos(:)';
  vel_sup = cin.vel(:)';
  acc_sup = cin.acc(:)';

  S_sup = max(max(pos_sup)-min(pos_sup), max(param.S_carrera, 1e-6));
  pos_sup = pos_sup - min(pos_sup);

  Ffluid_base = gibbs_carga_fluido(param);
  llenado = min(max(leer_campo(param, 'llenado_bomba', leer_campo(param, 'eta_vol', 0.85)), 0), 1.2);
  eta_valv = min(max(leer_campo(param, 'eficiencia_valvulas', 1.0), 0), 1.2);
  Ffric = abs(leer_campo(param, 'friccion_bomba_N', 0));

  % Retardo por velocidad de onda: fisicamente la respuesta de fondo no puede
  % ser instantanea respecto a superficie.
  tau = malla.L / max(malla.c_min, 1);
  tau = min(max(tau, 0), 0.45*T);
  fase_lag = tau / max(T, 1e-9);

  pos_ret = interp_periodico(t, pos_sup, t - tau, T);
  vel_ret = interp_periodico(t, vel_sup, t - tau, T);

  % Perdida de carrera por elasticidad: aproximacion estable. Se usa el rango
  % de carga de fluido y la rigidez equivalente para estimar carrera perdida.
  K = max(malla.K_eq_N_m, 1);
  perdida_elastica = max(Ffluid_base * max(llenado,0.1) / K, 0);
  if isfield(param, 'tuberia_anclada') && param.tuberia_anclada == 0
      perdida_elastica = 1.12 * perdida_elastica;
  end
  % Transmisibilidad dinamica aproximada de la sarta como sistema oscilatorio
  % forzado. Esto permite que la carrera de fondo sea menor o mayor que la
  % superficial segun frecuencia, masa equivalente, rigidez y amortiguamiento.
  % No se aplica limite superior artificial contra S_sup.
  masa_eff_tr = max(0.35 * max(malla.masa_total_kg, 1), 1);
  omega = 2*pi / max(T, 1e-9);
  omega_n = sqrt(K / masa_eff_tr);
  zeta_dyn = max(leer_campo(opciones, 'amortiguamiento', leer_campo(param, 'gibbs_amortiguamiento', 0.045)), 0.035);
  rfreq = omega / max(omega_n, 1e-9);
  ganancia_dyn = sqrt(1 + (2*zeta_dyn*rfreq)^2) / ...
                 max(sqrt((1-rfreq^2)^2 + (2*zeta_dyn*rfreq)^2), 1e-6);
  S_fondo_obj = S_sup * ganancia_dyn - perdida_elastica;
  S_fondo_obj = max(S_fondo_obj, 0.20*S_sup);

  % Movimiento de fondo: retardo + ligera deformacion de onda. Se normaliza el
  % rango a la carrera dinamica objetivo, que puede ser mayor que la superficial.
  pos_shape = pos_ret + 0.035*S_sup*sin(2*pi*(fase - fase_lag + 0.08));
  pos_shape = suavizar_periodico(pos_shape, max(9, round(0.035*n_out)));
  rpos = max(pos_shape) - min(pos_shape);
  if rpos <= 1e-9
      pos_fondo = pos_shape;
  else
      pos_fondo = (pos_shape - min(pos_shape)) * S_fondo_obj / rpos;
  end

  % Carga de fondo. En la carta de fondo la carga de fluido debe transferirse
  % con apertura/cierre de valvulas, pero no como escalon vertical matematico.
  % Se usa una compuerta suave basada en posicion y velocidad retardada.
  xn = pos_fondo / max(max(pos_fondo), 1e-9);
  vesc = max(abs(vel_ret));
  if vesc <= 1e-12, vesc = 1; end
  vnorm = vel_ret / vesc;
  ksig = 16;  % transicion suave, no instantanea
  gate_up = sigmoid(ksig * vnorm);

  % Recorte de extremos para representar retardo de valvulas cerca de cambio de
  % carrera; evita saltos de carga sin movimiento y da cartas mas apaisadas.
  margen_pos = 0.06;
  gate_pos = sigmoid(ksig*(xn - margen_pos)) .* sigmoid(ksig*((1-margen_pos) - xn));
  valvula = gate_up .* gate_pos;
  valvula = min(max(suavizar_periodico(valvula, max(17, round(0.075*n_out))), 0), 1);

  F_fondo_min = Ffric + 0.04 * Ffluid_base;
  F_fondo_amp = Ffluid_base * llenado * eta_valv;
  F_bomba = F_fondo_min + F_fondo_amp .* valvula;

  % Friccion viscosa leve en fondo: agrega inclinacion a la carta sin generar
  % paredes verticales. El signo se toma de la velocidad de fondo.
  vfondo = gradiente_periodico(pos_fondo, t);
  F_bomba = F_bomba + 0.06 * F_fondo_amp * (vfondo / max(max(abs(vfondo)), 1e-9));
  F_bomba = max(F_bomba, 0);
  F_bomba = suavizar_periodico(F_bomba, max(13, round(0.055*n_out)));

  % Carga superficial: peso flotado + carga de fondo retardada hacia superficie
  % + componentes dinamicas suaves. No se permite salto vertical instantaneo.
  F_fondo_hacia_sup = interp_periodico(t, F_bomba, t - 0.35*tau, T);
  zeta = max(leer_campo(opciones, 'amortiguamiento', leer_campo(param, 'gibbs_amortiguamiento', 0.045)), 0);
  masa_eff = 0.28 * max(malla.masa_total_kg, 1);
  c_amort = zeta * sqrt(max(K * masa_eff, 1));
  Fsup = malla.peso_flotado_N + F_fondo_hacia_sup + 0.22*masa_eff*acc_sup + c_amort*vel_sup;
  Fsup = max(Fsup, 0);
  Fsup = suavizar_periodico(Fsup, max(15, round(0.055*n_out)));

  % Cierre periodico suave para evitar discontinuidad visual en el ultimo punto.
  F_bomba = cerrar_periodico_suave(F_bomba, max(12, round(0.04*n_out)));
  Fsup = cerrar_periodico_suave(Fsup, max(12, round(0.04*n_out)));
  pos_fondo = cerrar_periodico_suave(pos_fondo, max(12, round(0.04*n_out)));

  llenado_inst = llenado * ones(size(t));
  [metricas, cartas] = gibbs_calcular_metricas_bomba(param, pos_sup, Fsup, pos_fondo, F_bomba, t, valvula, llenado_inst);
  espaciamiento = gibbs_estimacion_espaciamiento(param, metricas, cartas, malla);

  res = struct();
  res.modo = 'forward';
  res.modelo = 'Gibbs_forward_estable_AOS_v13_oscilatorio_sin_limite_carrera';
  res.t = t(:);
  res.carta_sup = cartas.carta_sup;
  res.carta_fondo = cartas.carta_fondo;
  res.posicion_superficie_m = pos_sup(:);
  res.posicion_fondo_m = pos_fondo(:);
  res.velocidad_fondo_m_s = vfondo(:);
  res.carga_superficie_N = Fsup(:);
  res.carga_fondo_N = F_bomba(:);
  res.valvula_factor = valvula(:);
  res.llenado_inst = llenado_inst(:);
  res.metricas = metricas;
  res.espaciamiento = espaciamiento;
  res.info = struct();
  res.info.vel_onda_min_m_s = malla.c_min;
  res.info.vel_onda_max_m_s = malla.c_max;
  res.info.retardo_onda_s = tau;
  res.info.K_eq_N_m = malla.K_eq_N_m;
  res.info.peso_flotado_N = malla.peso_flotado_N;
  res.info.metodo_forward = 'estable';
  res.info.ganancia_dinamica_carrera = ganancia_dyn;
  res.info.frecuencia_relativa = rfreq;
  res.info.aviso = 'Modo estable v13: la carrera de fondo puede amplificarse por dinamica oscilatoria. Validar/calibrar contra QROD/SROD.';
end


function res = gibbs_forward_gibbs1963(param, varillas, malla, opciones)
  % Primer intento AOS de solucion Gibbs 1963 por diferencias parciales.
  %
  % Base fisica:
  %   u_tt = a^2 u_xx - (pi*a*v/(2L)) u_t
  % con la eleccion dx/a = dt. La ecuacion discreta usada es:
  %   U_i^{n+1} = (U_{i+1}^n + U_{i-1}^n - U_i^{n-1} + r U_i^n)/(1+r)
  % donde r = pi*a*v*dt/(2L).
  %
  % Condicion superior: desplazamiento impuesto en polished rod.
  % Condicion inferior: condicion de bomba tipo Gibbs
  %   alpha*u(L,t) + beta*u_x(L,t) = P(t)
  % con estados basicos: libre, toma de carga, levantando fluido, descarga.
  %
  % Estado: experimental. Uniformiza la sarta a una equivalente; no reemplaza
  % todavia a QROD/SROD ni a una validacion de campo.

  if nargin < 4 || ~isstruct(opciones), opciones = struct(); end

  T = 60 / max(param.N_velocidad, 1e-6);
  S = max(leer_campo(param, 'S_carrera', 1.5), 1e-6);
  L = max(malla.L, leer_campo(param, 'D_bomba', 1500));
  E = media_segura(malla.E_e, 207e9);
  rho = media_segura(malla.rho_e, 7850);
  a_onda = sqrt(E / max(rho, 1));

  n_x = max(round(leer_campo(opciones, 'n_nodos_objetivo', 41)), 9);
  n_x = min(n_x, 81);
  dx = L / (n_x - 1);
  dt = dx / max(a_onda, 1);
  n_per = max(round(T / dt), 180);
  dt = T / n_per;
  % Recalcular dx para mantener dx/a = dt, como recomienda Gibbs.
  dx = a_onda * dt;
  L_eff = dx * (n_x - 1);
  if abs(L_eff - L) / max(L,1) > 0.08
      % Si el ajuste se aleja mucho de la profundidad real, aumentamos nodos.
      n_x = min(max(round(L/(a_onda*dt))+1, n_x), 121);
      dx = L / (n_x - 1);
      dt = dx / max(a_onda, 1);
      n_per = max(round(T / dt), 180);
      dt = T / n_per;
      dx = a_onda * dt;
  end

  n_ciclos = max(round(leer_campo(opciones, 'n_ciclos', 10)), 4);
  n_total = n_per * n_ciclos;
  n_out = max(round(leer_campo(opciones, 'n_t', 720)), 240);

  Aeq = max(malla.K_eq_N_m * L / max(E,1), malla.A_top_m2);
  EA = E * Aeq;
  Wb = max(malla.peso_flotado_N, 0);
  Wf = max(gibbs_carga_fluido(param), 0);
  llenado = min(max(leer_campo(param, 'llenado_bomba', leer_campo(param, 'eta_vol', 0.85)), 0), 1.15);
  Wf = Wf * llenado * min(max(leer_campo(param,'eficiencia_valvulas',1.0),0),1.2);

  v_damp = max(leer_campo(opciones, 'amortiguamiento', leer_campo(param, 'gibbs_amortiguamiento', 0.045)), 0);
  r = pi * a_onda * v_damp * dt / (2 * max(L,1));

  t_cycle = (0:n_per-1) * dt;
  cin = cinematica_superficie(param.tipo_unidad, S, param.N_velocidad, t_cycle);
  top = cin.pos(:)';
  top = top - min(top);

  U_prev = zeros(n_x,1);
  U_curr = zeros(n_x,1);
  U_next = zeros(n_x,1);
  U_prev(:) = top(1);
  U_curr(:) = top(1);

  estado = 1; % 1 libre bajando, 2 toma carga, 3 levantando, 4 descarga
  u_fijo = U_curr(end);
  u_fijo_desc = U_curr(end);

  rec_t = zeros(1,n_per);
  rec_top = zeros(1,n_per);
  rec_bot = zeros(1,n_per);
  rec_load_top = zeros(1,n_per);
  rec_load_bot = zeros(1,n_per);
  rec_estado = zeros(1,n_per);

  for it = 1:n_total
      ic = mod(it-1, n_per) + 1;
      U_curr(1) = top(ic);

      for i = 2:n_x-1
          U_next(i) = (U_curr(i+1) + U_curr(i-1) - U_prev(i) + r*U_curr(i)) / (1+r);
      end
      U_next(1) = top(ic);

      % Carga dinamica en bomba antes de elegir el siguiente borde.
      Fp = EA * (1.5*U_curr(end) - 2*U_curr(end-1) + 0.5*U_curr(end-2)) / max(dx,1e-9);
      dUb = U_curr(end) - U_prev(end);

      % Sensado de eventos, siguiendo la logica Gibbs: cierre/apertura de
      % valvulas por posicion extrema y transferencia de carga.
      if estado == 1
          % Libre y descargado: al llegar al PMI inicia toma de carga.
          if dUb > 0
              estado = 2;
              u_fijo = U_curr(end);
          end
      elseif estado == 2
          % Bomba fija mientras la carga de fluido pasa a las varillas.
          if Fp >= Wf
              estado = 3;
          end
      elseif estado == 3
          % Levantando fluido: al llegar al PMS inicia descarga.
          if dUb < 0
              estado = 4;
              u_fijo_desc = U_curr(end);
          end
      elseif estado == 4
          % Descarga: cuando la carga cae cerca de cero, queda libre.
          if Fp <= 0.05*max(Wf,1)
              estado = 1;
          end
      end

      if estado == 1
          alpha = 0; beta = 1; Pbc = 0;
      elseif estado == 2
          alpha = 1; beta = 0; Pbc = u_fijo;
      elseif estado == 3
          alpha = 0; beta = 1; Pbc = Wf / max(EA,1);
      else
          alpha = 1; beta = 0; Pbc = u_fijo_desc;
      end

      % Borde inferior de Gibbs en diferencia: alpha*u + beta*u_x = P.
      denom = alpha*dx + 1.5*beta;
      U_next(end) = (dx*Pbc + beta*(2*U_next(end-1) - 0.5*U_next(end-2))) / max(denom,1e-12);

      % Evitar derivas numericas por condiciones iniciales pobres.
      if any(~isfinite(U_next)) || any(abs(U_next) > 30*S)
          warning('Gibbs 1963 experimental inestable. Se usa modo estable.');
          res = gibbs_forward_estable(param, varillas, malla, opciones);
          return;
      end

      if it > (n_ciclos-1)*n_per
          il = ic;
          rec_t(il) = (il-1)*dt;
          rec_top(il) = U_curr(1);
          rec_bot(il) = U_curr(end);
          Ftop_dyn = EA * (-1.5*U_curr(1) + 2*U_curr(2) - 0.5*U_curr(3)) / max(dx,1e-9);
          Fbot_dyn = EA * (1.5*U_curr(end) - 2*U_curr(end-1) + 0.5*U_curr(end-2)) / max(dx,1e-9);
          rec_load_top(il) = max(Wb + Ftop_dyn, 0);
          rec_load_bot(il) = max(Fbot_dyn, 0);
          rec_estado(il) = estado;
      end

      U_prev = U_curr;
      U_curr = U_next;
  end

  tq = linspace(0, T, n_out+1); tq(end) = [];
  t = tq;
  pos_sup = interp1([rec_t, T], [rec_top, rec_top(1)], tq, 'linear');
  pos_fondo = interp1([rec_t, T], [rec_bot, rec_bot(1)], tq, 'linear');
  carga_sup = interp1([rec_t, T], [rec_load_top, rec_load_top(1)], tq, 'linear');
  carga_fondo = interp1([rec_t, T], [rec_load_bot, rec_load_bot(1)], tq, 'linear');
  estado_v = interp1([rec_t, T], [rec_estado, rec_estado(1)], tq, 'nearest');

  % Cierre/suavizado minimo. No suavizamos en exceso para conservar reflexiones.
  carga_sup = max(suavizar_periodico(carga_sup, max(3, round(0.012*n_out))), 0);
  carga_fondo = max(suavizar_periodico(carga_fondo, max(3, round(0.012*n_out))), 0);
  pos_fondo = cerrar_periodico_suave(pos_fondo, max(6, round(0.02*n_out)));

  llenado_inst = llenado * ones(size(t));
  [metricas, cartas] = gibbs_calcular_metricas_bomba(param, pos_sup, carga_sup, pos_fondo, carga_fondo, t, estado_v, llenado_inst);
  espaciamiento = gibbs_estimacion_espaciamiento(param, metricas, cartas, malla);

  res = struct();
  res.modo = 'forward';
  res.modelo = 'Gibbs_1963_diferencias_parciales_AOS_v14_EXPERIMENTAL';
  res.t = t(:);
  res.carta_sup = cartas.carta_sup;
  res.carta_fondo = cartas.carta_fondo;
  res.posicion_superficie_m = pos_sup(:);
  res.posicion_fondo_m = pos_fondo(:);
  vf_tmp = gradiente_periodico(pos_fondo, t);
  res.velocidad_fondo_m_s = vf_tmp(:);
  res.carga_superficie_N = carga_sup(:);
  res.carga_fondo_N = carga_fondo(:);
  res.valvula_factor = estado_v(:);
  res.llenado_inst = llenado_inst(:);
  res.metricas = metricas;
  res.espaciamiento = espaciamiento;
  res.info = struct();
  res.info.metodo_forward = 'gibbs1963';
  res.info.ecuacion = 'u_tt = a^2 u_xx - (pi*a*v/(2L))*u_t, dx/a=dt';
  res.info.condicion_bomba = 'alpha*u(L,t)+beta*u_x(L,t)=P(t) con sensado simple de valvulas';
  res.info.vel_onda_m_s = a_onda;
  res.info.dt_s = dt;
  res.info.dx_m = dx;
  res.info.n_nodos = n_x;
  res.info.n_ciclos = n_ciclos;
  res.info.Wf_N = Wf;
  res.info.Wb_N = Wb;
  res.info.aviso = 'Primer intento Gibbs 1963. Validar contra cartas reales/QROD/SROD antes de uso operativo.';
end

function v = media_segura(x, defecto)
  v = defecto;
  if isnumeric(x) && ~isempty(x)
      y = x(isfinite(x) & x > 0);
      if ~isempty(y), v = mean(y); end
  end
end

function y = suavizar_periodico(x, ventana)
  x = x(:)';
  n = length(x);
  y = zeros(size(x));
  ventana = max(round(ventana),1);
  m = floor(ventana/2);
  for i=1:n
      s = 0; c = 0;
      for j=-m:m
          k = mod(i+j-1,n)+1;
          s = s + x(k);
          c = c + 1;
      end
      y(i)=s/max(c,1);
  end
end

function y = sigmoid(x)
  y = 1 ./ (1 + exp(-max(min(x,60),-60)));
end

function y = cerrar_periodico_suave(x, nblend)
  x = x(:)';
  n = length(x);
  y = x;
  nblend = min(max(round(nblend),1), floor(n/3));
  if n < 4 || nblend < 2
      if n >= 1, y(end) = y(1); end
      return;
  end
  delta = y(end) - y(1);
  for i=1:n
      y(i) = y(i) - delta * (i-1) / max(n-1,1);
  end
  y = suavizar_periodico(y, max(3, round(nblend/2)));
  y(end) = y(1);
end


function y = interp_periodico(t, x, tq, T)
  t = t(:)'; x = x(:)'; tq = tq(:)';
  if isempty(t) || isempty(x)
      y = zeros(size(tq));
      return;
  end
  t_ext = [t, T];
  x_ext = [x, x(1)];
  tqm = mod(tq, T);
  y = interp1(t_ext, x_ext, tqm, 'linear');
  malos = isnan(y) | ~isfinite(y);
  if any(malos)
      y(malos) = interp1(t_ext, x_ext, tqm(malos), 'nearest', 'extrap');
  end
end

function v = sign_seguro(x)
  v = zeros(size(x));
  v(x > 0) = 1;
  v(x < 0) = -1;
end

function y = gradiente_periodico(x, t)
  x = x(:)'; t = t(:)'; n = length(x); y = zeros(size(x));
  if n < 3, return; end
  dt = median(diff(t));
  if isempty(dt) || ~isfinite(dt) || dt <= 0, dt = 1; end
  for i=1:n
      im=i-1; if im<1, im=n; end
      ip=i+1; if ip>n, ip=1; end
      y(i) = (x(ip)-x(im))/(2*dt);
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

function v = leer_campo_texto(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if ischar(tmp)
          v = tmp;
      end
  end
end

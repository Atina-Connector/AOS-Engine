function res = gibbs2_solver_dynamic(param, malla)
  % GIBBS2_SOLVER_DYNAMIC
  % Solver dinamico axial para la sarta de varillas GF2.
  %
  % Modelo resuelto para las perturbaciones respecto del equilibrio:
  %
  %   M*q_dd + C*q_d + K*q = F_bomba_dinamica
  %
  % donde K se construye con la rigidez axial EA/L de cada elemento.
  % La velocidad de onda es longitudinal: c = sqrt(E/rho), y NO
  % sqrt(T/mu), que corresponde a una cuerda con ondas transversales.
  %
  % La posicion total se reconstruye como:
  %
  %   U_total = U_equilibrio_estatico + q_dinamica
  %
  % De esta forma no se suma dos veces el peso de la sarta ni la carga
  % estatica de la bomba.

  if nargin < 2
    error('gibbs2_solver_dynamic requiere param y malla.');
  end
  if ~isstruct(param) || ~isstruct(malla)
    error('param y malla deben ser estructuras.');
  end

  param = gibbs2_dynamic_defaults(param);

  [n, m_node, dx_e, k_e, c_e] = preparar_malla_local(param, malla);

  g = param.gibbs2_gravedad;
  spm = max(valor_campo(param, 'N_velocidad', 0), ...
            param.gibbs2_min_spm);
  T_ciclo = 60.0 / spm;

  ncy = max(1, round(param.gibbs2_n_ciclos));
  ppc = max(round(param.gibbs2_min_puntos_por_ciclo), ...
            round(param.gibbs2_puntos_por_ciclo));
  nt = ncy * ppc + 1;
  dt_salida = T_ciclo / ppc;

  % Paso interno consistente con la onda longitudinal realmente usada.
  cfl = min(max(param.gibbs2_cfl, 0.05), 0.95);
  dt_critico = cfl * min(dx_e ./ max(c_e, eps));
  if ~isfinite(dt_critico) || dt_critico <= 0
    error('No se pudo calcular un paso temporal estable para GF2.');
  end

  oversampling = max(1, round(param.gibbs2_oversampling));
  sub = max(1, ceil(dt_salida / dt_critico)) * oversampling;
  dt = dt_salida / sub;
  n_pasos = (nt - 1) * sub;

  % Carga de bomba y equilibrio estatico coherentes entre si.
  bomba = calcular_cargas_bomba_local(param, g, T_ciclo);
  [u_eq, tension_estatica_e, carga_estatica_superficie] = ...
    equilibrio_estatico_local(m_node, k_e, bomba.F_ref_N, ...
                              g, param.gibbs2_buoyancy_factor_rods);

  % q es el desplazamiento dinamico respecto del equilibrio estatico.
  q = zeros(n, 1);
  vel = zeros(n, 1);

  % Amortiguamiento de Gibbs expresado como razon [1/s].
  L_total = sum(dx_e);
  c_ref = sum(c_e .* dx_e) / max(L_total, eps);
  delta = max(param.gibbs2_delta_damping, 0);
  gamma = pi * c_ref * delta / (2.0 * max(L_total, eps)); % [1/s]

  % Almacenamiento
  TT = zeros(nt, 1);
  U = zeros(nt, n);
  V = zeros(nt, n);
  Ftop = zeros(nt, 1);
  Fbot = zeros(nt, 1);
  Valve = zeros(nt, 1);

  % Estado inicial
  [us, vs] = gibbs2_surface_motion(0, param);
  q(1) = us;
  vel(1) = vs;
  [Fb, apertura] = carga_bomba_suave_local(vel(n), bomba);

  TT(1) = 0;
  U(1, :) = (u_eq + q).';
  V(1, :) = vel.';
  Ftop(1) = carga_estatica_superficie + k_e(1) * (q(1) - q(2));
  Fbot(1) = Fb;
  Valve(1) = apertura;

  rec = 2;

  % Integracion explicita semi-implicita. Para una cadena axial lineal
  % es mas estable que Euler explicito directo, siempre que se respete CFL.
  for paso = 1:n_pasos
    t_actual = (paso - 1) * dt;

    % Condicion de borde superior impuesta en el tiempo actual.
    [us, vs] = gibbs2_surface_motion(t_actual, param);
    q(1) = us;
    vel(1) = vs;

    [Fb_actual, apertura_actual] = ...
      carga_bomba_suave_local(vel(n), bomba);

    fuerza = fuerza_dinamica_local(q, vel, m_node, k_e, ...
                                   Fb_actual, bomba.F_ref_N, gamma);

    acc = fuerza ./ m_node;
    acc(1) = 0;

    % Euler semi-implicito: primero velocidad, luego posicion.
    vel(2:n) = vel(2:n) + dt * acc(2:n);
    q(2:n) = q(2:n) + dt * vel(2:n);

    % Imponer exactamente el movimiento del polished rod al final del paso.
    t_nuevo = paso * dt;
    [us, vs] = gibbs2_surface_motion(t_nuevo, param);
    q(1) = us;
    vel(1) = vs;

    if mod(paso, sub) == 0
      [Fb_salida, apertura_salida] = ...
        carga_bomba_suave_local(vel(n), bomba);

      TT(rec) = t_nuevo;
      U(rec, :) = (u_eq + q).';
      V(rec, :) = vel.';
      Ftop(rec) = carga_estatica_superficie + ...
                  k_e(1) * (q(1) - q(2));
      Fbot(rec) = Fb_salida;
      Valve(rec) = apertura_salida;
      rec = rec + 1;
    end
  end

  if rec ~= nt + 1
    error('GF2 registro %d puntos y esperaba %d.', rec - 1, nt);
  end

  version = valor_campo(param, 'gibbs2_version', ...
                        'AOS_BM_Gibbs_Foundation2_axial_FE');

  res = struct();
  res.version = version;
  res.param = param;
  res.malla = malla;
  res.t = TT;
  res.U = U;
  res.V = V;
  res.F_superficie_N = Ftop;
  res.F_bomba_N = Fbot;
  res.apertura_valvula = Valve;
  res.ciclos_simulados = ncy;
  res.ciclos_descartados = param.gibbs2_descartar_ciclos;
  res.modelo = 'dynamic_GF2_axial_finite_elements';
  res.integrador = param.gibbs2_integrador;

  % Diagnostico numerico y fisico para auditoria.
  res.diagnostico = struct();
  res.diagnostico.c_onda_elementos_m_s = c_e;
  res.diagnostico.c_onda_referencia_m_s = c_ref;
  res.diagnostico.gamma_damping_1_s = gamma;
  res.diagnostico.cfl = cfl;
  res.diagnostico.dt_salida_s = dt_salida;
  res.diagnostico.dt_integracion_s = dt;
  res.diagnostico.subpasos_por_salida = sub;
  res.diagnostico.carga_bomba_up_N = bomba.F_up_N;
  res.diagnostico.carga_bomba_down_N = bomba.F_down_N;
  res.diagnostico.carga_bomba_ref_N = bomba.F_ref_N;
  res.diagnostico.carga_estatica_superficie_N = ...
    carga_estatica_superficie;
  res.diagnostico.tension_estatica_elementos_N = tension_estatica_e;
  res.diagnostico.u_equilibrio_m = u_eq;
end

function fuerza = fuerza_dinamica_local(q, vel, m_node, k_e, ...
                                         Fb, F_ref, gamma)
  % Fuerzas nodales de una barra axial discretizada.
  n = numel(q);
  fuerza = zeros(n, 1);

  for e = 1:n-1
    % Deformacion dinamica del elemento e.
    f_e = k_e(e) * (q(e+1) - q(e));
    fuerza(e) = fuerza(e) + f_e;
    fuerza(e+1) = fuerza(e+1) - f_e;
  end

  % La carga estatica F_ref ya esta contenida en u_eq. Aqui solo se aplica
  % el incremento dinamico de la carga de bomba.
  fuerza(n) = fuerza(n) - (Fb - F_ref);

  % Amortiguamiento dimensionalmente consistente:
  % [kg] * [1/s] * [m/s] = [N].
  fuerza(2:n) = fuerza(2:n) - gamma .* m_node(2:n) .* vel(2:n);

  % El nodo 1 tiene desplazamiento impuesto y no se integra.
  fuerza(1) = 0;
end

function [u_eq, T_e, F_superficie] = equilibrio_estatico_local( ...
    m_node, k_e, F_ref, g, buoyancy_factor)
  % Equilibrio estatico bajo carga media de bomba y peso aparente.
  n = numel(m_node);
  bf = min(max(buoyancy_factor, 0), 1.5);
  peso_nodal = m_node * g * bf;

  T_e = zeros(n-1, 1);
  carga_debajo = F_ref;

  for e = n-1:-1:1
    carga_debajo = carga_debajo + peso_nodal(e+1);
    T_e(e) = carga_debajo;
  end

  u_eq = zeros(n, 1);
  for e = 1:n-1
    elongacion = T_e(e) / max(k_e(e), eps);
    % Convencion: carrera positiva hacia arriba; elongacion estatica hacia abajo.
    u_eq(e+1) = u_eq(e) - elongacion;
  end

  % La carga del polished rod incluye todo el peso nodal y la bomba media.
  F_superficie = F_ref + sum(peso_nodal);
end

function bomba = calcular_cargas_bomba_local(param, g, T_ciclo)
  WC = min(max(valor_campo(param, 'WC', 0), 0), 1);
  rho_o = max(valor_campo(param, 'rho_o', 850), 1);
  rho_w = max(valor_campo(param, 'rho_w', 1000), 1);
  rho_l = rho_o * (1 - WC) + rho_w * WC;

  Dp_mm = max(valor_campo(param, 'D_bomba_mm', 1), eps);
  Dp = Dp_mm / 1000.0;
  Ap = pi * (Dp / 2.0)^2;

  profundidad = profundidad_bomba_local(param);
  Pwh = max(valor_campo(param, 'P_wh', 0), 0);
  Pintake = presion_intake_local(param);

  Pdescarga = Pwh + rho_l * g * max(profundidad, 0);
  deltaP = max(Pdescarga - Pintake, 0);

  llenado = min(max(param.gibbs2_llenado_bomba, 0), 1.2);
  F_hidraulica = deltaP * Ap * llenado;

  F_fric_up = fuerza_friccion_local(param.gibbs2_friccion_ascenso_N, ...
                                    param.gibbs2_friccion_ascenso_frac, ...
                                    F_hidraulica);
  F_fric_down = fuerza_friccion_local(param.gibbs2_friccion_descenso_N, ...
                                      param.gibbs2_friccion_descenso_frac, ...
                                      F_hidraulica);

  bomba = struct();
  bomba.F_up_N = F_hidraulica + F_fric_up;
  bomba.F_down_N = F_fric_down;
  bomba.F_ref_N = 0.5 * (bomba.F_up_N + bomba.F_down_N);
  bomba.F_hidraulica_N = F_hidraulica;
  bomba.P_descarga_Pa = Pdescarga;
  bomba.P_intake_Pa = Pintake;
  bomba.deltaP_Pa = deltaP;
  bomba.area_piston_m2 = Ap;
  bomba.rho_l_kg_m3 = rho_l;

  vmax_superficie = pi * max(valor_campo(param, 'S_carrera', 0), 0) / ...
                     max(T_ciclo, eps);
  v_por_fraccion = max(param.gibbs2_valve_transition_frac, 0) * ...
                   vmax_superficie;
  bomba.v_transicion_m_s = max([param.gibbs2_valve_vel_threshold, ...
                                v_por_fraccion, eps]);
end

function [Fb, apertura] = carga_bomba_suave_local(v_bomba, bomba)
  % Transicion continua entre carrera descendente y ascendente.
  % apertura = 0: estado de descenso; apertura = 1: estado de ascenso.
  apertura = 0.5 * (1.0 + tanh(v_bomba / bomba.v_transicion_m_s));
  Fb = bomba.F_down_N + ...
       (bomba.F_up_N - bomba.F_down_N) * apertura;
end

function F = fuerza_friccion_local(F_abs, fraccion, F_base)
  if isfinite(F_abs) && F_abs >= 0
    F = F_abs;
  else
    F = max(fraccion, 0) * max(F_base, 0);
  end
end

function P = presion_intake_local(param)
  if isfinite(param.gibbs2_presion_intake_Pa)
    P = max(param.gibbs2_presion_intake_Pa, 0);
    return;
  end

  candidatos = {'P_intake', 'P_intake_Pa', 'P_intake_min'};
  P = 0;
  for k = 1:numel(candidatos)
    nombre = candidatos{k};
    if isfield(param, nombre) && isnumeric(param.(nombre)) && ...
       isscalar(param.(nombre)) && isfinite(param.(nombre))
      P = max(param.(nombre), 0);
      return;
    end
  end
end

function D = profundidad_bomba_local(param)
  % Prioriza TVD explicita si existe; conserva D_bomba por compatibilidad.
  candidatos = {'D_bomba_TVD', 'prof_bomba_TVD', 'TVD_bomba', 'D_bomba'};
  D = 0;
  for k = 1:numel(candidatos)
    nombre = candidatos{k};
    if isfield(param, nombre) && isnumeric(param.(nombre)) && ...
       isscalar(param.(nombre)) && isfinite(param.(nombre))
      D = max(param.(nombre), 0);
      return;
    end
  end
end

function [n, m_node, dx_e, k_e, c_e] = ...
    preparar_malla_local(param, malla)
  if isfield(malla, 'n')
    n = round(malla.n);
  elseif isfield(malla, 'm')
    n = numel(malla.m);
  else
    error('La malla no contiene n ni m.');
  end

  if n < 2
    error('La malla GF2 requiere al menos dos nodos.');
  end

  if ~isfield(malla, 'm')
    error('La malla no contiene masas nodales m.');
  end
  m_node = malla.m(:);
  if numel(m_node) ~= n || any(~isfinite(m_node)) || any(m_node <= 0)
    error('malla.m debe contener %d masas nodales positivas.', n);
  end

  if ~isfield(malla, 'dx')
    error('La malla no contiene longitudes de elemento dx.');
  end
  dx_e = vector_elementos_local(malla.dx, n-1, 'malla.dx');
  if any(~isfinite(dx_e)) || any(dx_e <= 0)
    error('Todos los elementos de malla.dx deben ser positivos.');
  end

  if isfield(malla, 'k_e')
    k_e = vector_elementos_local(malla.k_e, n-1, 'malla.k_e');
  else
    if ~isfield(malla, 'E') || ~isfield(malla, 'A')
      error('La malla requiere k_e o bien E y A.');
    end
    E_e = vector_elementos_local(malla.E, n-1, 'malla.E');
    A_e = vector_elementos_local(malla.A, n-1, 'malla.A');
    k_e = E_e .* A_e ./ dx_e;
  end
  if any(~isfinite(k_e)) || any(k_e <= 0)
    error('Todas las rigideces axiales k_e deben ser positivas.');
  end

  if isfield(malla, 'c_onda')
    c_e = vector_elementos_local(malla.c_onda, n-1, 'malla.c_onda');
  else
    if ~isfield(malla, 'E')
      error('La malla requiere c_onda o E para calcular sqrt(E/rho).');
    end
    E_e = vector_elementos_local(malla.E, n-1, 'malla.E');
    rho_rod = max(valor_campo(param, 'gibbs2_rho_rod', 7850), eps);
    c_e = sqrt(E_e ./ rho_rod);
  end
  if any(~isfinite(c_e)) || any(c_e <= 0)
    error('Todas las velocidades longitudinales c_onda deben ser positivas.');
  end
end

function v = vector_elementos_local(x, n_elem, nombre)
  if ~isnumeric(x) || isempty(x)
    error('%s debe ser numerico y no vacio.', nombre);
  end
  x = x(:);
  if numel(x) == 1
    v = repmat(x, n_elem, 1);
  elseif numel(x) == n_elem
    v = x;
  elseif numel(x) == n_elem + 1
    % Compatibilidad con propiedades almacenadas por nodo.
    v = 0.5 * (x(1:end-1) + x(2:end));
  else
    error('%s debe ser escalar, tener %d elementos o %d nodos.', ...
          nombre, n_elem, n_elem + 1);
  end
end

function value = valor_campo(s, name, default_value)
  if isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
  else
    value = default_value;
  end
end

function res = gibbs18_solver_forward(param, malla)
% Solver forward BM Gibbs Foundation v18.3.
% Octave compatible.
% Top: desplazamiento impuesto en polished rod.
% Bottom: bomba como condicion de borde inferior.
%
% v18.3 agrega modo cuasiestatico estabilizado para casos de baja velocidad.
% Esto evita que un caso lento y bomba llena genere oscilaciones numericas que
% no corresponden fisicamente. El solver dinamico original queda disponible.
  param = gibbs18_defaults(param);

  modo = param.gibbs18_modo_solver;
  if strcmpi(modo,'automatico')
      if param.N_velocidad <= param.gibbs18_spm_limite_cuasiestatico
          modo_resuelto = 'cuasiestatico';
      else
          modo_resuelto = 'dinamico_foundation';
      end
  else
      modo_resuelto = modo;
  end

  if strcmpi(modo_resuelto,'cuasiestatico') || strcmpi(modo_resuelto,'quasi')
      res = gibbs18_solver_quasi_static(param, malla, modo_resuelto);
      return;
  end

  res = gibbs18_solver_dynamic_foundation(param, malla, modo_resuelto);
end

function res = gibbs18_solver_quasi_static(param, malla, modo_resuelto)
% Modelo cuasiestatico: util para validar carga, diametro, llenado y promedio.
% Para 1500 m, 3 spm y bomba llena debe entregar carta casi paralelogramo.
  n = malla.n;
  spm = max(param.N_velocidad, 0.1);
  T = 60/spm;
  ncy = max(1, round(param.gibbs18_n_ciclos));
  ppc = max(120, round(param.gibbs18_puntos_por_ciclo));
  nt = ncy*ppc + 1;
  t = (0:nt-1)'*(T/ppc);

  U = zeros(nt,n);
  V = zeros(nt,n);
  Ftop = zeros(nt,1);
  Ftop_dyn = zeros(nt,1);
  Fbot = zeros(nt,1);

  WC = min(max(leer_num(param,'WC',0.5),0),1);
  rho_l = leer_num(param,'rho_o',850)*(1-WC) + leer_num(param,'rho_w',1000)*WC;
  Dp = max(leer_num(param,'D_bomba_mm',32),1)/1000;
  Ap = pi*(Dp/2)^2;
  Pcol = max(leer_num(param,'D_bomba',1500),0)*rho_l*9.81;
  Pwh = max(leer_num(param,'P_wh',10e5),0);
  Pf = (Pcol + Pwh)*Ap;
  llenado = min(max(leer_num(param,'gibbs18_llenado_bomba',1),0),1.2);
  F_down = Pf*(1-llenado);
  F_up = Pf;

  rod_weight = sum(malla.m)*9.81*leer_num(param,'gibbs18_buoyancy_factor_rods',0.87);
  Krod = max(malla.E*malla.A/max(malla.L,1), 1);
  m_eff = sum(malla.m)*leer_num(param,'gibbs18_factor_inercia_superficie',0.35);
  c_eff = 0.0;
  if isfield(param,'gibbs18_factor_viscoso_superficie')
      c_eff = max(param.gibbs18_factor_viscoso_superficie,0)*sum(malla.m);
  end

  Fref = 0.5*(F_up + F_down);
  for i = 1:nt
      ti = t(i);
      [us, vs] = gibbs18_surface_motion(ti, param);
      accs = gibbs18_surface_accel(ti, param);
      alpha = gibbs18_upstroke_factor(ti, param);
      Fb = F_down + (F_up - F_down)*alpha;

      % La bomba se desplaza con el PR menos la elongacion elastica incremental.
      % Se usa carga respecto de la carga media para evitar desplazar toda la
      % carrera por el offset estatico.
      up = us - (Fb - Fref)/Krod;
      vp = vs;  % primera aproximacion foundation

      U(i,:) = linspace(us, up, n);
      V(i,:) = linspace(vs, vp, n);
      Fbot(i) = Fb;
      Ftop(i) = rod_weight + Fb + m_eff*accs + c_eff*vs;
      Ftop_dyn(i) = Ftop(i) - rod_weight;
  end

  res.version = param.gibbs18_version;
  res.param = param;
  res.malla = malla;
  res.t = t;
  res.U = U;
  res.V = V;
  res.F_superficie_dinamica_N = Ftop_dyn;
  res.F_superficie_N = Ftop;
  res.F_bomba_N = Fbot;
  res.ciclos_simulados = ncy;
  res.ciclos_descartados = param.gibbs18_descartar_ciclos;
  res.modelo = 'quasi_static_rod_pump_foundation';
  res.modo_solver_resuelto = modo_resuelto;
  res.diagnostico_cargas = gibbs18_static_surface_load(param, malla, Fbot);
  res.diagnostico_cargas.offset_superficie_N = rod_weight;
  res.diagnostico_cargas.modo = 'cuasiestatico_directo';
  res.nota = 'Foundation v18.3: modo cuasiestatico estabilizado para validacion de cargas y cartas.';
end

function res = gibbs18_solver_dynamic_foundation(param, malla, modo_resuelto)
% Solver dinamico foundation original, conservado para pruebas de propagacion.
  n = malla.n;
  spm = max(param.N_velocidad, 0.1);
  T = 60/spm;
  ncy = max(1, round(param.gibbs18_n_ciclos));
  ppc = max(120, round(param.gibbs18_puntos_por_ciclo));
  nt = ncy*ppc + 1;
  dt = T/ppc;
  dt_cfl = 0.45*malla.dx/max(malla.c_onda,1);
  sub = max(1, ceil(dt/dt_cfl));
  dt_int = dt/sub;
  nt_int = (nt-1)*sub + 1;
  t_int = (0:nt_int-1)'*dt_int;

  u = zeros(n,1); vel = zeros(n,1);
  U = zeros(nt,n); V = zeros(nt,n); TT = zeros(nt,1);
  Ftop_dyn = zeros(nt,1); Ftop = zeros(nt,1); Fbot = zeros(nt,1);
  rec = 1;
  gamma = max(param.gibbs18_amortiguamiento,0);

  for it = 1:nt_int
      ti = t_int(it);
      [u(1), vel(1)] = gibbs18_surface_motion(ti, param);
      force = zeros(n,1);
      for j = 2:n-1
          force(j) = malla.k*(u(j-1) - 2*u(j) + u(j+1));
      end
      Fb = gibbs18_bottom_boundary(ti, u(n), vel(n), param);
      force(n) = malla.k*(u(n-1) - u(n)) + Fb;
      force(2:n) = force(2:n) - gamma*malla.m(2:n).*vel(2:n);
      acc = zeros(n,1);
      acc(2:n) = force(2:n)./max(malla.m(2:n),1e-9);
      vel(2:n) = vel(2:n) + dt_int*acc(2:n);
      u(2:n) = u(2:n) + dt_int*vel(2:n);
      [u(1), vel(1)] = gibbs18_surface_motion(ti+dt_int, param);

      if mod(it-1,sub)==0
          TT(rec) = ti;
          U(rec,:) = u(:)'; V(rec,:) = vel(:)';
          Ftop_dyn(rec) = malla.k*(u(1)-u(2));
          Ftop(rec) = Ftop_dyn(rec);
          Fbot(rec) = Fb;
          rec = rec + 1;
      end
  end
  res.version = param.gibbs18_version;
  res.param = param; res.malla = malla; res.t = TT; res.U = U; res.V = V;
  res.F_superficie_dinamica_N = Ftop_dyn;
  res.F_superficie_N = Ftop;
  res.F_bomba_N = Fbot;

  if isfield(param,'gibbs18_aplicar_offset_estatico') && param.gibbs18_aplicar_offset_estatico
      diag_static = gibbs18_static_surface_load(param, malla, Fbot);
      res.F_superficie_N = Ftop_dyn + diag_static.offset_superficie_N;
      res.diagnostico_cargas = diag_static;
  else
      diag_static = gibbs18_static_surface_load(param, malla, Fbot);
      diag_static.offset_superficie_N = 0;
      diag_static.modo = 'desactivado';
      res.diagnostico_cargas = diag_static;
  end
  res.ciclos_simulados = ncy; res.ciclos_descartados = param.gibbs18_descartar_ciclos;
  res.modelo = 'mass_spring_1D_forward_foundation';
  res.modo_solver_resuelto = modo_resuelto;
  res.nota = 'Foundation v18.3: solver dinamico preliminar, no validado contra casos comerciales.';
end

function a = gibbs18_surface_accel(t, param)
  S = max(leer_num(param,'S_carrera',1.5), 0);
  spm = max(leer_num(param,'N_velocidad',6), 0.1);
  T = 60/spm;
  w = 2*pi/T;
  a = 0.5*S*w*w*cos(w*t);
end

function alpha = gibbs18_upstroke_factor(t, param)
% 1 en carrera ascendente, 0 en descendente, con transicion corta.
  spm = max(leer_num(param,'N_velocidad',6), 0.1);
  T = 60/spm;
  phi = (t - floor(t/T)*T)/T;
  epsf = min(max(leer_num(param,'gibbs18_valve_transition_frac',0.006),0.001),0.05);
  if phi < epsf
      alpha = smoothstep(phi/epsf);
  elseif phi <= 0.5-epsf
      alpha = 1;
  elseif phi < 0.5+epsf
      alpha = 1 - smoothstep((phi-(0.5-epsf))/(2*epsf));
  elseif phi <= 1-epsf
      alpha = 0;
  else
      alpha = smoothstep((phi-(1-epsf))/epsf);
  end
end

function y = smoothstep(x)
  x = min(max(x,0),1);
  y = x*x*(3 - 2*x);
end

function v = leer_num(s,campo,def)
  v = def;
  if isstruct(s) && isfield(s,campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1)), v = tmp(1); end
  end
end

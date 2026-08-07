function res = gibbs3_solver_dynamic(param, malla)
% GIBBS3_SOLVER_DYNAMIC Solver axial FE de Gibbs Foundation 3.
%
% Resuelve perturbaciones q respecto del equilibrio estatico:
%   M*q_dd + C*q_d + K*q = f_bomba(t) - f_bomba_ref
% con desplazamiento impuesto en el polished rod.

  bomba = gibbs3_pump_model(param, malla);
  eq = gibbs3_static_equilibrium(param, malla, bomba);

  n = malla.n;
  Tcy = 60.0/param.N_velocidad;
  ppc = param.gibbs3_puntos_por_ciclo;
  ncy = param.gibbs3_n_ciclos;
  nt = ncy*ppc + 1;
  dt_out = Tcy/ppc;

  dt_cfl = param.gibbs3_cfl * min(malla.dx_m ./ malla.c_onda_m_s);
  sub = ceil(dt_out/dt_cfl) * param.gibbs3_oversampling;
  dt = dt_out/sub;
  nsteps = (nt-1)*sub;

  L = malla.L_m;
  c_ref = sum(malla.c_onda_m_s .* malla.dx_m)/L;
  gamma = pi*c_ref*param.gibbs3_delta_damping/(2*L);

  q = zeros(n,1);
  vel = zeros(n,1);
  alpha = param.gibbs3_apertura_valvula_inicial;

  TT = zeros(nt,1);
  U = zeros(nt,n);
  V = zeros(nt,n);
  Ftop = zeros(nt,1);
  Fbot = zeros(nt,1);
  Valve = zeros(nt,1);
  FLPP = zeros(nt,1);
  DPLPP = zeros(nt,1);
  QLPP = zeros(nt,1);

  [us,vs] = gibbs3_surface_motion(0,param);
  q(1)=us; vel(1)=vs;
  Fb_base = carga_bomba(alpha,bomba);
  lpp_inst = gibbs3_lpp_hydraulics(param,bomba,vel(n));
  Fb = Fb_base + lpp_inst.F_firmada_N;
  registrar(1,0);
  rec = 2;

  for istep = 1:nsteps
    t0 = (istep-1)*dt;
    [us,vs] = gibbs3_surface_motion(t0,param);
    q(1)=us; vel(1)=vs;

    alpha_obj = 0.5*(1+tanh(vel(n)/bomba.velocidad_transicion_m_s));
    if bomba.tau_valvula_s > 0
      alpha = alpha + dt*(alpha_obj-alpha)/bomba.tau_valvula_s;
      alpha = min(max(alpha,0),1);
    else
      alpha = alpha_obj;
    end
    Fb_base = carga_bomba(alpha,bomba);
    lpp_inst = gibbs3_lpp_hydraulics(param,bomba,vel(n));
    Fb = Fb_base + lpp_inst.F_firmada_N;

    f = fuerzas_axiales(q,vel,malla,Fb,bomba.F_ref_N,gamma);
    acc = f ./ malla.masa_nodal_kg;
    acc(1)=0;

    % Euler simplectico: estable para la cadena axial bajo el limite CFL.
    vel(2:n) = vel(2:n) + dt*acc(2:n);
    q(2:n) = q(2:n) + dt*vel(2:n);

    t1 = istep*dt;
    [us,vs] = gibbs3_surface_motion(t1,param);
    q(1)=us; vel(1)=vs;

    if mod(istep,sub)==0
      registrar(rec,t1);
      rec=rec+1;
    end
  end

  if rec ~= nt+1
    error('GF3 registro %d puntos y esperaba %d.',rec-1,nt);
  end

  res = struct();
  res.version = param.gibbs3_version;
  res.modelo = param.gibbs3_modelo;
  res.integrador = param.gibbs3_integrador;
  res.param = param;
  res.malla = malla;
  res.bomba = bomba;
  res.equilibrio = eq;
  res.t = TT;
  res.U = U;
  res.V = V;
  res.F_superficie_N = Ftop;
  res.F_bomba_N = Fbot;
  res.apertura_valvula = Valve;
  res.F_LPP_N = FLPP;
  res.deltaP_LPP_Pa = DPLPP;
  res.Q_LPP_m3_s = QLPP;
  res.ciclos_simulados = ncy;
  res.ciclos_descartados = param.gibbs3_descartar_ciclos;
  res.diagnostico = struct( ...
    'dt_salida_s',dt_out, ...
    'dt_integracion_s',dt, ...
    'subpasos_por_salida',sub, ...
    'c_onda_referencia_m_s',c_ref, ...
    'gamma_damping_1_s',gamma, ...
    'cfl_configurado',param.gibbs3_cfl, ...
    'carga_estatica_superficie_N',eq.carga_superficie_N);

  function registrar(i,t)
    TT(i)=t;
    U(i,:)=(eq.u_m+q).';
    V(i,:)=vel.';
    Ftop(i)=eq.carga_superficie_N + malla.k_e_N_m(1)*(q(1)-q(2));
    Fbot(i)=Fb;
    Valve(i)=alpha;
    FLPP(i)=lpp_inst.F_firmada_N;
    DPLPP(i)=lpp_inst.deltaP_total_Pa;
    QLPP(i)=lpp_inst.Q_m3_s;
  end
end

function f = fuerzas_axiales(q,vel,malla,Fb,Fref,gamma)
  n = numel(q);
  f = zeros(n,1);
  for e=1:n-1
    fe = malla.k_e_N_m(e)*(q(e+1)-q(e));
    f(e)=f(e)+fe;
    f(e+1)=f(e+1)-fe;
  end
  f(n)=f(n)-(Fb-Fref);
  f(2:n)=f(2:n)-gamma.*malla.masa_nodal_kg(2:n).*vel(2:n);
  f(1)=0;
end

function F = carga_bomba(alpha,bomba)
  F = bomba.F_down_N + alpha*(bomba.F_up_N-bomba.F_down_N);
end

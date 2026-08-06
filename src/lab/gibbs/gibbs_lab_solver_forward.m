function r = gibbs_lab_solver_forward(param)
% gibbs_lab_solver_forward.m - Gibbs Solver Lab v17.
% EXPERIMENTAL. No reemplaza BM operativo.
%
% Resuelve la ecuacion de onda axial amortiguada:
%   u_tt = vs^2 u_xx - c u_t
% con movimiento impuesto en superficie u(0,t) por polished rod.
%
% No agrega ondas esteticas. Las oscilaciones/reflexiones que aparezcan salen
% de la discretizacion, de la condicion inferior y del amortiguamiento.

  param = gibbs_lab_defaults(param);
  g = 9.80665;
  S = max(param.S_carrera, 0.01);
  spm = max(param.N_velocidad, 0.1);
  T = 60/spm;
  L = max(param.D_bomba, 1);
  WC = min(max(param.WC,0),1);
  rho_l = param.rho_o*(1-WC) + param.rho_w*WC;

  d_rod = max(param.diam_varilla_mm,1)/1000;
  A = pi*(d_rod/2)^2;
  E = max(param.E_acero, 1e9);
  rho_rod = max(param.rho_acero, 1000);
  vs = sqrt(E/rho_rod);

  Dp = max(param.D_bomba_mm,1)/1000;
  Ap = pi*(Dp/2)^2;
  Wf = rho_l*g*L*Ap;
  Wb = rho_rod*g*A*L*(1 - 0.12);

  Nx = max(8, round(param.gibbs_lab_nx));
  dx = L/Nx;
  lambda = 0.95;
  dt = lambda*dx/vs;
  ciclos = max(param.gibbs_lab_ciclos, 2.0);
  Nt = max(ceil(ciclos*T/dt)+2, 100);
  t_all = (0:Nt-1)'*dt;
  c = max(param.gibbs_lab_c_damp, 0);

  u = zeros(Nx+1, Nt); % fila 1 superficie, fila Nx+1 fondo
  % Movimiento impuesto en polished rod.
  u(1,:) = 0.5*S*(1 - cos(2*pi*t_all'/T));

  % Condicion inicial: sarta en reposo, consistente con posicion inicial.
  u(:,1) = 0;
  u(:,2) = 0;
  u(1,1:2) = u(1,1:2);

  bc = 'bomba_ideal_llena';
  if isfield(param,'gibbs_lab_bc') && ischar(param.gibbs_lab_bc)
      bc = param.gibbs_lab_bc;
  end

  % Diferencias explicitas. La condicion inferior se aplica como frontera.
  lam2 = (vs*dt/dx)^2;
  for n = 2:Nt-1
      % Interior
      for i = 2:Nx
          damp = c*dt*(u(i,n)-u(i,n-1));
          u(i,n+1) = 2*u(i,n) - u(i,n-1) + lam2*(u(i+1,n)-2*u(i,n)+u(i-1,n)) - damp;
      end

      % Frontera superior impuesta.
      u(1,n+1) = 0.5*S*(1 - cos(2*pi*t_all(n+1)/T));

      % Frontera inferior.
      switch lower(bc)
          case 'fijo'
              u(Nx+1,n+1) = 0;
          case 'libre'
              % du/dx = 0
              u(Nx+1,n+1) = u(Nx,n+1);
          case 'carga_constante'
              % EA du/dx = Wf, signo elegido para traccion positiva.
              u(Nx+1,n+1) = u(Nx,n+1) + dx*Wf/(E*A);
          otherwise
              % Bomba ideal llena: durante ascenso del piston se aplica Wf;
              % durante descenso queda descargada. Estado basado en velocidad
              % calculada del nodo de fondo, no en forma estetica.
              vf = (u(Nx+1,n) - u(Nx+1,n-1))/dt;
              if vf >= 0
                  Fb = Wf;
              else
                  Fb = 0;
              end
              u(Nx+1,n+1) = u(Nx,n+1) + dx*Fb/(E*A);
      end
  end

  % Tomar el ultimo ciclo para graficar/diagnosticar.
  t0 = t_all(end) - T;
  idx = find(t_all >= t0);
  t = t_all(idx) - t_all(idx(1));
  U = u(:,idx);
  n = length(t);

  x_sup = U(1,:)';
  x_fondo = U(end,:)';

  % Cargas por Hooke. Signos ajustados para que la traccion positiva sea legible.
  F_sup_dyn = E*A*(U(2,:) - U(1,:))/dx;
  F_fondo_dyn = E*A*(U(end,:) - U(end-1,:))/dx;
  carga_sup = Wb + F_sup_dyn(:);
  carga_fondo = F_fondo_dyn(:);

  % Estado de bomba diagnostico, no usado para dibujar ondas.
  vf = gradient(x_fondo, mean(diff(t)));
  estado = double(vf >= 0);

  r = struct();
  r.modelo = ['Gibbs_Solver_Lab_v17_forward_' bc];
  r.advertencia = 'LABORATORIO EXPERIMENTAL: solver forward desde polished rod; no BM operativo.';
  r.param = param;
  r.t = t;
  r.T = T;
  r.x_sup = x_sup;
  r.x_fondo = x_fondo;
  r.carga_sup_kN = carga_sup/1000;
  r.carga_fondo_kN = carga_fondo/1000;
  r.estado_bomba = estado(:);
  r.estado_superficie = estado(:);
  r.Wf_kN = Wf/1000;
  r.Wb_kN = Wb/1000;
  r.a_onda = vs;
  r.tau = L/vs;
  r.periodo_onda_ida_vuelta = 2*L/vs;
  r.S_sup = max(x_sup)-min(x_sup);
  r.S_fondo = max(x_fondo)-min(x_fondo);
  r.transmision = r.S_fondo/max(r.S_sup,eps);
  r.llenado = 1.0;
  r.Q_teorico_fondo_m3d = Ap*r.S_fondo*(spm/60)*86400;
  r.Q_efectivo_m3d = r.Q_teorico_fondo_m3d;
  r.U_malla = U;
  r.x_malla = linspace(0,L,Nx+1)';
  r.sin_hardcode_onda = true;
  r.condicion_inferior = bc;
end

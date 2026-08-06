function malla = gibbs18_build_rod_mesh(param)
% Malla 1D de sarta. v18 usa una sarta equivalente uniforme como fundacion.
  L = max(leer_num(param,'D_bomba',1500), 10);
  n = max(8, round(leer_num(param,'gibbs18_n_nodos',41)));
  E = leer_num(param,'gibbs18_E_Pa',207e9);
  rho = leer_num(param,'gibbs18_rho_rod',7850);
  d = leer_num(param,'gibbs18_diam_varilla_mm',22.2) / 1000;
  A = pi * (d/2)^2;
  dx = L/(n-1);
  x = linspace(0, L, n)';
  k = E*A/dx;
  m = rho*A*dx*ones(n,1);
  m(1) = m(1)/2; m(n) = m(n)/2;
  malla.L = L; malla.n = n; malla.x = x; malla.dx = dx;
  malla.E = E; malla.rho = rho; malla.A = A; malla.d_m = d;
  malla.k = k; malla.m = m; malla.c_onda = sqrt(E/rho);
end

function v = leer_num(s,campo,def)
  v = def;
  if isstruct(s) && isfield(s,campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1)), v = tmp(1); end
  end
end

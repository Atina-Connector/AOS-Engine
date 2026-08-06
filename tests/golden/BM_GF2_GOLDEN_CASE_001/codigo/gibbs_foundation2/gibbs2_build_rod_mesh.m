function malla = gibbs2_build_rod_mesh(param)
  L = max(leer_num(param,'D_bomba',1500), 10);
  n = max(8, round(leer_num(param,'gibbs2_n_nodos',41)));
  E = leer_num(param,'gibbs2_E_Pa',207e9);
  rho = leer_num(param,'gibbs2_rho_rod',7850);
  d = leer_num(param,'gibbs2_diam_varilla_mm',22.2) / 1000;
  A = pi * (d/2)^2;
  dx = L/(n-1);
  x = linspace(0, L, n)';
  % Rigidez por elemento: debe ser un vector de (n-1) elementos
  k_e = (E * A / dx) * ones(n-1, 1);
  m = rho * A * dx * ones(n,1);
  m(1) = m(1)/2; m(n) = m(n)/2;
  % Rigidez equivalente de toda la sarta
  k_equiv = 1 / sum(1 ./ k_e);
  malla.L = L; malla.n = n; malla.x = x; malla.dx = dx;
  malla.E = E; malla.rho = rho; malla.A = A; malla.d_m = d;
  malla.k_e = k_e; malla.m = m; malla.c_onda = sqrt(E/rho);
  malla.k_equiv = k_equiv;
end

function v = leer_num(s,c,d)
  v = d;
  if isstruct(s) && isfield(s,c)
    tmp = s.(c);
    if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
      v = tmp(1);
    end
  end
end

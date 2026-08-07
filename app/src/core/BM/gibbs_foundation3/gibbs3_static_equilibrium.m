function eq = gibbs3_static_equilibrium(param, malla, bomba)
% GIBBS3_STATIC_EQUILIBRIUM Equilibrio axial con peso flotado proyectado.

  n = malla.n;
  g = param.gibbs3_gravedad_m_s2;

  % Peso axial por elemento: masa*g*flotacion*componente vertical.
  peso_e = malla.masa_elemento_kg .* g .* ...
           malla.factor_flotacion_e .* malla.factor_vertical_e;

  T_e = zeros(n-1,1);
  carga = bomba.F_ref_N;
  for e = n-1:-1:1
    carga = carga + peso_e(e);
    T_e(e) = carga;
  end

  u_eq = zeros(n,1);
  for e = 1:n-1
    u_eq(e+1) = u_eq(e) - T_e(e)/malla.k_e_N_m(e);
  end

  eq = struct();
  eq.u_m = u_eq;
  eq.tension_elemento_N = T_e;
  eq.peso_axial_elemento_N = peso_e;
  eq.carga_superficie_N = bomba.F_ref_N + sum(peso_e);
end

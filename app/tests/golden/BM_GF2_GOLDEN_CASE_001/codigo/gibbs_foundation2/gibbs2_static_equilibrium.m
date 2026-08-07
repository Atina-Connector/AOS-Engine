function u_eq = gibbs2_static_equilibrium(param, malla)
  % Desplazamiento estático de la sarta bajo peso propio y carga de bomba.
  if ~isstruct(malla) || ~isfield(malla, 'm') || ~isfield(malla, 'k_e')
    error('gibbs2_static_equilibrium: malla inválida');
  end
  n = malla.n;
  g = 9.81;
  F_ref = gibbs2_bottom_static_load(param);
  u_eq = zeros(n, 1);
  u_eq(1) = 0;
  F_below = F_ref;
  for i = n:-1:2
      if i == n
          F_below = F_ref + 0.5 * malla.m(i) * g;
      else
          F_below = F_below + 0.5 * (malla.m(i) + malla.m(i+1)) * g;
      end
      u_eq(i) = u_eq(i-1) + F_below / malla.k_e(i-1);
  end
end

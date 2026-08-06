function P_b_pa = aos_presion_burbuja_pa(valor, default_bar)
% aos_presion_burbuja_pa.m - Normaliza P_b a Pa.
  if nargin < 2 || isempty(default_bar), default_bar = 100; end
  P_b_pa = aos_presion_bar_a_pa(valor, default_bar);
end

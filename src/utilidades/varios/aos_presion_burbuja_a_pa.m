function P_b_pa = aos_presion_burbuja_a_pa(valor, default_bar)
% aos_presion_burbuja_a_pa.m
% Normaliza presion de burbuja para AOS.
% Regla operativa 0.0.11: en menus el usuario ingresa bar; internamente se usa Pa.
% Defensa: si llega un valor numerico menor que 2000 se interpreta como bar.

  if nargin < 2 || isempty(default_bar)
      default_bar = 100;
  end

  if nargin < 1 || isempty(valor) || ~isnumeric(valor) || ~isfinite(valor)
      P_b_pa = default_bar * 1e5;
      return;
  end

  valor = valor(1);
  if valor < 2000
      P_b_pa = valor * 1e5;
  else
      P_b_pa = valor;
  end
end

function carta_filtrada = filtrar_picos_carta(carta_cruda, umbral_factor)
  % filtrar_picos_carta.m - Filtro defensivo para cartas dinamometricas.
  % Elimina picos numericos y rellena por interpolacion local.

  if nargin < 2 || isempty(umbral_factor), umbral_factor = 10; end
  if isempty(carta_cruda) || size(carta_cruda,2) < 2
      carta_filtrada = carta_cruda;
      return;
  end

  pos = carta_cruda(:,1);
  carga = carta_cruda(:,2);
  N = length(carga);
  if N < 3
      carta_filtrada = carta_cruda;
      return;
  end

  derivada = zeros(N,1);
  for i = 2:N-1
      dx = pos(i+1) - pos(i-1);
      if abs(dx) < 1e-12
          derivada(i) = 0;
      else
          derivada(i) = (carga(i+1) - carga(i-1)) / dx;
      end
  end
  derivada(1) = derivada(2);
  derivada(N) = derivada(N-1);

  vals = abs(derivada(isfinite(derivada)));
  if isempty(vals)
      mediana_deriv = 0;
  else
      mediana_deriv = median(vals);
  end
  umbral = umbral_factor * max(mediana_deriv, 1e-6);
  es_pico = abs(derivada) > umbral;
  es_pico = es_pico | isnan(carga) | isinf(carga);

  carga_filtrada = carga;
  buenos = find(~es_pico);
  if length(buenos) >= 2
      malos = find(es_pico);
      carga_filtrada(malos) = interp1(pos(buenos), carga(buenos), pos(malos), 'linear', 'extrap');
  elseif length(buenos) == 1
      carga_filtrada(es_pico) = carga(buenos(1));
  end

  carta_filtrada = [pos, carga_filtrada];
end

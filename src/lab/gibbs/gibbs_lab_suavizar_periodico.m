function y = gibbs_lab_suavizar_periodico(x, ventana)
% Suavizado circular simple, compatible con Octave.
  x = x(:);
  n = length(x);
  ventana = max(1, round(ventana));
  if ventana <= 1 || n < 3
      y = x;
      return;
  end
  if mod(ventana,2) == 0, ventana = ventana + 1; end
  k = ones(ventana,1) / ventana;
  m = floor(ventana/2);
  xp = [x(n-m+1:n); x; x(1:m)];
  yp = conv(xp, k, 'same');
  y = yp(m+1:m+n);
end

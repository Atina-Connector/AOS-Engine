function aos_dibujar_spot(x, y, estado, tam)
  if nargin < 4, tam = 9; end
  try
      plot(x, y, 'o', 'markersize', tam, 'markerfacecolor', aos_color_estado(estado), 'markeredgecolor', [0 0 0]);
  catch
      plot(x, y, 'o');
  end
end

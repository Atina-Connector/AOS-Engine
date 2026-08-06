function plot_mandriles(valv_D, valv_Pgas, valv_Ptub, P_iny_sup, D_packer, grad_abajo, grad_arriba)
  % Grafica curvas de presión de gas y tubing (estilo Kermit Brown)
  % valv_D     : vector de profundidades TVD de mandriles (m)
  % valv_Pgas  : presiones de gas en cada mandril (Pa)
  % valv_Ptub  : presiones de tubing estimadas en cada mandril (Pa)
  % P_iny_sup  : presión de inyección superficial (Pa)
  % D_packer   : profundidad del packer (m)
  % grad_abajo : gradiente de descarga hacia abajo (Pa/m)
  % grad_arriba: gradiente de descarga hacia arriba (Pa/m)

  figure;
  hold on;

  % Curva de presión del gas de inyección (fondo continuo)
  D_plot = linspace(0, max(valv_D)+50, 100);
  P_plot = P_iny_sup * exp(0.016 * 9.81 * D_plot / (0.85 * 8.314 * (300+403)/2));  % perfil barométrico
  plot(P_plot/1e5, D_plot, 'r-', 'LineWidth', 2);

  % Curva de presión en el tubing (zig-zag)
  P_tub_actual = valv_Ptub(end);
  D_actual = valv_D(end);
  % Segmento desde la válvula operativa hasta el packer (hacia abajo)
  P_packer = P_tub_actual + grad_abajo * (D_packer - D_actual);
  plot([P_tub_actual, P_packer]/1e5, [D_actual, D_packer], 'b--', 'LineWidth', 1.5);

  % Segmentos hacia arriba
  for i = length(valv_D):-1:2
      D_inf = valv_D(i);
      D_sup = valv_D(i-1);
      P_inf = valv_Ptub(i);
      P_sup_antes = P_inf + grad_arriba * (D_sup - D_inf);  % D_sup < D_inf
      plot([P_inf, P_sup_antes]/1e5, [D_inf, D_sup], 'b--', 'LineWidth', 1.5);
  end

  % Puntos de mandriles
  plot(valv_Pgas/1e5, valv_D, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
  % Líneas verticales finas
  for i = 1:length(valv_D)
      plot([valv_Ptub(i), valv_Pgas(i)]/1e5, [valv_D(i), valv_D(i)], 'k-', 'LineWidth', 0.5);
  end

  xlabel('Presión (bar)');
  ylabel('Profundidad TVD (m)');
  title('Curvas de gradiente de presión – Diseño de mandriles');
  legend({'P_{gas disponible}', 'P_{tubing}'}, 'Location', 'northeast');
  set(gca, 'YDir', 'reverse');
  grid on;
  hold off;
end

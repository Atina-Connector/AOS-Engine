function gibbs2_plot(res)
  try
    figure('Name','AOS GF2 - Cartas dinámicas');
    subplot(2,2,1);
    plot(res.promedio.u_superficie_m, res.promedio.F_superficie_N/1000, '-');
    xlabel('Posición PR (m)'); ylabel('Carga sup. (kN)');
    title('Carta superficie'); grid on;

    subplot(2,2,2);
    plot(res.promedio.u_bomba_m, res.promedio.F_bomba_N/1000, '-');
    xlabel('Posición bomba (m)'); ylabel('Carga bomba (kN)');
    title('Carta fondo'); grid on;

    subplot(2,2,3);
    plot(res.t, res.U(:,1), '-', res.t, res.U(:,end), '-');
    xlabel('Tiempo (s)'); ylabel('Desplazamiento (m)');
    legend('PR','Bomba'); grid on;

    subplot(2,2,4);
    plot(res.t, res.F_superficie_N/1000, '-');
    xlabel('Tiempo (s)'); ylabel('Carga sup. (kN)'); grid on;
  catch err
    fprintf('Error al graficar: %s\n', err.message);
  end
end

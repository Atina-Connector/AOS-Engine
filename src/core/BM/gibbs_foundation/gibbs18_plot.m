function gibbs18_plot(res)
% Graficos basicos. Protegido para terminales sin GUI.
% Las cartas dinamometricas se muestran como un unico lazo promedio cerrado.
  try
      figure('Name','AOS BM Gibbs Foundation v18.3');
      subplot(2,2,1);
      plot(res.promedio.u_superficie_m, res.promedio.F_superficie_N/1000, '-');
      xlabel('Posicion PR [m]'); ylabel('Carga superficie [kN]');
      title('Carta superficie promedio v18.3'); grid on;

      subplot(2,2,2);
      plot(res.promedio.u_bomba_m, res.promedio.F_bomba_N/1000, '-');
      xlabel('Posicion bomba [m]'); ylabel('Carga bomba [kN]');
      title('Carta fondo promedio v18.3'); grid on;

      subplot(2,2,3);
      plot(res.t, res.U(:,1), '-', res.t, res.U(:,end), '-');
      xlabel('Tiempo [s]'); ylabel('Desplazamiento [m]'); title('PR vs bomba');
      legend('PR','Bomba'); grid on;

      subplot(2,2,4);
      plot(res.t, res.F_superficie_N/1000, '-');
      xlabel('Tiempo [s]'); ylabel('Carga [kN]'); title('Carga superficie corregida'); grid on;
  catch err
      fprintf('Aviso: no se pudieron graficar resultados v18.3: %s\n', err.message);
  end
end

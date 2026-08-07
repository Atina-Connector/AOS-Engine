function [param, carta_sup, carta_fondo, diag] = diagnostico_cartas_bm(param, varillas, mostrar_tabla)
% diagnostico_cartas_bm.m - Genera, grafica y guarda cartas BM/Gibbs.
%
% Devuelve cartas completas y guarda 30 puntos livianos en param para .aosrpt.

  if nargin < 3, mostrar_tabla = true; end

  n_puntos = 500;
  if isfield(param, 'bm_puntos_carta') && param.bm_puntos_carta > 50
      n_puntos = round(param.bm_puntos_carta);
  end

  t = linspace(0, 60 / max(param.N_velocidad, 1e-6), n_puntos);
  cin = cinematica_superficie(param.tipo_unidad, param.S_carrera, param.N_velocidad, t);

  opciones = struct();
  opciones.detalle = true;
  [carta_sup, carta_fondo, t_aux, u_aux, diag] = ecuacion_onda_gibbs(cin, varillas, param, opciones);

  N_total = size(carta_sup, 1);
  n_tabla = min(30, N_total);
  indices = unique(round(linspace(1, N_total, n_tabla)));
  param.cartas_sup = carta_sup(indices, :);
  param.cartas_fondo = carta_fondo(indices, :);
  param.gibbs_diag = diag;

  fprintf('\n--- CARTAS DINAMOMETRICAS BM / GIBBS ---\n');
  fprintf('Modelo carta      : %s\n', diag.modelo);
  fprintf('Rigidez varillas  : %.2e N/m\n', diag.K_rod_Nm);
  fprintf('Rigidez efectiva  : %.2e N/m\n', diag.K_total_Nm);
  fprintf('Velocidad de onda : %.0f m/s\n', diag.a_onda_ms);
  fprintf('Retardo onda      : %.3f s\n', diag.tau_s);

  figure;
  subplot(2,1,1);
  plot(carta_sup(:,1), carta_sup(:,2)/1e3, '-');
  xlabel('Posicion punto pulido (m)'); ylabel('Carga (kN)');
  title('Carta Dinamometrica de Superficie - BM/Gibbs'); grid on;
  subplot(2,1,2);
  plot(carta_fondo(:,1), carta_fondo(:,2)/1e3, '-');
  xlabel('Posicion piston/fondo (m)'); ylabel('Carga (kN)');
  title('Carta Dinamometrica de Fondo - BM/Gibbs'); grid on;
  drawnow;

  if mostrar_tabla
      fprintf('\n--- TABLA LIVIANA DE CARTAS (para reporte, %d puntos) ---\n', length(indices));
      fprintf('Punto | Pos.Sup (m) | Carga Sup (kN) | Pos.Fondo (m) | Carga Fondo (kN)\n');
      fprintf('------|-------------|----------------|---------------|------------------\n');
      for i = 1:length(indices)
          fprintf('  %2d  |  %9.4f  |    %8.1f    |   %9.4f   |     %8.1f\n', i, ...
              param.cartas_sup(i,1), param.cartas_sup(i,2)/1000, ...
              param.cartas_fondo(i,1), param.cartas_fondo(i,2)/1000);
      end
      fprintf('------|-------------|----------------|---------------|------------------\n');
  end
end

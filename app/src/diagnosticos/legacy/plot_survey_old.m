function plot_survey_old(survey)
  % Grafica la trayectoria del pozo (MD‑TVD, inclinación, diámetro, 3D)
  % survey: estructura con MD, TVD, inclinacion (grados), azimut (grados), ID_tubing

  % Calcular coordenadas 3D para la trayectoria
  % Convertir ángulos a radianes
  inc_rad = deg2rad(survey.inclinacion);
  azi_rad = deg2rad(survey.azimut);

  % Inicializar coordenadas en (0,0,0) en superficie
  X = zeros(size(survey.MD));
  Y = zeros(size(survey.MD));
  Z = survey.TVD;   % TVD ya es la profundidad vertical (eje Z hacia abajo)

  % Integrar numéricamente para obtener X e Y (desplazamiento horizontal)
  for i = 2:length(survey.MD)
      dMD = survey.MD(i) - survey.MD(i-1);
      % Componente vertical y horizontal del segmento
      dZ = dMD * cos(inc_rad(i-1));   % contribución a TVD (ya tenemos TVD directo, pero lo recalculamos por consistencia)
      % Para X e Y usamos el ángulo promedio del segmento
      inc_prom = (inc_rad(i-1) + inc_rad(i))/2;
      azi_prom = (azi_rad(i-1) + azi_rad(i))/2;
      dH = dMD * sin(inc_prom);   % desplazamiento horizontal en dirección del azimut
      X(i) = X(i-1) + dH * cos(azi_prom);
      Y(i) = Y(i-1) + dH * sin(azi_prom);
  end

  % Figura con 4 subgráficos
  figure('Position', [50 50 1200 800]);

  % 1. MD vs TVD
  subplot(2,2,1);
  plot(survey.TVD, survey.MD, 'k-', 'LineWidth', 2);
  xlabel('TVD (m)'); ylabel('MD (m)');
  title('Trayectoria MD‑TVD');
  set(gca, 'YDir', 'reverse');
  grid on;

  % 2. Inclinación
  subplot(2,2,2);
  plot(survey.inclinacion, survey.MD, 'b-', 'LineWidth', 2);
  xlabel('Inclinación (°)'); ylabel('MD (m)');
  title('Inclinación');
  set(gca, 'YDir', 'reverse');
  grid on;

  % 3. Diámetro de tubing (si está disponible)
  if isfield(survey, 'ID_tubing')
      subplot(2,2,3);
      plot(survey.ID_tubing*1000, survey.MD, 'r-', 'LineWidth', 2);
      xlabel('Diámetro interno (mm)'); ylabel('MD (m)');
      title('Diámetro de tubing');
      set(gca, 'YDir', 'reverse');
      grid on;
  end

   % 4. Vista 3D de la trayectoria (eje Z hacia abajo, 0 arriba)
  subplot(2,2,4);
  plot3(X, Y, survey.TVD, 'k-', 'LineWidth', 2);   % TVD positivo hacia abajo
  xlabel('X (m)'); ylabel('Y (m)'); zlabel('Profundidad TVD (m)');
  title('Trayectoria 3D');
  grid on; axis equal;
  set(gca, 'ZDir', 'reverse');   % invertir eje Z para que 0 quede arriba
  view(30, 15);   % ángulo de vista: azimut 30°, elevación 15°
end

MD = survey.MD;
TVD = survey.TVD;
    if isfield(survey, 'inclinacion'), inclinacion = survey.inclinacion;
  end

 % Preparar variables para el reporte enriquecido
MD = survey.MD;
TVD = survey.TVD;
if isfield(survey, 'inclinacion')
    inclinacion = survey.inclinacion;
end
drawnow;  % Forzar renderizado de la figura

% Extraer variables del survey para el exportador
MD = survey.MD;
TVD = survey.TVD;
if isfield(survey, 'inclinacion')
    inclinacion = survey.inclinacion;
end

exportar_grafico_modulo();

function plot_survey(survey, punzados, preguntar_exportacion)
% PLOT_SURVEY Grafica trayectoria, geometria e intervalos de punzado.
% Uso:
%   plot_survey(survey)
%   plot_survey(survey, punzados)
%   plot_survey(survey, punzados, preguntar_exportacion)
%
% Si no se pasa punzados, se buscan automaticamente en CONFIG_ACTIVA o en
% la geologia global cargada desde el .aosdat.

  if nargin < 1 || ~isstruct(survey) || ~isfield(survey, 'MD') || isempty(survey.MD)
      error('plot_survey requiere un survey valido.');
  end
  if nargin < 2 || isempty(punzados)
      punzados = buscar_punzados_activos();
  else
      [punzados,~]=aos_punzados_normalizar(punzados);
      if ~isempty(punzados.tramos)
          punzados.tramos=punzados.tramos([punzados.tramos.activo]);
      endif
  end
  if nargin < 3 || isempty(preguntar_exportacion)
      preguntar_exportacion = true;
  end

  survey = completar_campos(survey);
  MD = survey.MD(:); TVD = survey.TVD(:);
  inc_rad = survey.inclinacion(:) * pi / 180;
  azi_rad = survey.azimut(:) * pi / 180;

  X = zeros(size(MD));
  Y = zeros(size(MD));
  for i = 2:length(MD)
      dMD = MD(i) - MD(i-1);
      inc_prom = (inc_rad(i-1) + inc_rad(i)) / 2;
      azi_prom = (azi_rad(i-1) + azi_rad(i)) / 2;
      dH = dMD * sin(inc_prom);
      X(i) = X(i-1) + dH * cos(azi_prom);
      Y(i) = Y(i-1) + dH * sin(azi_prom);
  end

  figure('Position', [30 40 1450 850], 'Name', 'AOS - Survey y punzados');

  % 1. MD vs TVD con punzados resaltados.
  subplot(2,3,1);
  plot(TVD, MD, 'k-', 'LineWidth', 2); hold on;
  dibujar_punzados_md_tvd(MD, TVD, punzados);
  xlabel('TVD [m]'); ylabel('MD [m]');
  title('Trayectoria MD-TVD (punzados en rojo; ver zoom dedicado)');
  set(gca, 'YDir', 'reverse'); grid on;

  % 2. Inclinacion.
  subplot(2,3,2);
  plot(survey.inclinacion, MD, 'b-', 'LineWidth', 2);
  xlabel('Inclinacion [grados]'); ylabel('MD [m]');
  title('Inclinacion');
  set(gca, 'YDir', 'reverse'); grid on;

  % 3. Diametro de tubing.
  subplot(2,3,3);
  plot(survey.ID_tubing * 1000, MD, 'r-', 'LineWidth', 2);
  xlabel('ID tubing [mm]'); ylabel('MD [m]');
  title('Diametro interno de tubing');
  set(gca, 'YDir', 'reverse'); grid on;

  % 4. Trayectoria 3D con punzados.
  subplot(2,3,4);
  plot3(X, Y, TVD, 'k-', 'LineWidth', 2); hold on;
  dibujar_punzados_3d(MD, TVD, X, Y, punzados);
  xlabel('X [m]'); ylabel('Y [m]'); zlabel('TVD [m]');
  title('Trayectoria 3D');
  grid on; axis equal;
  set(gca, 'ZDir', 'reverse');
  view(30, 15);

  % 5. Nuevo track dedicado a intervalos de punzado.
  subplot(2,3,5);
  dibujar_track_punzados(punzados, MD);

  % 6. Azimut y resumen.
  subplot(2,3,6);
  plot(survey.azimut, MD, 'm-', 'LineWidth', 2);
  xlabel('Azimut [grados]'); ylabel('MD [m]');
  title(titulo_resumen_punzados(punzados));
  set(gca, 'YDir', 'reverse'); grid on;

  drawnow;

  % Variables usadas por el exportador de grafico enriquecido.
  if preguntar_exportacion
      inclinacion = survey.inclinacion; %#ok<NASGU>
      try
          exportar_grafico_modulo();
      catch err
          fprintf('Aviso: no se pudo preparar exportacion del grafico survey: %s\n', err.message);
      end
  end
end

function survey = completar_campos(survey)
  n = length(survey.MD);
  survey.MD = survey.MD(:);
  if ~isfield(survey, 'TVD') || isempty(survey.TVD), survey.TVD = survey.MD; end
  if ~isfield(survey, 'inclinacion') || isempty(survey.inclinacion), survey.inclinacion = zeros(n,1); end
  if ~isfield(survey, 'azimut') || isempty(survey.azimut), survey.azimut = zeros(n,1); end
  if ~isfield(survey, 'ID_tubing') || isempty(survey.ID_tubing), survey.ID_tubing = 0.062 * ones(n,1); end
  survey.TVD = survey.TVD(:);
  survey.inclinacion = survey.inclinacion(:);
  survey.azimut = survey.azimut(:);
  survey.ID_tubing = survey.ID_tubing(:);
end

function punzados = buscar_punzados_activos()
  punzados=aos_obtener_punzados_activos(struct(),struct());
end

function tf = es_intervalos(p)
  tf = isstruct(p) && isfield(p, 'tramos') && ~isempty(p.tramos);
end

function dibujar_punzados_md_tvd(MD, TVD, punzados)
  if ~es_intervalos(punzados), return; end
  for i = 1:length(punzados.tramos)
      md = [punzados.tramos(i).MD_desde, punzados.tramos(i).MD_hasta];
      tvd = interp1(MD, TVD, md, 'linear', 'extrap');
      plot(tvd, md, 'r-', 'LineWidth', 5);
  end
end

function dibujar_punzados_3d(MD, TVD, X, Y, punzados)
  if ~es_intervalos(punzados), return; end
  for i = 1:length(punzados.tramos)
      md = linspace(punzados.tramos(i).MD_desde, punzados.tramos(i).MD_hasta, 12);
      xp = interp1(MD, X, md, 'linear', 'extrap');
      yp = interp1(MD, Y, md, 'linear', 'extrap');
      zp = interp1(MD, TVD, md, 'linear', 'extrap');
      plot3(xp, yp, zp, 'r-', 'LineWidth', 5);
  end
end

function dibujar_track_punzados(punzados, MD)
  if ~es_intervalos(punzados)
      axis off;
      text(0.5, 0.55, 'No hay intervalos de punzado cargados', ...
           'HorizontalAlignment', 'center', 'FontWeight', 'bold');
      text(0.5, 0.43, 'Carguelos en [PUNZADOS] del .aosdat', ...
           'HorizontalAlignment', 'center');
      title('Intervalos de punzado');
      return;
  end

  densidades = [punzados.tramos.densidad_tpm];
  xmax = max([densidades, 1]);
  hold on;
  for i = 1:length(punzados.tramos)
      t = punzados.tramos(i);
      d = max(t.densidad_tpm, 0.05 * xmax);
      x = [0 d d 0];
      y = [t.MD_desde t.MD_desde t.MD_hasta t.MD_hasta];
      patch(x, y, [0.85 0.85 0.85], 'EdgeColor', 'r', 'LineWidth', 1.5);
      etiqueta = sprintf(' %.1f-%.1f m | %g tiros/m', t.MD_desde, t.MD_hasta, t.densidad_tpm);
      text(d, (t.MD_desde + t.MD_hasta)/2, etiqueta, 'FontSize', 8, 'VerticalAlignment', 'middle');
  end
  xlabel('Densidad [tiros/m]'); ylabel('MD [m]');
  title('Zoom de intervalos de punzado');
  set(gca, 'YDir', 'reverse');
  xlim([0, xmax * 1.8]);
  md_min = min([punzados.tramos.MD_desde]);
  md_max = max([punzados.tramos.MD_hasta]);
  span = max(md_max-md_min, 1);
  margen = max(5, 0.20*span);
  ylim([md_min-margen, md_max+margen]);
  set(gca, 'YTickMode', 'auto');
  grid on;
end

function txt = titulo_resumen_punzados(punzados)
  if ~es_intervalos(punzados)
      txt = 'Azimut - sin punzados';
      return;
  end
  L = 0; tiros = 0;
  for i = 1:length(punzados.tramos)
      Li = max(punzados.tramos(i).MD_hasta - punzados.tramos(i).MD_desde, 0);
      L = L + Li;
      tiros = tiros + Li * punzados.tramos(i).densidad_tpm;
  end
  txt = sprintf('Azimut | %d tramos, %.1f m, ~%.0f tiros', length(punzados.tramos), L, tiros);
end

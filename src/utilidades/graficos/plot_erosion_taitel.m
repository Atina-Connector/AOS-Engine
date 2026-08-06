function hfig = plot_erosion_taitel(arg1, varargin)
  % plot_erosion_taitel.m
  % Grafico comun y detallado de tuberia para AOS.
  %
  % Uso nuevo recomendado:
  %   diag = diagnostico_tuberia_produccion(...);
  %   plot_erosion_taitel(diag)
  %
  % Uso heredado compatible:
  %   plot_erosion_taitel(survey, V_real, V_eros, V_carga, regimenes, sistema)

  diag = struct();
  perfil = struct();
  sistema = 'AOS';

  if nargin == 1 && isstruct(arg1) && isfield(arg1, 'perfil')
      diag = arg1;
      perfil = diag.perfil;
      if isfield(diag, 'sistema'), sistema = diag.sistema; end
  else
      if nargin < 5
          error('plot_erosion_taitel requiere un diagnostico o la firma heredada completa.');
      end
      survey = arg1;
      V_real = varargin{1};
      V_eros = varargin{2};
      V_carga = varargin{3};
      regimenes = varargin{4};
      if length(varargin) >= 5, sistema = varargin{5}; end
      perfil.MD = survey.MD(:);
      if isfield(survey, 'TVD'), perfil.TVD = survey.TVD(:); else, perfil.TVD = perfil.MD; end
      if isfield(survey, 'inclinacion'), perfil.inclinacion = survey.inclinacion(:); else, perfil.inclinacion = zeros(size(perfil.MD)); end
      if isfield(survey, 'ID_tubing'), perfil.ID = survey.ID_tubing(:); else, perfil.ID = 0.062 * ones(size(perfil.MD)); end
      perfil.Vsg = V_real(:);
      perfil.Vsl = zeros(size(perfil.MD));
      perfil.Vmix = V_real(:);
      perfil.V_eros = V_eros(:);
      perfil.V_carga = V_carga(:);
      perfil.ratio_erosion = perfil.Vmix ./ max(perfil.V_eros, eps);
      perfil.ratio_carga = perfil.Vsg ./ max(perfil.V_carga, eps);
      perfil.regimenes = regimenes(:);
      perfil.Qgas_profile_std = zeros(size(perfil.MD));
      perfil.Qiny_profile_std = zeros(size(perfil.MD));
      perfil.Qgas_form_std = 0;
      perfil.Qiny_std = 0;
      perfil.Qgas_total_std = 0;
      perfil.Ql = 0;
      perfil.D_inyeccion = NaN;
      perfil.alerta.erosion = find(perfil.ratio_erosion > 1);
      perfil.alerta.carga = find(perfil.ratio_carga < 1);
      perfil.alerta.slug = find(strcmp(perfil.regimenes, 'slug'));
      perfil.alerta.transicion = find(strcmp(perfil.regimenes, 'transicion'));
      diag.perfil = perfil;
      diag.sistema = sistema;
  end

  MD = perfil.MD(:);
  n = length(MD);
  if n < 2
      fprintf('No se grafica Taitel: survey con menos de 2 puntos.\n');
      hfig = [];
      return;
  end

  hfig = figure('Name', ['Diagnostico comun tuberia - ' sistema], 'Position', [70, 60, 1350, 780]);

  % 1) Trayectoria
  subplot(2,3,1);
  plot(perfil.TVD, MD, 'b-', 'LineWidth', 1.8); hold on;
  marcar_profundidad(perfil, 'MD');
  xlabel('TVD (m)'); ylabel('MD (m)');
  title('Trayectoria usada'); grid on; set(gca, 'YDir', 'reverse');

  % 2) Velocidades
  subplot(2,3,2);
  plot(perfil.Vsg, MD, 'b-', 'LineWidth', 1.6); hold on;
  plot(perfil.Vsl, MD, 'c-', 'LineWidth', 1.2);
  plot(perfil.Vmix, MD, 'k-', 'LineWidth', 1.6);
  plot(perfil.V_eros, MD, 'r--', 'LineWidth', 1.4);
  plot(perfil.V_carga, MD, 'g--', 'LineWidth', 1.4);
  marcar_profundidad(perfil, 'MD');
  xlabel('Velocidad (m/s)'); ylabel('MD (m)');
  legend('Vsg gas','Vsl liq','Vmix','Limite erosion','Turner carga','Location','best');
  title('Velocidades y limites'); grid on; set(gca, 'YDir', 'reverse');

  % 3) Factores de seguridad / margen
  subplot(2,3,3);
  plot(perfil.ratio_erosion, MD, 'r-', 'LineWidth', 1.6); hold on;
  plot(perfil.ratio_carga, MD, 'g-', 'LineWidth', 1.6);
  xl = xlim();
  plot([1 1], [min(MD) max(MD)], 'k--', 'LineWidth', 1.0);
  xlim([min([xl(1), 0]) max([xl(2), 1.2])]);
  marcar_profundidad(perfil, 'MD');
  xlabel('Relacion adimensional'); ylabel('MD (m)');
  legend('Vmix/Veros','Vsg/Vcarga','Limite 1.0','Location','best');
  title('Margenes operativos'); grid on; set(gca, 'YDir', 'reverse');

  % 4) Taitel / regimen
  subplot(2,3,4);
  graficar_regimenes(perfil);
  title('Regimen de flujo - Taitel simplificado');

  % 5) Gas y tramo con inyeccion
  subplot(2,3,5);
  qg = perfil.Qgas_profile_std * 86400;
  qgi = perfil.Qiny_profile_std * 86400;
  plot(qg, MD, 'b-', 'LineWidth', 1.8); hold on;
  plot(qgi, MD, 'm--', 'LineWidth', 1.4);
  marcar_profundidad(perfil, 'MD');
  xlabel('Gas [Sm3/d]'); ylabel('MD (m)');
  legend('Gas total local std','Gas inyectado','Location','best');
  title('Perfil de gas usado'); grid on; set(gca, 'YDir', 'reverse');

  % 6) Resumen textual
  subplot(2,3,6);
  axis off;
  lineas = resumen_lineas(perfil, sistema);
  paso = min(0.055, 0.94 / max(numel(lineas), 1));
  for i = 1:numel(lineas)
      text(0.02, 0.98 - (i - 1) * paso, lineas{i}, 'Units', 'normalized', ...
           'VerticalAlignment', 'top', 'FontName', 'monospace', 'Interpreter', 'none');
  end
end

function graficar_regimenes(perfil)
  MD = perfil.MD(:);
  n = length(MD);
  for i = 1:n-1
      y1 = MD(i); y2 = MD(i+1);
      if i <= length(perfil.regimenes)
          reg = perfil.regimenes{i};
      else
          reg = 'desconocido';
      end
      color = color_regimen(reg);
      fill([0 1 1 0], [y1 y1 y2 y2], color, 'EdgeColor', 'none'); hold on;
  end
  xlim([0 1]); ylim([min(MD) max(MD)]);
  set(gca, 'XTick', [], 'YDir', 'reverse'); ylabel('MD (m)'); grid on;
  marcar_profundidad(perfil, 'strip');
  h1 = fill(NaN, NaN, 'w', 'FaceColor', color_regimen('burbuja'), 'EdgeColor', 'k');
  h2 = fill(NaN, NaN, 'w', 'FaceColor', color_regimen('slug'), 'EdgeColor', 'k');
  h3 = fill(NaN, NaN, 'w', 'FaceColor', color_regimen('slug_severo'), 'EdgeColor', 'k');
  h4 = fill(NaN, NaN, 'w', 'FaceColor', color_regimen('transicion'), 'EdgeColor', 'k');
  h5 = fill(NaN, NaN, 'w', 'FaceColor', color_regimen('niebla'), 'EdgeColor', 'k');
  legend([h1 h2 h3 h4 h5], {'Burbuja','Slug','Slug severo','Transicion','Niebla'}, 'Location', 'best');
end

function c = color_regimen(reg)
  if strcmp(reg, 'burbuja')
      c = [0.60 1.00 0.60];
  elseif strcmp(reg, 'slug')
      c = [1.00 1.00 0.60];
  elseif strcmp(reg, 'slug_severo')
      c = [1.00 0.60 0.60];
  elseif strcmp(reg, 'transicion')
      c = [1.00 0.80 0.55];
  elseif strcmp(reg, 'niebla')
      c = [0.60 0.70 1.00];
  else
      c = [0.90 0.90 0.90];
  end
end

function marcar_profundidad(perfil, tipo)
  if ~isfield(perfil, 'D_inyeccion') || ~isfinite(perfil.D_inyeccion)
      return;
  end
  D = perfil.D_inyeccion;
  if D < min(perfil.MD) || D > max(perfil.MD)
      return;
  end
  if strcmp(tipo, 'strip')
      plot([0 1], [D D], 'k:', 'LineWidth', 1.2);
      text(0.02, D, ' iny/levant.', 'VerticalAlignment', 'bottom');
  else
      xl = xlim();
      plot(xl, [D D], 'k:', 'LineWidth', 1.2);
      xlim(xl);
  end
end

function lineas = resumen_lineas(perfil, sistema)
  % Cada elemento es una linea independiente: text() con gnuplot no debe
  % recibir un string multilinea (\n dentro de un solo string), porque el
  % backend puede interpretar cada linea como un comando gnuplot separado.
  [uso_erosion, idxe] = max(perfil.ratio_erosion);
  [margen_carga, idxc] = min(perfil.ratio_carga);
  ql_m3d = perfil.Ql * 86400;
  ql_bpd = ql_m3d / 0.1589873;
  qgf = perfil.Qgas_form_std * 86400;
  qgi = perfil.Qiny_std * 86400;
  qgt = perfil.Qgas_total_std * 86400;
  if isfinite(perfil.D_inyeccion)
      dstr = sprintf('%.0f m MD', perfil.D_inyeccion);
  else
      dstr = 'no definida';
  end
  lineas = { ...
      sprintf('Sistema: %s', sistema), ...
      sprintf('Survey: %d puntos', length(perfil.MD)), ...
      sprintf('MD: %.0f - %.0f m', min(perfil.MD), max(perfil.MD)), ...
      sprintf('TVD: %.0f - %.0f m', min(perfil.TVD), max(perfil.TVD)), ...
      sprintf('D iny/levant.: %s', dstr), ...
      '', ...
      sprintf('Ql: %.1f m3/d (%.0f bpd)', ql_m3d, ql_bpd), ...
      sprintf('Gas form.: %.0f Sm3/d', qgf), ...
      sprintf('Gas iny.:  %.0f Sm3/d', qgi), ...
      sprintf('Gas total: %.0f Sm3/d', qgt), ...
      '', ...
      'Uso erosion max:', ...
      sprintf('  %.2f en MD %.0f m', uso_erosion, perfil.MD(idxe)), ...
      'Margen carga min:', ...
      sprintf('  %.2f en MD %.0f m', margen_carga, perfil.MD(idxc)), ...
      '', ...
      'Criterios:', ...
      '  Erosion: API14E simpl.', ...
      '  Carga: Turner simpl.', ...
      '  Regimen: Taitel v06 simpl.'};
end

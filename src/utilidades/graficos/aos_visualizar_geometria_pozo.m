function aos_visualizar_geometria_pozo(modo, survey, punzados, info)
% Visualizacion transversal de survey, punzados y completacion.
  if nargin < 1 || isempty(modo), modo = 'integral'; endif
  if nargin < 2, survey = []; endif
  if nargin < 3, punzados = []; endif
  if nargin < 4 || ~isstruct(info), info = struct(); endif
  [punzados,~]=aos_punzados_normalizar(punzados);

  modo = lower(strtrim(modo));
  switch modo
    case 'integral'
      visualizar_integral_local(survey, punzados, info);
    case 'survey2d'
      visualizar_2d_local(survey, punzados, info);
    case 'survey3d'
      visualizar_3d_local(survey, punzados, info);
    case 'punzados'
      visualizar_punzados_local(survey, punzados, info);
    case 'tabla_survey'
      imprimir_tabla_survey_local(survey);
    case 'tabla_punzados'
      imprimir_tabla_punzados_local(punzados);
    otherwise
      error('Modo de geometria no reconocido: %s', modo);
  endswitch
endfunction

function visualizar_integral_local(survey, punzados, info)
  if isempty(survey)
    fprintf('No hay survey cargado en la configuracion activa.\n');
    if tiene_punzados_local(punzados)
      visualizar_punzados_local(survey, punzados, info);
    endif
    return;
  endif

  imprimir_resumen_completacion_local(survey, punzados, info);
  if exist('plot_survey', 'file') == 2
    plot_survey(survey, punzados, false);
  else
    visualizar_2d_local(survey, punzados, info);
  endif
endfunction

function visualizar_2d_local(survey, punzados, info)
  if isempty(survey)
    fprintf('No hay survey cargado en la configuracion activa.\n');
    return;
  endif

  titulo = titulo_local('AOS - Survey 2D', info);
  figure('Name', titulo, 'NumberTitle', 'off', 'Position', [120 80 980 760]);
  plot(survey.TVD, survey.MD, 'k-', 'LineWidth', 2); hold on;
  if tiene_punzados_local(punzados)
    for i = 1:numel(punzados.tramos)
      t = punzados.tramos(i);
      md = linspace(t.MD_desde, t.MD_hasta, 20);
      tvd = interp1(survey.MD, survey.TVD, md, 'linear', 'extrap');
      if t.activo,estilo='r-';else,estilo='--';endif
      plot(tvd, md, estilo, 'LineWidth', 5);
    endfor
  endif
  marcar_profundidades_local(survey);
  xlabel('TVD [m]');
  ylabel('MD [m]');
  title('Trayectoria MD / TVD y punzados');
  set(gca, 'YDir', 'reverse');
  grid on;
  legend_local(tiene_punzados_local(punzados));
endfunction

function visualizar_3d_local(survey, punzados, info)
  if isempty(survey)
    fprintf('No hay survey cargado en la configuracion activa.\n');
    return;
  endif

  [X, Y] = coordenadas_local(survey);
  titulo = titulo_local('AOS - Trayectoria 3D', info);
  figure('Name', titulo, 'NumberTitle', 'off', 'Position', [120 80 1050 780]);
  plot3(X, Y, survey.TVD, 'k-', 'LineWidth', 2); hold on;
  if tiene_punzados_local(punzados)
    for i = 1:numel(punzados.tramos)
      t = punzados.tramos(i);
      md = linspace(t.MD_desde, t.MD_hasta, 20);
      xp = interp1(survey.MD, X, md, 'linear', 'extrap');
      yp = interp1(survey.MD, Y, md, 'linear', 'extrap');
      zp = interp1(survey.MD, survey.TVD, md, 'linear', 'extrap');
      if t.activo,estilo='r-';else,estilo='--';endif
      plot3(xp, yp, zp, estilo, 'LineWidth', 5);
    endfor
  endif
  xlabel('X [m]'); ylabel('Y [m]'); zlabel('TVD [m]');
  title('Trayectoria tridimensional del pozo');
  set(gca, 'ZDir', 'reverse');
  grid on; axis equal; view(35, 20);
endfunction

function visualizar_punzados_local(survey, punzados, info)
  if ~tiene_punzados_local(punzados)
    fprintf('No hay intervalos de punzado cargados.\n');
    return;
  endif

  tramos = punzados.tramos;
  dens = [tramos.densidad_tpm];
  xmax = max([dens, 1]);
  titulo = titulo_local('AOS - Punzados', info);
  figure('Name', titulo, 'NumberTitle', 'off', 'Position', [150 100 900 720]);
  hold on;
  for i = 1:numel(tramos)
    t = tramos(i);
    d = max(t.densidad_tpm, 0.05 * xmax);
    if t.activo,borde='r';relleno=[0.85 0.85 0.85];estado='ACTIVO';
    else,borde=[0.4 0.4 0.4];relleno=[0.95 0.95 0.95];estado='INACTIVO';endif
    patch([0 d d 0], [t.MD_desde t.MD_desde t.MD_hasta t.MD_hasta], ...
          relleno, 'EdgeColor', borde, 'LineWidth', 1.5);
    texto = sprintf(' %s | %.1f-%.1f m | %.2f tiros/m | %s', ...
                    t.nombre, t.MD_desde, t.MD_hasta, t.densidad_tpm,estado);
    text(d, (t.MD_desde + t.MD_hasta) / 2, texto, ...
         'FontSize', 9, 'VerticalAlignment', 'middle');
  endfor
  xlabel('Densidad [tiros/m]'); ylabel('MD [m]');
  title(sprintf('Intervalos de punzado - %d tramos', numel(tramos)));
  set(gca, 'YDir', 'reverse'); grid on;
  xlim([0, xmax * 2.0]);
  mdmin = min([tramos.MD_desde]); mdmax = max([tramos.MD_hasta]);
  margen = max(5, 0.15 * max(mdmax - mdmin, 1));
  ylim([mdmin - margen, mdmax + margen]);
  if ~isempty(survey)
    fprintf('Rango del survey: MD %.1f a %.1f m.\n', min(survey.MD), max(survey.MD));
  endif
endfunction

function imprimir_tabla_survey_local(survey)
  if isempty(survey)
    fprintf('No hay survey cargado.\n');
    return;
  endif
  fprintf('\n--- TABLA DEL SURVEY ---\n');
  fprintf(' N      MD(m)      TVD(m)    Inc(deg)    Azi(deg)   IDtbg(mm)   IDcsg(mm)\n');
  for i = 1:numel(survey.MD)
    fprintf('%3d %10.2f %11.2f %11.3f %11.3f %11.3f %11.3f\n', ...
            i, survey.MD(i), survey.TVD(i), survey.inclinacion(i), ...
            survey.azimut(i), 1000 * survey.ID_tubing(i), ...
            1000 * survey.ID_casing(i));
  endfor
endfunction

function imprimir_tabla_punzados_local(punzados)
  [punzados,~]=aos_punzados_normalizar(punzados);
  if isempty(punzados.tramos)
    fprintf('No hay intervalos de punzado cargados.\n');
    return;
  endif
  fprintf('\n--- TABLA COMPLETA DE PUNZADOS ---\n');
  fprintf(' N  ID             MD desde   MD hasta  Long.  tiros/m diam(mm) Act  Tiros  Formacion / zona\n');
  for i=1:numel(punzados.tramos)
    t=punzados.tramos(i);L=t.MD_hasta-t.MD_desde;nt=L*t.densidad_tpm;
    zona=t.formacion;if isempty(zona),zona=t.nombre;endif
    fprintf('%2d  %-13s %9.2f %10.2f %6.2f %7.2f %8.2f %3s %6.0f  %s\n', ...
      i,cortar_local(t.id,13),t.MD_desde,t.MD_hasta,L,t.densidad_tpm, ...
      1000*t.diametro_punzado_m,si_no_local(t.activo),nt,zona);
  endfor
endfunction

function imprimir_resumen_completacion_local(survey, punzados, info)
  global CONFIG_ACTIVA;
  fprintf('\n--- ESTADO MECANICO INTEGRAL ---\n');
  if isfield(info, 'pozo') && ~isempty(info.pozo)
    fprintf('Pozo                     : %s\n', info.pozo);
  endif
  fprintf('Survey                   : %d puntos\n', numel(survey.MD));
  fprintf('Profundidad final        : %.1f m MD / %.1f m TVD\n', ...
          max(survey.MD), survey.TVD(end));
  if tiene_punzados_local(punzados)
    fprintf('Punzados                 : %d intervalos (%d activos) | %.1f a %.1f m MD\n', ...
            numel(punzados.tramos),sum([punzados.tramos.activo]), ...
            min([punzados.tramos.MD_desde]),max([punzados.tramos.MD_hasta]));
  else
    fprintf('Punzados                 : no cargados\n');
  endif
  if isstruct(CONFIG_ACTIVA)
    imprimir_profundidad_local(CONFIG_ACTIVA, {'D_packer','prof_packer_m'}, 'Packer');
    imprimir_profundidad_local(CONFIG_ACTIVA, {'D_iny','D_iny_m','D_levantamiento'}, 'SLA / inyeccion');
    imprimir_profundidad_local(CONFIG_ACTIVA, {'D_bomba','D_bomba_m'}, 'Bomba');
    imprimir_profundidad_local(CONFIG_ACTIVA, {'D_res','D_res_m','prof_reservorio_m'}, 'Reservorio');
  endif
endfunction

function imprimir_profundidad_local(cfg, campos, etiqueta)
  v = NaN;
  for i = 1:numel(campos)
    if isfield(cfg, campos{i}) && isnumeric(cfg.(campos{i})) && ...
       isscalar(cfg.(campos{i})) && isfinite(cfg.(campos{i}))
      v = cfg.(campos{i});
      break;
    endif
  endfor
  if ~isfinite(v) && isfield(cfg, 'estado_mecanico') && isstruct(cfg.estado_mecanico)
    for i = 1:numel(campos)
      if isfield(cfg.estado_mecanico, campos{i}) && isnumeric(cfg.estado_mecanico.(campos{i})) && ...
         isscalar(cfg.estado_mecanico.(campos{i})) && isfinite(cfg.estado_mecanico.(campos{i}))
        v = cfg.estado_mecanico.(campos{i});
        break;
      endif
    endfor
  endif
  if isfinite(v)
    fprintf('%-25s: %.1f m MD\n', etiqueta, v);
  endif
endfunction

function marcar_profundidades_local(survey)
  global CONFIG_ACTIVA;
  if ~isstruct(CONFIG_ACTIVA), return; endif
  items = {
    'Packer', {'D_packer','prof_packer_m'};
    'SLA', {'D_iny','D_iny_m','D_levantamiento'};
    'Bomba', {'D_bomba','D_bomba_m'};
    'Reservorio', {'D_res','D_res_m'}
  };
  xl = xlim();
  for i = 1:size(items, 1)
    v = primer_numero_local(CONFIG_ACTIVA, items{i, 2});
    if isfinite(v) && v >= min(survey.MD) && v <= max(survey.MD)
      tvd = interp1(survey.MD, survey.TVD, v, 'linear', 'extrap');
      plot(tvd, v, 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 6);
      text(tvd + 0.015 * max(diff(xl), 1), v, items{i, 1}, 'FontSize', 8);
    endif
  endfor
endfunction

function v = primer_numero_local(s, campos)
  v = NaN;
  for i = 1:numel(campos)
    if isfield(s, campos{i}) && isnumeric(s.(campos{i})) && ...
       isscalar(s.(campos{i})) && isfinite(s.(campos{i}))
      v = double(s.(campos{i}));
      return;
    endif
  endfor
  if isfield(s, 'estado_mecanico') && isstruct(s.estado_mecanico)
    for i = 1:numel(campos)
      if isfield(s.estado_mecanico, campos{i}) && isnumeric(s.estado_mecanico.(campos{i})) && ...
         isscalar(s.estado_mecanico.(campos{i})) && isfinite(s.estado_mecanico.(campos{i}))
        v = double(s.estado_mecanico.(campos{i}));
        return;
      endif
    endfor
  endif
endfunction

function [X, Y] = coordenadas_local(survey)
  n = numel(survey.MD);
  X = zeros(n, 1); Y = zeros(n, 1);
  inc = survey.inclinacion(:) * pi / 180;
  azi = survey.azimut(:) * pi / 180;
  for i = 2:n
    dmd = survey.MD(i) - survey.MD(i-1);
    incp = 0.5 * (inc(i-1) + inc(i));
    azip = 0.5 * (azi(i-1) + azi(i));
    dh = dmd * sin(incp);
    X(i) = X(i-1) + dh * cos(azip);
    Y(i) = Y(i-1) + dh * sin(azip);
  endfor
endfunction

function legend_local(con_punzados)
  if con_punzados
    try
      legend('Survey', 'Punzados', 'Location', 'best');
    catch
    end_try_catch
  endif
endfunction

function t = titulo_local(base, info)
  t = base;
  if isfield(info, 'pozo') && ~isempty(info.pozo)
    t = [base ' - ' info.pozo];
  endif
endfunction

function tf = tiene_punzados_local(p)
  tf = isstruct(p) && isfield(p, 'tramos') && ~isempty(p.tramos);
endfunction

function s = si_no_local(x)
  if x, s = 'SI'; else, s = 'NO'; endif
endfunction

function out = cortar_local(txt,n)
  [out,ok]=aos_texto_seguro(txt,'');if ~ok,out='';endif
  if length(out)>n,out=out(1:n);endif
endfunction

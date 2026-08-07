function [ruta, estado] = aos_generar_imagen_punzados(param, tipo, carpeta)
% Genera una imagen geometrica independiente de punzados.
% Compatible con GNU Octave.

  if nargin < 2 || isempty(tipo)
    tipo = 'AOS';
  endif
  if nargin < 3 || isempty(carpeta)
    carpeta = tempdir();
  endif

  ruta = '';
  estado = 'NO_DISPONIBLE';
  intervalos = punzados_local(param);
  if isempty(intervalos)
    return;
  endif

  survey = survey_local(param);
  ruta = [tempname(carpeta) '.png'];
  fig = [];
  try
    fig = figure('Visible', 'off', 'Position', [100 100 980 720]);
    n = size(intervalos, 1);
    md_medio = mean(intervalos, 2);
    longitud = intervalos(:,2) - intervalos(:,1);

    subplot(1,2,1);
    hold on;
    for k = 1:n
      patch([0 1 1 0], ...
            [intervalos(k,1) intervalos(k,1) intervalos(k,2) intervalos(k,2)], ...
            [0.82 0.82 0.82], 'EdgeColor', 'k');
      text(1.04, md_medio(k), sprintf('Tramo %d', k), 'Interpreter', 'none');
    endfor
    set(gca, 'YDir', 'reverse', 'XTick', []);
    grid on;
    ylabel('MD (m)');
    title(sprintf('Punzados - %d tramos', n));
    if ~isempty(survey)
      ylim([min([survey.MD(:); intervalos(:,1)]) max([survey.MD(:); intervalos(:,2)])]);
    endif

    subplot(1,2,2);
    barh(md_medio, longitud, 0.55);
    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('Longitud del intervalo (m)');
    ylabel('MD medio (m)');
    title(['Longitud punzada - ' upper(tipo)]);

    print(fig, '-dpng', '-r150', ruta);
    close(fig);
    fig = [];
    estado = 'OK';
  catch err
    if ~isempty(fig)
      try
        if ishandle(fig)
          close(fig);
        endif
      catch
      end_try_catch
    endif
    if exist(ruta, 'file') == 2
      delete(ruta);
    endif
    ruta = '';
    estado = ['ERROR_' limpiar_estado_local(err.message)];
  end_try_catch
endfunction

function survey = survey_local(param)
  survey = [];
  global CONFIG_ACTIVA;
  fuentes = {param, CONFIG_ACTIVA};
  for i = 1:numel(fuentes)
    a = fuentes{i};
    if ~isstruct(a)
      continue;
    endif
    if isfield(a, 'survey') && isstruct(a.survey)
      a = a.survey;
    endif
    if isfield(a, 'MD') && isfield(a, 'TVD') && ...
       isnumeric(a.MD) && isnumeric(a.TVD)
      n = min(numel(a.MD), numel(a.TVD));
      if n >= 2
        survey = a;
        survey.MD = a.MD(1:n)(:);
        survey.TVD = a.TVD(1:n)(:);
        return;
      endif
    endif
  endfor
endfunction

function intervalos = punzados_local(param)
  intervalos = [];
  global CONFIG_ACTIVA geologia;

  if exist('aos_obtener_punzados_activos', 'file') == 2
    try
      x = aos_obtener_punzados_activos(geologia, param);
      intervalos = normalizar_local(x);
      if ~isempty(intervalos)
        return;
      endif
    catch
    end_try_catch
  endif

  fuentes = {param, CONFIG_ACTIVA, geologia};
  nombres = {'punzados','perforaciones','intervalos_punzados','intervalos'};
  for i = 1:numel(fuentes)
    a = fuentes{i};
    if ~isstruct(a)
      continue;
    endif
    for j = 1:numel(nombres)
      if isfield(a, nombres{j})
        intervalos = normalizar_local(a.(nombres{j}));
        if ~isempty(intervalos)
          return;
        endif
      endif
    endfor
  endfor
endfunction

function a = normalizar_local(x)
  a = [];
  if isempty(x)
    return;
  endif
  if isnumeric(x) && size(x,2) >= 2
    a = double(x(:,1:2));
    a = a(all(isfinite(a),2),:);
    return;
  endif
  if isstruct(x)
    for k = 1:numel(x)
      md1 = pick_local(x(k), {'MD_desde_m','MD_desde','md_desde','top','tope','MD_top','desde'});
      md2 = pick_local(x(k), {'MD_hasta_m','MD_hasta','md_hasta','base','fondo','MD_base','hasta'});
      if isfinite(md1) && isfinite(md2)
        a(end+1,:) = [min(md1,md2) max(md1,md2)];
      endif
    endfor
  endif
endfunction

function v = pick_local(s, campos)
  v = NaN;
  for k = 1:numel(campos)
    if isfield(s, campos{k}) && isnumeric(s.(campos{k})) && ...
       isscalar(s.(campos{k})) && isfinite(s.(campos{k}))
      v = s.(campos{k});
      return;
    endif
  endfor
endfunction

function s = limpiar_estado_local(txt)
  if ~ischar(txt)
    txt = 'DESCONOCIDO';
  endif
  s = regexprep(txt, '[^A-Za-z0-9]+', '_');
  if isempty(s)
    s = 'DESCONOCIDO';
  endif
endfunction

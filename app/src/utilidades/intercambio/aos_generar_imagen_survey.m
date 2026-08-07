function [ruta, estado] = aos_generar_imagen_survey(param, tipo, carpeta)
% Genera el Survey 2D actual (MD-TVD, inclinacion y azimut).
% No incluye la vista 3D; esa sale en aos_generar_imagen_survey_3d_punzados.

  if nargin < 2 || isempty(tipo)
    tipo = 'AOS';
  endif
  if nargin < 3 || isempty(carpeta)
    carpeta = tempdir();
  endif

  ruta = '';
  estado = 'NO_DISPONIBLE';
  survey = survey_local(param);
  if isempty(survey)
    return;
  endif

  md = survey.MD(:);
  tvd = survey.TVD(:);
  n = min(numel(md), numel(tvd));
  if n < 2
    estado = 'SURVEY_INSUFICIENTE';
    return;
  endif
  md = md(1:n);
  tvd = tvd(1:n);
  inc = vector_local(survey, {'inclinacion','INC','inc'}, n, 0);
  azi = vector_local(survey, {'azimut','AZI','azi'}, n, 0);
  equipo_md = equipo_md_local(param, tipo);

  ruta = [tempname(carpeta) '.png'];
  fig = [];
  try
    fig = figure('Visible', 'off', 'Position', [100 100 1180 720]);

    subplot(1,3,1);
    plot(tvd, md, 'k-', 'LineWidth', 2.0);
    hold on;
    if isfinite(equipo_md)
      equipo_tvd = interp1(md, tvd, equipo_md, 'linear', 'extrap');
      plot(equipo_tvd, equipo_md, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
      text(equipo_tvd, equipo_md, ['  ' upper(tipo)], 'Interpreter', 'none');
    endif
    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('TVD (m)');
    ylabel('MD (m)');
    title('Survey 2D - Trayectoria MD-TVD');

    subplot(1,3,2);
    plot(inc, md, 'b-', 'LineWidth', 2.0);
    hold on;
    if isfinite(equipo_md)
      inc_eq = interp1(md, inc, equipo_md, 'linear', 'extrap');
      plot(inc_eq, equipo_md, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
    endif
    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('Inclinacion (deg)');
    ylabel('MD (m)');
    title('Inclinacion');

    subplot(1,3,3);
    plot(azi, md, 'r-', 'LineWidth', 2.0);
    hold on;
    if isfinite(equipo_md)
      azi_eq = interp1(md, azi, equipo_md, 'linear', 'extrap');
      plot(azi_eq, equipo_md, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
    endif
    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('Azimut (deg)');
    ylabel('MD (m)');
    title('Azimut');

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
    candidato = fuentes{i};
    if ~isstruct(candidato)
      continue;
    endif
    if isfield(candidato, 'survey') && isstruct(candidato.survey)
      candidato = candidato.survey;
    endif
    if isfield(candidato, 'MD') && isfield(candidato, 'TVD') && ...
       isnumeric(candidato.MD) && isnumeric(candidato.TVD)
      n = min(numel(candidato.MD), numel(candidato.TVD));
      if n >= 2
        survey = candidato;
        survey.MD = candidato.MD(1:n)(:);
        survey.TVD = candidato.TVD(1:n)(:);
        [survey.MD, orden] = sort(survey.MD);
        survey.TVD = survey.TVD(orden);
        survey = ordenar_campo_local(survey, 'inclinacion', n, orden);
        survey = ordenar_campo_local(survey, 'INC', n, orden);
        survey = ordenar_campo_local(survey, 'inc', n, orden);
        survey = ordenar_campo_local(survey, 'azimut', n, orden);
        survey = ordenar_campo_local(survey, 'AZI', n, orden);
        survey = ordenar_campo_local(survey, 'azi', n, orden);
        return;
      endif
    endif
  endfor
endfunction

function s = ordenar_campo_local(s, nombre, n, orden)
  if isfield(s, nombre) && isnumeric(s.(nombre))
    v = s.(nombre)(:);
    if numel(v) >= n
      s.(nombre) = v(1:n)(orden);
    endif
  endif
endfunction

function v = vector_local(s, nombres, n, defecto)
  v = defecto * ones(n, 1);
  for k = 1:numel(nombres)
    nombre = nombres{k};
    if isfield(s, nombre) && isnumeric(s.(nombre)) && ~isempty(s.(nombre))
      x = s.(nombre)(:);
      m = min(n, numel(x));
      v(1:m) = x(1:m);
      return;
    endif
  endfor
endfunction

function md = equipo_md_local(param, tipo)
  md = NaN;
  global CONFIG_ACTIVA;
  fuentes = {param, CONFIG_ACTIVA};
  tipo_u = upper(tipo);
  if ~isempty(strfind(tipo_u, 'BES')) || ~isempty(strfind(tipo_u, 'BM'))
    campos = {'D_bomba','prof_bomba','profundidad_bomba'};
  else
    campos = {'D_iny','D_valv','prof_iny','profundidad_inyeccion'};
  endif
  for i = 1:numel(fuentes)
    a = fuentes{i};
    if ~isstruct(a)
      continue;
    endif
    for k = 1:numel(campos)
      if isfield(a, campos{k}) && isnumeric(a.(campos{k})) && ...
         isscalar(a.(campos{k})) && isfinite(a.(campos{k}))
        md = a.(campos{k});
        return;
      endif
    endfor
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

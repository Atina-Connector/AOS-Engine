function [info, h] = aos_cad_visor_3d(escena, opciones)
% AOS_CAD_VISOR_3D Render 3D de una escena (dato puro). Sin geometria propia.
% No calcula unidades ni fisica. Solo dibuja.
%
% [info, h] = aos_cad_visor_3d(escena, opciones)
%   opciones.visible  default false (headless)
%   opciones.png      ruta opcional para export PNG
%   opciones.cerrar   default true si visible=false o si se exporta png
%
% Patron headless: figure('Visible','off') + print -dpng + close.
  if nargin < 1, escena = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif

  info = struct();
  info.n_objetos_dibujados = 0;
  info.png = '';
  info.visible = false;
  info.figura_abierta = false;
  info.vacia = true;
  h = [];

  visible = false;
  png = '';
  if isfield(opciones, 'visible'), visible = logical(opciones.visible); endif
  if isfield(opciones, 'png') && ~isempty(opciones.png)
    png = char(opciones.png);
  endif
  cerrar = ~visible || ~isempty(png);
  if isfield(opciones, 'cerrar'), cerrar = logical(opciones.cerrar); endif

  info.visible = visible;

  n_obj = 0;
  objetos = {};
  if isstruct(escena) && isfield(escena, 'objetos') && iscell(escena.objetos)
    objetos = escena.objetos;
    n_obj = numel(objetos);
  endif

  if n_obj < 1
    info.vacia = true;
    fprintf('AOS CAD visor 3D: escena vacia (sin figura).\n');
    return;
  endif
  info.vacia = false;

  vis_flag = 'off';
  if visible, vis_flag = 'on'; endif

  toolkit_prev = '';
  toolkit_cambiado = false;
  toolkit_fig = '';
  try
    % FLTK no puede print() headless sin DISPLAY; gnuplot si.
    if ~visible
      toolkit_prev = graphics_toolkit();
      disponibles = available_graphics_toolkits();
      if any(strcmp(disponibles, 'gnuplot'))
        toolkit_fig = 'gnuplot';
        if ~strcmp(toolkit_prev, 'gnuplot')
          graphics_toolkit('gnuplot');
          toolkit_cambiado = true;
        endif
      endif
    endif

    if ~isempty(toolkit_fig)
      h = figure('Visible', vis_flag, 'Name', 'AOS CAD Visor 3D', ...
        'NumberTitle', 'off', 'Position', [80 60 960 720], ...
        '__graphics_toolkit__', toolkit_fig);
    else
      h = figure('Visible', vis_flag, 'Name', 'AOS CAD Visor 3D', ...
        'NumberTitle', 'off', 'Position', [80 60 960 720]);
    endif
    info.figura_abierta = true;
    hold on;
    grid on;
    axis equal;
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title('AOS CAD — visor 3D (escena)');
    view(35, 25);

    tipos_leyenda = {};
    handles_leyenda = [];
    n_dib = 0;

    for i = 1:n_obj
      o = objetos{i};
      if ~isstruct(o), continue; endif
      if isfield(o, 'visible') && ~o.visible, continue; endif
      tipo = 'OBJ';
      if isfield(o, 'tipo'), tipo = char(o.tipo); endif
      [hh, ok] = dibujar_objeto_local(o, tipo);
      if ~ok, continue; endif
      n_dib = n_dib + 1;
      if ~isempty(hh) && ~any(strcmp(tipos_leyenda, tipo))
        tipos_leyenda{end+1} = tipo; %#ok<AGROW>
        handles_leyenda(end+1) = hh; %#ok<AGROW>
      endif
      etiqueta_local(o);
    endfor

    info.n_objetos_dibujados = n_dib;
    if ~isempty(handles_leyenda)
      try
        legend(handles_leyenda, tipos_leyenda, 'Location', 'northeast', ...
          'Interpreter', 'none');
      catch
      end_try_catch
    endif

    if ~isempty(png)
      try
        print(h, '-dpng', '-r120', png);
        if exist(png, 'file') == 2
          info.png = png;
        endif
      catch
        info.png = '';
      end_try_catch
    endif

    if cerrar
      try
        if ishandle(h), close(h); endif
      catch
      end_try_catch
      h = [];
      info.figura_abierta = false;
    endif
  catch err
    if ~isempty(h)
      try
        if ishandle(h), close(h); endif
      catch
      end_try_catch
    endif
    h = [];
    info.figura_abierta = false;
    fprintf('AOS CAD visor 3D: error de render (%s).\n', err.message);
  end_try_catch

  if toolkit_cambiado
    try
      graphics_toolkit(toolkit_prev);
    catch
    end_try_catch
  endif
endfunction

function [hh, ok] = dibujar_objeto_local(o, tipo)
  hh = [];
  ok = false;
  [col_ov, tiene_ov] = color_rgb_local(o);
  switch upper(tipo)
    case 'POZO'
      pts = pts_local(o);
      if size(pts, 1) < 2, return; endif
      if tiene_ov
        hh = plot3(pts(:, 1), pts(:, 2), pts(:, 3), '-', ...
          'Color', col_ov, 'LineWidth', 2.0);
      else
        hh = plot3(pts(:, 1), pts(:, 2), pts(:, 3), 'k-', 'LineWidth', 2.0);
      endif
      ok = true;
    case 'TRAMO'
      pts = pts_local(o);
      if size(pts, 1) < 2, return; endif
      col = [0.15 0.45 0.85];
      if tiene_ov, col = col_ov; endif
      hh = plot3(pts(:, 1), pts(:, 2), pts(:, 3), '-', ...
        'Color', col, 'LineWidth', 1.6);
      ok = true;
    case 'NODO'
      pts = pts_local(o);
      if size(pts, 1) < 1, return; endif
      col_e = [0.85 0.55 0.1];
      col_f = [0.9 0.7 0.2];
      if tiene_ov
        col_e = col_ov;
        col_f = col_ov;
      endif
      hh = plot3(pts(1, 1), pts(1, 2), pts(1, 3), 'o', ...
        'Color', col_e, 'MarkerFaceColor', col_f, ...
        'MarkerSize', 7);
      ok = true;
    case 'EQUIPO_3D'
      hh = dibujar_caja_local(o);
      ok = ~isempty(hh);
    otherwise
      pts = pts_local(o);
      if size(pts, 1) >= 2
        if tiene_ov
          hh = plot3(pts(:, 1), pts(:, 2), pts(:, 3), '-', 'Color', col_ov);
        else
          hh = plot3(pts(:, 1), pts(:, 2), pts(:, 3), 'b-');
        endif
        ok = true;
      elseif size(pts, 1) == 1
        if tiene_ov
          hh = plot3(pts(1, 1), pts(1, 2), pts(1, 3), '.', 'Color', col_ov);
        else
          hh = plot3(pts(1, 1), pts(1, 2), pts(1, 3), 'b.');
        endif
        ok = true;
      endif
  endswitch
endfunction

function hh = dibujar_caja_local(o)
  hh = [];
  [col_ov, tiene_ov] = color_rgb_local(o);
  bb = [];
  if isfield(o, 'bbox') && isstruct(o.bbox), bb = o.bbox; endif
  req = {'xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'};
  okb = ~isempty(bb);
  if okb
    for i = 1:numel(req)
      if ~isfield(bb, req{i}) || ~isfinite(bb.(req{i})), okb = false; break; endif
    endfor
  endif
  if ~okb
    pts = pts_local(o);
    if size(pts, 1) >= 1
      col_e = [0.55 0.2 0.7];
      col_f = [0.7 0.45 0.85];
      if tiene_ov
        col_e = col_ov;
        col_f = col_ov;
      endif
      hh = plot3(pts(1, 1), pts(1, 2), pts(1, 3), 's', ...
        'Color', col_e, 'MarkerFaceColor', col_f, ...
        'MarkerSize', 8);
    endif
    return;
  endif
  x = [bb.xmin, bb.xmax];
  y = [bb.ymin, bb.ymax];
  z = [bb.zmin, bb.zmax];
  % 12 aristas de la caja AABB
  edges = [
    x(1) y(1) z(1); x(2) y(1) z(1); NaN NaN NaN;
    x(2) y(1) z(1); x(2) y(2) z(1); NaN NaN NaN;
    x(2) y(2) z(1); x(1) y(2) z(1); NaN NaN NaN;
    x(1) y(2) z(1); x(1) y(1) z(1); NaN NaN NaN;
    x(1) y(1) z(2); x(2) y(1) z(2); NaN NaN NaN;
    x(2) y(1) z(2); x(2) y(2) z(2); NaN NaN NaN;
    x(2) y(2) z(2); x(1) y(2) z(2); NaN NaN NaN;
    x(1) y(2) z(2); x(1) y(1) z(2); NaN NaN NaN;
    x(1) y(1) z(1); x(1) y(1) z(2); NaN NaN NaN;
    x(2) y(1) z(1); x(2) y(1) z(2); NaN NaN NaN;
    x(2) y(2) z(1); x(2) y(2) z(2); NaN NaN NaN;
    x(1) y(2) z(1); x(1) y(2) z(2); NaN NaN NaN;
  ];
  col = [0.55 0.2 0.7];
  if tiene_ov, col = col_ov; endif
  hh = plot3(edges(:, 1), edges(:, 2), edges(:, 3), '-', ...
    'Color', col, 'LineWidth', 1.2);
endfunction

function [col, ok] = color_rgb_local(o)
  col = [];
  ok = false;
  if ~isstruct(o) || ~isfield(o, 'color_rgb'), return; endif
  c = o.color_rgb;
  if ~isnumeric(c) || numel(c) < 3, return; endif
  col = double(c(1:3)(:)');
  if all(isfinite(col)), ok = true; endif
endfunction

function pts = pts_local(o)
  pts = zeros(0, 3);
  if ~isfield(o, 'puntos') || isempty(o.puntos), return; endif
  p = double(o.puntos);
  if size(p, 2) == 2
    p = [p, zeros(size(p, 1), 1)];
  endif
  if size(p, 2) >= 3
    pts = p(:, 1:3);
  endif
endfunction

function etiqueta_local(o)
  txt = '';
  if isfield(o, 'asset_id') && ~isempty(o.asset_id)
    txt = char(o.asset_id);
  elseif isfield(o, 'id') && ~isempty(o.id)
    txt = char(o.id);
  endif
  if isempty(txt), return; endif
  xyz = [NaN, NaN, NaN];
  if isfield(o, 'ancla') && isnumeric(o.ancla) && numel(o.ancla) >= 3 && ...
      all(isfinite(o.ancla(1:3)))
    xyz = double(o.ancla(1:3)(:)');
  else
    pts = pts_local(o);
    if size(pts, 1) >= 1
      xyz = mean(pts, 1);
    endif
  endif
  if any(~isfinite(xyz)), return; endif
  text(xyz(1), xyz(2), xyz(3), ['  ' txt], 'FontSize', 7, 'Interpreter', 'none');
endfunction

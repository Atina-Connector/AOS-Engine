function [info, h] = aos_cad_visor_2d(usar_resultados, arg2, opciones)
% AOS_CAD_VISOR_2D Visor 2D Octave desde tablas/resultados (representacion secundaria).
% Colorea tramos por |caudal| o dp si hay resultados; si no, por capa/orden.
%
% Uso interactivo (sin cambios):
%   aos_cad_visor_2d(usar_resultados, silencioso)
% Export headless:
%   [info, h] = aos_cad_visor_2d(usar_resultados, opciones)
%   opciones.visible  default true (interactivo)
%   opciones.png      ruta opcional para export PNG
%   opciones.cerrar   default true si visible=false o si se exporta png
%   opciones.silencioso default false
%
% Patron headless: figure('Visible','off') + print -dpng + close.
  global CONFIG_ACTIVA;
  if nargin < 1 || isempty(usar_resultados), usar_resultados = true; endif

  silencioso = false;
  visible = true;
  png = '';
  cerrar = false;
  if nargin < 2, arg2 = []; endif
  if nargin < 3 || isempty(opciones), opciones = struct(); endif
  if isstruct(arg2)
    opciones = arg2;
  elseif ~isempty(arg2)
    silencioso = logical(arg2);
  endif
  if ~isstruct(opciones), opciones = struct(); endif

  if isfield(opciones, 'silencioso'), silencioso = logical(opciones.silencioso); endif
  if isfield(opciones, 'visible'), visible = logical(opciones.visible); endif
  if isfield(opciones, 'png') && ~isempty(opciones.png)
    png = char(opciones.png);
  endif
  if isfield(opciones, 'usar_resultados')
    usar_resultados = logical(opciones.usar_resultados);
  endif
  cerrar = ~visible || ~isempty(png);
  if isfield(opciones, 'cerrar'), cerrar = logical(opciones.cerrar); endif

  info = struct();
  info.png = '';
  info.visible = visible;
  info.figura_abierta = false;
  info.n_nodos = 0;
  info.n_tramos = 0;
  h = [];

  if isempty(CONFIG_ACTIVA) || ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOS CAD_TOPO: no hay modelo_aoscad para visualizar.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  nodos = modelo.tablas_entrada.nodos;
  tramos = modelo.tablas_entrada.tramos;
  res_t = {};
  dominio_tramos = {};
  [dominio_activo, ~] = aos_cad_hidraulica_dominio_activo(modelo);
  if ~isempty(dominio_activo) && isfield(dominio_activo, 'tramos_seleccionados')
    dominio_tramos = dominio_activo.tramos_seleccionados;
    if ischar(dominio_tramos), dominio_tramos = {dominio_tramos}; endif
  endif
  if usar_resultados && isfield(modelo, 'tablas_resultados') && ...
      isfield(modelo.tablas_resultados, 'tramos')
    res_t = modelo.tablas_resultados.tramos;
  endif

  info.n_nodos = numel(nodos);
  info.n_tramos = numel(tramos);

  vis_flag = 'on';
  if ~visible, vis_flag = 'off'; endif

  toolkit_prev = '';
  toolkit_cambiado = false;
  toolkit_fig = '';

  unwind_protect
    try
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
        h = figure('Visible', vis_flag, 'Name', 'AOS CAD-TOP Visor 2D', ...
          'NumberTitle', 'off', '__graphics_toolkit__', toolkit_fig);
      else
        h = figure('Visible', vis_flag, 'Name', 'AOS CAD-TOP Visor 2D', ...
          'NumberTitle', 'off');
      endif
      info.figura_abierta = true;
      hold on;
      grid on;
      axis equal;
      title('AOS CAD-TOP — visor 2D (tablas/resultados)');
      xlabel('X [m]'); ylabel('Y [m]');

      % Escala de color por caudal
      vals = [];
      for i = 1:numel(res_t)
        q = caudal_resultado_local(res_t{i});
        if isfinite(q)
          vals(end+1) = abs(q); %#ok<AGROW>
        endif
      endfor
      vmin = 0; vmax = 1;
      if ~isempty(vals)
        vmin = min(vals); vmax = max(vals);
        if abs(vmax - vmin) < 1e-15, vmax = vmin + 1; endif
      endif

      for i = 1:numel(tramos)
        tr = tramos{i};
        x = [tr.x1, tr.x2];
        y = [tr.y1, tr.y2];
        col = [0.2 0.4 0.8];
        lw = 1.5;
        if ~isempty(dominio_tramos) && ~any(strcmp(dominio_tramos, char(tr.id)))
          col = [0.72 0.72 0.72]; lw = 0.8;
        endif
        if ~isempty(res_t)
          for j = 1:numel(res_t)
            if strcmp(res_t{j}.id, tr.id)
              q = caudal_resultado_local(res_t{j});
              if ~isfinite(q), q = 0; endif
              t = (abs(q) - vmin) / (vmax - vmin);
              col = [t, 0.15, 1 - t]; % azul→rojo
              lw = 1.5 + 3 * t;
              break;
            endif
          endfor
        endif
        plot(x, y, '-', 'Color', col, 'LineWidth', lw);
        mx = mean(x); my = mean(y);
        text(mx, my, tr.id, 'FontSize', 8, 'Color', [0.1 0.1 0.1]);
      endfor

      for i = 1:numel(nodos)
        n = nodos{i};
        plot(n.x, n.y, 'ko', 'MarkerFaceColor', [0.9 0.7 0.1], 'MarkerSize', 8);
        text(n.x + 0.5, n.y + 0.5, n.id, 'FontSize', 8);
      endfor

      if ~isempty(res_t)
        try
          cb = colorbar();
          caxis([vmin vmax]);
          set(get(cb, 'ylabel'), 'string', '|Q| m3/s');
        catch
          % colorbar opcional segun backend grafico
        end_try_catch
      endif
      hold off;

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
      rethrow(err);
    end_try_catch
  unwind_protect_cleanup
    if toolkit_cambiado
      try
        graphics_toolkit(toolkit_prev);
      catch
      end_try_catch
    endif
  end_unwind_protect

  if ~silencioso
    fprintf('Visor 2D: %d nodos, %d tramos (coloreado por resultados=%d).\n', ...
      numel(nodos), numel(tramos), ~isempty(res_t));
  endif
endfunction

function q = caudal_resultado_local(r)
  q = NaN;
  if ~isstruct(r), return; endif
  if isfield(r, 'caudal_liquido_m3s') && isnumeric(r.caudal_liquido_m3s) && ~isempty(r.caudal_liquido_m3s)
    q = r.caudal_liquido_m3s(1);
  elseif isfield(r, 'caudal_m3s') && isnumeric(r.caudal_m3s) && ~isempty(r.caudal_m3s)
    q = r.caudal_m3s(1);
  endif
endfunction

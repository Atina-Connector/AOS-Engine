function [ruta, estado] = aos_generar_imagen_aporte_punzados(param, Ql, carpeta)
% Genera grafico de aporte distribuido por punzados cuando hay geologia.

  if nargin < 2 || isempty(Ql)
    Ql = 0;
  endif
  if nargin < 3 || isempty(carpeta)
    carpeta = tempdir();
  endif

  ruta = '';
  estado = 'NO_DISPONIBLE';
  global geologia;
  if ~isstruct(geologia) || isempty(fieldnames(geologia))
    return;
  endif
  if exist('aos_obtener_punzados_activos', 'file') ~= 2 || ...
     exist('aos_distribuir_produccion_punzados', 'file') ~= 2
    return;
  endif

  try
    intervalos = aos_obtener_punzados_activos(geologia, param);
  catch err
    estado = ['ERROR_' limpiar_estado_local(err.message)];
    return;
  end_try_catch
  if isempty(intervalos)
    return;
  endif

  try
    dist = aos_distribuir_produccion_punzados(Ql, geologia, intervalos, param);
  catch err
    estado = ['ERROR_' limpiar_estado_local(err.message)];
    return;
  end_try_catch
  if ~isstruct(dist) || ~isfield(dist, 'tramos') || isempty(dist.tramos)
    return;
  endif

  ruta = [tempname(carpeta) '.png'];
  fig = [];
  try
    md = [dist.tramos.MD_medio_m];
    ql = [dist.tramos.Ql_m3d];
    qo = [dist.tramos.Qo_m3d];
    qw = [dist.tramos.Qw_m3d];

    fig = figure('Visible', 'off', 'Position', [100 100 980 720]);
    subplot(1,2,1);
    barh(md, ql, 0.55);
    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('Aporte liquido (m3/d)');
    ylabel('MD medio (m)');
    title('Aporte total por punzados');

    subplot(1,2,2);
    barh(md, [qo(:) qw(:)], 'stacked');
    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('Aporte (m3/d)');
    ylabel('MD medio (m)');
    legend('Petroleo', 'Agua', 'Location', 'northeast');
    title('Distribucion petroleo-agua');

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

function s = limpiar_estado_local(txt)
  if ~ischar(txt)
    txt = 'DESCONOCIDO';
  endif
  s = regexprep(txt, '[^A-Za-z0-9]+', '_');
  if isempty(s)
    s = 'DESCONOCIDO';
  endif
endfunction

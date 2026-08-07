function h = aos_cad_hidraulica_dominio_visualizar(dominio, titulo)
% Visualiza red completa en gris y dominio seleccionado resaltado.
  global CONFIG_ACTIVA;
  if nargin < 2 || isempty(titulo)
    titulo = 'AOSCAD - dominio hidraulico';
  endif
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD DOMINIO: no hay modelo activo.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  nodos = filas_local(modelo.tablas_entrada, 'nodos');
  tramos = filas_local(modelo.tablas_entrada, 'tramos');
  seleccion = {};
  inicio = '';
  fin = '';
  if nargin >= 1 && isstruct(dominio) && ~isempty(dominio)
    seleccion = celda_local(dominio, 'tramos_seleccionados');
    if isfield(dominio, 'nodo_inicio')
      inicio = char(dominio.nodo_inicio);
    endif
    if isfield(dominio, 'nodo_fin')
      fin = char(dominio.nodo_fin);
    endif
  endif

  h = figure('Name', titulo, 'NumberTitle', 'off');
  hold on;
  grid on;
  axis equal;
  title(titulo);
  xlabel('X [m]');
  ylabel('Y [m]');
  for i = 1:numel(tramos)
    tr = tramos{i};
    seleccionado = isfield(tr, 'id') && ...
      any(strcmp(seleccion, char(tr.id)));
    if seleccionado
      color = [0.85 0.15 0.10];
      ancho = 3.5;
    else
      color = [0.65 0.65 0.65];
      ancho = 1.0;
    endif
    plot([tr.x1 tr.x2], [tr.y1 tr.y2], '-', ...
      'Color', color, 'LineWidth', ancho);
    text(mean([tr.x1 tr.x2]), mean([tr.y1 tr.y2]), char(tr.id), ...
      'FontSize', 8, 'Color', [0.2 0.2 0.2]);
  endfor

  desplazamiento = desplazamiento_local(nodos);
  for i = 1:numel(nodos)
    n = nodos{i};
    id = char(n.id);
    marcador = 'o';
    relleno = [0.95 0.80 0.20];
    tamano = 7;
    if strcmp(id, inicio)
      marcador = '^';
      relleno = [0.10 0.70 0.20];
      tamano = 11;
    elseif strcmp(id, fin)
      marcador = 's';
      relleno = [0.85 0.15 0.10];
      tamano = 10;
    endif
    plot(n.x, n.y, ['k' marcador], ...
      'MarkerFaceColor', relleno, 'MarkerSize', tamano);
    text(n.x + desplazamiento, n.y + desplazamiento, id, 'FontSize', 8);
  endfor
  hold off;
endfunction

function rows = filas_local(te, campo)
  rows = {};
  if isstruct(te) && isfield(te, campo) && ~isempty(te.(campo))
    rows = te.(campo);
    if isstruct(rows)
      rows = num2cell(rows);
    endif
  endif
endfunction

function c = celda_local(s, campo)
  c = {};
  if ~isstruct(s) || ~isfield(s, campo) || isempty(s.(campo))
    return;
  endif
  valor = s.(campo);
  if ischar(valor)
    c = {valor};
  elseif iscell(valor)
    for i = 1:numel(valor)
      c{end+1} = char(valor{i});
    endfor
  endif
endfunction

function d = desplazamiento_local(nodos)
  xs = [];
  ys = [];
  for i = 1:numel(nodos)
    xs(end+1) = nodos{i}.x;
    ys(end+1) = nodos{i}.y;
  endfor
  if isempty(xs)
    d = 0.1;
    return;
  endif
  d = max([max(xs)-min(xs), max(ys)-min(ys), 1]) * 0.008;
endfunction

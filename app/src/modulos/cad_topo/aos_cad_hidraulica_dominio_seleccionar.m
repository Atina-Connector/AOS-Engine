function dominio = aos_cad_hidraulica_dominio_seleccionar(modo, silencioso)
% Selecciona nodo inicial y final sobre el plano o por ID.
  global CONFIG_ACTIVA;
  if nargin < 1 || isempty(modo)
    modo = 'GRAFICO';
  endif
  if nargin < 2
    silencioso = false;
  endif
  modo = upper(strtrim(char(modo)));
  aos_cad_hidraulica_preparar_modelo(true);
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  nodos = filas_local(modelo.tablas_entrada, 'nodos');
  if numel(nodos) < 2
    error('AOSCAD DOMINIO: se requieren al menos dos nodos.');
  endif

  if strcmp(modo, 'GRAFICO')
    h = [];
    try
      h = aos_cad_hidraulica_dominio_visualizar([], ...
        'Seleccione NODO INICIAL y luego NODO FINAL');
      fprintf('\nToque el nodo inicial en el plano...\n');
      [x0, y0] = ginput(1);
      id0 = nodo_cercano_local(nodos, x0, y0);
      n0 = nodo_por_id_local(nodos, id0);
      hold on;
      plot(n0.x, n0.y, 'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 12);
      hold off;
      fprintf('Nodo inicial seleccionado: %s\n', id0);
      fprintf('Toque el nodo final en el plano...\n');
      [x1, y1] = ginput(1);
      id1 = nodo_cercano_local(nodos, x1, y1);
      if ~isempty(h) && ishandle(h)
        close(h);
      endif
    catch err
      if ~isempty(h) && ishandle(h)
        close(h);
      endif
      fprintf(2, 'Seleccion grafica no disponible (%s).\n', err.message);
      fprintf('Se utilizara ingreso por ID.\n');
      [id0, id1] = leer_ids_local(nodos);
    end_try_catch
  else
    [id0, id1] = leer_ids_local(nodos);
  endif

  if strcmp(id0, id1)
    error('AOSCAD DOMINIO: el nodo inicial y final coinciden.');
  endif
  caminos = aos_cad_hidraulica_encontrar_caminos(modelo, id0, id1, 64);
  if isempty(caminos)
    error('AOSCAD DOMINIO: no existe camino entre %s y %s.', id0, id1);
  endif

  fprintf('\nCAMINOS DETECTADOS ENTRE %s Y %s: %d\n', ...
    id0, id1, numel(caminos));
  for i = 1:numel(caminos)
    fprintf('%2d - L=%.6g m | %s\n', i, caminos{i}.longitud_m, ...
      unir_local(caminos{i}.tramos, ' -> '));
  endfor

  seleccion = 1;
  if numel(caminos) > 1
    fprintf('%2d - Incluir todos como SUBRED/ANILLO (HYD_LOOP)\n', ...
      numel(caminos)+1);
    opcion = leer_entero_local('Seleccione camino', 1, 1, numel(caminos)+1);
    if opcion == numel(caminos)+1
      seleccion = 'TODOS';
    else
      seleccion = opcion;
    endif
  endif

  [dominio, modelo] = aos_cad_hidraulica_dominio_programatico( ...
    modelo, id0, id1, seleccion);
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  aos_cad_hidraulica_dominio_visualizar( ...
    dominio, sprintf('Dominio %s', dominio.id));
  if ~silencioso
    aos_cad_hidraulica_dominio_mostrar(false);
  endif

  respuesta = upper(strtrim(input( ...
    'Definir ahora condiciones de extremos? [S/n]: ', 's')));
  if isempty(respuesta) || strcmp(respuesta, 'S') || strcmp(respuesta, 'SI')
    if silencioso
      dominio = aos_cad_hidraulica_dominio_definir_condiciones( ...
        'P_INICIO_Q_FIN', [], [], [], true);
    else
      fprintf('\nModos: 1=P_INICIO_Q_FIN  2=Q_INICIO_P_FIN  3=P_INICIO_P_FIN\n');
      texto = input('Seleccione modo [1]: ', 's');
      if isempty(strtrim(texto))
        modo = 'P_INICIO_Q_FIN';
      else
        opm = round(str2double(texto));
        if opm == 2
          modo = 'Q_INICIO_P_FIN';
        elseif opm == 3
          modo = 'P_INICIO_P_FIN';
        else
          modo = 'P_INICIO_Q_FIN';
        endif
      endif
      dominio = aos_cad_hidraulica_dominio_definir_condiciones( ...
        modo, [], [], [], false);
    endif
  endif
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

function id = nodo_cercano_local(nodos, x, y)
  mejor = Inf;
  id = '';
  for i = 1:numel(nodos)
    distancia = hypot(nodos{i}.x-x, nodos{i}.y-y);
    if distancia < mejor
      mejor = distancia;
      id = char(nodos{i}.id);
    endif
  endfor
endfunction

function nodo = nodo_por_id_local(nodos, id)
  nodo = [];
  for i = 1:numel(nodos)
    if strcmp(char(nodos{i}.id), id)
      nodo = nodos{i};
      return;
    endif
  endfor
endfunction

function [id0, id1] = leer_ids_local(nodos)
  fprintf('\nNODOS DISPONIBLES:\n');
  for i = 1:numel(nodos)
    fprintf('%s  (%.6g, %.6g, %.6g)\n', char(nodos{i}.id), ...
      nodos{i}.x, nodos{i}.y, z_local(nodos{i}));
  endfor
  id0 = strtrim(input('ID nodo inicial: ', 's'));
  id1 = strtrim(input('ID nodo final: ', 's'));
  if isempty(nodo_por_id_local(nodos, id0))
    error('Nodo inicial no valido.');
  endif
  if isempty(nodo_por_id_local(nodos, id1))
    error('Nodo final no valido.');
  endif
endfunction

function z = z_local(nodo)
  z = 0;
  if isfield(nodo, 'z') && isnumeric(nodo.z) && ~isempty(nodo.z)
    z = nodo.z(1);
  endif
endfunction

function valor = leer_entero_local(etiqueta, defecto, minimo, maximo)
  texto = input(sprintf('%s [%d]: ', etiqueta, defecto), 's');
  if isempty(strtrim(texto))
    valor = defecto;
  else
    valor = round(str2double(texto));
  endif
  if ~isfinite(valor) || valor < minimo || valor > maximo
    error('Opcion fuera de rango.');
  endif
endfunction

function txt = unir_local(c, separador)
  txt = '';
  for i = 1:numel(c)
    if i > 1
      txt = [txt separador];
    endif
    txt = [txt char(c{i})];
  endfor
endfunction

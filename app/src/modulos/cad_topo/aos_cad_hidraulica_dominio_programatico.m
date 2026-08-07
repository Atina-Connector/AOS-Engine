function [dominio, modelo, caminos] = aos_cad_hidraulica_dominio_programatico(modelo, nodo_inicio, nodo_fin, seleccion)
% Define un dominio entre dos nodos sin interfaz grafica.
% seleccion: indice de camino o texto TODOS para conservar subred/anillo.
  if nargin < 4 || isempty(seleccion)
    seleccion = 1;
  endif
  caminos = aos_cad_hidraulica_encontrar_caminos( ...
    modelo, nodo_inicio, nodo_fin, 64);
  if isempty(caminos)
    error('AOSCAD DOMINIO: no existe camino entre %s y %s.', ...
      char(nodo_inicio), char(nodo_fin));
  endif

  todos = false;
  if ischar(seleccion)
    todos = any(strcmpi(strtrim(seleccion), ...
      {'TODOS', 'ALL', 'ANILLO', 'SUBRED'}));
  endif

  if todos && numel(caminos) > 1
    seleccionados = caminos;
    tipo = 'LOOP_SUBNETWORK';
    indice_camino = 0;
  else
    if ~isnumeric(seleccion) || isempty(seleccion)
      seleccion = 1;
    endif
    indice_camino = round(seleccion(1));
    if indice_camino < 1 || indice_camino > numel(caminos)
      error('AOSCAD DOMINIO: indice de camino fuera de rango.');
    endif
    seleccionados = {caminos{indice_camino}};
    tipo = 'SELECTED_PATH';
  endif

  ids_nodos = {};
  ids_tramos = {};
  for i = 1:numel(seleccionados)
    camino = seleccionados{i};
    ids_nodos = union_estable_local(ids_nodos, camino.nodos);
    ids_tramos = union_estable_local(ids_tramos, camino.tramos);
  endfor
  longitud = longitud_unica_local(modelo, ids_tramos);

  dominios = {};
  if isfield(modelo, 'tablas_entrada') && ...
      isfield(modelo.tablas_entrada, 'dominios_hidraulicos') && ...
      ~isempty(modelo.tablas_entrada.dominios_hidraulicos)
    dominios = modelo.tablas_entrada.dominios_hidraulicos;
    if isstruct(dominios)
      dominios = num2cell(dominios);
    endif
  endif
  for i = 1:numel(dominios)
    dominios{i}.activo = false;
  endfor

  dominio = struct();
  dominio.id = siguiente_id_local(dominios);
  dominio.tipo = tipo;
  dominio.estado = 'CONFIRMADO';
  dominio.activo = true;
  dominio.nodo_inicio = char(nodo_inicio);
  dominio.nodo_fin = char(nodo_fin);
  dominio.sentido = 'INICIO_A_FIN';
  dominio.nodos_seleccionados = ids_nodos;
  dominio.tramos_seleccionados = ids_tramos;
  dominio.cantidad_caminos_detectados = numel(caminos);
  dominio.camino_seleccionado = indice_camino;
  dominio.caminos = seleccionados;
  dominio.longitud_total_m = longitud;
  dominio.origen_seleccion = 'USUARIO_SOBRE_DXF';
  dominio.condicion_extremos = 'PENDIENTE';
  dominio.creado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  dominio.modificado_en = dominio.creado_en;
  dominio.estado_solver = 'LISTO_CAMINO_SIMPLE';
  if strcmp(tipo, 'LOOP_SUBNETWORK')
    dominio.estado_solver = 'LISTO_LAZO_KIRCHHOFF';
  endif
  dominio.notas = ['La red completa permanece en tablas_entrada; ' ...
    'el solver usa solo los nodos y tramos de este dominio.'];

  dominios{end+1} = dominio;
  modelo.tablas_entrada.dominios_hidraulicos = dominios;
  if ~isfield(modelo, 'simulacion') || ~isstruct(modelo.simulacion)
    modelo.simulacion = struct();
  endif
  modelo.simulacion.dominio_hidraulico_activo_id = dominio.id;
  modelo = aos_cad_hidraulica_invalidar_por_dominio( ...
    modelo, 'SELECCIONAR_DOMINIO_HIDRAULICO', ...
    sprintf('%s:%s->%s', dominio.id, ...
      dominio.nodo_inicio, dominio.nodo_fin));
endfunction

function out = union_estable_local(a, b)
  out = a;
  if ischar(b)
    b = {b};
  endif
  for i = 1:numel(b)
    valor = char(b{i});
    if ~any(strcmp(out, valor))
      out{end+1} = valor;
    endif
  endfor
endfunction

function id = siguiente_id_local(dominios)
  maximo = 0;
  for i = 1:numel(dominios)
    if ~isstruct(dominios{i}) || ~isfield(dominios{i}, 'id')
      continue;
    endif
    token = regexp(char(dominios{i}.id), '(\d+)$', 'tokens', 'once');
    if ~isempty(token)
      maximo = max(maximo, str2double(token{1}));
    endif
  endfor
  id = sprintf('DOMAIN-%03d', maximo + 1);
endfunction

function longitud = longitud_unica_local(modelo, ids_tramos)
  longitud = 0;
  tramos = modelo.tablas_entrada.tramos;
  if isstruct(tramos)
    tramos = num2cell(tramos);
  endif
  for i = 1:numel(tramos)
    tramo = tramos{i};
    if ~isfield(tramo, 'id') || ...
        ~any(strcmp(ids_tramos, char(tramo.id)))
      continue;
    endif
    valor = 0;
    if isfield(tramo, 'longitud_m')
      valor = aos_aoscad_valor(tramo.longitud_m);
    endif
    if isnumeric(valor) && ~isempty(valor)
      longitud = longitud + valor(1);
    endif
  endfor
endfunction

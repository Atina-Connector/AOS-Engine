function ok = aos_cad_hidraulica_dominio_validar(silencioso)
% Valida seleccion, continuidad y suficiencia de BC del dominio.
% Emite items estructurados HID_BC_* / HID_MODO_* sin silenciar fallas.
  global CONFIG_ACTIVA;
  if nargin < 1
    silencioso = false;
  endif
  ok = false;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD DOMINIO: no hay modelo activo.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  [dominio, ~] = aos_cad_hidraulica_dominio_activo(modelo);
  if isempty(dominio)
    if ~silencioso
      fprintf('Sin dominio selectivo: se validara la red completa.\n');
    endif
    aos_cad_hidraulica_validar_red(silencioso);
    ok = true;
    return;
  endif

  items = {};
  modo = '';
  if isfield(dominio, 'condicion_extremos') && ~isempty(dominio.condicion_extremos)
    modo = upper(strtrim(char(dominio.condicion_extremos)));
  endif

  es_lazo = strcmpi(char(dominio.tipo), 'LOOP_SUBNETWORK');
  multifasico_en_lazo = false;
  if es_lazo
    multifasico_en_lazo = dominio_tiene_multifasico_local(modelo, dominio);
  endif

  if es_lazo && multifasico_en_lazo
    items{end+1} = item_local('HID_MODO_NO_SOPORTADO_EN_LAZO', ...
      sprintf(['Dominio %s es LOOP_SUBNETWORK con tramos multifasicos; ' ...
               'lazos DEV1 solo admiten MONOFASICO_DARCY.'], ...
              char(dominio.id)), 'ERROR');
    modelo = guardar_items_local(modelo, items);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    if ~silencioso
      fprintf('\nDOMINIO %s: LAZO CON MULTIFASICO NO SOPORTADO\n', dominio.id);
      imprimir_items_local(items);
    endif
    ok = false;
    return;
  endif

  caminos = aos_cad_hidraulica_encontrar_caminos( ...
    modelo, dominio.nodo_inicio, dominio.nodo_fin, 64);
  if isempty(caminos)
    error('AOSCAD DOMINIO: los extremos dejaron de estar conectados.');
  endif

  [n_P, n_Q, nodos_P] = contar_bc_dominio_local(modelo, dominio);

  if isempty(modo) || strcmp(modo, 'PENDIENTE')
    items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
      'Faltan condiciones de extremos (condicion_extremos=PENDIENTE).', ...
      'ERROR');
  elseif strcmp(modo, 'P_INICIO_Q_FIN')
    if n_P < 1 || n_Q < 1
      items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
        'P_INICIO_Q_FIN requiere BC PRESION en inicio y CAUDAL en fin.', ...
        'ERROR');
    endif
  elseif strcmp(modo, 'Q_INICIO_P_FIN')
    if n_P < 1 || n_Q < 1
      items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
        'Q_INICIO_P_FIN requiere BC CAUDAL en inicio y PRESION en fin.', ...
        'ERROR');
    endif
  elseif strcmp(modo, 'P_INICIO_P_FIN')
    if es_lazo
      if n_P < 2
        items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
          'P_INICIO_P_FIN en lazo requiere dos BC PRESION (inicio y fin).', ...
          'ERROR');
      endif
    elseif ~strcmpi(char(dominio.tipo), 'SELECTED_PATH') || ...
        grado_maximo_dominio_local(modelo, dominio) >= 3
      items{end+1} = item_local('HID_MODO_PP_REQUIERE_CAMINO_SIMPLE', ...
        ['P_INICIO_P_FIN solo se admite sobre SELECTED_PATH sin ' ...
         'bifurcaciones (camino simple).'], 'ERROR');
    elseif ~isfield(dominio, 'presion_inicio_bar') || ...
        ~isfield(dominio, 'presion_fin_bar') || ...
        ~isfinite(dominio.presion_inicio_bar) || ...
        ~isfinite(dominio.presion_fin_bar)
      items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
        'P_INICIO_P_FIN requiere presion_inicio_bar y presion_fin_bar.', ...
        'ERROR');
    elseif n_P < 1
      items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
        'P_INICIO_P_FIN requiere al menos un BC PRESION de referencia.', ...
        'ERROR');
    endif
  else
    items{end+1} = item_local('HID_BC_INSUFICIENTE', ...
      sprintf('Modo de condicion desconocido: %s.', modo), 'ERROR');
  endif

  if n_P > 1 && ~es_lazo
    items{end+1} = item_local('HID_BC_SOBREDETERMINADA', ...
      sprintf(['DEV1 admite una sola fuente de PRESION en caminos; el dominio tiene ' ...
               '%d nodos con BC PRESION.'], numel(unique(nodos_P))), ...
      'ERROR');
  endif

  hay_error = false;
  for i = 1:numel(items)
    if strcmpi(items{i}.severidad, 'ERROR')
      hay_error = true;
      break;
    endif
  endfor

  if ~hay_error
    if es_lazo
      items{end+1} = item_local('HID_LAZO_MODO_CONDICION_OK', ...
        sprintf('Modo %s suficiente para HYD_LOOP sobre %s.', ...
                modo, char(dominio.tipo)), 'INFO');
    else
      items{end+1} = item_local('HID_MODO_CONDICION_OK', ...
        sprintf('Modo %s suficiente para solver DEV1 sobre %s.', ...
                modo, char(dominio.tipo)), 'INFO');
    endif
  endif

  modelo = guardar_items_local(modelo, items);
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

  if hay_error
    ok = false;
    if ~silencioso
      fprintf('\nDOMINIO HIDRAULICO: CONDICIONES INSUFICIENTES O INVALIDAS\n');
      fprintf('ID   : %s\n', dominio.id);
      fprintf('Modo : %s\n', iif_str_local(modo, '(sin modo)'));
      imprimir_items_local(items);
    endif
    return;
  endif

  cfg = aos_cad_hidraulica_defaults(modelo);
  red = aos_cad_hidraulica_preparar(modelo, cfg);
  ok = true;
  if ~silencioso
    fprintf('\nDOMINIO HIDRAULICO VALIDADO\n');
    fprintf('ID             : %s\n', dominio.id);
    fprintf('Modo extremos  : %s\n', modo);
    fprintf('Inicio -> fin  : %s -> %s\n', ...
      dominio.nodo_inicio, dominio.nodo_fin);
    fprintf('Nodos activos  : %d\n', numel(red.nodos));
    fprintf('Tramos activos : %d\n', numel(red.tramos));
    fprintf('P referencia   : %.6g bar\n', red.P_root_Pa/1e5);
    fprintf('Ql total       : %.6g m3/d\n', red.ql_total_m3s*86400);
    if isfield(red, 'requiere_solver_lazos') && red.requiere_solver_lazos
      fprintf('Solver         : HYD_LOOP\n');
    endif
    imprimir_items_local(items);
  endif
endfunction

function tf = dominio_tiene_multifasico_local(modelo, dominio)
  tf = false;
  ids_tramos = celda_texto_local(dominio, 'tramos_seleccionados');
  tramos = {};
  if isfield(modelo, 'tablas_entrada') && isfield(modelo.tablas_entrada, 'tramos')
    tramos = modelo.tablas_entrada.tramos;
    if isstruct(tramos), tramos = num2cell(tramos); endif
  endif
  for i = 1:numel(tramos)
    tr = tramos{i};
    if ~isstruct(tr) || ~isfield(tr, 'id'), continue; endif
    if ~isempty(ids_tramos) && ~any(strcmp(ids_tramos, char(tr.id))), continue; endif
    mid = '';
    if isfield(tr, 'modelo_hidraulico'), mid = char(tr.modelo_hidraulico); endif
    mid = upper(strrep(strrep(strtrim(mid), '-', '_'), ' ', '_'));
    if any(strcmp(mid, {'MULTIFASICO_HB','MULTIFASICO_DR','MULTIFASICO_SIMPLIFICADO', ...
                        'HB','DR','HAGEDORN_BROWN','DUNS_ROS'}))
      tf = true; return;
    endif
  endfor
endfunction

function it = item_local(codigo, mensaje, severidad)
  it = struct('codigo', codigo, 'mensaje', mensaje, 'severidad', severidad);
endfunction

function [n_P, n_Q, nodos_P] = contar_bc_dominio_local(modelo, dominio)
  n_P = 0;
  n_Q = 0;
  nodos_P = {};
  bcs = {};
  if isfield(modelo, 'tablas_entrada') && ...
      isfield(modelo.tablas_entrada, 'condiciones_borde')
    bcs = modelo.tablas_entrada.condiciones_borde;
    if isstruct(bcs), bcs = num2cell(bcs); endif
  endif
  for i = 1:numel(bcs)
    bc = bcs{i};
    if ~isstruct(bc) || ~isfield(bc, 'dominio_id') || ...
        ~strcmp(char(bc.dominio_id), char(dominio.id))
      continue;
    endif
    tipo = '';
    if isfield(bc, 'tipo_bc'), tipo = upper(strtrim(char(bc.tipo_bc))); endif
    if strcmp(tipo, 'PRESION') || strcmp(tipo, 'PRESSURE')
      n_P = n_P + 1;
      if isfield(bc, 'nodo_ref')
        nodos_P{end+1} = char(bc.nodo_ref); %#ok<AGROW>
      endif
    elseif any(strcmp(tipo, {'CAUDAL','CAUDAL_LIQUIDO','DEMANDA','FLOW','LIQUID_FLOW'}))
      n_Q = n_Q + 1;
    endif
  endfor
endfunction

function modelo = guardar_items_local(modelo, items_nuevos)
  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  prev = modelo.validaciones.items;
  if ~iscell(prev), prev = num2cell(prev); endif
  keep = {};
  prefs = {'HID_BC_', 'HID_MODO_', 'HID_LAZO_MODO_'};
  for i = 1:numel(prev)
    it = prev{i};
    cod = '';
    if isstruct(it) && isfield(it, 'codigo'), cod = char(it.codigo); endif
    drop = false;
    for p = 1:numel(prefs)
      if strncmp(cod, prefs{p}, numel(prefs{p}))
        drop = true;
        break;
      endif
    endfor
    if ~drop
      keep{end+1} = it; %#ok<AGROW>
    endif
  endfor
  modelo.validaciones.items = [keep, items_nuevos];
  hay_error = false;
  for i = 1:numel(items_nuevos)
    if strcmpi(items_nuevos{i}.severidad, 'ERROR')
      hay_error = true;
      break;
    endif
  endfor
  if hay_error
    modelo.validaciones.estado = 'ERROR';
  elseif strcmpi(char(getfield_local(modelo.validaciones, 'estado', '')), 'ERROR')
    % conservar ERROR previo de otras fuentes
  else
    modelo.validaciones.estado = 'OK';
  endif
endfunction

function v = getfield_local(s, f, d)
  if isstruct(s) && isfield(s, f), v = s.(f); else v = d; endif
endfunction

function imprimir_items_local(items)
  for i = 1:numel(items)
    it = items{i};
    fprintf(' [%s] %s: %s\n', char(it.severidad), char(it.codigo), ...
      char(it.mensaje));
  endfor
endfunction

function s = iif_str_local(val, alt)
  if isempty(val), s = alt; else s = val; endif
endfunction

function gmax = grado_maximo_dominio_local(modelo, dominio)
  gmax = 0;
  ids_nodos = celda_texto_local(dominio, 'nodos_seleccionados');
  ids_tramos = celda_texto_local(dominio, 'tramos_seleccionados');
  if isempty(ids_nodos) || isempty(ids_tramos)
    return;
  endif
  grado = zeros(1, numel(ids_nodos));
  tramos = {};
  if isfield(modelo, 'tablas_entrada') && ...
      isfield(modelo.tablas_entrada, 'tramos')
    tramos = modelo.tablas_entrada.tramos;
    if isstruct(tramos), tramos = num2cell(tramos); endif
  endif
  for i = 1:numel(tramos)
    tr = tramos{i};
    if ~isstruct(tr) || ~isfield(tr, 'id') || ...
        ~any(strcmp(ids_tramos, char(tr.id)))
      continue;
    endif
    io = find(strcmp(ids_nodos, char(tr.nodo_o)), 1);
    id = find(strcmp(ids_nodos, char(tr.nodo_d)), 1);
    if ~isempty(io), grado(io) = grado(io) + 1; endif
    if ~isempty(id), grado(id) = grado(id) + 1; endif
  endfor
  if ~isempty(grado)
    gmax = max(grado);
  endif
endfunction

function c = celda_texto_local(s, campo)
  c = {};
  if ~isstruct(s) || ~isfield(s, campo) || isempty(s.(campo))
    return;
  endif
  valor = s.(campo);
  if ischar(valor)
    c = {valor};
  elseif iscell(valor)
    for i = 1:numel(valor)
      c{end+1} = char(valor{i}); %#ok<AGROW>
    endfor
  endif
endfunction

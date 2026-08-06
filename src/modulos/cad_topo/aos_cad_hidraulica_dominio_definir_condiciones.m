function dominio = aos_cad_hidraulica_dominio_definir_condiciones(varargin)
% Define condiciones de extremos del dominio activo.
% Uso legacy (modo default P_INICIO_Q_FIN):
%   (P_inicio_bar, Q_fin_m3d, Qg_fin_sm3d, silencioso)
% Uso con modo:
%   (modo, valor_a, valor_b, Qg_sm3d, silencioso)
%   P_INICIO_Q_FIN : valor_a=P_inicio_bar, valor_b=Q_fin_m3d
%   Q_INICIO_P_FIN : valor_a=Q_inicio_m3d, valor_b=P_fin_bar
%   P_INICIO_P_FIN : valor_a=P_inicio_bar, valor_b=P_fin_bar
  global CONFIG_ACTIVA;

  [modo, v1, v2, Qg_sm3d, silencioso] = parse_args_local(varargin{:});

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD DOMINIO: no hay modelo activo.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  [dominio, indice_dominio] = aos_cad_hidraulica_dominio_activo(modelo);
  if isempty(dominio)
    error('AOSCAD DOMINIO: seleccione un dominio primero.');
  endif
  es_lazo = strcmpi(char(dominio.tipo), 'LOOP_SUBNETWORK');

  if isempty(modo)
    if silencioso
      modo = 'P_INICIO_Q_FIN';
    else
      modo = elegir_modo_local();
    endif
  endif
  modo = upper(strtrim(char(modo)));
  modos_ok = {'P_INICIO_Q_FIN', 'Q_INICIO_P_FIN', 'P_INICIO_P_FIN'};
  if ~any(strcmp(modo, modos_ok))
    error('AOSCAD DOMINIO: modo de condicion no soportado: %s.', modo);
  endif

  if strcmp(modo, 'P_INICIO_P_FIN')
    motivo = '';
    if es_lazo
      % Nativo en lazo: dos BC de PRESION (pseudolazo), sin biseccion.
    elseif ~strcmpi(char(dominio.tipo), 'SELECTED_PATH')
      motivo = 'P_INICIO_P_FIN exige un dominio SELECTED_PATH (camino simple).';
    elseif grado_maximo_dominio_local(modelo, dominio) >= 3
      motivo = ['P_INICIO_P_FIN no admite arbol ramificado ' ...
                '(reparto de caudal no unico).'];
    endif
    if ~isempty(motivo)
      modelo = agregar_item_local(modelo, 'HID_MODO_PP_REQUIERE_CAMINO_SIMPLE', ...
        motivo, 'ERROR');
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
      error(['AOSCAD DOMINIO: P_INICIO_P_FIN requiere camino simple ' ...
             '(HID_MODO_PP_REQUIERE_CAMINO_SIMPLE).']);
    endif
  endif

  [P_inicio_bar, Q_fin_m3d, Q_inicio_m3d, P_fin_bar, Qg_sm3d] = ...
    leer_valores_local(modo, v1, v2, Qg_sm3d, silencioso);

  condiciones = {};
  if isfield(modelo.tablas_entrada, 'condiciones_borde') && ...
      ~isempty(modelo.tablas_entrada.condiciones_borde)
    condiciones = modelo.tablas_entrada.condiciones_borde;
    if isstruct(condiciones)
      condiciones = num2cell(condiciones);
    endif
  endif
  conservar = {};
  for i = 1:numel(condiciones)
    bc = condiciones{i};
    es_mismo_dominio = isstruct(bc) && isfield(bc, 'dominio_id') && ...
      strcmp(char(bc.dominio_id), char(dominio.id));
    if ~es_mismo_dominio
      conservar{end+1} = bc; %#ok<AGROW>
    endif
  endfor
  condiciones = conservar;

  switch modo
    case 'P_INICIO_Q_FIN'
      condiciones{end+1} = bc_presion_local(dominio, dominio.nodo_inicio, ...
        P_inicio_bar, 'ENTRADA_DOMINIO', 'PIN');
      condiciones{end+1} = bc_caudal_local(dominio, dominio.nodo_fin, ...
        Q_fin_m3d, 'SALIDA_DOMINIO', 'QOUT');
      if Qg_sm3d > 0
        condiciones{end+1} = bc_gas_local(dominio, dominio.nodo_fin, ...
          Qg_sm3d, 'SALIDA_DOMINIO', 'QGOUT');
      endif
      dominio.presion_inicio_bar = P_inicio_bar;
      dominio.caudal_fin_m3d = Q_fin_m3d;
      dominio.presion_fin_bar = NaN;
      dominio.caudal_inicio_m3d = NaN;

    case 'Q_INICIO_P_FIN'
      condiciones{end+1} = bc_presion_local(dominio, dominio.nodo_fin, ...
        P_fin_bar, 'SALIDA_DOMINIO', 'POUT');
      condiciones{end+1} = bc_caudal_local(dominio, dominio.nodo_inicio, ...
        Q_inicio_m3d, 'ENTRADA_DOMINIO', 'QIN');
      if Qg_sm3d > 0
        condiciones{end+1} = bc_gas_local(dominio, dominio.nodo_inicio, ...
          Qg_sm3d, 'ENTRADA_DOMINIO', 'QGIN');
      endif
      dominio.presion_fin_bar = P_fin_bar;
      dominio.caudal_inicio_m3d = Q_inicio_m3d;
      dominio.presion_inicio_bar = NaN;
      dominio.caudal_fin_m3d = NaN;

    case 'P_INICIO_P_FIN'
      if es_lazo
        % Dos fuentes de presion: el solver de lazos cierra el pseudolazo.
        condiciones{end+1} = bc_presion_local(dominio, dominio.nodo_inicio, ...
          P_inicio_bar, 'ENTRADA_DOMINIO', 'PIN');
        condiciones{end+1} = bc_presion_local(dominio, dominio.nodo_fin, ...
          P_fin_bar, 'SALIDA_DOMINIO', 'POUT');
        dominio.presion_inicio_bar = P_inicio_bar;
        dominio.presion_fin_bar = P_fin_bar;
        dominio.caudal_fin_m3d = NaN;
        dominio.caudal_inicio_m3d = NaN;
      else
        % Una sola fuente P (inicio). Q en fin es la incognita; valor inicial
        % provisional para el solver hasta la biseccion externa.
        if ~isfinite(Q_fin_m3d) || Q_fin_m3d < 0
          Q_fin_m3d = 100;
        endif
        condiciones{end+1} = bc_presion_local(dominio, dominio.nodo_inicio, ...
          P_inicio_bar, 'ENTRADA_DOMINIO', 'PIN');
        condiciones{end+1} = bc_caudal_local(dominio, dominio.nodo_fin, ...
          Q_fin_m3d, 'SALIDA_DOMINIO', 'QOUT');
        if Qg_sm3d > 0
          condiciones{end+1} = bc_gas_local(dominio, dominio.nodo_fin, ...
            Qg_sm3d, 'SALIDA_DOMINIO', 'QGOUT');
        endif
        dominio.presion_inicio_bar = P_inicio_bar;
        dominio.presion_fin_bar = P_fin_bar;
        dominio.caudal_fin_m3d = Q_fin_m3d;
        dominio.caudal_inicio_m3d = NaN;
      endif
  endswitch

  dominio.condicion_extremos = modo;
  dominio.caudal_gas_fin_sm3d = Qg_sm3d;
  dominio.modificado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');

  dominios = modelo.tablas_entrada.dominios_hidraulicos;
  if isstruct(dominios)
    dominios = num2cell(dominios);
  endif
  dominios{indice_dominio} = dominio;
  modelo.tablas_entrada.dominios_hidraulicos = dominios;
  modelo.tablas_entrada.condiciones_borde = condiciones;
  modelo = aos_cad_hidraulica_invalidar_por_dominio( ...
    modelo, 'EDITAR_CONDICIONES_DOMINIO', dominio.id);
  if es_lazo && strcmp(modo, 'P_INICIO_P_FIN')
    modelo = agregar_item_local(modelo, 'HID_MODO_PP_NATIVO_LAZO', ...
      'P_INICIO_P_FIN nativo en LOOP_SUBNETWORK (pseudolazo, sin biseccion).', ...
      'INFO');
  endif
  modelo.simulacion.dominio_hidraulico_activo_id = dominio.id;
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

  if ~silencioso
    fprintf('\nCONDICIONES DEL DOMINIO %s\n', dominio.id);
    fprintf('Modo   : %s\n', modo);
    switch modo
      case 'P_INICIO_Q_FIN'
        fprintf('Inicio : %s  P=%.6g bar\n', dominio.nodo_inicio, P_inicio_bar);
        fprintf('Fin    : %s  Ql=%.6g m3/d  Qg=%.6g Sm3/d\n', ...
          dominio.nodo_fin, Q_fin_m3d, Qg_sm3d);
      case 'Q_INICIO_P_FIN'
        fprintf('Inicio : %s  Ql=%.6g m3/d  Qg=%.6g Sm3/d\n', ...
          dominio.nodo_inicio, Q_inicio_m3d, Qg_sm3d);
        fprintf('Fin    : %s  P=%.6g bar\n', dominio.nodo_fin, P_fin_bar);
      case 'P_INICIO_P_FIN'
        fprintf('Inicio : %s  P=%.6g bar\n', dominio.nodo_inicio, P_inicio_bar);
        fprintf('Fin    : %s  P=%.6g bar\n', dominio.nodo_fin, P_fin_bar);
        if es_lazo
          fprintf('Nota   : cierre nativo por pseudolazo Kirchhoff (sin biseccion).\n');
        else
          fprintf('Fin    : Q provisional=%.6g m3/d\n', Q_fin_m3d);
          fprintf('Nota   : el caudal se cerrara por biseccion al ejecutar.\n');
        endif
    endswitch
    fprintf('Resultados anteriores: INVALIDADOS.\n');
  endif
endfunction

function [modo, v1, v2, Qg, silencioso] = parse_args_local(varargin)
  modo = '';
  v1 = [];
  v2 = [];
  Qg = [];
  silencioso = false;
  if nargin >= 1 && es_modo_local(varargin{1})
    modo = upper(strtrim(char(varargin{1})));
    if nargin >= 2, v1 = varargin{2}; endif
    if nargin >= 3, v2 = varargin{3}; endif
    if nargin >= 4, Qg = varargin{4}; endif
    if nargin >= 5, silencioso = logical(varargin{5}(1)); endif
  else
    modo = 'P_INICIO_Q_FIN';
    if nargin >= 1, v1 = varargin{1}; endif
    if nargin >= 2, v2 = varargin{2}; endif
    if nargin >= 3, Qg = varargin{3}; endif
    if nargin >= 4, silencioso = logical(varargin{4}(1)); endif
  endif
endfunction

function tf = es_modo_local(x)
  tf = false;
  if ischar(x)
    s = upper(strtrim(x));
    tf = any(strcmp(s, {'P_INICIO_Q_FIN', 'Q_INICIO_P_FIN', 'P_INICIO_P_FIN'}));
  endif
endfunction

function modo = elegir_modo_local()
  fprintf('\nModos de condicion de extremos:\n');
  fprintf(' 1 - P_INICIO_Q_FIN  (P conocida en inicio; Q en fin) [default]\n');
  fprintf(' 2 - Q_INICIO_P_FIN  (Q conocida en inicio; P en fin)\n');
  fprintf(' 3 - P_INICIO_P_FIN  (P en ambos; Q por biseccion, solo camino simple)\n');
  texto = input('Seleccione modo [1]: ', 's');
  if isempty(strtrim(texto))
    modo = 'P_INICIO_Q_FIN';
    return;
  endif
  op = round(str2double(texto));
  if op == 2
    modo = 'Q_INICIO_P_FIN';
  elseif op == 3
    modo = 'P_INICIO_P_FIN';
  else
    modo = 'P_INICIO_Q_FIN';
  endif
endfunction

function [P_inicio_bar, Q_fin_m3d, Q_inicio_m3d, P_fin_bar, Qg_sm3d] = ...
    leer_valores_local(modo, v1, v2, Qg_sm3d, silencioso)
  P_inicio_bar = NaN;
  Q_fin_m3d = NaN;
  Q_inicio_m3d = NaN;
  P_fin_bar = NaN;
  if isempty(Qg_sm3d)
    if silencioso
      Qg_sm3d = 0;
    else
      Qg_sm3d = leer_numero_local('Demanda de gas estandar [Sm3/d]', 0);
    endif
  endif

  switch modo
    case 'P_INICIO_Q_FIN'
      if isempty(v1)
        if silencioso, P_inicio_bar = 20; else
          P_inicio_bar = leer_numero_local('Presion en nodo inicial [bar]', 20);
        endif
      else
        P_inicio_bar = v1;
      endif
      if isempty(v2)
        if silencioso, Q_fin_m3d = 100; else
          Q_fin_m3d = leer_numero_local('Demanda liquida en nodo final [m3/d]', 100);
        endif
      else
        Q_fin_m3d = v2;
      endif
      if ~isfinite(P_inicio_bar) || P_inicio_bar <= 0
        error('AOSCAD DOMINIO: presion inicial invalida.');
      endif
      if ~isfinite(Q_fin_m3d) || Q_fin_m3d < 0 || ...
          ~isfinite(Qg_sm3d) || Qg_sm3d < 0
        error('AOSCAD DOMINIO: los caudales de demanda deben ser no negativos.');
      endif

    case 'Q_INICIO_P_FIN'
      if isempty(v1)
        if silencioso, Q_inicio_m3d = 100; else
          Q_inicio_m3d = leer_numero_local( ...
            'Caudal liquido en nodo inicial [m3/d]', 100);
        endif
      else
        Q_inicio_m3d = v1;
      endif
      if isempty(v2)
        if silencioso, P_fin_bar = 20; else
          P_fin_bar = leer_numero_local('Presion en nodo final [bar]', 20);
        endif
      else
        P_fin_bar = v2;
      endif
      if ~isfinite(P_fin_bar) || P_fin_bar <= 0
        error('AOSCAD DOMINIO: presion final invalida.');
      endif
      if ~isfinite(Q_inicio_m3d) || Q_inicio_m3d < 0 || ...
          ~isfinite(Qg_sm3d) || Qg_sm3d < 0
        error('AOSCAD DOMINIO: los caudales de demanda deben ser no negativos.');
      endif

    case 'P_INICIO_P_FIN'
      if isempty(v1)
        if silencioso, P_inicio_bar = 20; else
          P_inicio_bar = leer_numero_local('Presion en nodo inicial [bar]', 20);
        endif
      else
        P_inicio_bar = v1;
      endif
      if isempty(v2)
        if silencioso, P_fin_bar = 15; else
          P_fin_bar = leer_numero_local('Presion en nodo final [bar]', 15);
        endif
      else
        P_fin_bar = v2;
      endif
      Q_fin_m3d = 100;
      if ~isfinite(P_inicio_bar) || P_inicio_bar <= 0
        error('AOSCAD DOMINIO: presion inicial invalida.');
      endif
      if ~isfinite(P_fin_bar) || P_fin_bar <= 0
        error('AOSCAD DOMINIO: presion final invalida.');
      endif
      if P_fin_bar >= P_inicio_bar
        error(['AOSCAD DOMINIO: en P_INICIO_P_FIN la presion final debe ' ...
               'ser menor que la inicial (flujo con perdidas).']);
      endif
      if ~isfinite(Qg_sm3d) || Qg_sm3d < 0
        error('AOSCAD DOMINIO: el caudal de gas debe ser no negativo.');
      endif
  endswitch
endfunction

function bc = bc_presion_local(dominio, nodo_ref, P_bar, rol, sufijo)
  bc = struct();
  bc.id = sprintf('BC-%s-%s', dominio.id, sufijo);
  bc.dominio_id = dominio.id;
  bc.nodo_ref = nodo_ref;
  bc.tipo_bc = 'PRESION';
  bc.valor = aos_aoscad_campo(P_bar * 1e5, 'Pa', ...
    'USUARIO_SELECCION_DXF', 'AOSCAD_OCTAVE', '');
  bc.unidad = 'Pa';
  bc.rol = rol;
endfunction

function bc = bc_caudal_local(dominio, nodo_ref, Q_m3d, rol, sufijo)
  bc = struct();
  bc.id = sprintf('BC-%s-%s', dominio.id, sufijo);
  bc.dominio_id = dominio.id;
  bc.nodo_ref = nodo_ref;
  bc.tipo_bc = 'CAUDAL';
  bc.valor = aos_aoscad_campo(Q_m3d / 86400, 'm3/s', ...
    'USUARIO_SELECCION_DXF', 'AOSCAD_OCTAVE', '');
  bc.unidad = 'm3/s';
  bc.rol = rol;
endfunction

function bc = bc_gas_local(dominio, nodo_ref, Qg_sm3d, rol, sufijo)
  bc = struct();
  bc.id = sprintf('BC-%s-%s', dominio.id, sufijo);
  bc.dominio_id = dominio.id;
  bc.nodo_ref = nodo_ref;
  bc.tipo_bc = 'CAUDAL_GAS_STD';
  bc.valor = aos_aoscad_campo(Qg_sm3d / 86400, 'Sm3/s', ...
    'USUARIO_SELECCION_DXF', 'AOSCAD_OCTAVE', '');
  bc.unidad = 'Sm3/s';
  bc.rol = rol;
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

function modelo = agregar_item_local(modelo, codigo, mensaje, severidad)
  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  items = {};
  if isfield(modelo.validaciones, 'items') && ~isempty(modelo.validaciones.items)
    items = modelo.validaciones.items;
    if isstruct(items), items = num2cell(items); endif
  endif
  items{end+1} = struct('codigo', codigo, 'mensaje', mensaje, ...
    'severidad', severidad);
  modelo.validaciones.items = items;
  if strcmpi(severidad, 'ERROR')
    modelo.validaciones.estado = 'ERROR';
  endif
endfunction

function v = leer_numero_local(etiqueta, defecto)
  texto = input(sprintf('%s [%.6g]: ', etiqueta, defecto), 's');
  if isempty(strtrim(texto))
    v = defecto;
  else
    v = str2double(texto);
  endif
endfunction

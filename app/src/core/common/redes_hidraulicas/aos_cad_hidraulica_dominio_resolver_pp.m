function [modelo, resultados] = aos_cad_hidraulica_dominio_resolver_pp(modelo, cfg, silencioso)
% Cierra P_INICIO_P_FIN por biseccion externa sobre Q reutilizando el solver.
% Solo SELECTED_PATH. Emite HID_MODO_PP_ITERATIVO / HID_MODO_PP_NO_CONVERGE.
  if nargin < 3, silencioso = false; endif
  if nargin < 2 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(modelo); endif

  [dominio, indice_dominio] = aos_cad_hidraulica_dominio_activo(modelo);
  if isempty(dominio)
    error('AOSCAD DOMINIO: P_INICIO_P_FIN requiere dominio activo.');
  endif
  if ~strcmpi(char(dominio.tipo), 'SELECTED_PATH') || ...
      grado_maximo_dominio_local(modelo, dominio) >= 3
    modelo = append_item_local(modelo, 'HID_MODO_PP_REQUIERE_CAMINO_SIMPLE', ...
      ['P_INICIO_P_FIN exige SELECTED_PATH sin bifurcaciones ' ...
       '(camino simple).'], 'ERROR');
    global CONFIG_ACTIVA;
    if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) && ...
        isfield(CONFIG_ACTIVA, 'cad_topologia')
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    endif
    error('AOSCAD DOMINIO: HID_MODO_PP_REQUIERE_CAMINO_SIMPLE');
  endif
  if ~isfield(dominio, 'presion_fin_bar') || ~isfinite(dominio.presion_fin_bar)
    error('AOSCAD DOMINIO: falta presion_fin_bar para P_INICIO_P_FIN.');
  endif
  if ~isfield(dominio, 'presion_inicio_bar') || ~isfinite(dominio.presion_inicio_bar)
    error('AOSCAD DOMINIO: falta presion_inicio_bar para P_INICIO_P_FIN.');
  endif

  P_obj = dominio.presion_fin_bar * 1e5;
  id_fin = char(dominio.nodo_fin);

  Q_lo = 0;
  Q_hi = max(100, valor_q_actual_local(modelo, dominio)) / 86400;  % m3/s
  f_lo = residual_pp_local(modelo, cfg, dominio, Q_lo, id_fin, P_obj);
  f_hi = residual_pp_local(modelo, cfg, dominio, Q_hi, id_fin, P_obj);

  % Expandir bracket: mayor Q => menor P_fin => residual mas negativo.
  n_expand = 0;
  while f_hi > 0 && n_expand < 20
    Q_hi = max(Q_hi * 2, Q_hi + 100/86400);
    f_hi = residual_pp_local(modelo, cfg, dominio, Q_hi, id_fin, P_obj);
    n_expand = n_expand + 1;
  endwhile
  if f_lo < 0 && f_hi < 0
    % Incluso Q=0 queda por debajo del objetivo: no hay caudal fisico.
    modelo = actualizar_q_bc_local(modelo, dominio, 0);
    [modelo, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    resid = presion_nodo_local(resultados, id_fin) - P_obj;
    modelo = append_item_local(modelo, 'HID_MODO_PP_NO_CONVERGE', ...
      sprintf(['No se pudo encerrar raiz P_fin(Q); residual=%.6g Pa ' ...
               '(P_fin demasiado baja aun en Q=0).'], resid), 'ERROR');
    if ~silencioso
      aos_cad_hidraulica_imprimir(modelo, resultados);
    endif
    return;
  endif
  if f_lo * f_hi > 0
    modelo = actualizar_q_bc_local(modelo, dominio, Q_hi * 86400);
    [modelo, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    resid = presion_nodo_local(resultados, id_fin) - P_obj;
    modelo = append_item_local(modelo, 'HID_MODO_PP_NO_CONVERGE', ...
      sprintf(['No se pudo encerrar raiz P_fin(Q)-P_obj; residual=%.6g Pa ' ...
               'tras expandir Q_hi=%.6g m3/d.'], resid, Q_hi*86400), 'ERROR');
    if ~silencioso
      aos_cad_hidraulica_imprimir(modelo, resultados);
    endif
    return;
  endif

  convergio = false;
  Q_mid = Q_hi;
  resid = f_hi;
  n_iter = 0;
  for it = 1:cfg.max_iter_presion
    n_iter = it;
    Q_mid = 0.5 * (Q_lo + Q_hi);
    modelo = actualizar_q_bc_local(modelo, dominio, Q_mid * 86400);
    [modelo, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    P_fin = presion_nodo_local(resultados, id_fin);
    resid = P_fin - P_obj;
    if abs(resid) <= cfg.tol_presion_Pa
      convergio = true;
      break;
    endif
    if resid > 0
      Q_lo = Q_mid;
    else
      Q_hi = Q_mid;
    endif
  endfor

  % Persistir Q resuelto en el dominio.
  [dominio, indice_dominio] = aos_cad_hidraulica_dominio_activo(modelo);
  if ~isempty(dominio) && indice_dominio > 0
    dominio.caudal_fin_m3d = Q_mid * 86400;
    dominio.modificado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    dominios = modelo.tablas_entrada.dominios_hidraulicos;
    if isstruct(dominios), dominios = num2cell(dominios); endif
    dominios{indice_dominio} = dominio;
    modelo.tablas_entrada.dominios_hidraulicos = dominios;
  endif

  modelo = append_item_local(modelo, 'HID_MODO_PP_ITERATIVO', ...
    sprintf(['Biseccion P-P: %d iteraciones, Q=%.6g m3/d, ' ...
             'residual_P=%.6g Pa.'], n_iter, Q_mid*86400, resid), 'INFO');
  if ~convergio
    modelo = append_item_local(modelo, 'HID_MODO_PP_NO_CONVERGE', ...
      sprintf(['P_INICIO_P_FIN no convergio en %d iteraciones; ' ...
               'ultimo residual_P=%.6g Pa (tol=%.6g).'], ...
              n_iter, resid, cfg.tol_presion_Pa), 'ERROR');
  endif

  if ~silencioso
    aos_cad_hidraulica_imprimir(modelo, resultados);
  endif
endfunction

function resid = residual_pp_local(modelo, cfg, dominio, Q_m3s, id_fin, P_obj)
  modelo2 = actualizar_q_bc_local(modelo, dominio, Q_m3s * 86400);
  [~, resultados] = aos_cad_hidraulica_resolver(modelo2, cfg, true);
  resid = presion_nodo_local(resultados, id_fin) - P_obj;
endfunction

function modelo = actualizar_q_bc_local(modelo, dominio, Q_m3d)
  bcs = modelo.tablas_entrada.condiciones_borde;
  if isstruct(bcs), bcs = num2cell(bcs); endif
  for i = 1:numel(bcs)
    bc = bcs{i};
    if ~isstruct(bc) || ~isfield(bc, 'dominio_id') || ...
        ~strcmp(char(bc.dominio_id), char(dominio.id))
      continue;
    endif
    tipo = '';
    if isfield(bc, 'tipo_bc'), tipo = upper(strtrim(char(bc.tipo_bc))); endif
    if ~any(strcmp(tipo, {'CAUDAL','CAUDAL_LIQUIDO','DEMANDA','FLOW','LIQUID_FLOW'}))
      continue;
    endif
    if ~isfield(bc, 'nodo_ref') || ...
        ~strcmp(char(bc.nodo_ref), char(dominio.nodo_fin))
      continue;
    endif
    bc.valor = aos_aoscad_campo(Q_m3d / 86400, 'm3/s', ...
      'USUARIO_SELECCION_DXF', 'AOSCAD_OCTAVE', '');
    bc.unidad = 'm3/s';
    bcs{i} = bc;
  endfor
  modelo.tablas_entrada.condiciones_borde = bcs;
endfunction

function Q_m3d = valor_q_actual_local(modelo, dominio)
  Q_m3d = 100;
  if isfield(dominio, 'caudal_fin_m3d') && isfinite(dominio.caudal_fin_m3d) && ...
      dominio.caudal_fin_m3d > 0
    Q_m3d = dominio.caudal_fin_m3d;
    return;
  endif
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
    if any(strcmp(tipo, {'CAUDAL','CAUDAL_LIQUIDO','DEMANDA','FLOW','LIQUID_FLOW'}))
      v = aos_aoscad_valor(bc.valor);
      if ~isempty(v) && isfinite(v(1))
        Q_m3d = v(1) * 86400;
      endif
    endif
  endfor
endfunction

function P = presion_nodo_local(resultados, id_nodo)
  P = NaN;
  if ~isstruct(resultados) || ~isfield(resultados, 'nodos')
    return;
  endif
  nodos = resultados.nodos;
  if isstruct(nodos), nodos = num2cell(nodos); endif
  for i = 1:numel(nodos)
    n = nodos{i};
    if isstruct(n) && isfield(n, 'id') && strcmp(char(n.id), id_nodo)
      if isfield(n, 'presion_Pa')
        P = n.presion_Pa;
      endif
      return;
    endif
  endfor
endfunction

function gmax = grado_maximo_dominio_local(modelo, dominio)
  gmax = 0;
  ids_nodos = {};
  ids_tramos = {};
  if isfield(dominio, 'nodos_seleccionados')
    ids_nodos = dominio.nodos_seleccionados;
    if ischar(ids_nodos), ids_nodos = {ids_nodos}; endif
  endif
  if isfield(dominio, 'tramos_seleccionados')
    ids_tramos = dominio.tramos_seleccionados;
    if ischar(ids_tramos), ids_tramos = {ids_tramos}; endif
  endif
  if isempty(ids_nodos) || isempty(ids_tramos)
    return;
  endif
  for i = 1:numel(ids_nodos), ids_nodos{i} = char(ids_nodos{i}); endfor
  for i = 1:numel(ids_tramos), ids_tramos{i} = char(ids_tramos{i}); endfor
  grado = zeros(1, numel(ids_nodos));
  tramos = {};
  if isfield(modelo, 'tablas_entrada') && isfield(modelo.tablas_entrada, 'tramos')
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
  if ~isempty(grado), gmax = max(grado); endif
endfunction

function modelo = append_item_local(modelo, codigo, mensaje, severidad)
  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  items = modelo.validaciones.items;
  if ~iscell(items), items = num2cell(items); endif
  % Evitar duplicar el mismo codigo PP en reintentos intermedios.
  keep = {};
  for i = 1:numel(items)
    it = items{i};
    cod = '';
    if isstruct(it) && isfield(it, 'codigo'), cod = char(it.codigo); endif
    if any(strcmp(cod, {'HID_MODO_PP_ITERATIVO', 'HID_MODO_PP_NO_CONVERGE', ...
                        'HID_MODO_PP_REQUIERE_CAMINO_SIMPLE'})) && ...
        strcmp(cod, codigo)
      continue;
    endif
    keep{end+1} = it; %#ok<AGROW>
  endfor
  keep{end+1} = struct('codigo', codigo, 'mensaje', mensaje, ...
    'severidad', severidad);
  modelo.validaciones.items = keep;
  if strcmpi(severidad, 'ERROR')
    modelo.validaciones.estado = 'ERROR';
  endif
endfunction

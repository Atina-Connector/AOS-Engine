function validaciones = aos_cad_validar_topologia(silencioso)
% AOS_CAD_VALIDAR_TOPOLOGIA Validaciones minimas sobre tablas (no visor).
% Nodos huerfanos, tramos con refs invalidas, nodos duplicados residuales,
% equipo/valvula/BC con nodo_ref invalido; STEP ligero: PRODUCT/solido.
  global CONFIG_ACTIVA;
  if nargin < 1, silencioso = false; endif

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOS CAD_TOPO: no hay modelo_aoscad para validar.');
  endif

  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  te = modelo.tablas_entrada;
  nodos = {};
  if isfield(te, 'nodos'), nodos = te.nodos; endif
  tramos = {};
  if isfield(te, 'tramos'), tramos = te.tramos; endif
  equipos = {};
  if isfield(te, 'equipos'), equipos = te.equipos; endif
  valvulas = {};
  if isfield(te, 'valvulas'), valvulas = te.valvulas; endif
  accesorios = {};
  if isfield(te, 'accesorios'), accesorios = te.accesorios; endif
  bcs = {};
  if isfield(te, 'condiciones_borde'), bcs = te.condiciones_borde; endif

  ids_nodo = {};
  for i = 1:numel(nodos)
    ids_nodo{end+1} = char(nodos{i}.id); %#ok<AGROW>
  endfor

  items = {};
  n_err = 0; n_adv = 0;

  % Grado de nodos
  grado = zeros(1, numel(nodos));
  for i = 1:numel(tramos)
    tr = tramos{i};
    for k = 1:numel(nodos)
      if strcmp(nodos{k}.id, tr.nodo_o), grado(k) = grado(k) + 1; endif
      if strcmp(nodos{k}.id, tr.nodo_d), grado(k) = grado(k) + 1; endif
    endfor
  endfor

  for i = 1:numel(nodos)
    if grado(i) == 0
      items{end+1} = item_local('NODO_HUERFANO', ...
        sprintf('Nodo %s sin tramos (grado 0)', char(nodos{i}.id)), 'ADVERTENCIA'); %#ok<AGROW>
      n_adv = n_adv + 1;
    endif
  endfor

  for i = 1:numel(tramos)
    tr = tramos{i};
    tid = char(tr.id);
    if ~ismember(char(tr.nodo_o), ids_nodo)
      items{end+1} = item_local('TRAMO_NODO_O', ...
        sprintf('Tramo %s nodo_o=%s inexistente', tid, char(tr.nodo_o)), 'ERROR'); %#ok<AGROW>
      n_err = n_err + 1;
    endif
    if ~ismember(char(tr.nodo_d), ids_nodo)
      items{end+1} = item_local('TRAMO_NODO_D', ...
        sprintf('Tramo %s nodo_d=%s inexistente', tid, char(tr.nodo_d)), 'ERROR'); %#ok<AGROW>
      n_err = n_err + 1;
    endif
  endfor

  tol = 0.05;
  if isfield(modelo, 'topologia') && isfield(modelo.topologia, 'tolerancia_m')
    tol = modelo.topologia.tolerancia_m;
  endif
  for i = 1:numel(nodos)
    for j = (i+1):numel(nodos)
      d = hypot(nodos{i}.x - nodos{j}.x, nodos{i}.y - nodos{j}.y);
      if d < tol
        items{end+1} = item_local('NODO_DUPLICADO', ...
          sprintf('Nodos %s y %s a %.4f m (< tol %.3f)', ...
            char(nodos{i}.id), char(nodos{j}.id), d, tol), 'ADVERTENCIA'); %#ok<AGROW>
        n_adv = n_adv + 1;
      endif
    endfor
  endfor

  [items, n_err] = validar_ref_local(equipos, ids_nodo, 'EQUIPO_NODO_REF', items, n_err);
  [items, n_err] = validar_ref_local(valvulas, ids_nodo, 'VALVULA_NODO_REF', items, n_err);
  [items, n_err] = validar_ref_local(accesorios, ids_nodo, 'ACCESORIO_NODO_REF', items, n_err);
  [items, n_err] = validar_ref_local(bcs, ids_nodo, 'BC_NODO_REF', items, n_err);

  cad = CONFIG_ACTIVA.cad_topologia;
  if isfield(cad, 'step_n_productos') || isfield(cad, 'step_n_solidos')
    np = 0; ns = 0;
    if isfield(cad, 'step_n_productos'), np = cad.step_n_productos; endif
    if isfield(cad, 'step_n_solidos'), ns = cad.step_n_solidos; endif
    if np == 0 && ns > 0
      items{end+1} = item_local('STEP_SIN_PRODUCT', ...
        'Solidos BREP sin PRODUCT asociados', 'ADVERTENCIA'); %#ok<AGROW>
      n_adv = n_adv + 1;
    elseif np > 0 && ns == 0
      items{end+1} = item_local('STEP_SIN_SOLIDO', ...
        'PRODUCT sin solido BREP asociado', 'ADVERTENCIA'); %#ok<AGROW>
      n_adv = n_adv + 1;
    endif
  endif

  estado = 'OK';
  if n_adv > 0, estado = 'ADVERTENCIA'; endif
  if n_err > 0, estado = 'ERROR'; endif

  prev_items = {};
  if isfield(modelo, 'validaciones') && isfield(modelo.validaciones, 'items')
    prev_items = modelo.validaciones.items;
  endif
  keep = {};
  for i = 1:numel(prev_items)
    it = prev_items{i};
    cod = '';
    if isfield(it, 'codigo'), cod = char(it.codigo); endif
    if isempty(strfind(cod, 'NODO_')) && isempty(strfind(cod, 'TRAMO_')) ...
        && isempty(strfind(cod, 'EQUIPO_')) && isempty(strfind(cod, 'VALVULA_')) ...
        && isempty(strfind(cod, 'ACCESORIO_')) && isempty(strfind(cod, 'BC_')) ...
        && isempty(strfind(cod, 'STEP_SIN'))
      keep{end+1} = it; %#ok<AGROW>
    endif
  endfor
  all_items = [keep, items];

  validaciones = struct('estado', estado, 'items', {all_items});
  modelo.validaciones = validaciones;
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

  if ~silencioso
    fprintf('\n--- VALIDACION TOPOLOGIA (tablas) ---\n');
    fprintf('estado      : %s\n', estado);
    fprintf('items       : %d (err=%d adv=%d)\n', numel(items), n_err, n_adv);
    for i = 1:min(12, numel(items))
      fprintf('  [%s] %s: %s\n', items{i}.severidad, items{i}.codigo, items{i}.mensaje);
    endfor
  endif
endfunction

function it = item_local(codigo, mensaje, severidad)
  it = struct('codigo', codigo, 'mensaje', mensaje, 'severidad', severidad);
endfunction

function [items, n_err] = validar_ref_local(filas, ids_nodo, codigo, items, n_err)
  for i = 1:numel(filas)
    f = filas{i};
    if ~isfield(f, 'nodo_ref') || isempty(f.nodo_ref), continue; endif
    if ~ismember(char(f.nodo_ref), ids_nodo)
      fid = '?';
      if isfield(f, 'id'), fid = char(f.id); endif
      items{end+1} = item_local(codigo, ...
        sprintf('%s id=%s nodo_ref=%s invalido', codigo, fid, char(f.nodo_ref)), ...
        'ERROR'); %#ok<AGROW>
      n_err = n_err + 1;
    endif
  endfor
endfunction

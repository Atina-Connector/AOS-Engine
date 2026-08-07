function red = aos_cad_hidraulica_validar_red(silencioso)
% Valida topologia, BC y restricciones del solver sin ejecutar presiones.
  if nargin < 1, silencioso = false; endif
  [modelo, cfg] = aos_cad_hidraulica_preparar_modelo(true);
  [diag, items_topo] = aos_cad_hidraulica_diagnosticar_topologia(modelo, cfg);

  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  prev = modelo.validaciones.items;
  if ~iscell(prev), prev = num2cell(prev); endif
  prev = limpiar_codigos_local(prev, 'HID_');
  modelo.validaciones.items = [prev, items_topo];
  hay_error = false;
  for i = 1:numel(items_topo)
    if isstruct(items_topo{i}) && isfield(items_topo{i}, 'severidad') && ...
        strcmpi(char(items_topo{i}.severidad), 'ERROR')
      hay_error = true;
      break;
    endif
  endfor
  if hay_error
    modelo.validaciones.estado = 'ERROR';
  elseif isempty(items_topo)
    modelo.validaciones.estado = 'OK';
  else
    modelo.validaciones.estado = 'OK';
  endif
  global CONFIG_ACTIVA;
  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) && ...
      isfield(CONFIG_ACTIVA, 'cad_topologia')
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  endif

  if ~silencioso
    fprintf('\nDIAGNOSTICO TOPOLOGIA HIDRAULICA\n');
    fprintf('Bifurcaciones   : %d\n', diag.n_bifurcaciones);
    fprintf('Topologia       : %s\n', char(diag.topologia));
    fprintf('Fuentes P       : %d\n', diag.n_fuentes_presion);
    fprintf('Lazos           : %s\n', si_no_local(diag.tiene_lazos));
    if isfield(diag, 'n_lazos_independientes')
      fprintf('Lazos indep.    : %d\n', diag.n_lazos_independientes);
    endif
    if isfield(diag, 'solver_requerido')
      fprintf('Solver req.     : %s\n', char(diag.solver_requerido));
    endif
    for i = 1:numel(items_topo)
      it = items_topo{i};
      fprintf(' [%s] %s: %s\n', char(it.severidad), char(it.codigo), char(it.mensaje));
    endfor
  endif

  red = struct();
  red.diag_topologia = diag;
  red.items_topologia = items_topo;
  if hay_error
    if ~silencioso
      fprintf('\nValidacion detenida: corrija la topologia antes de preparar la red.\n');
    endif
    return;
  endif

  red = aos_cad_hidraulica_preparar(modelo, cfg);
  red.diag_topologia = diag;
  red.items_topologia = items_topo;
  if ~silencioso
    fprintf('\nRED HIDRAULICA DEV1 VALIDADA\n');
    if isfield(red, 'dominio_hidraulico') && ~isempty(red.dominio_hidraulico)
      d = red.dominio_hidraulico;
      fprintf('Dominio         : %s (%s)\n', char(d.id), char(d.tipo));
      fprintf('Inicio -> fin   : %s -> %s\n', char(d.nodo_inicio), char(d.nodo_fin));
    else
      fprintf('Dominio         : RED COMPLETA\n');
    endif
    fprintf('Nodo de presion : %s\n', red.ids_nodo{red.root});
    fprintf('Presion raiz    : %.6g bar\n', red.P_root_Pa / 1e5);
    fprintf('Nodos activos   : %d\n', sum(red.visited));
    fprintf('Tramos activos  : %d\n', sum(red.active_edge));
    fprintf('Ql total        : %.6g m3/d\n', red.ql_total_m3s * 86400);
    fprintf('Qg total        : %.6g Sm3/d\n', red.qg_total_std_m3s * 86400);
    fprintf('Bifurcaciones   : %d\n', diag.n_bifurcaciones);
    fprintf('Topologia       : %s\n', char(diag.topologia));
    fprintf('Lazos           : %s\n', si_no_local(red.tiene_lazos));
    if isfield(red, 'n_lazos_independientes')
      fprintf('Lazos indep.    : %d\n', red.n_lazos_independientes);
    endif
    if isfield(red, 'requiere_solver_lazos') && red.requiere_solver_lazos
      fprintf('Solver req.     : HYD_LOOP\n');
    elseif isfield(diag, 'solver_requerido')
      fprintf('Solver req.     : %s\n', char(diag.solver_requerido));
    endif
  endif
endfunction

function s = si_no_local(tf)
  if tf, s = 'SI'; else, s = 'NO'; endif
endfunction

function items = limpiar_codigos_local(items, pref)
  keep = {};
  for i = 1:numel(items)
    it = items{i}; cod = '';
    if isstruct(it) && isfield(it, 'codigo'), cod = char(it.codigo); endif
    if ~strncmp(cod, pref, numel(pref)), keep{end+1} = it; endif %#ok<AGROW>
  endfor
  items = keep;
endfunction

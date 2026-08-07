function dominio = aos_cad_hidraulica_dominio_mostrar(silencioso)
% Muestra el dominio hidraulico activo y sus tramos.
  global CONFIG_ACTIVA;
  if nargin < 1
    silencioso = false;
  endif
  dominio = [];
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    if ~silencioso
      fprintf('No hay modelo AOSCAD activo.\n');
    endif
    return;
  endif
  [dominio, ~] = aos_cad_hidraulica_dominio_activo( ...
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad);
  if isempty(dominio)
    if ~silencioso
      fprintf('Dominio hidraulico: RED COMPLETA (sin seleccion).\n');
    endif
    return;
  endif
  if silencioso
    return;
  endif

  fprintf('\n--- DOMINIO HIDRAULICO ACTIVO ---\n');
  fprintf('ID               : %s\n', char(dominio.id));
  fprintf('Tipo             : %s\n', char(dominio.tipo));
  fprintf('Estado           : %s\n', char(dominio.estado));
  fprintf('Inicio           : %s\n', char(dominio.nodo_inicio));
  fprintf('Fin              : %s\n', char(dominio.nodo_fin));
  fprintf('Caminos hallados : %d\n', ...
    numero_local(dominio, 'cantidad_caminos_detectados', 1));
  fprintf('Longitud         : %.6g m\n', ...
    numero_local(dominio, 'longitud_total_m', NaN));
  fprintf('Condiciones      : %s\n', ...
    texto_local(dominio, 'condicion_extremos', 'PENDIENTE'));
  fprintf('Estado solver    : %s\n', ...
    texto_local(dominio, 'estado_solver', ''));
  tramos = celda_local(dominio, 'tramos_seleccionados');
  nodos = celda_local(dominio, 'nodos_seleccionados');
  fprintf('Nodos (%d)       : %s\n', numel(nodos), unir_local(nodos, ' -> '));
  fprintf('Tramos (%d)      : %s\n', numel(tramos), unir_local(tramos, ', '));
endfunction

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && isnumeric(s.(campo)) && ...
      ~isempty(s.(campo))
    v = s.(campo)(1);
  endif
endfunction

function v = texto_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && ~isempty(s.(campo))
    v = char(s.(campo));
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

function txt = unir_local(c, separador)
  txt = '';
  for i = 1:numel(c)
    if i > 1
      txt = [txt separador];
    endif
    txt = [txt char(c{i})];
  endfor
endfunction

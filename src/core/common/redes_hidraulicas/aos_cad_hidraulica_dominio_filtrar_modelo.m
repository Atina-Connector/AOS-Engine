function [modelo_red, dominio] = aos_cad_hidraulica_dominio_filtrar_modelo(modelo)
% Crea una vista local del modelo limitada al dominio hidraulico activo.
% No altera las tablas completas almacenadas en el .aoscad.
  modelo_red = modelo;
  [dominio, ~] = aos_cad_hidraulica_dominio_activo(modelo);
  if isempty(dominio)
    % Las condiciones ligadas a dominios historicos no se aplican a la red completa.
    if isfield(modelo_red, 'tablas_entrada') && ...
        isfield(modelo_red.tablas_entrada, 'condiciones_borde')
      bcs = filas_local(modelo_red.tablas_entrada, 'condiciones_borde');
      globales = {};
      for i = 1:numel(bcs)
        bc = bcs{i};
        if ~isstruct(bc) || ~isfield(bc, 'dominio_id') || isempty(bc.dominio_id)
          globales{end+1} = bc;
        endif
      endfor
      modelo_red.tablas_entrada.condiciones_borde = globales;
    endif
    return;
  endif

  if ~isfield(dominio, 'estado') || ...
      ~strcmpi(char(dominio.estado), 'CONFIRMADO')
    error('AOSCAD DOMINIO: el dominio activo no esta confirmado.');
  endif
  ids_nodos = celda_texto_local(dominio, 'nodos_seleccionados');
  ids_tramos = celda_texto_local(dominio, 'tramos_seleccionados');
  if isempty(ids_nodos) || isempty(ids_tramos)
    error('AOSCAD DOMINIO: dominio activo sin nodos o tramos seleccionados.');
  endif

  te = modelo.tablas_entrada;
  te.nodos = filtrar_id_local(filas_local(te, 'nodos'), ids_nodos);
  te.tramos = filtrar_id_local(filas_local(te, 'tramos'), ids_tramos);

  bcs = filas_local(te, 'condiciones_borde');
  bcs_dominio = {};
  bcs_legacy = {};
  for i = 1:numel(bcs)
    bc = bcs{i};
    if ~isstruct(bc) || ~isfield(bc, 'nodo_ref')
      continue;
    endif
    if ~any(strcmp(ids_nodos, char(bc.nodo_ref)))
      continue;
    endif
    if isfield(bc, 'dominio_id') && ~isempty(bc.dominio_id)
      if isfield(dominio, 'id') && ...
          strcmp(char(bc.dominio_id), char(dominio.id))
        bcs_dominio{end+1} = bc;
      endif
    else
      bcs_legacy{end+1} = bc;
    endif
  endfor
  if ~isempty(bcs_dominio)
    te.condiciones_borde = bcs_dominio;
  else
    te.condiciones_borde = bcs_legacy;
  endif

  modelo_red.tablas_entrada = te;
  if ~isfield(modelo_red, 'simulacion') || ...
      ~isstruct(modelo_red.simulacion)
    modelo_red.simulacion = struct();
  endif
  modelo_red.simulacion.dominio_hidraulico_efectivo = dominio;
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

function out = filtrar_id_local(rows, ids)
  out = {};
  for i = 1:numel(rows)
    r = rows{i};
    if isstruct(r) && isfield(r, 'id') && ...
        any(strcmp(ids, char(r.id)))
      out{end+1} = r;
    endif
  endfor
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
      c{end+1} = char(valor{i});
    endfor
  elseif isstruct(valor)
    for i = 1:numel(valor)
      if isfield(valor(i), 'id')
        c{end+1} = char(valor(i).id);
      endif
    endfor
  endif
endfunction

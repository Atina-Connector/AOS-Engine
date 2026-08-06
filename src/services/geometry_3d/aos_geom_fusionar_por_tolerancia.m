function [nodos_out, mapa] = aos_geom_fusionar_por_tolerancia(nodos, tol)
% AOS_GEOM_FUSIONAR_POR_TOLERANCIA Fusiona nodos por proximidad 2D.
% Preferir estado CONFIRMADA; propagar tipo distinto de JUNCTION.
% mapa.(id_original) = id_canonico (remapeo).
  nodos_out = {};
  mapa = struct();
  if nargin < 2 || isempty(tol), tol = 0.05; endif
  if isempty(nodos), return; endif

  for i = 1:numel(nodos)
    n = nodos{i};
    found = '';
    for j = 1:numel(nodos_out)
      if hypot(nodos_out{j}.x - n.x, nodos_out{j}.y - n.y) <= tol
        found = nodos_out{j}.id;
        % Preferir CONFIRMADA
        if isfield(n, 'estado_conexion') && strcmp(n.estado_conexion, 'CONFIRMADA')
          nodos_out{j}.estado_conexion = 'CONFIRMADA'; %#ok<AGROW>
          if isfield(n, 'tipo') && ~strcmp(n.tipo, 'JUNCTION')
            nodos_out{j}.tipo = n.tipo; %#ok<AGROW>
          endif
        endif
        break;
      endif
    endfor
    if isempty(found)
      nodos_out{end+1} = n; %#ok<AGROW>
      mapa.(n.id) = n.id;
    else
      mapa.(n.id) = found;
    endif
  endfor
endfunction

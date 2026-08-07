function [idx, dmin] = aos_geom_punto_mas_cercano(puntos, x, y, tol)
% AOS_GEOM_PUNTO_MAS_CERCANO Indice 1-based del punto mas cercano a (x,y).
% puntos: cell de structs (.x/.y) o matriz Nx2/Nx3.
% Si tol vacio o Inf no filtra; si dmin > tol, idx = [].
  idx = [];
  dmin = Inf;
  if nargin < 4, tol = []; endif

  [px, py, n] = extraer_xy_local(puntos);
  if n < 1, return; endif

  best = [];
  for i = 1:n
    d = hypot(px(i) - x, py(i) - y);
    if d < dmin
      dmin = d;
      best = i;
    endif
  endfor

  if isempty(best), return; endif
  if ~isempty(tol) && isfinite(tol) && dmin > tol
    return;
  endif
  idx = best;
endfunction

function [px, py, n] = extraer_xy_local(puntos)
  px = [];
  py = [];
  n = 0;
  if iscell(puntos)
    n = numel(puntos);
    px = NaN(n, 1);
    py = NaN(n, 1);
    for i = 1:n
      p = puntos{i};
      if isstruct(p) && isfield(p, 'x') && isfield(p, 'y')
        px(i) = p.x;
        py(i) = p.y;
      elseif isnumeric(p) && numel(p) >= 2
        px(i) = p(1);
        py(i) = p(2);
      endif
    endfor
  elseif isnumeric(puntos) && ~isempty(puntos) && size(puntos, 2) >= 2
    n = size(puntos, 1);
    px = puntos(:, 1);
    py = puntos(:, 2);
  endif
endfunction

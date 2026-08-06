function [bbox, centroide] = aos_geom_bbox(puntos)
% AOS_GEOM_BBOX Bounding box y centroide de un conjunto de puntos.
% puntos: cell de structs (.x/.y[.z]) o matriz Nx2/Nx3.
% bbox: struct xmin/xmax/ymin/ymax[/zmin/zmax]; centroide: [cx cy] o [cx cy cz].
  bbox = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN);
  centroide = [NaN, NaN];
  [xyz, n, tiene_z] = extraer_xyz_local(puntos);
  if n < 1, return; endif

  xs = xyz(:, 1);
  ys = xyz(:, 2);
  bbox.xmin = min(xs);
  bbox.xmax = max(xs);
  bbox.ymin = min(ys);
  bbox.ymax = max(ys);
  if tiene_z
    zs = xyz(:, 3);
    bbox.zmin = min(zs);
    bbox.zmax = max(zs);
    centroide = [mean(xs), mean(ys), mean(zs)];
  else
    centroide = [mean(xs), mean(ys)];
  endif
endfunction

function [xyz, n, tiene_z] = extraer_xyz_local(puntos)
  xyz = [];
  n = 0;
  tiene_z = false;
  if iscell(puntos)
    n = numel(puntos);
    if n < 1, return; endif
    xyz = NaN(n, 3);
    for i = 1:n
      p = puntos{i};
      if isstruct(p)
        if isfield(p, 'x'), xyz(i, 1) = p.x; endif
        if isfield(p, 'y'), xyz(i, 2) = p.y; endif
        if isfield(p, 'z') && isfinite(p.z)
          xyz(i, 3) = p.z;
          tiene_z = true;
        else
          xyz(i, 3) = 0;
        endif
      elseif isnumeric(p) && numel(p) >= 2
        xyz(i, 1) = p(1);
        xyz(i, 2) = p(2);
        if numel(p) >= 3 && isfinite(p(3))
          xyz(i, 3) = p(3);
          tiene_z = true;
        else
          xyz(i, 3) = 0;
        endif
      endif
    endfor
    if ~tiene_z
      xyz = xyz(:, 1:2);
    endif
  elseif isnumeric(puntos) && ~isempty(puntos) && size(puntos, 2) >= 2
    n = size(puntos, 1);
    if size(puntos, 2) >= 3
      xyz = puntos(:, 1:3);
      tiene_z = true;
    else
      xyz = puntos(:, 1:2);
    endif
  endif
endfunction

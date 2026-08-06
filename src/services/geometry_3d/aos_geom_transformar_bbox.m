function bbox_out = aos_geom_transformar_bbox(bbox_in, T)
% AOS_GEOM_TRANSFORMAR_BBOX Transforma AABB por T 4x4 (8 vertices) y recalcula.
% Correcto bajo rotacion; no transforma solo dos esquinas.
  bbox_out = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  if nargin < 1 || isempty(bbox_in) || ~isstruct(bbox_in), return; endif
  if nargin < 2 || isempty(T), T = eye(4); endif

  req = {'xmin', 'xmax', 'ymin', 'ymax'};
  for i = 1:numel(req)
    if ~isfield(bbox_in, req{i}) || ~isfinite(bbox_in.(req{i}))
      return;
    endif
  endfor
  zmin = 0; zmax = 0;
  if isfield(bbox_in, 'zmin') && isfinite(bbox_in.zmin), zmin = bbox_in.zmin; endif
  if isfield(bbox_in, 'zmax') && isfinite(bbox_in.zmax), zmax = bbox_in.zmax; endif
  if (~isfield(bbox_in, 'zmin') || ~isfinite(bbox_in.zmin)) && ...
      (~isfield(bbox_in, 'zmax') || ~isfinite(bbox_in.zmax))
    % 2D: mantener z=0
    zmin = 0; zmax = 0;
  endif

  xs = [bbox_in.xmin, bbox_in.xmax];
  ys = [bbox_in.ymin, bbox_in.ymax];
  zs = [zmin, zmax];
  pts = zeros(8, 3);
  k = 0;
  for ix = 1:2
    for iy = 1:2
      for iz = 1:2
        k = k + 1;
        pts(k, :) = [xs(ix), ys(iy), zs(iz)];
      endfor
    endfor
  endfor

  T = double(T);
  if size(T, 1) < 4 || size(T, 2) < 4
    T4 = eye(4);
    r = min(3, size(T, 1));
    c = min(3, size(T, 2));
    T4(1:r, 1:c) = T(1:r, 1:c);
    T = T4;
  endif

  ones_col = ones(8, 1);
  homog = [pts, ones_col]';
  out = (T * homog)';
  xyz = out(:, 1:3);

  bbox_out.xmin = min(xyz(:, 1));
  bbox_out.xmax = max(xyz(:, 1));
  bbox_out.ymin = min(xyz(:, 2));
  bbox_out.ymax = max(xyz(:, 2));
  bbox_out.zmin = min(xyz(:, 3));
  bbox_out.zmax = max(xyz(:, 3));
endfunction

function [T, adv] = aos_geom_axis2_matriz(origen_xyz, eje_z, dir_x)
% AOS_GEOM_AXIS2_MATRIZ Matriz homogenea 4x4 desde AXIS2_PLACEMENT_3D.
% Ortonormaliza por Gram-Schmidt. Independiente del formato STEP.
  adv = {};
  if nargin < 1 || isempty(origen_xyz), origen_xyz = [0, 0, 0]; endif
  if nargin < 2 || isempty(eje_z), eje_z = [0, 0, 1]; endif
  if nargin < 3 || isempty(dir_x), dir_x = [1, 0, 0]; endif

  o = reshape(double(origen_xyz(1:min(3, numel(origen_xyz)))), 1, []);
  if numel(o) < 3, o = [o, zeros(1, 3 - numel(o))]; endif
  z = reshape(double(eje_z(1:min(3, numel(eje_z)))), 1, []);
  if numel(z) < 3, z = [z, zeros(1, 3 - numel(z))]; endif
  x = reshape(double(dir_x(1:min(3, numel(dir_x)))), 1, []);
  if numel(x) < 3, x = [x, zeros(1, 3 - numel(x))]; endif

  nz = norm(z);
  nx = norm(x);
  if nz < 1e-15 || nx < 1e-15
    adv{end+1} = 'AXIS2_DEGENERADO'; %#ok<AGROW>
    if nz < 1e-15, z = [0, 0, 1]; nz = 1; endif
    if nx < 1e-15, x = [1, 0, 0]; nx = 1; endif
  endif
  z = z / nz;
  x = x / nx;

  % Proyectar x ortogonal a z
  x_proj = x - dot(x, z) * z;
  nxp = norm(x_proj);
  if nxp < 1e-12
    % Elegir eje auxiliar
    if abs(z(1)) < 0.9
      aux = [1, 0, 0];
    else
      aux = [0, 1, 0];
    endif
    x_proj = cross(z, aux);
    nxp = norm(x_proj);
    adv{end+1} = 'AXIS2_NO_ORTOGONAL'; %#ok<AGROW>
  else
    % Si habia componente no ortogonal significativa
    if abs(dot(x, z)) > 1e-8
      adv{end+1} = 'AXIS2_NO_ORTOGONAL'; %#ok<AGROW>
    endif
  endif
  x = x_proj / nxp;
  y = cross(z, x);
  ny = norm(y);
  if ny < 1e-15
    adv{end+1} = 'AXIS2_DEGENERADO'; %#ok<AGROW>
    y = [0, 1, 0];
  else
    y = y / ny;
  endif

  R = [x(:), y(:), z(:)];
  if det(R) < 0
    y = -y;
    R = [x(:), y(:), z(:)];
  endif

  T = eye(4);
  T(1:3, 1:3) = R;
  T(1:3, 4) = o(:);
endfunction

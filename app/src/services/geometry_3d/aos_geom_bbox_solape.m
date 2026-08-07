function [hay_solape, volumen_solape_m3, distancia_m] = aos_geom_bbox_solape(bbox_a, bbox_b)
% AOS_GEOM_BBOX_SOLAPE Solape AABB, volumen de solape [m3] y distancia minima [m].
% Servicio puro: sin dependencias CAD ni graficos.
% hay_solape: true solo si el volumen de interseccion es estrictamente > 0.
% distancia_m: 0 si hay solape de volumen; separacion euclidea de gaps si no.
% Si alguna bbox es indeterminada (NaN/Inf), hay_solape=false, volumen=0,
% distancia_m=Inf (el llamador CAD debe emitir item, nunca asumir 0).
  hay_solape = false;
  volumen_solape_m3 = 0;
  distancia_m = Inf;

  [ok_a, a] = normalizar_bbox_local(bbox_a);
  [ok_b, b] = normalizar_bbox_local(bbox_b);
  if ~ok_a || ~ok_b
    return;
  endif

  ox = min(a.xmax, b.xmax) - max(a.xmin, b.xmin);
  oy = min(a.ymax, b.ymax) - max(a.ymin, b.ymin);
  oz = min(a.zmax, b.zmax) - max(a.zmin, b.zmin);

  if ox > 0 && oy > 0 && oz > 0
    hay_solape = true;
    volumen_solape_m3 = ox * oy * oz;
    distancia_m = 0;
    return;
  endif

  dx = max(0, -ox);
  dy = max(0, -oy);
  dz = max(0, -oz);
  distancia_m = sqrt(dx * dx + dy * dy + dz * dz);
  volumen_solape_m3 = 0;
  hay_solape = false;
endfunction

function [ok, bb] = normalizar_bbox_local(bbox_in)
  ok = false;
  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
  if nargin < 1 || isempty(bbox_in) || ~isstruct(bbox_in)
    return;
  endif
  req = {'xmin', 'xmax', 'ymin', 'ymax'};
  for i = 1:numel(req)
    if ~isfield(bbox_in, req{i}) || ~isfinite(bbox_in.(req{i}))
      return;
    endif
    bb.(req{i}) = double(bbox_in.(req{i})(1));
  endfor
  zmin = 0; zmax = 0;
  if isfield(bbox_in, 'zmin') && isfinite(bbox_in.zmin)
    zmin = double(bbox_in.zmin(1));
  endif
  if isfield(bbox_in, 'zmax') && isfinite(bbox_in.zmax)
    zmax = double(bbox_in.zmax(1));
  endif
  if isfield(bbox_in, 'zmin') && ~isfinite(bbox_in.zmin)
    return;
  endif
  if isfield(bbox_in, 'zmax') && ~isfinite(bbox_in.zmax)
    return;
  endif
  bb.zmin = zmin;
  bb.zmax = zmax;
  if bb.xmin > bb.xmax || bb.ymin > bb.ymax || bb.zmin > bb.zmax
    return;
  endif
  ok = true;
endfunction

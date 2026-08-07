function ok = test_aos_geom_servicios()
% TEST_AOS_GEOM_SERVICIOS Equivalencia punto cercano / fusion / bbox + bordes.
  ok = true;
  cand = fileparts(mfilename('fullpath'));
  while ~isempty(cand) && exist(fullfile(cand, 'AOS.m'), 'file') ~= 2
    parent = fileparts(cand);
    if strcmp(parent, cand), break; endif
    cand = parent;
  endwhile
  root = cand;
  addpath(fullfile(root, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n=== test_aos_geom_servicios ===\n');

  % --- Punto mas cercano: equivalencia con referencia hypot ---
  pts = { ...
    struct('x', 0, 'y', 0), ...
    struct('x', 10, 'y', 0), ...
    struct('x', 5, 'y', 5)};
  [idx_ref, d_ref] = ref_punto_cercano_local(pts, 4.9, 4.8, []);
  [idx_srv, d_srv] = aos_geom_punto_mas_cercano(pts, 4.9, 4.8, []);
  ok = check_local(ok, isequal(idx_ref, idx_srv) && abs(d_ref - d_srv) < 1e-15, ...
    'punto cercano equivale a referencia');

  % Empate de distancia: gana el primero (indice menor)
  pts_emp = {struct('x', 0, 'y', 0), struct('x', 2, 'y', 0)};
  [idx_e, ~] = aos_geom_punto_mas_cercano(pts_emp, 1, 0, []);
  ok = check_local(ok, idx_e == 1, 'empate distancia: primer indice');

  % Tolerancia: fuera de tol -> vacio
  [idx_t, d_t] = aos_geom_punto_mas_cercano(pts, 100, 100, 1.0);
  ok = check_local(ok, isempty(idx_t) && isfinite(d_t), 'tol: fuera de rango idx vacio');

  % Tolerancia cero: solo distancia exacta 0
  [idx_z, ~] = aos_geom_punto_mas_cercano(pts, 0, 0, 0);
  ok = check_local(ok, idx_z == 1, 'tol cero: hit exacto');
  [idx_z2, ~] = aos_geom_punto_mas_cercano(pts, 0.001, 0, 0);
  ok = check_local(ok, isempty(idx_z2), 'tol cero: miss');

  % Lista vacia
  [idx_v, d_v] = aos_geom_punto_mas_cercano({}, 1, 1, []);
  ok = check_local(ok, isempty(idx_v) && isinf(d_v), 'lista vacia punto cercano');

  % Matriz Nx2
  M = [0 0; 3 4; 10 0];
  [idx_m, d_m] = aos_geom_punto_mas_cercano(M, 0, 0, []);
  ok = check_local(ok, idx_m == 1 && abs(d_m) < 1e-15, 'matriz Nx2 punto cercano');

  % --- Fusion por tolerancia: equivalencia con referencia ---
  nodos = { ...
    struct('id', 'N1', 'x', 0, 'y', 0, 'tipo', 'JUNCTION', 'estado_conexion', 'INFERIDA_POR_PROXIMIDAD'), ...
    struct('id', 'N2', 'x', 0.02, 'y', 0, 'tipo', 'WELL', 'estado_conexion', 'CONFIRMADA'), ...
    struct('id', 'N3', 'x', 5, 'y', 0, 'tipo', 'JUNCTION', 'estado_conexion', 'INFERIDA_POR_PROXIMIDAD')};
  [out_ref, map_ref] = ref_fusionar_local(nodos, 0.05);
  [out_srv, map_srv] = aos_geom_fusionar_por_tolerancia(nodos, 0.05);
  ok = check_local(ok, numel(out_ref) == numel(out_srv), 'fusion: mismo numero nodos');
  ok = check_local(ok, numel(out_srv) == 2, 'fusion: N1+N2 colapsan');
  ok = check_local(ok, strcmp(map_ref.N1, map_srv.N1) && strcmp(map_ref.N2, map_srv.N2) ...
    && strcmp(map_ref.N3, map_srv.N3), 'fusion: mismo mapa remapeo');
  if numel(out_srv) >= 1
    ok = check_local(ok, strcmp(out_srv{1}.estado_conexion, 'CONFIRMADA'), ...
      'fusion: preferir CONFIRMADA');
    ok = check_local(ok, strcmp(out_srv{1}.tipo, 'WELL'), ...
      'fusion: propagar tipo distinto JUNCTION');
  endif

  [out_empty, map_empty] = aos_geom_fusionar_por_tolerancia({}, 0.05);
  ok = check_local(ok, isempty(out_empty) && isempty(fieldnames(map_empty)), ...
    'fusion lista vacia');

  % tol cero: no fusiona salvo coincidencia exacta
  nodos2 = { ...
    struct('id', 'A', 'x', 0, 'y', 0, 'tipo', 'JUNCTION', 'estado_conexion', 'INFERIDA_POR_PROXIMIDAD'), ...
    struct('id', 'B', 'x', 1e-9, 'y', 0, 'tipo', 'JUNCTION', 'estado_conexion', 'INFERIDA_POR_PROXIMIDAD')};
  [out_z, ~] = aos_geom_fusionar_por_tolerancia(nodos2, 0);
  ok = check_local(ok, numel(out_z) == 2, 'fusion tol cero: no colapsa');

  % --- BBox ---
  pts_bb = {struct('x', 1, 'y', 2, 'z', 3), struct('x', 5, 'y', 0, 'z', 1)};
  [bb, c] = aos_geom_bbox(pts_bb);
  ok = check_local(ok, abs(bb.xmin - 1) < 1e-15 && abs(bb.xmax - 5) < 1e-15 ...
    && abs(bb.ymin - 0) < 1e-15 && abs(bb.ymax - 2) < 1e-15, 'bbox xy');
  ok = check_local(ok, isfield(bb, 'zmin') && abs(bb.zmin - 1) < 1e-15 ...
    && abs(bb.zmax - 3) < 1e-15, 'bbox z');
  ok = check_local(ok, abs(c(1) - 3) < 1e-15 && abs(c(2) - 1) < 1e-15 ...
    && abs(c(3) - 2) < 1e-15, 'centroide 3d');

  [bb_v, c_v] = aos_geom_bbox({});
  ok = check_local(ok, isnan(bb_v.xmin) && all(isnan(c_v)), 'bbox lista vacia');

  if ok
    fprintf('RESULTADO: test_aos_geom_servicios APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_geom_servicios NO APROBADO\n');
  endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO  %s\n', msg);
    ok = false;
  endif
endfunction

function [idx, dmin] = ref_punto_cercano_local(puntos, x, y, tol)
  idx = [];
  dmin = Inf;
  best = [];
  for i = 1:numel(puntos)
    d = hypot(puntos{i}.x - x, puntos{i}.y - y);
    if d < dmin
      dmin = d;
      best = i;
    endif
  endfor
  if isempty(best), return; endif
  if ~isempty(tol) && isfinite(tol) && dmin > tol, return; endif
  idx = best;
endfunction

function [nodos_out, mapa] = ref_fusionar_local(nodos, tol)
  nodos_out = {};
  mapa = struct();
  for i = 1:numel(nodos)
    n = nodos{i};
    found = '';
    for j = 1:numel(nodos_out)
      if hypot(nodos_out{j}.x - n.x, nodos_out{j}.y - n.y) <= tol
        found = nodos_out{j}.id;
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

function ok = test_aos_asset_identity()
% TEST_AOS_ASSET_IDENTITY Determinismo, unicidad, extremos, handle, colision, contrato.
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

  fprintf('\n=== test_aos_asset_identity ===\n');

  % --- Determinismo: dos llamadas identicas ---
  fila = struct('x', 1.23456, 'y', 2.34567, 'z', 0, 'id', 'N001');
  [a1, c1, ~] = aos_asset_id_generar('NODO', fila, 'nodos', struct());
  [a2, c2, ~] = aos_asset_id_generar('NODO', fila, 'nodos', struct());
  ok = check_local(ok, strcmp(a1, a2) && strcmp(c1, c2), 'determinismo misma sesion');

  % Simular "otra sesion": clear functions + rehash + regenerar
  clear functions;
  rehash();
  iniciar_aos(true);
  [a3, ~, ~] = aos_asset_id_generar('NODO', fila, 'nodos', struct());
  ok = check_local(ok, strcmp(a1, a3), 'determinismo tras clear functions (sesion simulada)');

  % --- Extremos de tramo ordenados (direccion no cambia identidad) ---
  t_ab = struct('x1', 0, 'y1', 0, 'x2', 10, 'y2', 5, 'id', 'T001');
  t_ba = struct('x1', 10, 'y1', 5, 'x2', 0, 'y2', 0, 'id', 'T002');
  [aid_ab, cab, ~] = aos_asset_id_generar('TRAMO', t_ab, 'tramos', struct());
  [aid_ba, cba, ~] = aos_asset_id_generar('TRAMO', t_ba, 'tramos', struct());
  ok = check_local(ok, strcmp(cab, cba), 'clave tramo independiente de orden extremos');
  ok = check_local(ok, strcmp(aid_ab, aid_ba), 'asset_id tramo independiente de orden extremos');

  % --- Insensibilidad al handle DXF ---
  f_h1 = struct('x', 3, 'y', 4, 'z', 0, 'id', 'N010', 'handle', 'ABCD');
  f_h2 = struct('x', 3, 'y', 4, 'z', 0, 'id', 'N010', 'handle', 'FFFF');
  [ah1, ~, ~] = aos_asset_id_generar('NODO', f_h1, 'nodos', struct());
  [ah2, ~, ~] = aos_asset_id_generar('NODO', f_h2, 'nodos', struct());
  ok = check_local(ok, strcmp(ah1, ah2), 'asset_id insensible a handle DXF');

  % --- Unicidad: claves distintas => asset_id distintos (misma clave puede compartir) ---
  dxf_b = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_bloques.dxf');
  if exist(dxf_b, 'file') == 2
    global CONFIG_ACTIVA;
    CONFIG_ACTIVA = struct();
    if aos_cad_importar_dxf(dxf_b, true)
      m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      map_t = { ...
        'nodos', 'NODO'; 'tramos', 'TRAMO'; 'equipos', 'EQUIPO'; ...
        'valvulas', 'VALVULA'; 'accesorios', 'ACCESORIO'; ...
        'condiciones_borde', 'BC'; 'camaras', 'CAMARA'; ...
        'ramales', 'RAMAL'; 'accesos', 'ACCESO'};
      claves = {};
      aids = {};
      for t = 1:size(map_t, 1)
        nom = map_t{t, 1}; tipo = map_t{t, 2};
        if ~isfield(m.tablas_entrada, nom), continue; endif
        filas = m.tablas_entrada.(nom);
        for i = 1:numel(filas)
          f = filas{i};
          if ~isfield(f, 'asset_id') || isempty(f.asset_id), continue; endif
          [~, clave, ~] = aos_asset_id_generar(tipo, f, nom, struct());
          claves{end+1} = [tipo '|' clave]; %#ok<AGROW>
          aids{end+1} = char(f.asset_id); %#ok<AGROW>
        endfor
      endfor
      ok = check_local(ok, numel(aids) >= 1, 'fixture bloques produce asset_id');
      % Por cada clave distinta, un solo asset_id; claves distintas no colisionan
      [ucl, ~, ic] = unique(claves, 'stable');
      colision_hash = false;
      for u = 1:numel(ucl)
        idxs = find(ic == u);
        aid_u = unique(aids(idxs));
        if numel(aid_u) ~= 1
          colision_hash = true;
        endif
      endfor
      ok = check_local(ok, ~colision_hash, 'misma clave => mismo asset_id');
      % Claves distintas no deben compartir asset_id (hash collision silenciosa)
      aid_por_clave = {};
      for u = 1:numel(ucl)
        idxs = find(ic == u);
        aid_por_clave{end+1} = aids{idxs(1)}; %#ok<AGROW>
      endfor
      ok = check_local(ok, numel(unique(aid_por_clave)) == numel(aid_por_clave), ...
        'unicidad: claves distintas => asset_id distintos');
    else
      fprintf(2, 'FALLO  import demo_aos_bloques\n');
      ok = false;
    endif
  else
    fprintf(2, 'FALLO  falta demo_aos_bloques.dxf\n');
    ok = false;
  endif

  % --- Colision forzada ASSET_ID_COLISION (hash sombreado temporal) ---
  ok_col = probar_colision_forzada_local();
  ok = ok && ok_col;

  % --- Validacion de contrato ---
  act_ok = struct( ...
    'asset_id', 'AOS-NODO-abcdef12', ...
    'asset_type', 'NODO', ...
    'source', 'DXF', ...
    'validation_status', 'OK');
  [vok, ~] = aos_asset_identity_validar(act_ok);
  ok = check_local(ok, vok, 'activo completo valida contra contrato');

  act_bad = struct('asset_id', 'AOS-NODO-abcdef12', 'asset_type', 'NODO');
  [vbad, items_bad] = aos_asset_identity_validar(act_bad);
  ok = check_local(ok, ~vbad, 'activo incompleto no valida');
  hay_req = false;
  for i = 1:numel(items_bad)
    if isfield(items_bad{i}, 'codigo') && strcmp(items_bad{i}.codigo, 'ASSET_IDENTITY_REQUIRED')
      hay_req = true;
    endif
  endfor
  ok = check_local(ok, hay_req, 'activo incompleto emite ASSET_IDENTITY_REQUIRED');

  if ok
    fprintf('RESULTADO: test_aos_asset_identity APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_asset_identity NO APROBADO\n');
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

function ok = probar_colision_forzada_local()
  ok = true;
  tmp = tempname();
  mkdir(tmp);
  fid = fopen(fullfile(tmp, 'aos_asset_hash.m'), 'wt');
  if fid < 0
    fprintf(2, 'FALLO  no se pudo crear stub hash\n');
    ok = false;
    return;
  endif
  fprintf(fid, 'function h = aos_asset_hash(texto, n_hex)\n');
  fprintf(fid, '  if nargin < 2 || isempty(n_hex), n_hex = 8; endif\n');
  fprintf(fid, '  h = repmat(''a'', 1, max(1, round(double(n_hex(1)))));\n');
  fprintf(fid, 'endfunction\n');
  fclose(fid);

  addpath(tmp, '-begin');
  clear aos_asset_hash aos_asset_id_generar aos_asset_registro;
  rehash();

  modelo = struct();
  modelo.tablas_entrada = struct();
  modelo.tablas_entrada.nodos = { ...
    struct('x', 1, 'y', 1, 'z', 0, 'id', 'N_A'), ...
    struct('x', 9, 'y', 9, 'z', 0, 'id', 'N_B')};
  [reg, items] = aos_asset_registro(modelo);

  hay = false;
  for i = 1:numel(items)
    if isfield(items{i}, 'codigo') && strcmp(items{i}.codigo, 'ASSET_ID_COLISION')
      hay = true;
    endif
  endfor
  ok = check_local(ok, hay, 'ASSET_ID_COLISION forzada detectada');
  ok = check_local(ok, numel(reg) == 2, 'registro con 2 activos tras desambiguacion');
  if numel(reg) == 2
    ok = check_local(ok, ~strcmp(reg{1}.asset_id, reg{2}.asset_id), ...
      'asset_id desambiguados distintos');
  endif

  rmpath(tmp);
  clear aos_asset_hash aos_asset_id_generar aos_asset_registro;
  rehash();
  try
    delete(fullfile(tmp, 'aos_asset_hash.m'));
    rmdir(tmp);
  catch
  end_try_catch
endfunction

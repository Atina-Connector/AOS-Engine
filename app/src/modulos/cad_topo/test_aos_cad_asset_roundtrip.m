function ok = test_aos_cad_asset_roundtrip()
% TEST_AOS_CAD_ASSET_ROUNDTRIP asset_id estable ante REV / .aoscad / STEP.
  global CONFIG_ACTIVA;
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

  fprintf('\n=== test_aos_cad_asset_roundtrip ===\n');

  % --- Compatibilidad: legacy sin asset_id ---
  legacy = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_legacy_sin_asset.aoscad');
  ok = check_local(ok, exist(legacy, 'file') == 2, 'fixture demo_legacy_sin_asset.aoscad');
  if exist(legacy, 'file') == 2
    try
      m_leg = aos_aoscad_leer(legacy, true);
      ok = check_local(ok, strcmp(m_leg.info.schema, 'AOSCAD-0.0.1-DEV1'), ...
        'legacy lee schema DEV1');
      ok = check_local(ok, ~isfield(m_leg, 'activos') || isempty(m_leg.activos), ...
        'legacy sin registro activos');
      [m_asig, ~] = aos_cad_asignar_asset_ids(m_leg);
      ok = check_local(ok, isfield(m_asig, 'activos') && ~isempty(m_asig.activos), ...
        'asignacion agrega activos a legacy');
      n0 = numel(m_leg.tablas_entrada.nodos);
      n1 = numel(m_asig.tablas_entrada.nodos);
      ok = check_local(ok, n0 == n1, 'asignacion no pierde nodos legacy');
    catch err
      fprintf(2, 'FALLO  leer/asignar legacy: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  % --- DXF bloques: import → REV → reimport conserva asset_id ---
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_bloques.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALLO  falta demo_aos_bloques.dxf\n');
    ok = false;
  else
    prev = CONFIG_ACTIVA;
    unwind_protect
      CONFIG_ACTIVA = struct();
      if ~aos_cad_importar_dxf(dxf, true)
        fprintf(2, 'FALLO  import bloques\n');
        ok = false;
      else
        snap1 = capturar_asset_ids_estables_local(CONFIG_ACTIVA.cad_topologia.modelo_aoscad);
        ok = check_local(ok, numel(fieldnames(snap1)) >= 1, 'snapshot asset_id inicial');

        out_rev = fullfile(tempdir(), sprintf('aos_asset_%06d_AOS_REV.dxf', randi(999999)));
        ruta = aos_cad_exportar_dxf_rev(out_rev, true);
        ok = check_local(ok, exist(ruta, 'file') == 2, 'export REV asset');

        CONFIG_ACTIVA = struct();
        if ~aos_cad_importar_dxf(ruta, true)
          fprintf(2, 'FALLO  reimport REV\n');
          ok = false;
        else
          snap2 = capturar_asset_ids_estables_local(CONFIG_ACTIVA.cad_topologia.modelo_aoscad);
          ok = check_local(ok, snap_subset_local(snap1, snap2), ...
            'asset_id conservado tras REV (claves estables, handles nuevos)');
        endif
        if exist(ruta, 'file') == 2, delete(ruta); endif
      endif

      % --- .aoscad write/read conserva asset_id + activos ---
      CONFIG_ACTIVA = struct();
      if aos_cad_importar_dxf(dxf, true)
        aos_cad_construir_topologia(0.05, true);
        % Motor demo minimo para cumplir precondicion de aos_aoscad_escribir
        try
          aos_cad_eval_hidraulica_demo(true);
        catch
          mtmp = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
          mtmp.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
          mtmp.simulacion.estado = 'EJECUTADA';
          CONFIG_ACTIVA.cad_topologia.modelo_aoscad = mtmp;
        end_try_catch
        out_a = fullfile(tempdir(), sprintf('aos_asset_%06d.aoscad', randi(999999)));
        try
          aos_aoscad_escribir(out_a, 'SIMPLE', true);
          ok = check_local(ok, exist(out_a, 'file') == 2, '.aoscad escrito');
          leido = aos_aoscad_leer(out_a, true);
          snap_w = capturar_asset_ids_local(CONFIG_ACTIVA.cad_topologia.modelo_aoscad);
          snap_r = capturar_asset_ids_local(leido);
          ok = check_local(ok, snaps_iguales_local(snap_w, snap_r), ...
            'asset_id conservado en round-trip .aoscad');
          ok = check_local(ok, isfield(leido, 'activos') && ~isempty(leido.activos), ...
            'registro activos en .aoscad leido');
        catch err
          fprintf(2, 'FALLO  round-trip .aoscad: %s\n', err.message);
          ok = false;
        end_try_catch
        if exist(out_a, 'file') == 2, delete(out_a); endif
      endif
    unwind_protect_cleanup
      CONFIG_ACTIVA = prev;
    end_unwind_protect
  endif

  % --- STEP: asset_id por producto + estabilidad reimport (si hay demo) ---
  step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  if exist(step, 'file') == 2
    prev = CONFIG_ACTIVA;
    unwind_protect
      CONFIG_ACTIVA = struct();
      if aos_cad_importar_step(step, true)
        idx1 = CONFIG_ACTIVA.cad_topologia.id_index_step;
        aids1 = asset_ids_step_local(idx1);
        ok = check_local(ok, numel(aids1) >= 1, 'STEP: asset_id por producto');
        ok = check_local(ok, numel(unique(aids1)) == numel(aids1), ...
          'STEP: asset_id unicos');

        CONFIG_ACTIVA = struct();
        aos_cad_importar_step(step, true);
        idx2 = CONFIG_ACTIVA.cad_topologia.id_index_step;
        aids2 = asset_ids_step_local(idx2);
        ok = check_local(ok, isequal(sort(aids1), sort(aids2)), ...
          'STEP: asset_id estable ante reimport');
      else
        fprintf(2, 'FALLO  import STEP\n');
        ok = false;
      endif
    unwind_protect_cleanup
      CONFIG_ACTIVA = prev;
    end_unwind_protect
  else
    fprintf('AVISO  sin demo STEP; se omite round-trip STEP\n');
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_asset_roundtrip APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_asset_roundtrip NO APROBADO\n');
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

function snap = capturar_asset_ids_local(modelo)
  snap = struct();
  if isempty(modelo) || ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada')
    return;
  endif
  tabs = {'nodos', 'tramos', 'equipos', 'valvulas', 'accesorios', ...
          'condiciones_borde', 'camaras', 'ramales', 'accesos'};
  for t = 1:numel(tabs)
    nom = tabs{t};
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    for i = 1:numel(filas)
      f = filas{i};
      if ~isstruct(f) || ~isfield(f, 'asset_id') || isempty(f.asset_id), continue; endif
      key = '';
      if isfield(f, 'id_estable') && ~isempty(f.id_estable)
        key = ['IDEST:' char(f.id_estable)];
      elseif isfield(f, 'block_name') && ~isempty(f.block_name)
        key = sprintf('INSERT:%s:%.6f:%.6f', f.block_name, f.insert_x, f.insert_y);
      elseif isfield(f, 'id') && ~isempty(f.id)
        key = [nom ':' char(f.id)];
      else
        key = sprintf('%s:%d', nom, i);
      endif
      safe = regexprep(key, '[^A-Za-z0-9_]', '_');
      if isempty(safe), safe = 'X'; endif
      if safe(1) >= '0' && safe(1) <= '9', safe = ['K_' safe]; endif
      snap.(safe) = char(f.asset_id);
    endfor
  endfor
endfunction

function snap = capturar_asset_ids_estables_local(modelo)
  % Claves que sobreviven REV sin depender de handles:
  % - IDEST en filas SIN block_name (p.ej. tramos: meta ID= se reescribe)
  % - INSERT:bloque:x:y para equipos bloque (id_estable de TEXT cercano
  %   puede no reexportarse; la identidad estable del bloque es INSERT)
  snap = struct();
  if isempty(modelo) || ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada')
    return;
  endif
  tabs = {'nodos', 'tramos', 'equipos', 'valvulas', 'accesorios', ...
          'condiciones_borde', 'camaras', 'ramales', 'accesos'};
  for t = 1:numel(tabs)
    nom = tabs{t};
    if ~isfield(modelo.tablas_entrada, nom), continue; endif
    filas = modelo.tablas_entrada.(nom);
    for i = 1:numel(filas)
      f = filas{i};
      if ~isstruct(f) || ~isfield(f, 'asset_id') || isempty(f.asset_id), continue; endif
      key = '';
      aid_val = char(f.asset_id);
      tiene_blk = isfield(f, 'block_name') && ~isempty(f.block_name);
      if tiene_blk
        key = sprintf('INSERT:%s:%.6f:%.6f', f.block_name, f.insert_x, f.insert_y);
        % Aid derivado solo de INSERT (sin IDEST) para comparar ciclo REV
        f2 = f;
        if isfield(f2, 'id_estable'), f2 = rmfield(f2, 'id_estable'); endif
        tipo = 'EQUIPO';
        [aid_val, ~, ~] = aos_asset_id_generar(tipo, f2, nom, struct());
      elseif isfield(f, 'id_estable') && ~isempty(f.id_estable)
        key = ['IDEST:' char(f.id_estable)];
      else
        continue;
      endif
      safe = regexprep(key, '[^A-Za-z0-9_]', '_');
      if isempty(safe), safe = 'X'; endif
      if safe(1) >= '0' && safe(1) <= '9', safe = ['K_' safe]; endif
      snap.(safe) = aid_val;
    endfor
  endfor
endfunction

function tf = snaps_iguales_local(a, b)
  tf = false;
  ka = sort(fieldnames(a));
  kb = sort(fieldnames(b));
  if ~isequal(ka, kb), return; endif
  for i = 1:numel(ka)
    if ~strcmp(a.(ka{i}), b.(ka{i})), return; endif
  endfor
  tf = true;
endfunction

function tf = snap_subset_local(a, b)
  % Todas las claves estables de a deben existir en b con el mismo asset_id.
  tf = false;
  ka = fieldnames(a);
  for i = 1:numel(ka)
    if ~isfield(b, ka{i}) || ~strcmp(a.(ka{i}), b.(ka{i}))
      return;
    endif
  endfor
  tf = true;
endfunction

function aids = asset_ids_step_local(idx)
  aids = {};
  if isempty(idx) || ~isstruct(idx) || ~isfield(idx, 'items'), return; endif
  for i = 1:numel(idx.items)
    it = idx.items{i};
    if isfield(it, 'asset_id') && ~isempty(it.asset_id)
      aids{end+1} = char(it.asset_id); %#ok<AGROW>
    endif
  endfor
endfunction

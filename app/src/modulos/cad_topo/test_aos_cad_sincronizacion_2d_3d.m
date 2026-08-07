function ok = test_aos_cad_sincronizacion_2d_3d()
% TEST_AOS_CAD_SINCRONIZACION_2D_3D Orquestador sync DXF/STEP (Sprint 7 / T3).
% Headless. Trabaja solo sobre copias bajo intercambio/cad; no toca fixtures.
  ok = true;
  fprintf('\n=== test_aos_cad_sincronizacion_2d_3d ===\n');
  global CONFIG_ACTIVA;
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_sync_2d3d');
  if exist(tmpdir, 'dir') ~= 7, mkdir(tmpdir); endif

  dxf_fix = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_hidraulica_dev1.dxf');
  step_fix = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
  if exist(dxf_fix, 'file') ~= 2 || exist(step_fix, 'file') ~= 2
    fprintf(2, 'FALLO fixtures DXF/STEP ausentes\n');
    ok = false;
    fprintf('RESULTADO: test_aos_cad_sincronizacion_2d_3d NO APROBADO\n');
    return;
  endif

  dxf = fullfile(tmpdir, 'sync_dxf.dxf');
  step = fullfile(tmpdir, 'sync_step.step');

  unwind_protect
    copiar_binario_test_local(dxf_fix, dxf);
    copiar_binario_test_local(step_fix, step);
    mt_fx_dxf0 = aos_cad_mtime(dxf_fix);
    mt_fx_step0 = aos_cad_mtime(step_fix);

    % ---------- S1 DXF sin cambios ----------
    try
      preparar_sesion_local(dxf, step, true, true);
      snap = snapshot_local();
      [ok_s, rep] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true, ...
        'reconstruir_topologia', true, ...
        'reconstruir_vinculo', true, ...
        'reconstruir_escena', true));
      ok = check_local(ok, ok_s, 'S1 sync ok');
      ok = check_local(ok, isstruct(rep) ...
        && isfield(rep, 'fuentes_cambiadas') && isfield(rep, 'acciones') ...
        && isfield(rep, 'items') && isfield(rep, 'requiere_recalculo') ...
        && isfield(rep, 'escena_vigente') && isfield(rep, 'counts'), ...
        'S1 reporte campos');
      ok = check_local(ok, isempty(rep.fuentes_cambiadas), 'S1 sin fuentes_cambiadas');
      ok = check_local(ok, ~logical(rep.requiere_recalculo), 'S1 no requiere_recalculo');
      ok = check_local(ok, snapshot_igual_local(snap, snapshot_local()), ...
        'S1 ids/mtimes/resultados intactos');
    catch err
      fprintf(2, 'FALLO S1 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- S2 DXF modificado ----------
    try
      preparar_sesion_local(dxf, step, true, true);
      marcar_ejecutada_local();
      pause(1.05);
      tocar_archivo_local(dxf, 'DXF');
      [ok_s, rep] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true, ...
        'reconstruir_topologia', true, ...
        'reconstruir_vinculo', true, ...
        'reconstruir_escena', true));
      ok = check_local(ok, ok_s, 'S2 sync ok');
      ok = check_local(ok, tiene_fuente_local(rep, 'DXF'), 'S2 fuentes incluye DXF');
      ok = check_local(ok, ~tiene_fuente_local(rep, 'STEP'), 'S2 no marca STEP');
      ok = check_local(ok, logical(rep.requiere_recalculo), 'S2 requiere_recalculo');
      ok = check_local(ok, logical(rep.escena_vigente), 'S2 escena_vigente tras rebuild');
      ok = check_local(ok, acciones_orden_ok_local(rep.acciones, 'DXF'), ...
        'S2 orden acciones DXF');
      m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'S2 simulacion INVALIDADA_POR_EDICION');
      ok = check_local(ok, isempty(m.tablas_resultados.nodos) ...
        && isempty(m.tablas_resultados.tramos), 'S2 resultados vacios');
      ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'topologia') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.topologia), ...
        'S2 topologia reconstruida');
      ok = check_local(ok, isfield(rep.counts, 'n_objetos_escena') ...
        && rep.counts.n_objetos_escena > 0, 'S2 counts escena');
    catch err
      fprintf(2, 'FALLO S2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- S3 STEP sin cambios ----------
    try
      preparar_sesion_local(dxf, step, true, true);
      snap = snapshot_local();
      [ok_s, rep] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true));
      ok = check_local(ok, ok_s && isempty(rep.fuentes_cambiadas), ...
        'S3 STEP sesion sin cambios');
      ok = check_local(ok, snapshot_igual_local(snap, snapshot_local()), ...
        'S3 snapshot intacto');
    catch err
      fprintf(2, 'FALLO S3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- S4 STEP modificado ----------
    try
      preparar_sesion_local(dxf, step, true, true);
      marcar_ejecutada_local();
      pause(1.05);
      tocar_archivo_local(step, 'STEP');
      [ok_s, rep] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true, ...
        'reconstruir_topologia', true, ...
        'reconstruir_vinculo', true, ...
        'reconstruir_escena', true));
      ok = check_local(ok, ok_s, 'S4 sync ok');
      ok = check_local(ok, tiene_fuente_local(rep, 'STEP'), 'S4 fuentes incluye STEP');
      ok = check_local(ok, ~tiene_fuente_local(rep, 'DXF'), 'S4 no marca DXF');
      ok = check_local(ok, logical(rep.requiere_recalculo), 'S4 requiere_recalculo');
      ok = check_local(ok, logical(rep.escena_vigente), 'S4 escena_vigente');
      ok = check_local(ok, acciones_orden_ok_local(rep.acciones, 'STEP'), ...
        'S4 orden acciones STEP');
      m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'S4 simulacion INVALIDADA_POR_EDICION');
      ok = check_local(ok, isempty(m.tablas_resultados.nodos), 'S4 resultados vacios');
      ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'vinculo_3d') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.vinculo_3d) ...
        && CONFIG_ACTIVA.cad_topologia.vinculo_3d.vigente, ...
        'S4 vinculo reconstruido vigente');
      ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'id_index_step') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.id_index_step), ...
        'S4 id_index_step presente');
    catch err
      fprintf(2, 'FALLO S4 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- S5 ambas fuentes modificadas ----------
    try
      preparar_sesion_local(dxf, step, true, true);
      marcar_ejecutada_local();
      pause(1.05);
      tocar_archivo_local(dxf, 'DXF');
      tocar_archivo_local(step, 'STEP');
      [ok_s, rep] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true, ...
        'reconstruir_topologia', true, ...
        'reconstruir_vinculo', true, ...
        'reconstruir_escena', true));
      ok = check_local(ok, ok_s, 'S5 sync ok');
      ok = check_local(ok, tiene_fuente_local(rep, 'DXF') ...
        && tiene_fuente_local(rep, 'STEP'), 'S5 ambas fuentes');
      ok = check_local(ok, logical(rep.requiere_recalculo), 'S5 requiere_recalculo');
      ok = check_local(ok, logical(rep.escena_vigente), 'S5 escena_vigente');
      ok = check_local(ok, acciones_orden_ok_local(rep.acciones, 'AMBAS'), ...
        'S5 orden acciones ambas');
      m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m.simulacion.estado), 'INVALIDADA_POR_EDICION') ...
        && isempty(m.tablas_resultados.nodos), ...
        'S5 no mezcla geometria nueva con resultados viejos');
    catch err
      fprintf(2, 'FALLO S5 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- S6 idempotencia: segunda sync sin cambios ----------
    try
      preparar_sesion_local(dxf, step, true, true);
      marcar_ejecutada_local();
      pause(1.05);
      tocar_archivo_local(dxf, 'DXF');
      [ok1, ~] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true, ...
        'reconstruir_topologia', true, ...
        'reconstruir_vinculo', true, ...
        'reconstruir_escena', true));
      ok = check_local(ok, ok1, 'S6a primera sync ok');
      snap = snapshot_local();
      [ok2, rep2] = aos_cad_sincronizar_2d_3d(struct( ...
        'forzar', false, 'silencioso', true, ...
        'reconstruir_topologia', true, ...
        'reconstruir_vinculo', true, ...
        'reconstruir_escena', true));
      ok = check_local(ok, ok2, 'S6b segunda sync ok');
      ok = check_local(ok, isempty(rep2.fuentes_cambiadas), 'S6b sin cambios');
      ok = check_local(ok, snapshot_igual_local(snap, snapshot_local()), ...
        'S6b ids/resultados/mtimes intactos');
    catch err
      fprintf(2, 'FALLO S6 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- S7 fixtures origen intactos ----------
    try
      ok = check_local(ok, abs(aos_cad_mtime(dxf_fix) - mt_fx_dxf0) < 1e-6, ...
        'S7 mtime fixture DXF intacto');
      ok = check_local(ok, abs(aos_cad_mtime(step_fix) - mt_fx_step0) < 1e-6, ...
        'S7 mtime fixture STEP intacto');
    catch err
      fprintf(2, 'FALLO S7 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
    try
      if exist(tmpdir, 'dir') == 7
        delete(fullfile(tmpdir, '*'));
        rmdir(tmpdir);
      endif
    catch
    end_try_catch
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_sincronizacion_2d_3d APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_sincronizacion_2d_3d NO APROBADO\n');
  endif
endfunction

function preparar_sesion_local(dxf, step, con_dxf, con_step)
  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  CONFIG_ACTIVA.cad_topologia = struct();
  if con_dxf
    okd = aos_cad_importar_dxf(dxf, true);
    if ~okd, error('preparar: import DXF fallo'); endif
  endif
  if con_step
    oks = aos_cad_importar_step(step, true);
    if ~oks, error('preparar: import STEP fallo'); endif
  endif
  aos_cad_registrar_mtime(dxf);
  aos_cad_registrar_mtime(step);
  % Escena/vinculo iniciales vigentes
  opts_esc = struct('incluir_pozo', false, 'incluir_red', true, ...
    'incluir_step', true, 'incluir_puertos', false);
  [esc, ~] = aos_cad_escena_3d(CONFIG_ACTIVA.cad_topologia, opts_esc);
  [vin, modelo, ~] = aos_cad_vincular_asset_3d( ...
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad, ...
    struct('cad_topologia', CONFIG_ACTIVA.cad_topologia));
  modelo.escena_3d = esc;
  modelo.vinculo_3d = vin;
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.escena_3d = esc;
  CONFIG_ACTIVA.cad_topologia.vinculo_3d = vin;
  % Alinear mtimes registrados con disco
  aos_cad_registrar_mtime(dxf);
  aos_cad_registrar_mtime(step);
endfunction

function marcar_ejecutada_local()
  global CONFIG_ACTIVA;
  m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  m.simulacion.estado = 'EJECUTADA';
  m.simulacion.motor = 'MOTOR_STUB_SYNC';
  m.simulacion.corrida_id = 'CORRIDA_SYNC';
  m.simulacion.fecha = '2024-06-01 10:00:00';
  if ~isfield(m, 'tablas_resultados') || ~isstruct(m.tablas_resultados)
    m.tablas_resultados = struct();
  endif
  m.tablas_resultados.nodos = {struct('id', 'N_SYNC', 'P_Pa', 1e5)};
  m.tablas_resultados.tramos = {struct('id', 'T_SYNC', 'Q_m3s', 0.01)};
  if isfield(m, 'escena_3d') && isstruct(m.escena_3d)
    m.escena_3d.vigente = true;
  endif
  if isfield(m, 'vinculo_3d') && isstruct(m.vinculo_3d)
    m.vinculo_3d.vigente = true;
  endif
  if isfield(m, 'recursos_visuales') && isstruct(m.recursos_visuales)
    m.recursos_visuales.vigente = true;
    m.recursos_visuales.obsoletos = false;
  endif
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m;
  if isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d')
    CONFIG_ACTIVA.cad_topologia.escena_3d.vigente = true;
  endif
  if isfield(CONFIG_ACTIVA.cad_topologia, 'vinculo_3d')
    CONFIG_ACTIVA.cad_topologia.vinculo_3d.vigente = true;
  endif
endfunction

function snap = snapshot_local()
  global CONFIG_ACTIVA;
  ct = CONFIG_ACTIVA.cad_topologia;
  snap = struct();
  snap.dxf_mtime = [];
  snap.step_mtime = [];
  if isfield(ct, 'dxf_mtime'), snap.dxf_mtime = ct.dxf_mtime; endif
  if isfield(ct, 'step_mtime'), snap.step_mtime = ct.step_mtime; endif
  snap.estado = '';
  snap.n_nodos_res = 0;
  snap.n_tramos_res = 0;
  snap.ids_nodos = {};
  snap.ids_step = {};
  if isfield(ct, 'modelo_aoscad') && isstruct(ct.modelo_aoscad)
    m = ct.modelo_aoscad;
    if isfield(m, 'simulacion') && isfield(m.simulacion, 'estado')
      snap.estado = char(m.simulacion.estado);
    endif
    if isfield(m, 'tablas_resultados')
      if isfield(m.tablas_resultados, 'nodos')
        snap.n_nodos_res = numel(m.tablas_resultados.nodos);
      endif
      if isfield(m.tablas_resultados, 'tramos')
        snap.n_tramos_res = numel(m.tablas_resultados.tramos);
      endif
    endif
    if isfield(m, 'tablas_entrada') && isfield(m.tablas_entrada, 'nodos')
      for i = 1:numel(m.tablas_entrada.nodos)
        n = m.tablas_entrada.nodos{i};
        if isstruct(n) && isfield(n, 'id')
          snap.ids_nodos{end+1} = char(n.id); %#ok<AGROW>
        endif
      endfor
    endif
  endif
  if isfield(ct, 'id_index_step') && isstruct(ct.id_index_step) ...
      && isfield(ct.id_index_step, 'items')
    for i = 1:numel(ct.id_index_step.items)
      it = ct.id_index_step.items{i};
      if isstruct(it) && isfield(it, 'asset_id')
        snap.ids_step{end+1} = char(it.asset_id); %#ok<AGROW>
      elseif isstruct(it) && isfield(it, 'id')
        snap.ids_step{end+1} = char(it.id); %#ok<AGROW>
      endif
    endfor
  endif
endfunction

function tf = snapshot_igual_local(a, b)
  tf = false;
  if ~isstruct(a) || ~isstruct(b), return; endif
  if ~isequal(a.dxf_mtime, b.dxf_mtime), return; endif
  if ~isequal(a.step_mtime, b.step_mtime), return; endif
  if ~strcmp(char(a.estado), char(b.estado)), return; endif
  if a.n_nodos_res ~= b.n_nodos_res || a.n_tramos_res ~= b.n_tramos_res
    return;
  endif
  if ~isequal(a.ids_nodos, b.ids_nodos), return; endif
  if ~isequal(a.ids_step, b.ids_step), return; endif
  tf = true;
endfunction

function tf = tiene_fuente_local(rep, nombre)
  tf = false;
  if ~isstruct(rep) || ~isfield(rep, 'fuentes_cambiadas'), return; endif
  fc = rep.fuentes_cambiadas;
  if ~iscell(fc), fc = {fc}; endif
  for i = 1:numel(fc)
    if strcmpi(char(fc{i}), nombre)
      tf = true;
      return;
    endif
  endfor
endfunction

function tf = acciones_orden_ok_local(acciones, modo)
  tf = false;
  if ~iscell(acciones), return; endif
  keys = upper(strjoin(acciones, '|'));
  % Orden fijo requerido: DETECTAR -> REIMPORTAR -> INVALIDAR -> ...
  if isempty(strfind(keys, 'DETECTAR')), return; endif
  if strcmp(modo, 'DXF') || strcmp(modo, 'AMBAS')
    if isempty(strfind(keys, 'REIMPORT')), return; endif
    if isempty(strfind(keys, 'INVALIDAR')), return; endif
    if isempty(strfind(keys, 'TOPOLOGIA')), return; endif
    if isempty(strfind(keys, 'ESCENA')), return; endif
    if isempty(strfind(keys, 'REGISTRAR_MTIME')), return; endif
    i_det = idx_accion_local(acciones, 'DETECTAR');
    i_imp = idx_accion_local(acciones, 'REIMPORT');
    i_inv = idx_accion_local(acciones, 'INVALIDAR');
    i_topo = idx_accion_local(acciones, 'TOPOLOGIA');
    i_esc = idx_accion_local(acciones, 'ESCENA');
    i_mt = idx_accion_local(acciones, 'REGISTRAR_MTIME');
    if ~(i_det > 0 && i_imp > 0 && i_inv > 0 && i_topo > 0 && i_esc > 0 && i_mt > 0)
      return;
    endif
    if ~(i_det < i_imp && i_imp < i_inv && i_inv < i_topo && i_topo < i_esc && i_esc < i_mt)
      return;
    endif
  endif
  if strcmp(modo, 'STEP') || strcmp(modo, 'AMBAS')
    if isempty(strfind(keys, 'REIMPORT')), return; endif
    if isempty(strfind(keys, 'INVALIDAR')), return; endif
    if isempty(strfind(keys, 'VINCULO')) && isempty(strfind(keys, 'INDICE'))
      return;
    endif
    if isempty(strfind(keys, 'ESCENA')), return; endif
    i_det = idx_accion_local(acciones, 'DETECTAR');
    i_imp = idx_accion_local(acciones, 'REIMPORT');
    i_inv = idx_accion_local(acciones, 'INVALIDAR');
    i_vin = idx_accion_local(acciones, 'VINCULO');
    if i_vin < 0, i_vin = idx_accion_local(acciones, 'INDICE'); endif
    i_esc = idx_accion_local(acciones, 'ESCENA');
    if ~(i_det > 0 && i_imp > 0 && i_inv > 0 && i_vin > 0 && i_esc > 0)
      return;
    endif
    if ~(i_det < i_imp && i_imp < i_inv && i_inv < i_vin && i_vin < i_esc)
      return;
    endif
  endif
  if strcmp(modo, 'AMBAS')
    i_topo = idx_accion_local(acciones, 'TOPOLOGIA');
    i_vin = idx_accion_local(acciones, 'VINCULO');
    if i_vin < 0, i_vin = idx_accion_local(acciones, 'INDICE'); endif
    if ~(i_topo > 0 && i_vin > 0 && i_topo < i_vin)
      return;
    endif
  endif
  tf = true;
endfunction

function idx = idx_accion_local(acciones, token)
  idx = -1;
  tok = upper(token);
  for i = 1:numel(acciones)
    if ~isempty(strfind(upper(char(acciones{i})), tok))
      idx = i;
      return;
    endif
  endfor
endfunction

function tocar_archivo_local(ruta, etiqueta)
  fid = fopen(ruta, 'a');
  if fid < 0, error('no se pudo tocar %s', ruta); endif
  fprintf(fid, '\n/* AOS_SYNC_TOUCH_%s %s */\n', etiqueta, datestr(now, 30));
  fclose(fid);
endfunction

function copiar_binario_test_local(origen, destino)
  [pd, ~, ~] = fileparts(destino);
  if ~isempty(pd) && exist(pd, 'dir') ~= 7, mkdir(pd); endif
  fid_i = fopen(origen, 'rb');
  if fid_i < 0, error('no se pudo leer %s', origen); endif
  data = fread(fid_i);
  fclose(fid_i);
  fid_o = fopen(destino, 'wb');
  if fid_o < 0, error('no se pudo escribir %s', destino); endif
  fwrite(fid_o, data);
  fclose(fid_o);
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO: %s\n', msg);
    ok = false;
  endif
endfunction

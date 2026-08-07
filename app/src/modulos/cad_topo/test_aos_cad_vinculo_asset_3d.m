function ok = test_aos_cad_vinculo_asset_3d()
% TEST_AOS_CAD_VINCULO_ASSET_3D Selftest vinculo asset_id <-> geometry_id (X1-X5).
% Headless. No usa AOS_CAD_SKIP_VISOR. No registra verificadores (Linea E).
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

  fprintf('\n=== test_aos_cad_vinculo_asset_3d ===\n');

  step_eq = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  step_rep = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_ensamble_repetido.step');
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  legacy = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_legacy_sin_asset.aoscad');
  for f = {step_eq, step_rep, dxf, legacy}
    if exist(f{1}, 'file') ~= 2
      fprintf(2, 'FALTA fixture: %s\n', f{1});
      ok = false;
      fprintf(2, 'RESULTADO: test_aos_cad_vinculo_asset_3d NO APROBADO\n');
      return;
    endif
  endfor

  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_vinculo_3d');
  if exist(tmpdir, 'dir') ~= 7
    mkdir(tmpdir);
  endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    % ---------- X1 bidireccionalidad ----------
    try
      CONFIG_ACTIVA = struct();
      ok = check_local(ok, aos_cad_importar_step(step_eq, true), 'X1 import equipment');
      m_eq = aos_step_leer(step_eq);
      [vin1, mod1, items1] = aos_cad_vincular_asset_3d(struct(), struct( ...
        'cad_topologia', CONFIG_ACTIVA.cad_topologia, ...
        'indice_geometrico', m_eq.indice_geometrico, ...
        'id_index_step', CONFIG_ACTIVA.cad_topologia.id_index_step));
      ok = check_local(ok, isstruct(vin1) && isfield(vin1, 'por_asset_id') ...
        && isfield(vin1, 'por_geometry_id'), 'X1 vinculo struct');

      gids_idx = {};
      n_con_contraparte = 0;
      for i = 1:numel(m_eq.indice_geometrico.ocurrencias)
        oc = m_eq.indice_geometrico.ocurrencias{i};
        if ~isstruct(oc) || ~isfield(oc, 'geometry_id') || isempty(oc.geometry_id)
          continue;
        endif
        gid = char(oc.geometry_id);
        gids_idx{end+1} = gid; %#ok<AGROW>
        gk = safe_key_local(gid);
        ok = check_local(ok, isfield(vin1.por_geometry_id, gk), ...
          sprintf('X1 por_geometry_id tiene %s', gid));
        if isfield(vin1.por_geometry_id, gk)
          aid = char(vin1.por_geometry_id.(gk));
          ok = check_local(ok, ~isempty(aid), ...
            sprintf('X1 geometry_id -> asset_id no vacio (%s)', gid));
          if ~isempty(aid)
            n_con_contraparte = n_con_contraparte + 1;
            ak = safe_key_local(aid);
            ok = check_local(ok, isfield(vin1.geometry_ids_por_asset, ak), ...
              sprintf('X1 asset_id -> geometry_ids (%s)', aid));
            if isfield(vin1.geometry_ids_por_asset, ak)
              gids_a = vin1.geometry_ids_por_asset.(ak);
              ok = check_local(ok, any(strcmp(gids_a, gid)), ...
                sprintf('X1 viceversa incluye gid %s', gid));
            endif
          endif
        endif
      endfor
      ok = check_local(ok, vin1.n_vinculados == n_con_contraparte ...
        && n_con_contraparte == numel(gids_idx), ...
        'X1 n_vinculados = ocurrencias con contraparte');
      ok = check_local(ok, vin1.n_vinculados >= 1, 'X1 al menos un vinculo');
    catch err
      fprintf(2, 'FALLO X1 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- X2 uno a muchos (fixture repetido) ----------
    try
      CONFIG_ACTIVA = struct();
      ok = check_local(ok, aos_cad_importar_step(step_rep, true), 'X2 import repetido');
      m_rep = aos_step_leer(step_rep);
      [vin2, mod2, ~] = aos_cad_vincular_asset_3d(struct( ...
        'step_indice_geometrico', m_rep.indice_geometrico), struct( ...
        'cad_topologia', CONFIG_ACTIVA.cad_topologia));
      ok = check_local(ok, m_rep.indice_geometrico.n_ocurrencias == 2, ...
        'X2 dos ocurrencias en indice');
      ok = check_local(ok, vin2.n_vinculados == 2, 'X2 dos vinculaciones');

      aks = fieldnames(vin2.geometry_ids_por_asset);
      aid_multi = '';
      gids_multi = {};
      for i = 1:numel(aks)
        g = vin2.geometry_ids_por_asset.(aks{i});
        if numel(g) == 2
          aid_multi = aks{i};
          gids_multi = g;
          break;
        endif
      endfor
      ok = check_local(ok, ~isempty(aid_multi) && numel(gids_multi) == 2, ...
        'X2 un asset_id con dos geometry_id');
      ok = check_local(ok, numel(unique(gids_multi)) == 2, ...
        'X2 geometry_id distintos');

      if numel(gids_multi) == 2
        aid_back = {};
        for j = 1:2
          gk = safe_key_local(gids_multi{j});
          ok = check_local(ok, isfield(vin2.por_geometry_id, gk), ...
            sprintf('X2 por_geometry_id #%d', j));
          if isfield(vin2.por_geometry_id, gk)
            aid_back{end+1} = char(vin2.por_geometry_id.(gk)); %#ok<AGROW>
          endif
        endfor
        ok = check_local(ok, numel(aid_back) == 2 ...
          && strcmp(aid_back{1}, aid_back{2}), ...
          'X2 ambos geometry_id resuelven al mismo asset_id');
      endif

      % Activo con geometry_ids (uno a muchos persistido)
      tiene_ids = false;
      for i = 1:numel(mod2.activos)
        a = mod2.activos{i};
        if isstruct(a) && isfield(a, 'geometry_ids') && iscell(a.geometry_ids) ...
            && numel(a.geometry_ids) == 2
          tiene_ids = true;
          break;
        endif
      endfor
      ok = check_local(ok, tiene_ids, 'X2 geometry_ids en activo (uno a muchos)');
    catch err
      fprintf(2, 'FALLO X2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- X3 huerfanos auditables ----------
    try
      indice = struct();
      indice.ocurrencias = { ...
        struct('geometry_id', 'STEPOCC:ok:1', 'asset_id', 'AID_OK', ...
          'product_id', 'P', 'nombre', 'P'), ...
        struct('geometry_id', 'STEPOCC:orphan:1', 'asset_id', '', ...
          'product_id', '', 'nombre', '')};
      activos = { ...
        struct('asset_id', 'AID_OK', 'asset_type', 'STEP_PRODUCT', ...
          'source', 'STEP', 'validation_status', 'OK'), ...
        struct('asset_id', 'AID_HUERFANO', 'asset_type', 'NODO', ...
          'source', 'DXF', 'validation_status', 'OK')};
      modelo_x3 = struct();
      modelo_x3.activos = activos;
      modelo_x3.step_indice_geometrico = indice;
      [vin3, mod3, items3] = aos_cad_vincular_asset_3d(modelo_x3);
      ok = check_local(ok, vin3.n_vinculados == 1, 'X3 vinculo parcial intacto');
      ok = check_local(ok, vin3.n_asset_sin_geometria == 1, 'X3 un asset huerfano');
      ok = check_local(ok, vin3.n_geometria_sin_asset == 1, 'X3 una geometria huerfana');
      ok = check_local(ok, tiene_codigo_local(items3, 'VINCULO_3D_ASSET_SIN_GEOMETRIA'), ...
        'X3 item VINCULO_3D_ASSET_SIN_GEOMETRIA');
      ok = check_local(ok, tiene_codigo_local(items3, 'VINCULO_3D_GEOMETRIA_SIN_ASSET'), ...
        'X3 item VINCULO_3D_GEOMETRIA_SIN_ASSET');
      gk_ok = safe_key_local('STEPOCC:ok:1');
      ok = check_local(ok, isfield(vin3.por_geometry_id, gk_ok) ...
        && strcmp(char(vin3.por_geometry_id.(gk_ok)), 'AID_OK'), ...
        'X3 huerfanos no rompen vinculo existente');
      ok = check_local(ok, isfield(mod3, 'vinculo_3d') && isstruct(mod3.vinculo_3d), ...
        'X3 modelo conserva vinculo_3d');
    catch err
      fprintf(2, 'FALLO X3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- X4 persistencia y schema AOSCAD-0.0.1-DEV1 ----------
    try
      CONFIG_ACTIVA = struct();
      ok = check_local(ok, aos_cad_importar_dxf(dxf, true), 'X4 import DXF');
      aos_cad_construir_topologia(0.05, true);
      ok = check_local(ok, aos_cad_importar_step(step_eq, true), 'X4 import STEP');
      try
        aos_cad_eval_hidraulica_demo(true);
      catch
        mtmp = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        mtmp.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
        mtmp.simulacion.estado = 'EJECUTADA';
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad = mtmp;
      end_try_catch

      % Sin cad_topologia en opciones: evita activos DXF y sintetiza desde id_index_step.
      cad = CONFIG_ACTIVA.cad_topologia;
      [vin4, mod_step, ~] = aos_cad_vincular_asset_3d(struct(), struct( ...
        'indice_geometrico', cad.step_indice_geometrico, ...
        'id_index_step', cad.id_index_step));
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      if ~isfield(modelo, 'activos') || isempty(modelo.activos)
        modelo.activos = mod_step.activos;
      else
        modelo.activos = [modelo.activos(:).', mod_step.activos(:).'];
      endif
      modelo.vinculo_3d = vin4;
      if isfield(mod_step, 'step_indice_geometrico')
        modelo.step_indice_geometrico = mod_step.step_indice_geometrico;
      endif
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = vin4;

      n_gid_antes = contar_geometry_id_activos_local(modelo.activos);
      ok = check_local(ok, n_gid_antes >= 1, 'X4 geometry_id presente antes de escribir');

      out_a = fullfile(tmpdir, 'x4_vinculo_roundtrip.aoscad');
      if exist(out_a, 'file') == 2, delete(out_a); endif
      aos_aoscad_escribir(out_a, 'SIMPLE', true);
      ok = check_local(ok, exist(out_a, 'file') == 2, 'X4 .aoscad escrito');

      leido = [];
      exc_leer = false;
      try
        leido = aos_aoscad_leer(out_a, true);
      catch
        exc_leer = true;
      end_try_catch
      ok = check_local(ok, ~exc_leer && isstruct(leido), ...
        'X4 lee/valida schema (aos_aoscad_leer)');
      if isstruct(leido)
        ok = check_local(ok, strcmp(char(leido.info.schema), 'AOSCAD-0.0.1-DEV1'), ...
          'X4 info.schema AOSCAD-0.0.1-DEV1');
        n_gid_desp = 0;
        if isfield(leido, 'activos')
          n_gid_desp = contar_geometry_id_activos_local(leido.activos);
        endif
        ok = check_local(ok, n_gid_desp >= 1, ...
          'X4 geometry_id sobrevive round-trip');
        ok = check_local(ok, isfield(leido, 'vinculo_3d') ...
          && isstruct(leido.vinculo_3d), 'X4 vinculo_3d en .aoscad');
      endif
      if exist(out_a, 'file') == 2, delete(out_a); endif

      % Legacy sin asset: abre sin error ni advertencias nuevas de vinculo/escena
      m_leg = [];
      exc_leg = false;
      try
        m_leg = aos_aoscad_leer(legacy, true);
      catch
        exc_leg = true;
      end_try_catch
      ok = check_local(ok, ~exc_leg && isstruct(m_leg), 'X4 legacy abre sin error');
      if isstruct(m_leg)
        ok = check_local(ok, strcmp(char(m_leg.info.schema), 'AOSCAD-0.0.1-DEV1'), ...
          'X4 legacy schema DEV1');
        items_leg = {};
        if isfield(m_leg, 'validaciones') && isstruct(m_leg.validaciones) ...
            && isfield(m_leg.validaciones, 'items')
          items_leg = m_leg.validaciones.items;
        endif
        ok = check_local(ok, ~tiene_codigo_local(items_leg, 'VINCULO_3D_ASSET_SIN_GEOMETRIA') ...
          && ~tiene_codigo_local(items_leg, 'VINCULO_3D_GEOMETRIA_SIN_ASSET') ...
          && ~tiene_codigo_local(items_leg, 'ESCENA_3D_INVALIDADA_POR_EDICION'), ...
          'X4 legacy sin advertencias nuevas vinculo/escena');
      endif
    catch err
      fprintf(2, 'FALLO X4 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- X5 invalidacion ESCENA_3D_INVALIDADA_POR_EDICION ----------
    try
      CONFIG_ACTIVA = struct();
      ok = check_local(ok, aos_cad_importar_dxf(dxf, true), 'X5 import DXF');
      aos_cad_construir_topologia(0.05, true);
      ok = check_local(ok, aos_cad_importar_step(step_eq, true), 'X5 import STEP');

      fuente = struct();
      fuente.cad_topologia = CONFIG_ACTIVA.cad_topologia;
      opts_esc = struct('incluir_pozo', false, 'incluir_red', true, 'incluir_step', true);
      [esc1, ~] = aos_cad_escena_3d(fuente, opts_esc);
      ok = check_local(ok, isstruct(esc1) && esc1.vigente, 'X5 escena vigente inicial');

      [vin5, ~, ~] = aos_cad_vincular_asset_3d(struct(), struct( ...
        'cad_topologia', CONFIG_ACTIVA.cad_topologia));
      ok = check_local(ok, isstruct(vin5) && vin5.vigente, 'X5 vinculo vigente inicial');

      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      modelo.escena_3d = esc1;
      modelo.vinculo_3d = vin5;
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
      CONFIG_ACTIVA.cad_topologia.escena_3d = esc1;
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = vin5;

      nid = '';
      nodos = modelo.tablas_entrada.nodos;
      if ~isempty(nodos)
        n0 = nodos{1};
        if isfield(n0, 'id'), nid = char(n0.id); endif
      endif
      ok = check_local(ok, ~isempty(nid), 'X5 hay nodo para editar');
      if ~isempty(nid)
        z_nuevo = 1.234;
        edito = aos_aoscad_editar_campo('nodos', nid, 'z', z_nuevo, true);
        ok = check_local(ok, edito, 'X5 editar campo tabla');

        modelo2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        ok = check_local(ok, tiene_codigo_local(modelo2.validaciones.items, ...
          'ESCENA_3D_INVALIDADA_POR_EDICION'), ...
          'X5 ESCENA_3D_INVALIDADA_POR_EDICION');
        ok = check_local(ok, isfield(modelo2, 'simulacion') ...
          && strcmp(char(modelo2.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
          'X5 simulacion.estado INVALIDADA_POR_EDICION tras edicion');
        ok = check_local(ok, isfield(modelo2, 'escena_3d') ...
          && isstruct(modelo2.escena_3d) && ~modelo2.escena_3d.vigente, ...
          'X5 escena no vigente tras edicion');
        ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d') ...
          && ~CONFIG_ACTIVA.cad_topologia.escena_3d.vigente, ...
          'X5 cad_topologia.escena_3d no vigente');
        if isfield(CONFIG_ACTIVA.cad_topologia, 'vinculo_3d')
          ok = check_local(ok, ~CONFIG_ACTIVA.cad_topologia.vinculo_3d.vigente, ...
            'X5 vinculo no vigente tras edicion');
        endif

        % Reconstruir escena -> vigente
        fuente2 = struct();
        fuente2.cad_topologia = CONFIG_ACTIVA.cad_topologia;
        [esc2, ~] = aos_cad_escena_3d(fuente2, opts_esc);
        ok = check_local(ok, isstruct(esc2) && esc2.vigente, ...
          'X5 escena reconstruida vigente');
        CONFIG_ACTIVA.cad_topologia.escena_3d = esc2;
        modelo2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        modelo2.escena_3d = esc2;
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo2;
        ok = check_local(ok, CONFIG_ACTIVA.cad_topologia.escena_3d.vigente, ...
          'X5 cad_topologia escena vigente tras reconstruir');
      endif
    catch err
      fprintf(2, 'FALLO X5 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_vinculo_asset_3d APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_vinculo_asset_3d NO APROBADO\n');
  endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO: %s\n', msg);
    ok = false;
  endif
endfunction

function tf = tiene_codigo_local(items, codigo)
  tf = false;
  if nargin < 1 || isempty(items), return; endif
  if ~iscell(items), items = {items}; endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo)
      tf = true;
      return;
    endif
  endfor
endfunction

function n = contar_geometry_id_activos_local(activos)
  n = 0;
  if isempty(activos), return; endif
  if ~iscell(activos), activos = {activos}; endif
  for i = 1:numel(activos)
    a = activos{i};
    if isstruct(a) && isfield(a, 'geometry_id') && ~isempty(char(a.geometry_id))
      n = n + 1;
    endif
  endfor
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['H_' s]; endif
  k = s;
endfunction

function ok = test_aos_aoscad_recursos_visuales()
% TEST_AOS_AOSCAD_RECURSOS_VISUALES Generacion + persistencia ENRIQUECIDO (Sprint 7 T5/T6).
% Headless. Sin AOS_CAD_SKIP_VISOR. No modifica fixtures.
% P1-P4: round-trip escribir/leer, legacy, invalidacion, atomicidad PNG.
  ok = true;
  fprintf('\n=== test_aos_aoscad_recursos_visuales ===\n');
  global CONFIG_ACTIVA;
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_recursos_visuales');
  if exist(tmpdir, 'dir') ~= 7, mkdir(tmpdir); endif

  vis_anterior = get(0, 'defaultfigurevisible');
  set(0, 'defaultfigurevisible', 'off');

  unwind_protect
    % ---------- R1: ENRIQUECIDO genera al menos un recurso real ----------
    try
      limpiar_dir_local(tmpdir);
      m = modelo_minimo_local('ENRIQUECIDO', true, false);
      opts = struct('incluir_2d', true, 'incluir_3d', true, ...
        'incluir_overlay', true, 'visible', false, 'directorio', tmpdir);
      [rv, items] = aos_aoscad_generar_recursos_visuales(m, opts);
      ok = check_local(ok, isstruct(rv) && ~isempty(rv), 'R1 recursos struct');
      planos = lista_local(rv, 'planos');
      graficos = lista_local(rv, 'graficos');
      n_rec = numel(planos) + numel(graficos);
      ok = check_local(ok, n_rec >= 1, 'R1 al menos un recurso');
      ok = check_local(ok, recurso_real_local(rv, tmpdir), ...
        'R1 PNG real en disco (no stub)');
      ok = check_local(ok, isfield(rv, 'vigente') && logical(rv.vigente), ...
        'R1 vigente=true');
      ok = check_local(ok, isfield(rv, 'obsoletos') && ~logical(rv.obsoletos), ...
        'R1 obsoletos=false');
      ok = check_local(ok, isempty(findobj('type', 'figure')), ...
        'R1 sin figuras abiertas');
    catch err
      fprintf(2, 'FALLO R1 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- R2: SIMPLE no genera payload visual ----------
    try
      limpiar_dir_local(tmpdir);
      m = modelo_minimo_local('SIMPLE', true, false);
      [rv, items] = aos_aoscad_generar_recursos_visuales(m, struct( ...
        'visible', false, 'directorio', tmpdir));
      ok = check_local(ok, isempty(rv) || (iscell(rv) && numel(rv) == 0), ...
        'R2 SIMPLE recursos vacios');
      pngs = dir(fullfile(tmpdir, '*.png'));
      ok = check_local(ok, isempty(pngs), 'R2 SIMPLE sin PNG');
      ok = check_local(ok, isempty(findobj('type', 'figure')), ...
        'R2 sin figuras abiertas');
    catch err
      fprintf(2, 'FALLO R2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- R3: mismo modelo => mismo orden e ids ----------
    try
      limpiar_dir_local(tmpdir);
      m = modelo_minimo_local('ENRIQUECIDO', true, true);
      opts = struct('incluir_2d', true, 'incluir_3d', true, ...
        'incluir_overlay', true, 'visible', false, 'directorio', tmpdir);
      [rv1, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      ids1 = ids_recursos_local(rv1);
      [rv2, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      ids2 = ids_recursos_local(rv2);
      ok = check_local(ok, ~isempty(ids1), 'R3 ids no vacios');
      ok = check_local(ok, isequal(ids1, ids2), 'R3 orden/ids deterministas');
      ok = check_local(ok, isempty(findobj('type', 'figure')), ...
        'R3 sin figuras abiertas');
    catch err
      fprintf(2, 'FALLO R3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- R4: sin escena 3D => 2D + item informativo, no falla ----------
    try
      limpiar_dir_local(tmpdir);
      m = modelo_minimo_local('ENRIQUECIDO', true, false);
      if isfield(m, 'escena_3d'), m = rmfield(m, 'escena_3d'); endif
      opts = struct('incluir_2d', true, 'incluir_3d', true, ...
        'incluir_overlay', true, 'visible', false, 'directorio', tmpdir);
      [rv, items] = aos_aoscad_generar_recursos_visuales(m, opts);
      planos = lista_local(rv, 'planos');
      ok = check_local(ok, numel(planos) >= 1, 'R4 genera 2D sin escena');
      ok = check_local(ok, item_info_sin_escena_local(items), ...
        'R4 item informativo sin escena 3D');
      ids = ids_recursos_local(rv);
      ok = check_local(ok, ~any(strcmp(ids, 'VISTA_3D_ESCENA')), ...
        'R4 no inventa VISTA_3D_ESCENA');
      ok = check_local(ok, isempty(findobj('type', 'figure')), ...
        'R4 sin figuras abiertas');
    catch err
      fprintf(2, 'FALLO R4 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- R5: overlay solo si resultados vigentes ----------
    try
      limpiar_dir_local(tmpdir);
      m_sin = modelo_minimo_local('ENRIQUECIDO', false, true);
      m_sin.simulacion.estado = 'NO_EJECUTADA';
      m_sin.tablas_resultados = struct('nodos', {{}}, 'tramos', {{}});
      opts = struct('incluir_2d', true, 'incluir_3d', true, ...
        'incluir_overlay', true, 'visible', false, 'directorio', tmpdir);
      [rv_sin, ~] = aos_aoscad_generar_recursos_visuales(m_sin, opts);
      ids_sin = ids_recursos_local(rv_sin);
      ok = check_local(ok, ~any(strcmp(ids_sin, 'VISTA_3D_OVERLAY')), ...
        'R5a sin overlay sin resultados');

      m_con = modelo_minimo_local('ENRIQUECIDO', true, true);
      [rv_con, ~] = aos_aoscad_generar_recursos_visuales(m_con, opts);
      ids_con = ids_recursos_local(rv_con);
      ok = check_local(ok, any(strcmp(ids_con, 'VISTA_3D_OVERLAY')), ...
        'R5b overlay con resultados vigentes');
      ok = check_local(ok, isempty(findobj('type', 'figure')), ...
        'R5 sin figuras abiertas');
    catch err
      fprintf(2, 'FALLO R5 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- R6: contrato de recurso + rutas relativas, no base64 ----------
    try
      limpiar_dir_local(tmpdir);
      m = modelo_minimo_local('ENRIQUECIDO', true, true);
      opts = struct('incluir_2d', true, 'incluir_3d', true, ...
        'incluir_overlay', true, 'visible', false, 'directorio', tmpdir);
      [rv, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      recs = [lista_local(rv, 'planos'), lista_local(rv, 'graficos')];
      ok = check_local(ok, numel(recs) >= 1, 'R6 hay recursos');
      for i = 1:numel(recs)
        r = recs{i};
        ok = check_local(ok, isfield(r, 'id') && isfield(r, 'tipo') ...
          && isfield(r, 'titulo') && isfield(r, 'formato') ...
          && isfield(r, 'unidades') && isfield(r, 'origen') ...
          && isfield(r, 'ruta_relativa') && isfield(r, 'vigente') ...
          && isfield(r, 'asset_scope'), ...
          sprintf('R6 contrato campos id=%s', campo_id_local(r)));
        ok = check_local(ok, strcmp(char(r.formato), 'PNG'), 'R6 formato PNG');
        ok = check_local(ok, strcmp(char(r.origen), 'REGENERABLE_AOSCAD'), ...
          'R6 origen regenerable');
        ok = check_local(ok, ~isfield(r, 'base64') && ~isfield(r, 'blob'), ...
          'R6 sin base64/blob');
        rr = char(r.ruta_relativa);
        ok = check_local(ok, ~isempty(rr) && isempty(strfind(rr, ':')) ...
          && rr(1) ~= '/' && rr(1) ~= '\', ...
          sprintf('R6 ruta relativa %s', rr));
        [~, bn, be] = fileparts(rr);
        cands = {fullfile(tmpdir, rr), fullfile(tmpdir, [bn be]), ...
          fullfile(root, 'intercambio', 'cad', rr)};
        encontrado = false;
        for c = 1:numel(cands)
          if exist(cands{c}, 'file') == 2
            encontrado = true; break;
          endif
        endfor
        ok = check_local(ok, encontrado, ...
          sprintf('R6 PNG existe para %s', campo_id_local(r)));
      endfor
      ok = check_local(ok, isempty(findobj('type', 'figure')), ...
        'R6 sin figuras abiertas');
    catch err
      fprintf(2, 'FALLO R6 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- P1: round-trip ENRIQUECIDO via escribir/leer ----------
    out_a = '';
    try
      limpiar_dir_local(tmpdir);
      m = modelo_minimo_local('ENRIQUECIDO', true, true);
      m.recursos_visuales = struct( ...
        'tipo', 'RECURSOS_VIEWER', 'planos', {{}}, 'graficos', {{}}, ...
        'vigente', false, 'obsoletos', false, ...
        'nota', 'pendiente');
      if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
        CONFIG_ACTIVA = struct();
      endif
      if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
        CONFIG_ACTIVA.cad_topologia = struct();
      endif
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m;
      out_a = fullfile(tmpdir, 'roundtrip_enriquecido.aoscad');
      ruta = aos_aoscad_escribir(out_a, 'ENRIQUECIDO', true);
      ok = check_local(ok, exist(ruta, 'file') == 2, 'P1 archivo escrito');
      leido = aos_aoscad_leer(ruta, true);
      ok = check_local(ok, strcmp(char(leido.info.schema), 'AOSCAD-0.0.1-DEV1'), ...
        'P1 schema exacto');
      ok = check_local(ok, strcmp(char(leido.info.aoscad_perfil), 'ENRIQUECIDO'), ...
        'P1 perfil ENRIQUECIDO');
      ok = check_local(ok, isstruct(leido.recursos_visuales), 'P1 recursos struct');
      recs = [lista_local(leido.recursos_visuales, 'planos'), ...
              lista_local(leido.recursos_visuales, 'graficos')];
      ok = check_local(ok, numel(recs) >= 1, 'P1 recursos presentes tras round-trip');
      ok = check_local(ok, isfield(leido.recursos_visuales, 'vigente') ...
        && logical(leido.recursos_visuales.vigente), 'P1 vigente=true');
      for i = 1:numel(recs)
        r = recs{i};
        rr = char(r.ruta_relativa);
        ok = check_local(ok, ~isempty(rr) && isempty(strfind(rr, ':')), ...
          sprintf('P1 ruta relativa %s', rr));
        [~, bn, be] = fileparts(rr);
        cands = {fullfile(root, 'intercambio', 'cad', rr), ...
          fullfile(root, 'intercambio', 'cad', 'recursos', [bn be]), ...
          fullfile(tmpdir, rr), fullfile(tmpdir, [bn be])};
        encontrado = false;
        for c = 1:numel(cands)
          if exist(cands{c}, 'file') == 2
            info = dir(cands{c});
            if ~isempty(info) && info.bytes > 0
              encontrado = true; break;
            endif
          endif
        endfor
        ok = check_local(ok, encontrado, ...
          sprintf('P1 PNG legible id=%s', campo_id_local(r)));
      endfor
    catch err
      fprintf(2, 'FALLO P1 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- P2: legacy sin recursos_visuales lee sin error ni warning nuevo ---
    try
      m = modelo_minimo_local('SIMPLE', true, false);
      if isfield(m, 'recursos_visuales'), m = rmfield(m, 'recursos_visuales'); endif
      m.info.aoscad_perfil = 'SIMPLE';
      legacy = fullfile(tmpdir, 'legacy_sin_recursos.aoscad');
      texto = jsonencode(m);
      fid = fopen(legacy, 'wt');
      fprintf(fid, '%s\n', texto);
      fclose(fid);
      % No usar warning('off'): captura lastwarn sin silenciar el sistema.
      lastwarn('');
      leido = aos_aoscad_leer(legacy, true);
      [wmsg, wid] = lastwarn();
      ok = check_local(ok, isstruct(leido), 'P2 lee legacy');
      ok = check_local(ok, isfield(leido, 'recursos_visuales'), ...
        'P2 default recursos_visuales');
      ok = check_local(ok, isempty(wmsg), ...
        sprintf('P2 sin warnings nuevos (%s)', wid));
      ok = check_local(ok, strcmp(char(leido.info.schema), 'AOSCAD-0.0.1-DEV1'), ...
        'P2 schema exacto');
    catch err
      fprintf(2, 'FALLO P2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- P3: invalidacion deja recursos no vigentes ----------
    try
      m = modelo_minimo_local('ENRIQUECIDO', true, true);
      opts = struct('incluir_2d', true, 'incluir_3d', true, ...
        'incluir_overlay', true, 'visible', false, 'directorio', tmpdir);
      [rv, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      m.recursos_visuales = rv;
      [m2, ~] = aos_cad_invalidar_simulacion(m, 'edicion test persistencia');
      ok = check_local(ok, strcmp(char(m2.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'P3 estado invalidado');
      ok = check_local(ok, isstruct(m2.recursos_visuales) ...
        && isfield(m2.recursos_visuales, 'vigente') ...
        && ~logical(m2.recursos_visuales.vigente), ...
        'P3 recursos vigente=false');
      ok = check_local(ok, isfield(m2.recursos_visuales, 'obsoletos') ...
        && logical(m2.recursos_visuales.obsoletos), ...
        'P3 recursos obsoletos=true');
      % Persistir invalidado vía JSON directo (escribir exige simulacion vigente)
      out_inv = fullfile(tmpdir, 'invalidado_recursos.aoscad');
      texto = jsonencode(m2);
      fid = fopen(out_inv, 'wt');
      fprintf(fid, '%s\n', texto);
      fclose(fid);
      leido = aos_aoscad_leer(out_inv, true);
      ok = check_local(ok, strcmp(char(leido.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'P3 lee estado invalidado');
      ok = check_local(ok, isstruct(leido.recursos_visuales) ...
        && isfield(leido.recursos_visuales, 'vigente') ...
        && ~logical(leido.recursos_visuales.vigente), ...
        'P3 Viewer no vigente tras leer');
      ok = check_local(ok, isfield(leido.recursos_visuales, 'obsoletos') ...
        && logical(leido.recursos_visuales.obsoletos), ...
        'P3 Viewer ve obsoletos');
    catch err
      fprintf(2, 'FALLO P3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- P4: fallo PNG no corrompe .aoscad existente ----------
    try
      m = modelo_minimo_local('ENRIQUECIDO', true, false);
      if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
        CONFIG_ACTIVA = struct();
      endif
      CONFIG_ACTIVA.cad_topologia = struct('modelo_aoscad', m);
      out_p4 = fullfile(tmpdir, 'atomico_png.aoscad');
      aos_aoscad_escribir(out_p4, 'ENRIQUECIDO', true);
      ok = check_local(ok, exist(out_p4, 'file') == 2, 'P4a archivo inicial');
      fid = fopen(out_p4, 'rt');
      raw_antes = fread(fid, Inf, 'char=>char')';
      fclose(fid);
      ok = check_local(ok, ~isempty(strtrim(raw_antes)), 'P4a contenido inicial');

      % Forzar fallo de generacion: directorio de recursos = archivo (no dir)
      rec_dir = fullfile(root, 'intercambio', 'cad', 'recursos');
      backup_rec = '';
      bloqueo = fullfile(tmpdir, 'bloqueo_recursos_como_archivo');
      try
        if exist(rec_dir, 'dir') == 7
          backup_rec = [rec_dir '_bak_p4'];
          if exist(backup_rec, 'dir') == 7
            % ya hay backup; no tocar
            backup_rec = '';
          else
            movefile(rec_dir, backup_rec);
          endif
        endif
        % crear archivo donde deberia ir el directorio
        if exist(rec_dir, 'file') ~= 2 && exist(rec_dir, 'dir') ~= 7
          fid = fopen(rec_dir, 'wt');
          fprintf(fid, 'bloqueo\n');
          fclose(fid);
          bloqueo = rec_dir;
        endif

        m2 = modelo_minimo_local('ENRIQUECIDO', true, false);
        m2.recursos_visuales = struct( ...
          'tipo', 'RECURSOS_VIEWER', 'planos', {{}}, 'graficos', {{}}, ...
          'vigente', false, 'obsoletos', true, 'nota', 'forzar regen');
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m2;
        % Debe completar escritura atomica aunque PNG falle
        ruta2 = aos_aoscad_escribir(out_p4, 'ENRIQUECIDO', true);
        ok = check_local(ok, exist(ruta2, 'file') == 2, 'P4b archivo tras fallo PNG');
        leido = aos_aoscad_leer(ruta2, true);
        ok = check_local(ok, strcmp(char(leido.info.schema), 'AOSCAD-0.0.1-DEV1'), ...
          'P4b JSON valido tras fallo PNG');
        ok = check_local(ok, isfield(leido, 'tablas_entrada'), ...
          'P4b tablas intactas');
      catch err_inner
        fprintf(2, 'FALLO P4b excepcion: %s\n', err_inner.message);
        ok = false;
      end_try_catch
      % restaurar
      try
        if exist(bloqueo, 'file') == 2 && strcmp(bloqueo, rec_dir)
          delete(rec_dir);
        endif
        if ~isempty(backup_rec) && exist(backup_rec, 'dir') == 7
          if exist(rec_dir, 'dir') ~= 7 && exist(rec_dir, 'file') ~= 2
            movefile(backup_rec, rec_dir);
          endif
        endif
      catch
      end_try_catch
    catch err
      fprintf(2, 'FALLO P4 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    set(0, 'defaultfigurevisible', vis_anterior);
    try
      figs = findobj('type', 'figure');
      if ~isempty(figs), close(figs); endif
    catch
    end_try_catch
    CONFIG_ACTIVA = prev;
    try
      limpiar_dir_local(tmpdir);
    catch
    end_try_catch
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_aoscad_recursos_visuales APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_aoscad_recursos_visuales NO APROBADO\n');
  endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('  OK  %s\n', msg);
  else
    fprintf(2, '  FALLO %s\n', msg);
    ok = false;
  endif
endfunction

function m = modelo_minimo_local(perfil, con_resultados, con_escena)
  m = aos_aoscad_nuevo_paquete(perfil, 'INSTALACION', 'HIDRAULICO');
  m.tablas_entrada.nodos = { ...
    struct('id', 'N001', 'x', 0, 'y', 0, 'z', 0), ...
    struct('id', 'N002', 'x', 10, 'y', 0, 'z', 0)};
  m.tablas_entrada.tramos = { ...
    struct('id', 'T001', 'nodo_origen', 'N001', 'nodo_destino', 'N002', ...
      'x1', 0, 'y1', 0, 'x2', 10, 'y2', 0, 'diametro_m', 0.1)};
  if con_resultados
    m.simulacion.estado = 'EJECUTADA';
    m.simulacion.motor = 'AOSCAD-HIDRAULICA-0.0.1-DEV1';
    m.simulacion.corrida_id = 'TEST_REC_VIS';
    m.tablas_resultados.nodos = { ...
      struct('id', 'N001', 'presion_Pa', 2e5), ...
      struct('id', 'N002', 'presion_Pa', 1.5e5)};
    m.tablas_resultados.tramos = { ...
      struct('id', 'T001', 'caudal_liquido_m3s', 0.012)};
  else
    m.simulacion.estado = 'NO_EJECUTADA';
    m.tablas_resultados = struct('nodos', {{}}, 'tramos', {{}});
  endif
  if con_escena
    m.escena_3d = struct( ...
      'vigente', true, ...
      'n_objetos', 3, ...
      'objetos', {{ ...
        struct('id', 'N001', 'tipo', 'NODO', 'visible', true, ...
          'puntos', [0 0 0], 'ancla', [0 0 0]), ...
        struct('id', 'N002', 'tipo', 'NODO', 'visible', true, ...
          'puntos', [10 0 0], 'ancla', [10 0 0]), ...
        struct('id', 'T001', 'tipo', 'TRAMO', 'visible', true, ...
          'puntos', [0 0 0; 10 0 0])}});
  endif
endfunction

function arr = lista_local(rv, campo)
  arr = {};
  if ~isstruct(rv) || ~isfield(rv, campo) || isempty(rv.(campo)), return; endif
  v = rv.(campo);
  if iscell(v)
    arr = v;
  elseif isstruct(v)
    arr = cell(1, numel(v));
    for i = 1:numel(v), arr{i} = v(i); endfor
  endif
endfunction

function ids = ids_recursos_local(rv)
  ids = {};
  recs = [lista_local(rv, 'planos'), lista_local(rv, 'graficos')];
  for i = 1:numel(recs)
    if isstruct(recs{i}) && isfield(recs{i}, 'id')
      ids{end+1} = char(recs{i}.id); %#ok<AGROW>
    endif
  endfor
endfunction

function tf = recurso_real_local(rv, tmpdir)
  tf = false;
  recs = [lista_local(rv, 'planos'), lista_local(rv, 'graficos')];
  for i = 1:numel(recs)
    r = recs{i};
    if ~isstruct(r) || ~isfield(r, 'ruta_relativa'), continue; endif
    rr = char(r.ruta_relativa);
    [~, bn, be] = fileparts(rr);
    cands = {fullfile(tmpdir, rr), fullfile(tmpdir, [bn be]), ...
      fullfile(aos_cad_raiz(), 'intercambio', 'cad', rr)};
    for c = 1:numel(cands)
      if exist(cands{c}, 'file') == 2
        info = dir(cands{c});
        if ~isempty(info) && info.bytes > 0
          tf = true; return;
        endif
      endif
    endfor
  endfor
endfunction

function tf = item_info_sin_escena_local(items)
  tf = false;
  if isempty(items), return; endif
  if ~iscell(items), items = {items}; endif
  for i = 1:numel(items)
    it = items{i};
    if ~isstruct(it), continue; endif
    txt = '';
    if isfield(it, 'mensaje'), txt = [txt char(it.mensaje)]; endif
    if isfield(it, 'codigo'), txt = [txt ' ' char(it.codigo)]; endif
    if isfield(it, 'severidad'), sev = upper(char(it.severidad)); else sev = ''; endif
    up = upper(txt);
    if (~isempty(strfind(up, 'ESCENA')) || ~isempty(strfind(up, '3D'))) ...
        && (isempty(sev) || strcmp(sev, 'INFO') || strcmp(sev, 'ADVERTENCIA'))
      tf = true; return;
    endif
  endfor
endfunction

function id = campo_id_local(r)
  id = '?';
  if isstruct(r) && isfield(r, 'id'), id = char(r.id); endif
endfunction

function limpiar_dir_local(d)
  if exist(d, 'dir') ~= 7, return; endif
  files = dir(d);
  for i = 1:numel(files)
    if files(i).isdir, continue; endif
    try
      delete(fullfile(d, files(i).name));
    catch
    end_try_catch
  endfor
endfunction

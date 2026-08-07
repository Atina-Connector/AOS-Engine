function ok = test_aos_cad_dxf_edicion_externa()
% TEST_AOS_CAD_DXF_EDICION_EXTERNA Copia de trabajo DXF (simetrica a STEP).
% No lanza LibreCAD GUI. Headless.
  ok = true;
  global CONFIG_ACTIVA;
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_anillo.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALLO fixture ausente: %s\n', dxf);
    ok = false;
    fprintf('RESULTADO: test_aos_cad_dxf_edicion_externa NO APROBADO\n');
    return;
  endif

  dir_ed = fullfile(root, 'intercambio', 'cad', 'edicion');
  [~, nom, ext] = fileparts(dxf);
  copia_esperada = fullfile(dir_ed, [nom, ext]);
  if exist(copia_esperada, 'file') == 2
    delete(copia_esperada);
  endif

  hash0 = hash_archivo_local(dxf);
  mt0 = aos_cad_mtime(dxf);

  unwind_protect
  % --- D1: abrir/preparar edicion NO registra el fixture como editable ---
  try
    CONFIG_ACTIVA = struct();
    CONFIG_ACTIVA.cad_topologia = struct( ...
      'dxf_archivo', dxf, ...
      'marcador_sesion', 'SESION_ACTIVA_D1');

    [copia, info] = aos_cad_dxf_copia_edicion(dxf, struct( ...
      'forzar_recopia', true, ...
      'registrar_contexto', true));

    ct = CONFIG_ACTIVA.cad_topologia;
    ok = check_local(ok, exist(copia, 'file') == 2, 'D1 copia existe');
    ok = check_local(ok, strcmpi(copia, copia_esperada), 'D1 ruta bajo edicion');
    ok = check_local(ok, ~strcmpi(copia, dxf), 'D1 copia distinta del fixture');
    ok = check_local(ok, ~ruta_es_fixture_ejemplos_local(copia), ...
      'D1 destino no es fixture ejemplos');
    ok = check_local(ok, isfield(ct, 'dxf_archivo_origen') ...
      && strcmpi(char(ct.dxf_archivo_origen), dxf), 'D1 origen registrado');
    ok = check_local(ok, isfield(ct, 'dxf_archivo_edicion') ...
      && strcmpi(char(ct.dxf_archivo_edicion), copia), 'D1 copia registrada');
    ok = check_local(ok, isfield(ct, 'dxf_archivo') ...
      && strcmpi(char(ct.dxf_archivo), copia), ...
      'D1 editable (dxf_archivo) es la copia');
    ok = check_local(ok, ~strcmpi(char(ct.dxf_archivo), dxf), ...
      'D1 fixture NO es archivo editable');
    ok = check_local(ok, isfield(ct, 'dxf_mtime') && ~isempty(ct.dxf_mtime), ...
      'D1 mtime de copia registrado');
    ok = check_local(ok, logical(info.copiado), 'D1 flag copiado');
    ok = check_local(ok, strcmp(char(ct.marcador_sesion), 'SESION_ACTIVA_D1'), ...
      'D1 sesion no destruida');
  catch err
    fprintf(2, 'FALLO D1 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- D2: copia no altera hash/mtime del fixture ---
  try
    pause(1.05);
    [copia2, info2] = aos_cad_dxf_copia_edicion(dxf, struct('forzar_recopia', true));
    hash1 = hash_archivo_local(dxf);
    mt1 = aos_cad_mtime(dxf);
    ok = check_local(ok, strcmpi(copia2, copia_esperada), 'D2 ruta bajo edicion');
    ok = check_local(ok, logical(info2.copiado), 'D2 flag copiado');
    ok = check_local(ok, strcmp(hash1, hash0), 'D2 hash fixture intacto');
    ok = check_local(ok, abs(mt1 - mt0) < 1e-6, 'D2 mtime fixture intacto');
  catch err
    fprintf(2, 'FALLO D2 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- D3: reutilizar copia existente sin forzar ---
  try
    mt_c0 = aos_cad_mtime(copia_esperada);
    [copia3, info3] = aos_cad_dxf_copia_edicion(dxf, struct());
    mt_c1 = aos_cad_mtime(copia_esperada);
    ok = check_local(ok, strcmpi(copia3, copia_esperada), 'D3 misma ruta');
    ok = check_local(ok, logical(info3.reutilizado), 'D3 reutilizado');
    ok = check_local(ok, ~logical(info3.copiado), 'D3 no recopiado');
    ok = check_local(ok, abs(mt_c1 - mt_c0) < 1e-6, 'D3 mtime copia estable');
  catch err
    fprintf(2, 'FALLO D3 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- D4: sincronizar desde la copia preserva hash/mtime del fixture ---
  try
    CONFIG_ACTIVA = struct();
    aos_cad_importar_dxf(dxf, true);
    [copia4, ~] = aos_cad_dxf_copia_edicion(dxf, struct( ...
      'forzar_recopia', true, 'registrar_contexto', true));
    hash_pre = hash_archivo_local(dxf);
    mt_pre = aos_cad_mtime(dxf);

    pause(1.05);
    fid = fopen(copia4, 'a');
    if fid >= 0
      fprintf(fid, '\n0\nCOMMENT\n1\nAOS_DXF_EDIT_TOUCH\n');
      fclose(fid);
    endif

    ok_imp = aos_cad_importar_dxf(copia4, true);
    ok = check_local(ok, ok_imp, 'D4 reimport desde copia ok');
    hash_post = hash_archivo_local(dxf);
    mt_post = aos_cad_mtime(dxf);
    ok = check_local(ok, strcmp(hash_post, hash_pre), ...
      'D4 sync desde copia: hash fixture intacto');
    ok = check_local(ok, abs(mt_post - mt_pre) < 1e-6, ...
      'D4 sync desde copia: mtime fixture intacto');
    ct4 = CONFIG_ACTIVA.cad_topologia;
    ok = check_local(ok, isfield(ct4, 'dxf_archivo') ...
      && strcmpi(char(ct4.dxf_archivo), copia4), ...
      'D4 sesion apunta a copia editable');
    ok = check_local(ok, isfield(ct4, 'dxf_archivo_origen') ...
      && strcmpi(char(ct4.dxf_archivo_origen), dxf), ...
      'D4 origen fixture conservado');
  catch err
    fprintf(2, 'FALLO D4 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- D5: copia ausente / truncada / no legible -> item; sesion viva ---
  try
    CONFIG_ACTIVA = struct();
    aos_cad_importar_dxf(dxf, true);
    CONFIG_ACTIVA.cad_topologia.marcador_sesion = 'SESION_ACTIVA_D5';
    n_ent_prev = 0;
    if isfield(CONFIG_ACTIVA.cad_topologia, 'n_entidades')
      n_ent_prev = CONFIG_ACTIVA.cad_topologia.n_entidades;
    endif

    [copia5, ~] = aos_cad_dxf_copia_edicion(dxf, struct('forzar_recopia', true));

    % D5a: truncada
    fid = fopen(copia5, 'wb');
    if fid >= 0
      fwrite(fid, uint8('0\nSEC'), 'uint8');
      fclose(fid);
    endif
    [~, info_tr] = aos_cad_dxf_copia_edicion(dxf, struct( ...
      'forzar_recopia', false, ...
      'registrar_contexto', true, ...
      'validar_copia', true));
    ok = check_local(ok, isfield(info_tr, 'item') && isstruct(info_tr.item) ...
      && isfield(info_tr.item, 'codigo') ...
      && ~isempty(char(info_tr.item.codigo)), ...
      'D5a item por copia truncada');
    ok = check_local(ok, ...
      strcmp(char(CONFIG_ACTIVA.cad_topologia.marcador_sesion), 'SESION_ACTIVA_D5'), ...
      'D5a sesion no destruida (truncada)');
    ok = check_local(ok, ...
      isfield(CONFIG_ACTIVA.cad_topologia, 'n_entidades') ...
      && CONFIG_ACTIVA.cad_topologia.n_entidades == n_ent_prev, ...
      'D5a inventario sesion conservado (truncada)');

    % D5b: ausente (sin reparar: item + sesion intacta)
    fantasma = fullfile(dir_ed, 'dxf_edicion_fantasma_ausente.dxf');
    if exist(fantasma, 'file') == 2
      delete(fantasma);
    endif
    [~, info_au2] = aos_cad_dxf_copia_edicion(dxf, struct( ...
      'forzar_recopia', false, ...
      'registrar_contexto', true, ...
      'validar_copia', true, ...
      'ruta_copia_forzada', fantasma, ...
      'no_reparar', true));
    ok = check_local(ok, isfield(info_au2, 'item') && isstruct(info_au2.item) ...
      && isfield(info_au2.item, 'codigo'), ...
      'D5b item por copia ausente');
    ok = check_local(ok, ...
      strcmp(char(CONFIG_ACTIVA.cad_topologia.marcador_sesion), 'SESION_ACTIVA_D5'), ...
      'D5b sesion no destruida (ausente)');

    % D5c: no legible (binario basura)
    fid = fopen(copia5, 'wb');
    if fid >= 0
      fwrite(fid, uint8([0 255 1 2 3 4 5 6 7 8]), 'uint8');
      fclose(fid);
    endif
    [~, info_nl] = aos_cad_dxf_copia_edicion(dxf, struct( ...
      'forzar_recopia', false, ...
      'registrar_contexto', true, ...
      'validar_copia', true, ...
      'no_reparar', true));
    ok = check_local(ok, isfield(info_nl, 'item') && isstruct(info_nl.item) ...
      && isfield(info_nl.item, 'codigo'), ...
      'D5c item por copia no legible');
    ok = check_local(ok, ...
      strcmp(char(CONFIG_ACTIVA.cad_topologia.marcador_sesion), 'SESION_ACTIVA_D5'), ...
      'D5c sesion no destruida (no legible)');
    ok = check_local(ok, tiene_item_codigo_local(CONFIG_ACTIVA.cad_topologia, ...
      char(info_nl.item.codigo)), ...
      'D5c item persistido en sesion');
  catch err
    fprintf(2, 'FALLO D5 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % Limpieza de copias de este test
  if exist(copia_esperada, 'file') == 2
    delete(copia_esperada);
  endif
  fantasma = fullfile(dir_ed, 'dxf_edicion_fantasma_ausente.dxf');
  if exist(fantasma, 'file') == 2
    delete(fantasma);
  endif

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_dxf_edicion_externa APROBADO\n');
  else
    fprintf('RESULTADO: test_aos_cad_dxf_edicion_externa NO APROBADO\n');
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

function tf = ruta_es_fixture_ejemplos_local(ruta)
  tf = false;
  ruta = strrep(lower(char(ruta)), '/', filesep);
  marca = lower(fullfile('datos', 'ejemplos', 'cad'));
  tf = ~isempty(strfind(ruta, marca)); %#ok<STREMP>
endfunction

function h = hash_archivo_local(archivo)
  h = '';
  fid = fopen(archivo, 'rb');
  if fid < 0, return; endif
  data = fread(fid, Inf, 'uint8=>uint8');
  fclose(fid);
  try
    h = aos_asset_hash(char(data(:)'), 16);
  catch
    h = sprintf('%d_%d', numel(data), sum(double(data(:))));
  end_try_catch
endfunction

function tf = tiene_item_codigo_local(ct, codigo)
  tf = false;
  if ~isstruct(ct), return; endif
  items = {};
  if isfield(ct, 'dxf_items') && ~isempty(ct.dxf_items)
    items = ct.dxf_items;
  endif
  if ~iscell(items), items = {items}; endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), char(codigo))
      tf = true;
      return;
    endif
  endfor
endfunction

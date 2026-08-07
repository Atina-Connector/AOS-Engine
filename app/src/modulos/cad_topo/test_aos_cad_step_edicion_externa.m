function ok = test_aos_cad_step_edicion_externa()
% TEST_AOS_CAD_STEP_EDICION_EXTERNA Copia de trabajo + traer STEP exportado.
% No lanza FreeCAD GUI. Headless.
  ok = true;
  global CONFIG_ACTIVA;
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
  if exist(step, 'file') ~= 2
    fprintf(2, 'FALLO fixture ausente: %s\n', step);
    ok = false;
    fprintf('RESULTADO: test_aos_cad_step_edicion_externa NO APROBADO\n');
    return;
  endif

  dir_ed = fullfile(root, 'intercambio', 'cad', 'edicion');
  [~, nom, ext] = fileparts(step);
  copia_esperada = fullfile(dir_ed, [nom, ext]);
  % Limpieza previa de la copia de este fixture (no tocar otros)
  if exist(copia_esperada, 'file') == 2
    delete(copia_esperada);
  endif

  unwind_protect
  % --- E1: copia no altera mtime del origen ---
  try
    mt0 = aos_cad_mtime(step);
    pause(1.05); % margen de reloj de archivos en Windows
    [copia, info] = aos_cad_step_copia_edicion(step, struct('forzar_recopia', true));
    mt1 = aos_cad_mtime(step);
    ok = check_local(ok, exist(copia, 'file') == 2, 'E1 copia existe');
    ok = check_local(ok, strcmpi(copia, copia_esperada), 'E1 ruta bajo edicion');
    ok = check_local(ok, logical(info.copiado), 'E1 flag copiado');
    ok = check_local(ok, abs(mt1 - mt0) < 1e-6, 'E1 mtime origen intacto');
  catch err
    fprintf(2, 'FALLO E1 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- E2: reutilizar copia existente sin forzar ---
  try
    mt_c0 = aos_cad_mtime(copia_esperada);
    [copia2, info2] = aos_cad_step_copia_edicion(step, struct());
    mt_c1 = aos_cad_mtime(copia_esperada);
    ok = check_local(ok, strcmpi(copia2, copia_esperada), 'E2 misma ruta');
    ok = check_local(ok, logical(info2.reutilizado), 'E2 reutilizado');
    ok = check_local(ok, ~logical(info2.copiado), 'E2 no recopiado');
    ok = check_local(ok, abs(mt_c1 - mt_c0) < 1e-6, 'E2 mtime copia estable');
  catch err
    fprintf(2, 'FALLO E2 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- E3: traer STEP exportado invalida escena + simulacion ---
  try
    CONFIG_ACTIVA = struct();
    aos_cad_importar_step(step, true);
    [esc, ~] = aos_cad_escena_3d(CONFIG_ACTIVA.cad_topologia, struct());
    esc.vigente = true;
    CONFIG_ACTIVA.cad_topologia.escena_3d = esc;
    CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local();

    % Simula export: escribe una variante en edicion con mtime nuevo
    exportado = fullfile(dir_ed, 'export_freecad_simulado.step');
    copiar_binario_test_local(step, exportado);
    % tocar contenido minimo para fingerprint distinto + mtime
    fid = fopen(exportado, 'a');
    if fid >= 0
      fprintf(fid, '\n/* AOS_EXPORT_SIM %s */\n', datestr(now, 30));
      fclose(fid);
    endif

    ok_tr = aos_cad_traer_step_exportado(exportado, true);
    ok = check_local(ok, ok_tr, 'E3 traer ok');
    ct = CONFIG_ACTIVA.cad_topologia;
    ok = check_local(ok, isfield(ct, 'escena_3d') && isstruct(ct.escena_3d) ...
      && isfield(ct.escena_3d, 'vigente') && ~ct.escena_3d.vigente, ...
      'E3 escena no vigente');
    ok = check_local(ok, isfield(ct, 'vinculo_3d') && isstruct(ct.vinculo_3d) ...
      && isfield(ct.vinculo_3d, 'vigente') && ~ct.vinculo_3d.vigente, ...
      'E3 vinculo no vigente');
    ok = check_local(ok, tiene_codigo_local(ct, 'ESCENA_3D_INVALIDADA_POR_EDICION'), ...
      'E3 item ESCENA_3D_INVALIDADA_POR_EDICION');
    ok = check_local(ok, isfield(ct, 'step_archivo_edicion') ...
      && ~isempty(ct.step_archivo_edicion), 'E3 step_archivo_edicion');
    ok = check_local(ok, isfield(ct, 'modelo_aoscad') && isstruct(ct.modelo_aoscad) ...
      && isfield(ct.modelo_aoscad, 'simulacion') ...
      && strcmp(char(ct.modelo_aoscad.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
      'E3 simulacion.estado INVALIDADA_POR_EDICION tras traer');
  catch err
    fprintf(2, 'FALLO E3 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- E4: recarga por mtime sobre copia de edicion ---
  try
    CONFIG_ACTIVA = struct();
    [copia, ~] = aos_cad_step_copia_edicion(step, struct('forzar_recopia', true));
    aos_cad_importar_step(copia, true);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local();
    CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
    CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);
    aos_cad_registrar_mtime(copia);
    mt_prev = CONFIG_ACTIVA.cad_topologia.step_mtime;
    pause(1.05);
    fid = fopen(copia, 'a');
    if fid >= 0
      fprintf(fid, '\n/* AOS_MTIME_TOUCH %s */\n', datestr(now, 30));
      fclose(fid);
    endif
    hubo = aos_cad_recargar_si_cambio(false, true);
    ok = check_local(ok, hubo, 'E4 recargar detecta mtime en copia edicion');
    ok = check_local(ok, ...
      abs(CONFIG_ACTIVA.cad_topologia.step_mtime - mt_prev) > 1e-9, ...
      'E4 step_mtime actualizado');
    ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad) ...
      && strcmp(char(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.simulacion.estado), ...
        'INVALIDADA_POR_EDICION'), ...
      'E4 simulacion.estado INVALIDADA_POR_EDICION tras recarga');
  catch err
    fprintf(2, 'FALLO E4 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_step_edicion_externa APROBADO\n');
  else
    fprintf('RESULTADO: test_aos_cad_step_edicion_externa NO APROBADO\n');
  endif
endfunction

function m = modelo_ejecutado_local()
  m = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  m.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
  m.simulacion.estado = 'EJECUTADA';
  m.simulacion.corrida_id = 'E_PREV';
  m.tablas_resultados.nodos = {struct('id', 'N001', 'P_Pa', 1e5)};
  m.tablas_resultados.tramos = {struct('id', 'T001', 'Q_m3s', 0.01)};
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO: %s\n', msg);
    ok = false;
  endif
endfunction

function tf = tiene_codigo_local(ct, codigo)
  tf = false;
  if ~isstruct(ct) || ~isfield(ct, 'step_items'), return; endif
  its = ct.step_items;
  if ~iscell(its), its = {its}; endif
  for i = 1:numel(its)
    it = its{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo)
      tf = true;
      return;
    endif
  endfor
endfunction

function copiar_binario_test_local(origen, destino)
  fid_in = fopen(origen, 'rb');
  data = fread(fid_in, Inf, 'uint8=>uint8');
  fclose(fid_in);
  fid_out = fopen(destino, 'wb');
  fwrite(fid_out, data, 'uint8');
  fclose(fid_out);
endfunction

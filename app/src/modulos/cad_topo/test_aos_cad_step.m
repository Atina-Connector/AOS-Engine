function ok = test_aos_cad_step()
% TEST_AOS_CAD_STEP Prueba interna STEP. FreeCAD es editor externo opcional.
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

  fprintf('\n=== test_aos_cad_step ===\n');

  det = aos_cad_localizar_programa('FreeCAD');
  freecad_disponible = det.encontrado;
  if freecad_disponible
    fprintf('OK  FreeCAD detectado [%s]: %s\n', det.metodo, det.gui_cmd);
    if det.cli_disponible
      fprintf('OK  Interfaz FreeCAD de consola disponible (%d comando/s candidato/s).\n', numel(det.cli_cmds));
    else
      fprintf('AVISO  FreeCAD GUI detectado, pero no se confirmo interfaz de consola.\n');
    endif
  else
    fprintf('AVISO  FreeCAD no localizado por PATH, Flatpak, Snap, AppImage ni .desktop.\n');
    fprintf('       Solo queda sin probar la edicion visual externa en FreeCAD.\n');
  endif

  % occt-draw / Open CASCADE suelto: opcional informativo (Windows ausente por construccion).
  try
    req_plat = aos_verificar_requisitos_plataforma(false);
    occt_ok = false;
    if isstruct(req_plat) && isfield(req_plat, 'opencascade') ...
        && isstruct(req_plat.opencascade) && isfield(req_plat.opencascade, 'encontrado')
      occt_ok = logical(req_plat.opencascade.encontrado);
    endif
    if occt_ok
      fprintf('OK  occt-draw / Open CASCADE detectado (opcional).\n');
    else
      fprintf('AVISO  occt-draw / Open CASCADE suelto no disponible (opcional; en Windows esperado).\n');
    endif
  catch
    fprintf('AVISO  no se pudo consultar Open CASCADE/occt-draw (opcional).\n');
  end_try_catch

  step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  if exist(step, 'file') ~= 2
    fprintf(2, 'FALTA STEP de ejemplo: %s\n', step);
    ok = false;
    return;
  endif

  modelo = aos_step_leer(step);
  if modelo.n_entidades < 10
    fprintf(2, 'FALLO: se esperaban >=10 entidades STEP, hay %d.\n', modelo.n_entidades);
    ok = false;
  else
    fprintf('OK  entidades=%d\n', modelo.n_entidades);
  endif
  if modelo.n_solidos < 1
    fprintf(2, 'FALLO: se esperaba >=1 solido BREP.\n');
    ok = false;
  else
    fprintf('OK  solidos=%d\n', modelo.n_solidos);
  endif
  if modelo.n_productos < 1
    fprintf(2, 'FALLO: se esperaba >=1 PRODUCT.\n');
    ok = false;
  else
    fprintf('OK  productos=%d\n', modelo.n_productos);
  endif

  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  if ~aos_cad_importar_step(step, true)
    fprintf(2, 'FALLO: aos_cad_importar_step\n');
    ok = false;
  else
    fprintf('OK  import a CONFIG_ACTIVA.cad_topologia (step_*)\n');
    if ~isfield(CONFIG_ACTIVA.cad_topologia, 'step_archivo')
      fprintf(2, 'FALLO: falta step_archivo\n');
      ok = false;
    endif
  endif

  aos_cad_registrar_mtime(step);
  if ~aos_cad_recargar_si_cambio(true, true)
    fprintf(2, 'FALLO: recarga forzada STEP\n');
    ok = false;
  else
    fprintf('OK  recarga forzada STEP\n');
  endif

  % Export *_AOS_REV.step sin tocar la fuente
  fuente = CONFIG_ACTIVA.cad_topologia.step_archivo;
  mt0 = aos_cad_mtime(fuente);
  out_rev = fullfile(root, 'intercambio', 'cad', 'enviados', 'demo_aos_equipment_AOS_REV.step');
  outdir = fileparts(out_rev);
  if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
  try
    ruta = aos_cad_exportar_step_rev(out_rev, true);
    if exist(ruta, 'file') ~= 2
      fprintf(2, 'FALLO: REV STEP no creado\n');
      ok = false;
    else
      fprintf('OK  STEP REV creado: %s\n', ruta);
    endif
    mt1 = aos_cad_mtime(fuente);
    if abs(mt1 - mt0) > 1e-6
      fprintf(2, 'FALLO: mtime fuente STEP cambio\n');
      ok = false;
    else
      fprintf('OK  fuente STEP intacta (mtime)\n');
    endif
    if strcmpi(strrep(fuente, '\', '/'), strrep(ruta, '\', '/'))
      fprintf(2, 'FALLO: REV igual a fuente\n');
      ok = false;
    endif
  catch err
    fprintf(2, 'FALLO export STEP REV: %s\n', err.message);
    ok = false;
  end_try_catch

  % Sprint 2: asset_id por producto STEP + estabilidad ante reimport
  CONFIG_ACTIVA = struct();
  if aos_cad_importar_step(step, true)
    idx1 = CONFIG_ACTIVA.cad_topologia.id_index_step;
    aids1 = {};
    if isfield(idx1, 'items')
      for i = 1:numel(idx1.items)
        it = idx1.items{i};
        if isfield(it, 'asset_id') && ~isempty(it.asset_id)
          aids1{end+1} = char(it.asset_id); %#ok<AGROW>
        endif
      endfor
    endif
    if isempty(aids1)
      fprintf(2, 'FALLO: sin asset_id en productos STEP\n');
      ok = false;
    else
      fprintf('OK  asset_id STEP por producto (%d)\n', numel(aids1));
      if numel(unique(aids1)) ~= numel(aids1)
        fprintf(2, 'FALLO: asset_id STEP no unicos\n');
        ok = false;
      else
        fprintf('OK  asset_id STEP unicos\n');
      endif
    endif
    CONFIG_ACTIVA = struct();
    aos_cad_importar_step(step, true);
    idx2 = CONFIG_ACTIVA.cad_topologia.id_index_step;
    aids2 = {};
    if isfield(idx2, 'items')
      for i = 1:numel(idx2.items)
        it = idx2.items{i};
        if isfield(it, 'asset_id') && ~isempty(it.asset_id)
          aids2{end+1} = char(it.asset_id); %#ok<AGROW>
        endif
      endfor
    endif
    if isequal(sort(aids1), sort(aids2))
      fprintf('OK  asset_id STEP estable ante reimport\n');
    else
      fprintf(2, 'FALLO: asset_id STEP no estable ante reimport\n');
      ok = false;
    endif
  else
    fprintf(2, 'FALLO: reimport STEP para asset_id\n');
    ok = false;
  endif

  % ---------- Sprint 5 D3: checks aditivos (no tocan asserts congelados) ----------
  try
    if ~isfield(modelo, 'indice_geometrico') || ~isstruct(modelo.indice_geometrico)
      fprintf(2, 'FALLO: falta modelo.indice_geometrico (aditivo Sprint 5)\n');
      ok = false;
    else
      fprintf('OK  indice_geometrico presente (aditivo)\n');
    endif

    % id_index_step conserva campos previos; geometry_id es campo adicional
    if isfield(CONFIG_ACTIVA, 'cad_topologia') ...
        && isfield(CONFIG_ACTIVA.cad_topologia, 'id_index_step')
      idx_s5 = CONFIG_ACTIVA.cad_topologia.id_index_step;
      campos_prev = {'handle', 'id', 'id_estable', 'asset_id', 'tabla', 'producto'};
      if ~isfield(idx_s5, 'items') || isempty(idx_s5.items)
        fprintf(2, 'FALLO: id_index_step sin items para check aditivo\n');
        ok = false;
      else
        todos_campos = true;
        todos_gid = true;
        for i = 1:numel(idx_s5.items)
          it = idx_s5.items{i};
          for c = 1:numel(campos_prev)
            if ~isfield(it, campos_prev{c})
              todos_campos = false;
              break;
            endif
          endfor
          if ~isfield(it, 'geometry_id')
            todos_gid = false;
          endif
        endfor
        if todos_campos
          fprintf('OK  id_index_step conserva campos previos (handle/id/id_estable/asset_id/tabla/producto)\n');
        else
          fprintf(2, 'FALLO: id_index_step perdio campos previos\n');
          ok = false;
        endif
        if todos_gid
          fprintf('OK  geometry_id en items de id_index_step (aditivo)\n');
        else
          fprintf(2, 'FALLO: falta geometry_id en items de id_index_step\n');
          ok = false;
        endif
      endif
    else
      fprintf(2, 'FALLO: falta id_index_step para check aditivo\n');
      ok = false;
    endif
  catch err
    fprintf(2, 'FALLO checks aditivos Sprint 5: %s\n', err.message);
    ok = false;
  end_try_catch

  if ok
    if freecad_disponible
      fprintf('RESULTADO: test_aos_cad_step APROBADO (integracion externa FreeCAD disponible)\n');
    else
      fprintf('RESULTADO: test_aos_cad_step APROBADO (FreeCAD externo opcional no instalado)\n');
    endif
  else
    fprintf(2, 'RESULTADO: test_aos_cad_step NO APROBADO\n');
  endif
endfunction

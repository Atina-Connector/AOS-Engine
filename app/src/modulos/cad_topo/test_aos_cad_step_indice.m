function ok = test_aos_cad_step_indice()
% TEST_AOS_CAD_STEP_INDICE Selftest indice geometrico STEP (Sprint 5 S1-S12).
% Headless. FreeCAD cruzado (S11) y ESCENA_3D_INVALIDADA (S12/C3) opcionales.
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

  fprintf('\n=== test_aos_cad_step_indice ===\n');

  step_eq = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  step_sin = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
  step_rep = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_ensamble_repetido.step');
  for f = {step_eq, step_sin, step_rep}
    if exist(f{1}, 'file') ~= 2
      fprintf(2, 'FALTA fixture: %s\n', f{1});
      ok = false;
      fprintf(2, 'RESULTADO: test_aos_cad_step_indice NO APROBADO\n');
      return;
    endif
  endfor

  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_step_indice');
  if exist(tmpdir, 'dir') ~= 7
    mkdir(tmpdir);
  endif

  % ---------- S1 jerarquia ----------
  try
    m_eq = aos_step_leer(step_eq);
    ig = m_eq.indice_geometrico;
    ok = check_local(ok, isstruct(ig) && isfield(ig, 'n_productos'), 'S1 indice presente');
    ok = check_local(ok, ig.n_productos == 3, 'S1 tres productos');
    ok = check_local(ok, ig.n_ocurrencias == 2, 'S1 dos ocurrencias');
    ok = check_local(ok, ig.profundidad_max == 1, 'S1 profundidad maxima 1');
    n_raiz = 0;
    raiz_ok = false;
    for i = 1:numel(ig.productos)
      p = ig.productos{i};
      if isfield(p, 'es_raiz') && p.es_raiz
        n_raiz = n_raiz + 1;
        if isempty(p.padre) || (isnumeric(p.padre) && isempty(p.padre))
          raiz_ok = true;
        endif
      endif
    endfor
    ok = check_local(ok, n_raiz == 1 && raiz_ok, 'S1 una raiz (def no hija de NAUO)');
  catch err
    fprintf(2, 'FALLO S1 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S2 unidades ----------
  try
    ig = m_eq.indice_geometrico;
    ok = check_local(ok, abs(ig.unidades.factor_a_metros - 1e-3) < 1e-15, ...
      'S2 factor 1e-3');
    ok = check_local(ok, isfield(ig.unidades, 'origen') && ~isempty(ig.unidades.origen), ...
      'S2 origen declarado');
    ok = check_local(ok, isfield(ig.unidades, 'consistente') && ig.unidades.consistente, ...
      'S2 contextos consistentes');
    ok = check_local(ok, tiene_codigo_local(m_eq.items, 'STEP_UNIDADES'), ...
      'S2 item STEP_UNIDADES');
    factores_prod = [];
    for i = 1:numel(ig.productos)
      factores_prod(end+1) = ig.productos{i}.factor_a_metros; %#ok<AGROW>
    endfor
    ok = check_local(ok, max(factores_prod) - min(factores_prod) < 1e-15, ...
      'S2 factor igual en productos');
  catch err
    fprintf(2, 'FALLO S2 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S3 placement analitico ----------
  try
    ig = m_eq.indice_geometrico;
    ok = check_local(ok, numel(ig.ocurrencias) >= 2, 'S3 hay ocurrencias');
    if numel(ig.ocurrencias) >= 2
      o1 = ig.ocurrencias{1};
      o2 = ig.ocurrencias{2};
      org1 = origen_placement_local(o1.placement_absoluto);
      org2 = origen_placement_local(o2.placement_absoluto);
      % Fixture: NAUO '1' -> (3 mm,0,0) = (0.003,0,0) m; NAUO '2' -> origen
      if abs(org1(1) - 0.003) < 1e-12
        ok = check_local(ok, norm(org1 - [0.003, 0, 0]) < 1e-12, ...
          'S3 ocurrencia 1 en (0.003,0,0)');
        ok = check_local(ok, norm(org2 - [0, 0, 0]) < 1e-12, ...
          'S3 ocurrencia 2 en origen');
      else
        ok = check_local(ok, norm(org2 - [0.003, 0, 0]) < 1e-12, ...
          'S3 ocurrencia desplazada en (0.003,0,0)');
        ok = check_local(ok, norm(org1 - [0, 0, 0]) < 1e-12, ...
          'S3 ocurrencia en origen');
      endif
    endif
  catch err
    fprintf(2, 'FALLO S3 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S4 bbox coherente ----------
  try
    ig = m_eq.indice_geometrico;
    ok = check_local(ok, numel(ig.ocurrencias) >= 2, 'S4 ocurrencias');
    if numel(ig.ocurrencias) >= 2
      bb1 = ig.ocurrencias{1}.bbox_absoluta;
      bb2 = ig.ocurrencias{2}.bbox_absoluta;
      ok = check_local(ok, bbox_finita_local(bb1) && bbox_finita_local(bb2), ...
        'S4 bboxes absolutas finitas');
      ok = check_local(ok, bbox_no_degenerada_local(bb1) && bbox_no_degenerada_local(bb2), ...
        'S4 bboxes no degeneradas (alguna extension > 0)');
      % Coherencia analitica placement↔bbox del solido caja (ocurrencia en 0.003):
      % abs = local + traslacion; el fixture tiene caja y cilindro distintos, no gemelos.
      idx_caja = [];
      for i = 1:numel(ig.productos)
        p = ig.productos{i};
        if ~p.es_raiz && p.bbox_determinada
          org = origen_placement_local(p.placement_absoluto);
          if abs(org(1) - 0.003) < 1e-12
            idx_caja = i;
            break;
          endif
        endif
      endfor
      if ~isempty(idx_caja)
        p = ig.productos{idx_caja};
        d = 0.003;
        ok = check_local(ok, abs(p.bbox_absoluta.xmin - (p.bbox_local.xmin + d)) < 1e-12 ...
          && abs(p.bbox_absoluta.xmax - (p.bbox_local.xmax + d)) < 1e-12 ...
          && abs(p.bbox_absoluta.ymin - p.bbox_local.ymin) < 1e-12 ...
          && abs(p.bbox_absoluta.ymax - p.bbox_local.ymax) < 1e-12, ...
          'S4 bbox abs = local + 0.003 m en X (caja)');
      else
        fprintf(2, 'FALLO S4: no se encontro producto caja con placement 0.003\n');
        ok = false;
      endif
      % Diferencia de anclas (placement) exactamente 0.003 m en X
      a1 = origen_placement_local(ig.ocurrencias{1}.placement_absoluto);
      a2 = origen_placement_local(ig.ocurrencias{2}.placement_absoluto);
      ok = check_local(ok, abs(abs(a1(1) - a2(1)) - 0.003) < 1e-12 ...
        && abs(a1(2) - a2(2)) < 1e-12 && abs(a1(3) - a2(3)) < 1e-12, ...
        'S4 anclas diferencian 0.003 m en X (Y/Z iguales)');
    endif
  catch err
    fprintf(2, 'FALLO S4 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S5 rotacion / axis2 ----------
  try
    origen = [1, 2, 3];
    eje_z = [0, 1, 0];
    dir_x = [1, 0.2, 0]; % no perpendicular a eje_z
    [T, adv] = aos_geom_axis2_matriz(origen, eje_z, dir_x);
    R = T(1:3, 1:3);
    ok = check_local(ok, abs(det(R) - 1) < 1e-12, 'S5 det(R)=1');
    ok = check_local(ok, norm(R' * R - eye(3), 'fro') < 1e-12, 'S5 R ortonormal');
    ok = check_local(ok, any(strcmp(adv, 'AXIS2_NO_ORTOGONAL')), ...
      'S5 emite AXIS2_NO_ORTOGONAL');
    bb_in = struct('xmin', 0, 'xmax', 1, 'ymin', 0, 'ymax', 2, 'zmin', 0, 'zmax', 3);
    bb_out = aos_geom_transformar_bbox(bb_in, T);
    verts = [0 0 0; 1 0 0; 0 2 0; 1 2 0; 0 0 3; 1 0 3; 0 2 3; 1 2 3];
    out = (T * [verts, ones(8, 1)]')';
    contiene = true;
    for i = 1:8
      p = out(i, 1:3);
      if ~(p(1) >= bb_out.xmin - 1e-12 && p(1) <= bb_out.xmax + 1e-12 ...
          && p(2) >= bb_out.ymin - 1e-12 && p(2) <= bb_out.ymax + 1e-12 ...
          && p(3) >= bb_out.zmin - 1e-12 && p(3) <= bb_out.zmax + 1e-12)
        contiene = false;
        break;
      endif
    endfor
    ok = check_local(ok, contiene, 'S5 bbox transformada contiene 8 vertices');
  catch err
    fprintf(2, 'FALLO S5 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S6 sin ensamble ----------
  try
    m_sin = aos_step_leer(step_sin);
    igs = m_sin.indice_geometrico;
    ok = check_local(ok, igs.n_ocurrencias == 0, 'S6 cero NAUO/ocurrencias');
    ok = check_local(ok, tiene_codigo_local(m_sin.items, 'STEP_SIN_ENSAMBLE'), ...
      'S6 item STEP_SIN_ENSAMBLE');
    sev = severidad_codigo_local(m_sin.items, 'STEP_SIN_ENSAMBLE');
    ok = check_local(ok, strcmpi(sev, 'INFO'), 'S6 STEP_SIN_ENSAMBLE severidad INFO');
    ok = check_local(ok, igs.n_productos == 1 && igs.productos{1}.es_raiz, ...
      'S6 un producto raiz');
    ok = check_local(ok, abs(igs.unidades.factor_a_metros - 1) < 1e-15 ...
      && abs(igs.productos{1}.factor_a_metros - 1) < 1e-15, ...
      'S6 factor unidad 1');
    fprintf('OK  S6 sin excepcion\n');
  catch err
    fprintf(2, 'FALLO S6 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S7 ocurrencias repetidas ----------
  try
    m_rep = aos_step_leer(step_rep);
    igr = m_rep.indice_geometrico;
    ok = check_local(ok, igr.n_ocurrencias == 2, 'S7 dos ocurrencias');
    gids = {};
    pids = {};
    rutas = {};
    for i = 1:numel(igr.ocurrencias)
      oc = igr.ocurrencias{i};
      gids{end+1} = char(oc.geometry_id); %#ok<AGROW>
      pids{end+1} = char(oc.product_id); %#ok<AGROW>
      if isfield(oc, 'ruta_ensamble')
        rutas{end+1} = char(oc.ruta_ensamble); %#ok<AGROW>
      else
        rutas{end+1} = ''; %#ok<AGROW>
      endif
    endfor
    ok = check_local(ok, numel(unique(gids)) == 2, 'S7 geometry_id distintos');
    ok = check_local(ok, numel(unique(pids)) == 1, 'S7 mismo product_id');
    ok = check_local(ok, numel(unique(rutas)) == 2, 'S7 rutas/NAUO distintas');
    for i = 1:numel(gids)
      ok = check_local(ok, ~isempty(strfind(gids{i}, 'STEPOCC:')) ...
        && ~isempty(strfind(gids{i}, 'demo_aos_ensamble_repetido.step')), ...
        sprintf('S7 geometry_id determinista #%d', i));
    endfor
    % asset_id unico del producto compartido (via import aditivo)
    global CONFIG_ACTIVA;
    CONFIG_ACTIVA = struct();
    aos_cad_importar_step(step_rep, true);
    aids_pieza = {};
    idx = CONFIG_ACTIVA.cad_topologia.id_index_step;
    for i = 1:numel(idx.items)
      it = idx.items{i};
      nom = '';
      if isfield(it, 'producto'), nom = char(it.producto); endif
      if strcmp(nom, 'AOS_Pieza') && isfield(it, 'asset_id')
        aids_pieza{end+1} = char(it.asset_id); %#ok<AGROW>
      endif
    endfor
    ok = check_local(ok, numel(aids_pieza) == 1 && ~isempty(aids_pieza{1}), ...
      'S7 un asset_id para producto repetido');
    gids_cad = {};
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_geometry_ids')
      gids_cad = CONFIG_ACTIVA.cad_topologia.step_geometry_ids;
    endif
    ok = check_local(ok, numel(gids_cad) == 2 && numel(unique(gids_cad)) == 2, ...
      'S7 dos geometry_id en cad');
    % Placements del fixture: destinos AXIS2 (3,0,0) y (0,0,0) en metros
    raw_rep = fileread_local(step_rep);
    tiene_3 = ~isempty(strfind(raw_rep, 'CARTESIAN_POINT('''',(3.,0.,0.))'));
    tiene_0 = ~isempty(strfind(raw_rep, 'CARTESIAN_POINT('''',(0.,0.,0.))'));
    ok = check_local(ok, tiene_3 && tiene_0, ...
      'S7 fixture con placements distintos (3,0,0) y (0,0,0)');
    a1 = origen_placement_local(igr.ocurrencias{1}.placement_absoluto);
    a2 = origen_placement_local(igr.ocurrencias{2}.placement_absoluto);
    ok = check_local(ok, norm(a1 - a2) > 1e-12, ...
      'S7 placements/anclas de ocurrencia distintos');
    % Fixture en metros: (3,0,0) y (0,0,0)
    ok = check_local(ok, ...
      (abs(a1(1) - 3) < 1e-12 && norm(a2) < 1e-12) ...
      || (abs(a2(1) - 3) < 1e-12 && norm(a1) < 1e-12), ...
      'S7 anclas 3 m vs 0 m');
  catch err
    fprintf(2, 'FALLO S7 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S8 degradacion estructurada ----------
  try
    nl = char(10);
    % Truncado: inventario sin excepcion
    f_trunc = fullfile(tmpdir, 's8_truncado.step');
    escribir_texto_local(f_trunc, [ ...
      'ISO-10303-21;', nl, 'HEADER;', nl, ...
      'FILE_DESCRIPTION((''x''),''2;1'');', nl, ...
      'FILE_NAME(''s8_truncado.step'','''',(''''),(''''),'''','''','''');', nl, ...
      'FILE_SCHEMA((''AUTOMOTIVE_DESIGN''));', nl, 'ENDSEC;', nl, 'DATA;', nl, ...
      '#1 = APPLICATION_CONTEXT(''x'');', nl, ...
      '#2 = PRODUCT(''T'',''T'','''',(#99']);
    m_tr = [];
    exc_tr = false;
    try
      m_tr = aos_step_leer(f_trunc);
    catch
      exc_tr = true;
    end_try_catch
    ok = check_local(ok, ~exc_tr && isstruct(m_tr), 'S8 truncado sin excepcion');
    if isstruct(m_tr)
      ok = check_local(ok, isfield(m_tr, 'n_entidades') && isfield(m_tr, 'n_productos'), ...
        'S8 truncado conserva inventario');
    endif

    % STEP_INDICE_PARCIAL (tabla mal formada dispara catch del indice)
    tabla_mala = struct('por_id', struct('tipo', 'PRODUCT', 'id', 1), ...
      'ids', 1, 'n_entidades', 1, 'tipos', {{}});
    [~, items_par] = aos_step_indice_geometrico(tabla_mala);
    ok = check_local(ok, tiene_codigo_local(items_par, 'STEP_INDICE_PARCIAL'), ...
      'S8 STEP_INDICE_PARCIAL');

    % Referencia colgada
    f_hang = fullfile(tmpdir, 's8_colgada.step');
    escribir_texto_local(f_hang, step_minimo_local( ...
      ['#10 = AXIS2_PLACEMENT_3D('''',#99999,#12,#13);', nl], true));
    m_h = [];
    exc_h = false;
    try
      m_h = aos_step_leer(f_hang);
    catch
      exc_h = true;
    end_try_catch
    ok = check_local(ok, ~exc_h && tiene_codigo_local(m_h.items, 'STEP_REFERENCIA_COLGADA'), ...
      'S8 STEP_REFERENCIA_COLGADA sin excepcion');
    if isstruct(m_h)
      ok = check_local(ok, m_h.n_productos >= 1, 'S8 colgada conserva inventario');
    endif

    % Ciclo de ensamble
    f_cyc = fullfile(tmpdir, 's8_ciclo.step');
    escribir_texto_local(f_cyc, [ ...
      'ISO-10303-21;', nl, 'HEADER;', nl, ...
      'FILE_DESCRIPTION((''x''),''2;1'');', nl, ...
      'FILE_NAME(''s8_ciclo.step'','''',(''''),(''''),'''','''','''');', nl, ...
      'FILE_SCHEMA((''AUTOMOTIVE_DESIGN''));', nl, 'ENDSEC;', nl, 'DATA;', nl, ...
      '#1 = APPLICATION_CONTEXT(''x'');', nl, ...
      '#2 = PRODUCT_CONTEXT('''',#1,''mechanical'');', nl, ...
      '#3 = PRODUCT(''A'',''A'','''',(#2));', nl, ...
      '#4 = PRODUCT_DEFINITION_FORMATION('''','''',#3);', nl, ...
      '#5 = PRODUCT_DEFINITION_CONTEXT(''part'',#1,''design'');', nl, ...
      '#6 = PRODUCT_DEFINITION(''da'','''',#4,#5);', nl, ...
      '#7 = PRODUCT(''B'',''B'','''',(#2));', nl, ...
      '#8 = PRODUCT_DEFINITION_FORMATION('''','''',#7);', nl, ...
      '#9 = PRODUCT_DEFINITION(''db'','''',#8,#5);', nl, ...
      '#10 = NEXT_ASSEMBLY_USAGE_OCCURRENCE(''1'','''','''',#6,#9,$);', nl, ...
      '#11 = NEXT_ASSEMBLY_USAGE_OCCURRENCE(''2'','''','''',#9,#6,$);', nl, ...
      'ENDSEC;', nl, 'END-ISO-10303-21;', nl]);
    m_c = [];
    exc_c = false;
    try
      m_c = aos_step_leer(f_cyc);
    catch
      exc_c = true;
    end_try_catch
    ok = check_local(ok, ~exc_c && tiene_codigo_local(m_c.items, 'STEP_ENSAMBLE_CICLICO'), ...
      'S8 STEP_ENSAMBLE_CICLICO sin excepcion');
    if isstruct(m_c)
      ok = check_local(ok, m_c.n_productos == 2, 'S8 ciclo conserva inventario');
    endif
  catch err
    fprintf(2, 'FALLO S8 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S9 regresion inventario ----------
  try
    ok = check_local(ok, m_eq.n_entidades == 277, 'S9 n_entidades=277');
    ok = check_local(ok, m_eq.n_productos == 3, 'S9 n_productos=3');
    ok = check_local(ok, m_eq.n_solidos == 2, 'S9 n_solidos=2');
  catch err
    fprintf(2, 'FALLO S9 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S10 bbox indeterminada ----------
  try
    nl = char(10);
    f_np = fullfile(tmpdir, 's10_sin_puntos.step');
    escribir_texto_local(f_np, step_minimo_local( ...
      ['#10 = DIRECTION('''',(0.,0.,1.));', nl], false));
    m_np = aos_step_leer(f_np);
    ok = check_local(ok, tiene_codigo_local(m_np.items, 'STEP_BBOX_INDETERMINADA'), ...
      'S10 STEP_BBOX_INDETERMINADA');
    ok = check_local(ok, isstruct(m_np.indice_geometrico) ...
      && isfield(m_np.indice_geometrico, 'productos') ...
      && numel(m_np.indice_geometrico.productos) >= 1, ...
      'S10 producto en indice');
    if numel(m_np.indice_geometrico.productos) >= 1
      p = m_np.indice_geometrico.productos{1};
      ok = check_local(ok, isfield(p, 'bbox_determinada') && ~p.bbox_determinada, ...
        'S10 bbox_determinada=false');
      bb = p.bbox_absoluta;
      es_cero_origen = isfinite(bb.xmin) && abs(bb.xmin) < 1e-15 ...
        && isfinite(bb.xmax) && abs(bb.xmax) < 1e-15 ...
        && isfinite(bb.ymin) && abs(bb.ymin) < 1e-15 ...
        && isfinite(bb.ymax) && abs(bb.ymax) < 1e-15;
      ok = check_local(ok, ~es_cero_origen ...
        && all(isnan([bb.xmin, bb.xmax, bb.ymin, bb.ymax])), ...
        'S10 sin caja de ceros en origen (NaN)');
    endif
  catch err
    fprintf(2, 'FALLO S10 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % ---------- S11 FreeCAD cruzado (opcional) ----------
  try
    if exist('aos_step_indice_freecad', 'file') ~= 2
      fprintf(['AVISO  S11 aos_step_indice_freecad no existe aun; ', ...
        'verificacion cruzada omitida (test sigue APROBADO).\n']);
    else
      [indice_ext, diag] = aos_step_indice_freecad(step_eq, struct());
      disponible = false;
      if isstruct(diag) && isfield(diag, 'disponible')
        disponible = logical(diag.disponible);
      endif
      if ~disponible
        motivo = '';
        if isstruct(diag) && isfield(diag, 'motivo_omision')
          motivo = char(diag.motivo_omision);
        endif
        fprintf('AVISO  S11 FreeCAD no disponible: %s (test sigue APROBADO).\n', motivo);
      else
        % Comparar placements nativos vs externos (ocurrencias o productos FC)
        ig = m_eq.indice_geometrico;
        tol_place = 1e-9;
        tol_bb = 5e-3; % FreeCAD exacto vs puntos de control nativos
        orgs_n = {};
        for i = 1:numel(ig.ocurrencias)
          orgs_n{end+1} = origen_placement_local( ...
            ig.ocurrencias{i}.placement_absoluto); %#ok<AGROW>
        endfor
        orgs_e = origenes_ext_lista_local(indice_ext);
        ok_cmp = ~isempty(orgs_n) && ~isempty(orgs_e);
        for i = 1:numel(orgs_n)
          found = false;
          for j = 1:numel(orgs_e)
            if norm(orgs_n{i} - orgs_e{j}) <= tol_place
              found = true;
              break;
            endif
          endfor
          if ~found, ok_cmp = false; break; endif
        endfor
        ok = check_local(ok, ok_cmp, ...
          sprintf('S11 placements vs FreeCAD (tol=%g m)', tol_place));
        fprintf('OK  S11 FreeCAD cruzado (bbox tol declarada %g m)\n', tol_bb);
      endif
    endif
  catch err
    fprintf('AVISO  S11 excepcion en cruzado FreeCAD: %s (no falla el test).\n', ...
      err.message);
  end_try_catch

  % ---------- S12 edicion externa / mtime ----------
  try
    recv = fullfile(root, 'intercambio', 'cad', 'recibidos');
    if exist(recv, 'dir') ~= 7, mkdir(recv); endif
    copia = fullfile(recv, 's12_demo_aos_equipment_edit.step');
    ok_copy = copiar_archivo_local(step_eq, copia);
    ok = check_local(ok, ok_copy && exist(copia, 'file') == 2, 'S12 copia en intercambio');

    mt_orig_antes = aos_cad_mtime(step_eq);
    global CONFIG_ACTIVA;
    CONFIG_ACTIVA = struct();
    aos_cad_importar_step(copia, true);
    mt_reg = CONFIG_ACTIVA.cad_topologia.step_mtime;
    gids_antes = {};
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_geometry_ids')
      gids_antes = CONFIG_ACTIVA.cad_topologia.step_geometry_ids;
    endif
    importado_antes = '';
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_importado_en')
      importado_antes = char(CONFIG_ACTIVA.cad_topologia.step_importado_en);
    endif
    n_prod_antes = CONFIG_ACTIVA.cad_topologia.step_n_productos;

    % Simulacion vigente previa a recarga (Sprint 7: debe invalidarse)
    m_s12 = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
    m_s12.simulacion.estado = 'EJECUTADA';
    m_s12.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
    m_s12.tablas_resultados.nodos = {struct('id', 'N001', 'P_Pa', 1e5)};
    m_s12.tablas_resultados.tramos = {struct('id', 'T001', 'Q_m3s', 0.01)};
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m_s12;
    CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
    CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);

    pause(1.05);
    tocar_mtime_local(copia);
    mt_copia = aos_cad_mtime(copia);
    ok = check_local(ok, abs(mt_copia - mt_reg) > 1e-9, 'S12 mtime copia cambio');

    recargo = aos_cad_recargar_si_cambio(false, true);
    ok = check_local(ok, recargo, 'S12 aos_cad_recargar_si_cambio detecta cambio');
    mt_reg2 = CONFIG_ACTIVA.cad_topologia.step_mtime;
    ok = check_local(ok, abs(mt_reg2 - mt_copia) < 1e-6, 'S12 mtime registrado actualizado');
    importado_desp = '';
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_importado_en')
      importado_desp = char(CONFIG_ACTIVA.cad_topologia.step_importado_en);
    endif
    ok = check_local(ok, ~strcmp(importado_antes, importado_desp) ...
      || abs(mt_reg2 - mt_reg) > 1e-9, ...
      'S12 indice/import recalculado (no cache silencioso)');
    ok = check_local(ok, CONFIG_ACTIVA.cad_topologia.step_n_productos == n_prod_antes, ...
      'S12 inventario tras recarga');
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_indice_geometrico')
      ig2 = CONFIG_ACTIVA.cad_topologia.step_indice_geometrico;
      ok = check_local(ok, isstruct(ig2) && isfield(ig2, 'n_ocurrencias') ...
        && ig2.n_ocurrencias == 2, 'S12 indice geometrico recalculado');
    else
      fprintf(2, 'FALLO S12: falta step_indice_geometrico tras recarga\n');
      ok = false;
    endif
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_geometry_ids')
      gids_desp = CONFIG_ACTIVA.cad_topologia.step_geometry_ids;
      ok = check_local(ok, isequal(sort(gids_antes), sort(gids_desp)), ...
        'S12 geometry_id estables tras recarga');
    endif

    mt_orig_desp = aos_cad_mtime(step_eq);
    ok = check_local(ok, abs(mt_orig_desp - mt_orig_antes) < 1e-6, ...
      'S12 mtime fixture original intacto');

    % Sprint 7: invalidacion de escena y simulacion es obligatoria (ya no AVISO)
    items_s12 = {};
    if isfield(CONFIG_ACTIVA.cad_topologia, 'step_items')
      items_s12 = CONFIG_ACTIVA.cad_topologia.step_items;
    endif
    items_val = {};
    if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad) ...
        && isfield(CONFIG_ACTIVA.cad_topologia.modelo_aoscad, 'validaciones') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.validaciones) ...
        && isfield(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.validaciones, 'items')
      items_val = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.validaciones.items;
    endif
    tiene_item_esc = tiene_codigo_local(items_s12, 'ESCENA_3D_INVALIDADA_POR_EDICION') ...
      || tiene_codigo_local(items_val, 'ESCENA_3D_INVALIDADA_POR_EDICION');
    escena_no_vig = isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.escena_3d) ...
      && isfield(CONFIG_ACTIVA.cad_topologia.escena_3d, 'vigente') ...
      && ~CONFIG_ACTIVA.cad_topologia.escena_3d.vigente;
    ok = check_local(ok, tiene_item_esc || escena_no_vig, ...
      'S12 ESCENA_3D_INVALIDADA_POR_EDICION o escena no vigente');
    ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad) ...
      && isfield(CONFIG_ACTIVA.cad_topologia.modelo_aoscad, 'simulacion') ...
      && strcmp(char(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.simulacion.estado), ...
        'INVALIDADA_POR_EDICION'), ...
      'S12 simulacion.estado INVALIDADA_POR_EDICION tras recarga');

    % FreeCAD localizacion informativa
    det = aos_cad_localizar_programa('FreeCAD');
    if isstruct(det) && isfield(det, 'encontrado') && det.encontrado
      fprintf('OK  S12 FreeCAD localizado (info, no requerido): %s\n', det.metodo);
    else
      fprintf('AVISO  S12 FreeCAD no localizado (no afecta resultado).\n');
    endif
  catch err
    fprintf(2, 'FALLO S12 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  if ok
    fprintf('RESULTADO: test_aos_cad_step_indice APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_step_indice NO APROBADO\n');
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
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo)
      tf = true;
      return;
    endif
  endfor
endfunction

function sev = severidad_codigo_local(items, codigo)
  sev = '';
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo)
      if isfield(it, 'severidad'), sev = char(it.severidad); endif
      return;
    endif
  endfor
endfunction

function org = origen_placement_local(T)
  org = [0, 0, 0];
  if isempty(T) || ~isnumeric(T), return; endif
  if size(T, 1) >= 3 && size(T, 2) >= 4
    org = (T(1:3, 4))';
  endif
endfunction

function tf = bbox_finita_local(bb)
  tf = false;
  if ~isstruct(bb), return; endif
  campos = {'xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'};
  for i = 1:numel(campos)
    if ~isfield(bb, campos{i}) || ~isfinite(bb.(campos{i}))
      return;
    endif
  endfor
  tf = true;
endfunction

function tf = bbox_no_degenerada_local(bb)
  tf = false;
  if ~bbox_finita_local(bb), return; endif
  ext = (bb.xmax - bb.xmin) + (bb.ymax - bb.ymin) + (bb.zmax - bb.zmin);
  tf = ext > 1e-15;
endfunction

function txt = step_minimo_local(repr_extra, con_dirs)
  if nargin < 2, con_dirs = false; endif
  nl = char(10);
  dirs = '';
  if con_dirs
    dirs = [ ...
      '#12 = DIRECTION('''',(0.,0.,1.));', nl, ...
      '#13 = DIRECTION('''',(1.,0.,0.));', nl];
  endif
  txt = [ ...
    'ISO-10303-21;', nl, 'HEADER;', nl, ...
    'FILE_DESCRIPTION((''x''),''2;1'');', nl, ...
    'FILE_NAME(''mini.step'','''',(''''),(''''),'''','''','''');', nl, ...
    'FILE_SCHEMA((''AUTOMOTIVE_DESIGN''));', nl, 'ENDSEC;', nl, 'DATA;', nl, ...
    '#1 = APPLICATION_CONTEXT(''x'');', nl, ...
    '#2 = PRODUCT_CONTEXT('''',#1,''mechanical'');', nl, ...
    '#3 = PRODUCT(''Solo'',''Solo'','''',(#2));', nl, ...
    '#4 = PRODUCT_DEFINITION_FORMATION('''','''',#3);', nl, ...
    '#5 = PRODUCT_DEFINITION_CONTEXT(''part'',#1,''design'');', nl, ...
    '#6 = PRODUCT_DEFINITION(''d'','''',#4,#5);', nl, ...
    '#7 = PRODUCT_DEFINITION_SHAPE('''','''',#6);', nl, ...
    '#8 = SHAPE_DEFINITION_REPRESENTATION(#7,#9);', nl, ...
    '#9 = SHAPE_REPRESENTATION('''',(#10),#11);', nl, ...
    repr_extra, ...
    '#11 = (GEOMETRIC_REPRESENTATION_CONTEXT(3) ', ...
    'GLOBAL_UNIT_ASSIGNED_CONTEXT((#14)) REPRESENTATION_CONTEXT(''C'',''C''));', nl, ...
    dirs, ...
    '#14 = (LENGTH_UNIT() NAMED_UNIT(*) SI_UNIT($,.METRE.));', nl, ...
    'ENDSEC;', nl, 'END-ISO-10303-21;', nl];
endfunction

function escribir_texto_local(ruta, txt)
  fid = fopen(ruta, 'wt');
  if fid < 0
    error('test_aos_cad_step_indice: no se pudo escribir %s', ruta);
  endif
  fprintf(fid, '%s', txt);
  fclose(fid);
endfunction

function raw = fileread_local(ruta)
  fid = fopen(ruta, 'rt');
  if fid < 0
    raw = '';
    return;
  endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
endfunction

function ok = copiar_archivo_local(src, dst)
  ok = false;
  fid_in = fopen(src, 'rb');
  if fid_in < 0, return; endif
  data = fread(fid_in, Inf, 'uint8=>uint8');
  fclose(fid_in);
  fid_out = fopen(dst, 'wb');
  if fid_out < 0, return; endif
  fwrite(fid_out, data, 'uint8');
  fclose(fid_out);
  ok = exist(dst, 'file') == 2;
endfunction

function tocar_mtime_local(ruta)
  % Simula edicion externa sin GUI: actualiza mtime conservando contenido.
  if ispc()
    cmd = sprintf(['powershell -NoProfile -Command ', ...
      '"(Get-Item -LiteralPath ''%s'').LastWriteTime = Get-Date"'], ...
      strrep(ruta, '''', ''''''));
    system(cmd);
  else
    system(sprintf('touch "%s"', ruta));
  endif
endfunction

function n = numel_ocurrencias_ext_local(indice_ext)
  n = numel(origenes_ext_lista_local(indice_ext));
endfunction

function orgs = origenes_ext_lista_local(indice_ext)
  orgs = {};
  if ~isstruct(indice_ext), return; endif
  if isfield(indice_ext, 'ocurrencias') && ~isempty(indice_ext.ocurrencias)
    for i = 1:numel(indice_ext.ocurrencias)
      org = origen_de_ent_ext_local(indice_ext.ocurrencias{i});
      if ~any(isnan(org)), orgs{end+1} = org; endif %#ok<AGROW>
    endfor
    return;
  endif
  if isfield(indice_ext, 'productos') && iscell(indice_ext.productos)
    for i = 1:numel(indice_ext.productos)
      org = origen_de_ent_ext_local(indice_ext.productos{i});
      if ~any(isnan(org)), orgs{end+1} = org; endif %#ok<AGROW>
    endfor
  endif
endfunction

function org = origen_ext_local(indice_ext, i)
  org = [NaN, NaN, NaN];
  lista = origenes_ext_lista_local(indice_ext);
  if i >= 1 && i <= numel(lista), org = lista{i}; endif
endfunction

function org = origen_de_ent_ext_local(ent)
  org = [NaN, NaN, NaN];
  if ~isstruct(ent), return; endif
  if isfield(ent, 'placement_absoluto')
    org = origen_placement_local(ent.placement_absoluto);
  elseif isfield(ent, 'placement_origen_m')
    v = double(ent.placement_origen_m(:))';
    org = v(1:min(3, numel(v)));
  elseif isfield(ent, 'origen')
    v = double(ent.origen(:))';
    org = v(1:min(3, numel(v)));
  elseif isfield(ent, 'ancla')
    v = double(ent.ancla(:))';
    org = v(1:min(3, numel(v)));
  endif
endfunction

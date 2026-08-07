function ok = test_aos_cad_roundtrip_ids()
% TEST_AOS_CAD_ROUNDTRIP_IDS Import → mutar snapshot → reimport simulado → IDs + ALTA/BAJA.
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

  fprintf('\n=== test_aos_cad_roundtrip_ids ===\n');
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells_meta.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA DXF: %s\n', dxf);
    ok = false;
    return;
  endif

  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  if ~aos_cad_importar_dxf(dxf, true)
    fprintf(2, 'FALLO import inicial\n');
    ok = false;
    return;
  endif

  m1 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  idx1 = CONFIG_ACTIVA.cad_topologia.id_index;
  if ~isfield(idx1, 'por_handle') || isempty(fieldnames(idx1.por_handle))
    fprintf(2, 'FALLO: id_index vacio tras import\n');
    ok = false;
    return;
  endif

  % Guardar IDs de nodos/tramos con handle
  ids_nodo = {};
  handles_nodo = {};
  for i = 1:numel(m1.tablas_entrada.nodos)
    n = m1.tablas_entrada.nodos{i};
    if isfield(n, 'handle') && ~isempty(n.handle)
      ids_nodo{end+1} = n.id; %#ok<AGROW>
      handles_nodo{end+1} = n.handle; %#ok<AGROW>
    endif
  endfor
  if isempty(ids_nodo)
    fprintf(2, 'FALLO: nodos sin handle\n');
    ok = false;
    return;
  endif
  id_stable = ids_nodo{1};
  h_stable = handles_nodo{1};
  fprintf('OK  snapshot id=%s handle=%s\n', id_stable, h_stable);

  % Mutar snapshot: renombrar id del primer handle a ID_CUSTOM
  % Clave namespaced por tabla (nodos:handle) — evita colision CIRCLE nodo/equipo
  safe = upper(char(['nodos:' h_stable]));
  safe = regexprep(safe, '[^A-Z0-9_]', '_');
  if safe(1) >= '0' && safe(1) <= '9', safe = ['H_' safe]; endif
  if ~isfield(CONFIG_ACTIVA.cad_topologia.id_index.por_handle, safe)
    fprintf(2, 'FALLO: clave namespaced nodos no indexada (%s)\n', safe);
    ok = false;
    return;
  endif
  CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe).id = 'ID_CUSTOM';
  CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe).id_estable = 'ID_CUSTOM';
  CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe).tabla = 'nodos';

  % Simular BAJA: añadir handle fantasma
  CONFIG_ACTIVA.cad_topologia.id_index.por_handle.NODOS_DEADBEEF = struct( ...
    'handle', 'DEADBEEF', 'id', 'GONE', 'id_estable', 'GONE', 'tabla', 'nodos');

  % Reimport forzado
  if ~aos_cad_importar_dxf(dxf, true)
    fprintf(2, 'FALLO reimport\n');
    ok = false;
    return;
  endif

  m2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  found = false;
  for i = 1:numel(m2.tablas_entrada.nodos)
    n = m2.tablas_entrada.nodos{i};
    if isfield(n, 'handle') && strcmp(char(n.handle), char(h_stable))
      if strcmp(n.id, 'ID_CUSTOM')
        found = true;
        fprintf('OK  ID conservado tras reimport: %s\n', n.id);
      else
        fprintf(2, 'FALLO: esperado ID_CUSTOM, got %s\n', n.id);
        ok = false;
      endif
    endif
  endfor
  if ~found && ok
    fprintf(2, 'FALLO: no se encontro nodo con handle %s\n', h_stable);
    ok = false;
  endif

  items = m2.validaciones.items;
  hay_baja = false;
  for i = 1:numel(items)
    if isfield(items{i}, 'codigo') && strcmp(items{i}.codigo, 'ID_BAJA')
      hay_baja = true;
    endif
  endfor
  if ~hay_baja
    fprintf(2, 'FALLO: no se reporto ID_BAJA\n');
    ok = false;
  else
    fprintf('OK  ID_BAJA reportado\n');
  endif

  % Sprint1 C3: round-trip ID sobre INSERT (bloque + posicion)
  dxf_b = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_bloques.dxf');
  if exist(dxf_b, 'file') == 2
    CONFIG_ACTIVA = struct();
    if aos_cad_importar_dxf(dxf_b, true)
      eqs = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.equipos;
      key_ins = '';
      for i = 1:numel(eqs)
        if isfield(eqs{i}, 'block_name') && ~isempty(eqs{i}.block_name)
          key_ins = sprintf('INSERT:%s:%.6f:%.6f', eqs{i}.block_name, ...
            eqs{i}.insert_x, eqs{i}.insert_y);
          break;
        endif
      endfor
      if ~isempty(key_ins)
        safe2 = upper(char(['equipos:' key_ins]));
        safe2 = regexprep(safe2, '[^A-Z0-9_]', '_');
        if safe2(1) >= '0' && safe2(1) <= '9', safe2 = ['H_' safe2]; endif
        if isfield(CONFIG_ACTIVA.cad_topologia.id_index.por_handle, safe2)
          CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe2).id = 'INSERT_CUSTOM';
          CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe2).id_estable = 'INSERT_CUSTOM';
          CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe2).tabla = 'equipos';
          aos_cad_importar_dxf(dxf_b, true);
          eqs2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.equipos;
          found_ins = false;
          for i = 1:numel(eqs2)
            if strcmp(char(eqs2{i}.id), 'INSERT_CUSTOM'), found_ins = true; break; endif
          endfor
          if found_ins
            fprintf('OK  ID INSERT_CUSTOM conservado (clave bloque+pos)\n');
          else
            fprintf(2, 'FALLO: ID INSERT no persistio\n');
            ok = false;
          endif
        else
          fprintf(2, 'FALLO: clave INSERT no indexada (%s)\n', safe2);
          ok = false;
        endif
      else
        fprintf(2, 'FALLO: sin equipos INSERT en demo_aos_bloques\n');
        ok = false;
      endif
    else
      fprintf(2, 'FALLO: import demo_aos_bloques\n');
      ok = false;
    endif
  else
    fprintf(2, 'FALLO: falta demo_aos_bloques.dxf\n');
    ok = false;
  endif

  % Sprint 2: id_index.por_handle sigue + asset_id se conserva en el ciclo
  dxf_b2 = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_bloques.dxf');
  if exist(dxf_b2, 'file') == 2
    CONFIG_ACTIVA = struct();
    if aos_cad_importar_dxf(dxf_b2, true)
      idx_a = CONFIG_ACTIVA.cad_topologia.id_index;
      ok_idx = isfield(idx_a, 'por_handle') && ~isempty(fieldnames(idx_a.por_handle));
      if ~ok_idx
        fprintf(2, 'FALLO: id_index.por_handle vacio (Sprint 2)\n');
        ok = false;
      else
        fprintf('OK  id_index.por_handle sigue operativo\n');
      endif
      m_a = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      snap_a = struct();
      n_aid = 0;
      for i = 1:numel(m_a.tablas_entrada.equipos)
        eq = m_a.tablas_entrada.equipos{i};
        if ~isfield(eq, 'block_name') || isempty(eq.block_name), continue; endif
        if ~isfield(eq, 'asset_id') || isempty(eq.asset_id), continue; endif
        key = sprintf('INSERT:%s:%.6f:%.6f', eq.block_name, eq.insert_x, eq.insert_y);
        safe = upper(char(key));
        safe = regexprep(safe, '[^A-Z0-9_]', '_');
        if safe(1) >= '0' && safe(1) <= '9', safe = ['H_' safe]; endif
        % Aid estable por INSERT (sin IDEST de TEXT cercano que el REV puede omitir)
        eq2 = eq;
        if isfield(eq2, 'id_estable'), eq2 = rmfield(eq2, 'id_estable'); endif
        [aid_ins, ~, ~] = aos_asset_id_generar('EQUIPO', eq2, 'equipos', struct());
        snap_a.(safe) = aid_ins;
        n_aid = n_aid + 1;
      endfor
      if n_aid < 1
        fprintf(2, 'FALLO: sin asset_id en equipos INSERT\n');
        ok = false;
      else
        out_rev = fullfile(tempdir(), sprintf('aos_rt_ids_%06d_AOS_REV.dxf', randi(999999)));
        ruta_rev = aos_cad_exportar_dxf_rev(out_rev, true);
        CONFIG_ACTIVA = struct();
        if aos_cad_importar_dxf(ruta_rev, true)
          ok_idx2 = isfield(CONFIG_ACTIVA.cad_topologia, 'id_index') ...
            && isfield(CONFIG_ACTIVA.cad_topologia.id_index, 'por_handle') ...
            && ~isempty(fieldnames(CONFIG_ACTIVA.cad_topologia.id_index.por_handle));
          if ~ok_idx2
            fprintf(2, 'FALLO: id_index perdido tras REV\n');
            ok = false;
          else
            fprintf('OK  id_index.por_handle tras REV\n');
          endif
          eqs_b = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.equipos;
          conservados = 0;
          for i = 1:numel(eqs_b)
            eq = eqs_b{i};
            if ~isfield(eq, 'block_name') || isempty(eq.block_name), continue; endif
            key = sprintf('INSERT:%s:%.6f:%.6f', eq.block_name, eq.insert_x, eq.insert_y);
            safe = upper(char(key));
            safe = regexprep(safe, '[^A-Z0-9_]', '_');
            if safe(1) >= '0' && safe(1) <= '9', safe = ['H_' safe]; endif
            eq2 = eq;
            if isfield(eq2, 'id_estable'), eq2 = rmfield(eq2, 'id_estable'); endif
            [aid_ins, ~, ~] = aos_asset_id_generar('EQUIPO', eq2, 'equipos', struct());
            if isfield(snap_a, safe) && strcmp(snap_a.(safe), aid_ins)
              conservados = conservados + 1;
            endif
          endfor
          if conservados == n_aid
            fprintf('OK  asset_id conservado en ciclo REV (%d)\n', conservados);
          else
            fprintf(2, 'FALLO: asset_id no conservado (%d/%d)\n', conservados, n_aid);
            ok = false;
          endif
        else
          fprintf(2, 'FALLO: reimport REV asset_id\n');
          ok = false;
        endif
        if exist(ruta_rev, 'file') == 2, delete(ruta_rev); endif
      endif
    else
      fprintf(2, 'FALLO: import bloques para asset_id\n');
      ok = false;
    endif
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_roundtrip_ids APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_roundtrip_ids NO APROBADO\n');
  endif
endfunction

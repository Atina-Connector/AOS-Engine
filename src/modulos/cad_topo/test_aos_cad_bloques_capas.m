function ok = test_aos_cad_bloques_capas()
% TEST_AOS_CAD_BLOQUES_CAPAS Round-trip capas de usuario, BLOCKS e INSERT.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_bloques_capas ===\n');
  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_bloques.dxf');
  ok = check_local(ok, exist(dxf, 'file') == 2, 'fixture demo_aos_bloques.dxf');
  if ~ok, report_final(ok); return; endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    mt0 = aos_cad_mtime(dxf);
    CONFIG_ACTIVA = struct();
    ok_imp = aos_cad_importar_dxf(dxf, true);
    ok = check_local(ok, ok_imp, 'import DXF bloques');
    cad = CONFIG_ACTIVA.cad_topologia;
    ok = check_local(ok, isfield(cad, 'n_bloques') && cad.n_bloques >= 1, 'n_bloques>=1');
    ok = check_local(ok, isfield(cad, 'bloques') && numel(cad.bloques) >= 1, 'bloques parseados');
    if isfield(cad, 'bloques') && numel(cad.bloques) >= 1
      ok = check_local(ok, strcmp(cad.bloques{1}.name, 'BOMBA_TIPO_A'), 'bloque BOMBA_TIPO_A');
    endif

    capas_nom = {};
    for i = 1:numel(cad.capas)
      if isstruct(cad.capas{i}) && isfield(cad.capas{i}, 'name')
        capas_nom{end+1} = char(cad.capas{i}.name); %#ok<AGROW>
      endif
    endfor
    ok = check_local(ok, any(strcmp(capas_nom, 'PROCESO')), 'capa PROCESO');
    ok = check_local(ok, any(strcmp(capas_nom, 'INSTRUMENTACION')), 'capa INSTRUMENTACION');

    n_insert = 0;
    if isfield(cad, 'conteo_tipos') && isfield(cad.conteo_tipos, 'INSERT')
      n_insert = cad.conteo_tipos.INSERT;
    endif
    ok = check_local(ok, n_insert >= 2, 'al menos 2 INSERT');

    modelo = cad.modelo_aoscad;
    equipos = modelo.tablas_entrada.equipos;
    n_eq_blk = 0;
    for i = 1:numel(equipos)
      if isfield(equipos{i}, 'block_name') && strcmp(equipos{i}.block_name, 'BOMBA_TIPO_A')
        n_eq_blk = n_eq_blk + 1;
      endif
    endfor
    ok = check_local(ok, n_eq_blk >= 2, 'equipos con block_name BOMBA_TIPO_A');

    % Mutar ID estable de un equipo INSERT y verificar round-trip via REV
    idx = CONFIG_ACTIVA.cad_topologia.id_index;
    eq_key = '';
    for i = 1:numel(equipos)
      if isfield(equipos{i}, 'block_name') && ~isempty(equipos{i}.block_name)
        x = equipos{i}.insert_x; y = equipos{i}.insert_y;
        eq_key = sprintf('equipos:INSERT:%s:%.6f:%.6f', equipos{i}.block_name, x, y);
        break;
      endif
    endfor
    safe = key_safe_local(eq_key);
    if isfield(idx, 'por_handle') && isfield(idx.por_handle, safe)
      CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe).id = 'EQ_CUSTOM';
      CONFIG_ACTIVA.cad_topologia.id_index.por_handle.(safe).id_estable = 'EQ_CUSTOM';
    endif

    out = fullfile(tempdir(), sprintf('aos_bloques_%06d_AOS_REV.dxf', randi(999999)));
    ruta = aos_cad_exportar_dxf_rev(out, true);
    ok = check_local(ok, exist(ruta, 'file') == 2, 'export REV generado');

    % Verificar contenido REV: capas usuario, BLOCK, INSERT, UNIDADES=m
    raw = fileread_local(ruta);
    ok = check_local(ok, ~isempty(strfind(raw, 'PROCESO')), 'REV contiene PROCESO');
    ok = check_local(ok, ~isempty(strfind(raw, 'INSTRUMENTACION')), 'REV contiene INSTRUMENTACION');
    ok = check_local(ok, ~isempty(strfind(raw, 'BOMBA_TIPO_A')), 'REV contiene BOMBA_TIPO_A');
    ok = check_local(ok, ~isempty(strfind(raw, 'AOS UNIDADES=m')), 'REV contiene AOS UNIDADES=m');
    ok = check_local(ok, ~isempty(strfind(upper(raw), 'INSERT')), 'REV contiene INSERT');

    % Reimport REV
    aos_cad_importar_dxf(ruta, true);
    cad2 = CONFIG_ACTIVA.cad_topologia;
    ok = check_local(ok, isfield(cad2, 'n_bloques') && cad2.n_bloques >= 1, 'reimport n_bloques');
    capas2 = {};
    for i = 1:numel(cad2.capas)
      if isstruct(cad2.capas{i}) && isfield(cad2.capas{i}, 'name')
        capas2{end+1} = char(cad2.capas{i}.name); %#ok<AGROW>
      endif
    endfor
    ok = check_local(ok, any(strcmp(capas2, 'PROCESO')), 'reimport capa PROCESO');
    n_ins2 = 0;
    if isfield(cad2, 'conteo_tipos') && isfield(cad2.conteo_tipos, 'INSERT')
      n_ins2 = cad2.conteo_tipos.INSERT;
    endif
    ok = check_local(ok, n_ins2 >= 2, 'reimport >=2 INSERT');

    % ID custom persistido por clave INSERT
    eqs2 = cad2.modelo_aoscad.tablas_entrada.equipos;
    hay_custom = false;
    for i = 1:numel(eqs2)
      if strcmp(char(eqs2{i}.id), 'EQ_CUSTOM'), hay_custom = true; break; endif
    endfor
    ok = check_local(ok, hay_custom, 'ID EQ_CUSTOM persistido en INSERT');

    mt1 = aos_cad_mtime(dxf);
    ok = check_local(ok, abs(mt1 - mt0) < 1e-6 || isequal(mt1, mt0), 'mtime fuente intacto');
    if exist(ruta, 'file') == 2, delete(ruta); endif
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  report_final(ok);
endfunction

function s = key_safe_local(key)
  s = upper(char(key));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'H_EMPTY'; endif
  if s(1) >= '0' && s(1) <= '9'
    s = ['H_' s];
  endif
endfunction

function raw = fileread_local(ruta)
  fid = fopen(ruta, 'rt');
  if fid < 0, raw = ''; return; endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
endfunction

function ok = check_local(ok, cond, msg)
  if cond, fprintf('OK  %s\n', msg); else fprintf(2, 'FALLO  %s\n', msg); ok = false; endif
endfunction

function report_final(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_bloques_capas APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_bloques_capas NO APROBADO\n');
  endif
endfunction

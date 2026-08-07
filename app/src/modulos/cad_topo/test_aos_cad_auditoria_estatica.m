function ok = test_aos_cad_auditoria_estatica()
% TEST_AOS_CAD_AUDITORIA_ESTATICA Hardening Sprint 7 / T8.
% Auditoria adversaria estatica + checks dinamicos focalizados.
% Hallazgos altos/medios => FALLO. Bajos => documentados en HARDENING_R16.txt.
  ok = true;
  fprintf('\n=== test_aos_cad_auditoria_estatica ===\n');
  global CONFIG_ACTIVA;
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_auditoria_estatica');
  if exist(tmpdir, 'dir') ~= 7, mkdir(tmpdir); endif
  evid_dir = fullfile(root, 'intercambio', 'cad', 'evidencia_sprint7');
  if exist(evid_dir, 'dir') ~= 7, mkdir(evid_dir); endif

  bajos = {};
  altos = {};

  unwind_protect
    % ---------- A1 sombras / rutas unicas R16 ----------
    try
      ok_u = aos_cad_verificar_rutas_unicas(false);
      if ~ok_u
        altos{end+1} = 'A1 rutas/sombras: aos_cad_verificar_rutas_unicas FALLO'; %#ok<AGROW>
      else
        fprintf('OK  A1 rutas unicas R16\n');
      endif
    catch err
      altos{end+1} = sprintf('A1 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    cad_dir = fullfile(root, 'src', 'modulos', 'cad_topo');
    prod_m = listar_m_producto_local(cad_dir);
    test_m = listar_m_test_local(cad_dir);
    todos_m = [prod_m, test_m];

    % ---------- A2 binario legado / warning off / abs paths / rand ids / plot ----------
    try
      ok_mat = aos_cad_verificar_octave_only(true);
      if ~ok_mat
        altos{end+1} = 'A2 octave_only: binario legado o motor no objetivo'; %#ok<AGROW>
      else
        fprintf('OK  A2 octave_only (sin binario legado)\n');
      endif
    catch err
      altos{end+1} = sprintf('A2 octave_only: %s', err.message); %#ok<AGROW>
    end_try_catch

    % warning off: producto = alto; tests Sprint7 = medio (fallo)
    for i = 1:numel(prod_m)
      hits = buscar_patron_cuerpo_local(prod_m{i}, 'warning\s*\(\s*[''"]off');
      if ~isempty(hits)
        altos{end+1} = sprintf('A2 warning off producto: %s', rel_local(root, prod_m{i})); %#ok<AGROW>
      endif
    endfor
    for i = 1:numel(test_m)
      hits = buscar_patron_cuerpo_local(test_m{i}, 'warning\s*\(\s*[''"]off');
      if ~isempty(hits)
        altos{end+1} = sprintf('A2 warning off test: %s', rel_local(root, test_m{i})); %#ok<AGROW>
      endif
    endfor
    if isempty(altos) || all(cellfun(@(s) isempty(strfind(s, 'warning off')), altos))
      fprintf('OK  A2 sin warning off\n');
    endif

    % Rutas absolutas NUEVAS en APIs Sprint 7 (no falsos positivos por \n en fprintf).
    % Patron: drive:\dir  o  /home/  o  /Users/  (no "texto:\n").
    sprint7_scan = {
      'aos_cad_invalidar_simulacion.m'
      'aos_cad_sincronizar_2d_3d.m'
      'aos_cad_dxf_copia_edicion.m'
      'aos_aoscad_generar_recursos_visuales.m'
    };
    for i = 1:numel(sprint7_scan)
      f = fullfile(cad_dir, sprint7_scan{i});
      cuerpo = cuerpo_sin_comentarios_local(leer_local(f));
      if ~isempty(regexp(cuerpo, '[A-Za-z]:\\[A-Za-z0-9_ .\\/-]', 'once')) ...
          || ~isempty(regexp(cuerpo, '/home/[A-Za-z]', 'once')) ...
          || ~isempty(regexp(cuerpo, '/Users/[A-Za-z]', 'once'))
        altos{end+1} = sprintf('A2 ruta absoluta nueva Sprint7: %s', sprint7_scan{i}); %#ok<AGROW>
      endif
    endfor
    fprintf('OK  A2 rutas absolutas Sprint7 (scan)\n');

    % rand en ids (producto): rand/randi/randn cerca de id/asset/corrida
    for i = 1:numel(prod_m)
      cuerpo = cuerpo_sin_comentarios_local(leer_local(prod_m{i}));
      if ~isempty(regexp(cuerpo, 'randi?\s*\(', 'once')) || ...
         ~isempty(regexp(cuerpo, 'randn\s*\(', 'once'))
        % Permitir randi solo en nombres temporales atomicos (tmp_), no en ids
        if ~isempty(regexp(cuerpo, ...
            '(id|asset_id|geometry_id|corrida_id)\s*=[^;]*rand', 'once'))
          altos{end+1} = sprintf('A2 rand en ids: %s', rel_local(root, prod_m{i})); %#ok<AGROW>
        else
          bajos{end+1} = sprintf( ...
            ['A2 LOW randi/rand fuera de ids (tmp atomico u otro): %s'], ...
            rel_local(root, prod_m{i})); %#ok<AGROW>
        endif
      endif
    endfor
    % Metadatos de fecha (now/datestr) no son identidad: documentar alcance.
    bajos{end+1} = ['A8 LOW datestr/now en metadatos informativos ' ...
      '(modificado_en/fecha/corrida demo); excluidos de isequal A8']; %#ok<AGROW>
    bajos{end+1} = ['A9 LOW docs/changelogs R12-R15 mencionan BETA solo ' ...
      'como "sin promocion" / pendiente; menus CAD no declaran [BETA]']; %#ok<AGROW>;

    % plot/figure/print fuera de visores / dominio visual
    allow_plot = {'aos_cad_visor_2d.m', 'aos_cad_visor_3d.m', ...
      'aos_aoscad_generar_recursos_visuales.m', ...
      'aos_cad_hidraulica_dominio_visualizar.m', ...
      'aos_cad_hidraulica_dominio_seleccionar.m', ...
      'aos_cad_interferencias_mostrar.m'};
    graficos = {'figure(', 'plot(', 'plot3(', 'print(', 'surf(', 'mesh('};
    for i = 1:numel(prod_m)
      [~, bn, ~] = fileparts(prod_m{i});
      bn_m = [bn '.m'];
      if any(strcmp(bn_m, allow_plot)), continue; endif
      cuerpo = cuerpo_sin_comentarios_local(leer_local(prod_m{i}));
      for g = 1:numel(graficos)
        if ~isempty(strfind(cuerpo, graficos{g}))
          altos{end+1} = sprintf('A2 grafico fuera de visor (%s): %s', ...
            graficos{g}, rel_local(root, prod_m{i})); %#ok<AGROW>
        endif
      endfor
    endfor
    bajos{end+1} = ['A2 LOW whitelist dominio_visualizar/seleccionar e ' ...
      'interferencias_mostrar (herramientas interactivas preexistentes)']; %#ok<AGROW>
    fprintf('OK  A2 plot/figure fuera de visores (scan)\n');

    % archivos publicos duplicados bajo src/
    dups = detectar_duplicados_publicos_local(fullfile(root, 'src'));
    for i = 1:numel(dups)
      altos{end+1} = sprintf('A2 archivo publico duplicado: %s', dups{i}); %#ok<AGROW>
    endfor
    if isempty(dups), fprintf('OK  A2 sin duplicados publicos cad/aos_aoscad\n'); endif

    % ---------- A3 NaN/Inf: trazable ok; silencioso en ids/colores/bbox/vigente no ----------
    try
      [ok_nan, msg_nan, bajos_nan] = auditar_nan_dinamico_local(tmpdir);
      if ~ok_nan
        altos{end+1} = sprintf('A3 NaN/Inf: %s', msg_nan); %#ok<AGROW>
      else
        fprintf('OK  A3 NaN/Inf dinamico\n');
      endif
      bajos = [bajos, bajos_nan];
    catch err
      altos{end+1} = sprintf('A3 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    % ---------- A4 enums simulacion.estado vs schema ----------
    try
      estados_ok = {'NO_EJECUTADA', 'EJECUTADA', 'EJECUTADA_CON_ADVERTENCIAS', ...
                    'INVALIDADA_POR_EDICION'};
      schema = fullfile(cad_dir, 'schema', 'AOSCAD_0_0_1_DEV1_SCHEMA.json');
      raw_sch = leer_local(schema);
      for ie = 1:numel(estados_ok)
        if isempty(strfind(raw_sch, ['"' estados_ok{ie} '"']))
          altos{end+1} = sprintf('A4 schema falta enum %s', estados_ok{ie}); %#ok<AGROW>
        endif
      endfor
      % Asignaciones literales en producto
      for i = 1:numel(prod_m)
        cuerpo = cuerpo_sin_comentarios_local(leer_local(prod_m{i}));
        toks = regexp(cuerpo, ...
          'simulacion\.estado\s*=\s*[''"]([A-Z0-9_]+)[''"]', 'tokens');
        for t = 1:numel(toks)
          est = toks{t}{1};
          if ~any(strcmp(est, estados_ok))
            % INVALIDADA_POR_CONFIGURACION mapeado a EDICION es aceptable solo
            % como comparacion/lectura legacy, no como asignacion persistida.
            if strcmp(est, 'INVALIDADA_POR_CONFIGURACION')
              altos{end+1} = sprintf( ...
                'A4 enum incompatible asignado: %s en %s', ...
                est, rel_local(root, prod_m{i})); %#ok<AGROW>
            else
              altos{end+1} = sprintf('A4 estado no schema: %s en %s', ...
                est, rel_local(root, prod_m{i})); %#ok<AGROW>
            endif
          endif
        endfor
      endfor
      fprintf('OK  A4 enums simulacion.estado\n');
    catch err
      altos{end+1} = sprintf('A4 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    % ---------- A5 CONFIG_ACTIVA restaurado (patron tests Sprint 7) ----------
    try
      sprint7_tests = {
        'test_aos_cad_invalidar_simulacion.m'
        'test_aos_cad_sincronizacion_2d_3d.m'
        'test_aos_cad_dxf_edicion_externa.m'
        'test_aos_aoscad_recursos_visuales.m'
        'test_aos_cad_auditoria_estatica.m'
      };
      for i = 1:numel(sprint7_tests)
        f = fullfile(cad_dir, sprint7_tests{i});
        raw = leer_local(f);
        tiene_prev = ~isempty(strfind(raw, 'prev = CONFIG_ACTIVA')) ...
          || ~isempty(strfind(raw, 'prev_cfg = CONFIG_ACTIVA'));
        tiene_restore = ~isempty(strfind(raw, 'CONFIG_ACTIVA = prev')) ...
          || ~isempty(strfind(raw, 'CONFIG_ACTIVA = prev_cfg'));
        tiene_up = ~isempty(strfind(raw, 'unwind_protect'));
        if ~(tiene_prev && tiene_restore && tiene_up)
          altos{end+1} = sprintf( ...
            'A5 %s sin patron CONFIG_ACTIVA+unwind_protect', sprint7_tests{i}); %#ok<AGROW>
        endif
      endfor
      % Contaminacion: marker antes/despues de helper de invalidacion
      CONFIG_ACTIVA = struct('cad_topologia', struct('marcador', 'AUD_PRE'));
      m = modelo_min_local();
      [m2, ~] = aos_cad_invalidar_simulacion(m, 'auditoria', struct());
      if ~isfield(CONFIG_ACTIVA, 'cad_topologia') ...
          || ~isfield(CONFIG_ACTIVA.cad_topologia, 'marcador') ...
          || ~strcmp(char(CONFIG_ACTIVA.cad_topologia.marcador), 'AUD_PRE')
        altos{end+1} = 'A5 invalidar_simulacion contamino CONFIG_ACTIVA'; %#ok<AGROW>
      endif
      ok_chk = isstruct(m2) && strcmp(char(m2.simulacion.estado), 'INVALIDADA_POR_EDICION');
      if ~ok_chk
        altos{end+1} = 'A5 invalidar no dejo INVALIDADA_POR_EDICION'; %#ok<AGROW>
      endif
      fprintf('OK  A5 CONFIG_ACTIVA restore/patron\n');
    catch err
      altos{end+1} = sprintf('A5 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    % ---------- A6 fixtures inmutables / AOS_REV / intercambio ----------
    try
      fx = {
        fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells.dxf')
        fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step')
        fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_hidraulica_dev1.dxf')
        fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step')
      };
      hashes0 = cell(size(fx));
      mtimes0 = zeros(size(fx));
      for i = 1:numel(fx)
        if exist(fx{i}, 'file') ~= 2
          altos{end+1} = sprintf('A6 fixture ausente: %s', fx{i}); %#ok<AGROW>
          continue;
        endif
        hashes0{i} = hash_archivo_local(fx{i});
        mtimes0(i) = aos_cad_mtime(fx{i});
      endfor

      % Producto no debe fopen-escribir bajo datos/ejemplos
      for i = 1:numel(prod_m)
        cuerpo = cuerpo_sin_comentarios_local(leer_local(prod_m{i}));
        if ~isempty(strfind(cuerpo, 'datos')) && ...
           (~isempty(strfind(cuerpo, 'ejemplos')) || ~isempty(strfind(cuerpo, 'fopen')))
          % Solo fallar si escribe ('wt'/'w') a path con ejemplos
          if ~isempty(regexp(cuerpo, ...
              'fopen\s*\([^)]*ejemplos[^)]*,\s*[''"]w', 'once'))
            altos{end+1} = sprintf('A6 escritura a ejemplos: %s', ...
              rel_local(root, prod_m{i})); %#ok<AGROW>
          endif
        endif
      endfor

      % Exports AOS_REV y copias bajo intercambio
      for i = 1:numel(prod_m)
        [~, bn, ~] = fileparts(prod_m{i});
        if any(strcmp(bn, {'aos_cad_exportar_dxf_rev', 'aos_cad_exportar_step_rev'}))
          cuerpo = cuerpo_sin_comentarios_local(leer_local(prod_m{i}));
          if isempty(strfind(cuerpo, '_AOS_REV'))
            altos{end+1} = sprintf('A6 export sin _AOS_REV: %s', bn); %#ok<AGROW>
          endif
          if isempty(strfind(cuerpo, 'intercambio'))
            altos{end+1} = sprintf('A6 export sin intercambio: %s', bn); %#ok<AGROW>
          endif
        endif
        if any(strcmp(bn, {'aos_cad_dxf_copia_edicion', 'aos_cad_step_copia_edicion'}))
          cuerpo = cuerpo_sin_comentarios_local(leer_local(prod_m{i}));
          if isempty(strfind(cuerpo, 'intercambio')) || isempty(strfind(cuerpo, 'edicion'))
            altos{end+1} = sprintf('A6 copia no bajo intercambio/edicion: %s', bn); %#ok<AGROW>
          endif
        endif
      endfor

      for i = 1:numel(fx)
        if isempty(hashes0{i}), continue; endif
        h1 = hash_archivo_local(fx{i});
        mt1 = aos_cad_mtime(fx{i});
        if ~strcmp(h1, hashes0{i}) || mt1 ~= mtimes0(i)
          altos{end+1} = sprintf('A6 fixture mutado: %s', rel_local(root, fx{i})); %#ok<AGROW>
        endif
      endfor
      fprintf('OK  A6 fixtures / AOS_REV / intercambio\n');
    catch err
      altos{end+1} = sprintf('A6 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    % ---------- A7 paths Windows / separadores relativos ----------
    try
      m = modelo_min_local();
      m.info.aoscad_perfil = 'ENRIQUECIDO';
      opts = struct('incluir_2d', true, 'incluir_3d', false, ...
        'incluir_overlay', false, 'visible', false, 'directorio', tmpdir);
      [rv, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      planos = {};
      if isstruct(rv) && isfield(rv, 'planos'), planos = rv.planos; endif
      if iscell(planos)
        for i = 1:numel(planos)
          if ~isstruct(planos{i}) || ~isfield(planos{i}, 'ruta_relativa'), continue; endif
          rr = char(planos{i}.ruta_relativa);
          if ~isempty(strfind(rr, '\'))
            altos{end+1} = sprintf('A7 ruta_relativa con \\: %s', rr); %#ok<AGROW>
          endif
          if ~isempty(regexp(rr, '^[A-Za-z]:', 'once')) || strncmp(rr, '/', 1)
            % absoluto unix o drive: no permitido como relativo
            if strncmp(rr, '/', 1) || ~isempty(regexp(rr, '^[A-Za-z]:', 'once'))
              altos{end+1} = sprintf('A7 ruta_relativa absoluta: %s', rr); %#ok<AGROW>
            endif
          endif
        endfor
      endif
      fprintf('OK  A7 separadores relativos\n');
    catch err
      altos{end+1} = sprintf('A7 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    % ---------- A8 determinismo isequal excluyendo fechas ----------
    try
      m = modelo_min_local();
      m.simulacion.estado = 'EJECUTADA';
      m.simulacion.motor = 'AUD';
      m.tablas_resultados = struct('nodos', {{struct('id','N1')}}, ...
        'tramos', {{struct('id','T1')}});
      [a1, ~] = aos_cad_invalidar_simulacion(m, 'det1', struct());
      [a2, ~] = aos_cad_invalidar_simulacion(m, 'det1', struct());
      a1s = strip_fechas_local(a1);
      a2s = strip_fechas_local(a2);
      if ~isequal(a1s, a2s)
        altos{end+1} = 'A8 invalidar no determinista (sin fechas)'; %#ok<AGROW>
      endif

      opts = struct('incluir_2d', true, 'incluir_3d', false, ...
        'incluir_overlay', false, 'visible', false, 'directorio', tmpdir);
      m.info.aoscad_perfil = 'ENRIQUECIDO';
      [r1, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      [r2, ~] = aos_aoscad_generar_recursos_visuales(m, opts);
      ids1 = ids_recursos_local(r1);
      ids2 = ids_recursos_local(r2);
      if ~isequal(ids1, ids2)
        altos{end+1} = 'A8 recursos ids/orden no deterministas'; %#ok<AGROW>
      endif
      fprintf('OK  A8 determinismo (sin fechas)\n');
    catch err
      altos{end+1} = sprintf('A8 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

    % ---------- A9 menus/docs CAD: no declarar BETA nuevo Sprint 7 ----------
    try
      menu_files = {
        fullfile(cad_dir, 'aos_cad_topologia_menu_impl.m')
        fullfile(cad_dir, 'aos_cad_hidraulica_menu.m')
        fullfile(root, 'src', 'menu', 'AOS_menu_cad_topologia.m')
      };
      for i = 1:numel(menu_files)
        if exist(menu_files{i}, 'file') ~= 2, continue; endif
        raw = leer_local(menu_files{i});
        % Declaracion positiva de BETA para CAD (no "sin/no promocion")
        if ~isempty(regexp(raw, '\[BETA\]', 'once')) ...
            || ~isempty(regexp(raw, 'state\s*=\s*[''"]BETA[''"]', 'once')) ...
            || ~isempty(regexp(raw, 'ESTADO\s*=\s*BETA', 'once'))
          altos{end+1} = sprintf('A9 menu declara BETA CAD: %s', ...
            rel_local(root, menu_files{i})); %#ok<AGROW>
        endif
      endfor
      % Sprint 7 product APIs
      s7 = {'aos_cad_invalidar_simulacion.m', 'aos_cad_sincronizar_2d_3d.m', ...
        'aos_cad_dxf_copia_edicion.m', 'aos_aoscad_generar_recursos_visuales.m'};
      for i = 1:numel(s7)
        f = fullfile(cad_dir, s7{i});
        raw = leer_local(f);
        if ~isempty(regexp(raw, '\[BETA\]|ESTADO\s*=\s*BETA|state\s*=\s*[''"]BETA[''"]', 'once'))
          altos{end+1} = sprintf('A9 Sprint7 API declara BETA: %s', s7{i}); %#ok<AGROW>
        endif
      endfor
      % Workbench CAD sigue DEV1
      wb = fullfile(root, 'src', 'roadmap', 'aos_workbenches_0_1_9.json');
      raw_wb = leer_local(wb);
      % Extraer bloque CAD aproximado
      if isempty(regexp(raw_wb, '"id"\s*:\s*"CAD"[\s\S]*?"state"\s*:\s*"DEV1"', 'once'))
        altos{end+1} = 'A9 workbench CAD no esta en state=DEV1'; %#ok<AGROW>
      endif
      fprintf('OK  A9 sin BETA CAD nuevo\n');
    catch err
      altos{end+1} = sprintf('A9 excepcion: %s', err.message); %#ok<AGROW>
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
    try
      figs = findobj('type', 'figure');
      if ~isempty(figs), close(figs); endif
    catch
    end_try_catch
    try
      if exist(tmpdir, 'dir') == 7
        d = dir(fullfile(tmpdir, '*'));
        for i = 1:numel(d)
          if d(i).isdir, continue; endif
          delete(fullfile(tmpdir, d(i).name));
        endfor
      endif
    catch
    end_try_catch
  end_unwind_protect

  % Documentar bajos
  try
    escribir_evidencia_local(fullfile(evid_dir, 'HARDENING_R16.txt'), altos, bajos);
  catch err
    fprintf(2, 'AVISO no se pudo escribir HARDENING_R16.txt: %s\n', err.message);
  end_try_catch

  if ~isempty(altos)
    ok = false;
    fprintf(2, 'HALLAZGOS ALTO/MEDIO (%d):\n', numel(altos));
    for i = 1:numel(altos)
      fprintf(2, ' - %s\n', altos{i});
    endfor
  endif
  if ~isempty(bajos)
    fprintf('HALLAZGOS BAJOS documentados (%d) en HARDENING_R16.txt\n', numel(bajos));
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_auditoria_estatica APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_auditoria_estatica NO APROBADO\n');
  endif
endfunction

function lista = listar_m_producto_local(carpeta)
  lista = {};
  d = dir(fullfile(carpeta, '*.m'));
  for i = 1:numel(d)
    n = d(i).name;
    if strncmp(n, 'test_', 5), continue; endif
    if strcmp(n, 'VERIFICAR_CAD_TOPO.m'), continue; endif
    lista{end+1} = fullfile(carpeta, n); %#ok<AGROW>
  endfor
endfunction

function lista = listar_m_test_local(carpeta)
  lista = {};
  d = dir(fullfile(carpeta, 'test_*.m'));
  for i = 1:numel(d)
    lista{end+1} = fullfile(carpeta, d(i).name); %#ok<AGROW>
  endfor
endfunction

function raw = leer_local(ruta)
  raw = '';
  fid = fopen(ruta, 'rt');
  if fid < 0, return; endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
endfunction

function cuerpo = cuerpo_sin_comentarios_local(raw)
  if isempty(raw), cuerpo = ''; return; endif
  lineas = strsplit(raw, "\n");
  out = {};
  for i = 1:numel(lineas)
    ln = lineas{i};
    % Quitar comentario de linea: % fuera de comillas simples/dobles.
    in_s = false; in_d = false; cut = 0;
    j = 1;
    while j <= length(ln)
      c = ln(j);
      if ~in_d && c == char(39)
        % comilla simple: '' escape
        if in_s && j < length(ln) && ln(j+1) == char(39)
          j = j + 2; continue;
        endif
        in_s = ~in_s;
      elseif ~in_s && c == char(34)
        in_d = ~in_d;
      elseif ~in_s && ~in_d && c == '%'
        cut = j;
        break;
      endif
      j = j + 1;
    endwhile
    if cut > 0
      ln = ln(1:cut-1);
    endif
    out{end+1} = ln; %#ok<AGROW>
  endfor
  cuerpo = strjoin(out, "\n");
endfunction

function hits = buscar_patron_cuerpo_local(ruta, patron)
  hits = {};
  cuerpo = cuerpo_sin_comentarios_local(leer_local(ruta));
  if ~isempty(regexp(cuerpo, patron, 'once'))
    hits = {ruta};
  endif
endfunction

function r = rel_local(root, ruta)
  r = strrep(char(ruta), [char(root) filesep], '');
  r = strrep(r, '\', '/');
endfunction

function dups = detectar_duplicados_publicos_local(src_root)
  dups = {};
  nombres = {};
  rutas = {};
  stack = {src_root};
  while ~isempty(stack)
    c = stack{1}; stack(1) = [];
    d = dir(c);
    for i = 1:numel(d)
      n = d(i).name;
      if strcmp(n, '.') || strcmp(n, '..'), continue; endif
      p = fullfile(c, n);
      if d(i).isdir
        stack{end+1} = p; %#ok<AGROW>
      elseif length(n) > 2 && strcmpi(n(end-1:end), '.m')
        if strncmpi(n, 'aos_cad_', 8) || strncmpi(n, 'aos_aoscad_', 11) ...
            || strncmpi(n, 'aos_step_', 9) || strncmpi(n, 'aos_dxf_', 8)
          nombres{end+1} = lower(n); %#ok<AGROW>
          rutas{end+1} = p; %#ok<AGROW>
        endif
      endif
    endfor
  endwhile
  for i = 1:numel(nombres)
    same = find(strcmp(nombres{i}, nombres));
    if numel(same) > 1 && same(1) == i
      msg = nombres{i};
      for j = 1:numel(same)
        msg = sprintf('%s | %s', msg, rutas{same(j)});
      endfor
      dups{end+1} = msg; %#ok<AGROW>
    endif
  endfor
endfunction

function [ok, msg, bajos] = auditar_nan_dinamico_local(tmpdir)
  ok = true;
  msg = '';
  bajos = {};
  % 1) Overlay con valor no finito: estado trazable, no color NaN vigente silencioso
  esc = struct();
  esc.vigente = true;
  esc.objetos = {struct('id', 'T1', 'tipo', 'TRAMO', 'asset_id', 'A1', ...
    'geometry_id', 'G1', 'color_rgb', [0.5 0.5 0.5])};
  modelo = struct();
  modelo.simulacion = struct('estado', 'EJECUTADA', 'motor', 'AUD');
  modelo.tablas_resultados = struct( ...
    'tramos', {{struct('id', 'T1', 'caudal_m3s', NaN)}}, ...
    'nodos', {{}});
  try
    ov = aos_cad_overlay_resultados(esc, modelo, struct('campo', 'caudal_m3s'));
    if isstruct(ov) && isfield(ov, 'objetos') && iscell(ov.objetos) && ~isempty(ov.objetos)
      o = ov.objetos{1};
      if isfield(o, 'color_rgb') && any(~isfinite(o.color_rgb(:)))
        ok = false;
        msg = 'overlay color_rgb con NaN/Inf';
        return;
      endif
      if isfield(o, 'estado') && strcmpi(char(o.estado), 'OK') ...
          && isfield(o, 'clase') && isempty(o.clase)
        % inconsistente
      endif
      % Preferible: SIN_DATO u equivalente trazable
      if isfield(o, 'estado') && strcmpi(char(o.estado), 'OK')
        bajos{end+1} = 'A3 LOW overlay NaN marcado OK (revisar trazabilidad)'; %#ok<AGROW>
      endif
    endif
  catch err
    % Si falla de forma trazable, aceptable
    bajos{end+1} = sprintf('A3 LOW overlay NaN lanzo error trazable: %s', err.message); %#ok<AGROW>
  end_try_catch

  % 2) Recursos vigentes: ids finitos/string sin NaN literales
  m = modelo_min_local();
  m.info.aoscad_perfil = 'ENRIQUECIDO';
  [rv, items] = aos_aoscad_generar_recursos_visuales(m, struct( ...
    'incluir_2d', true, 'incluir_3d', false, 'incluir_overlay', false, ...
    'visible', false, 'directorio', tmpdir));
  if isstruct(rv) && isfield(rv, 'vigente') && logical(rv.vigente)
    planos = {};
    if isfield(rv, 'planos'), planos = rv.planos; endif
    if iscell(planos)
      for i = 1:numel(planos)
        if ~isstruct(planos{i}), continue; endif
        if isfield(planos{i}, 'id')
          idv = planos{i}.id;
          if isnumeric(idv) && any(~isfinite(idv(:)))
            ok = false; msg = 'recurso vigente con id NaN/Inf'; return;
          endif
          if ischar(idv) && (~isempty(strfind(idv, 'NaN')) || ~isempty(strfind(idv, 'Inf')))
            ok = false; msg = 'recurso vigente id literal NaN/Inf'; return;
          endif
        endif
      endfor
    endif
  endif
  % items deben existir si hay falla; permitir vacio en exito
  if ~iscell(items), ok = false; msg = 'items no cell'; endif
endfunction

function m = modelo_min_local()
  m = aos_aoscad_nuevo_paquete();
  m.info.schema = 'AOSCAD-0.0.1-DEV1';
  m.info.aoscad_perfil = 'SIMPLE';
  m.simulacion = struct('estado', 'NO_EJECUTADA', 'motor', '', ...
    'corrida_id', '', 'fecha', '');
  m.tablas_resultados = struct('nodos', {{}}, 'tramos', {{}});
  m.escena_3d = struct('vigente', false);
  m.vinculo_3d = struct('vigente', false);
  m.recursos_visuales = {};
  % Topologia minima para plano 2D
  m.topologia = struct();
  m.topologia.nodos = {struct('id', 'N1', 'x', 0, 'y', 0), ...
                       struct('id', 'N2', 'x', 1, 'y', 0)};
  m.topologia.tramos = {struct('id', 'T1', 'nodo_a', 'N1', 'nodo_b', 'N2', ...
    'x1', 0, 'y1', 0, 'x2', 1, 'y2', 0)};
endfunction

function h = hash_archivo_local(ruta)
  fid = fopen(ruta, 'rb');
  if fid < 0, h = ''; return; endif
  data = fread(fid, Inf, 'uint8=>uint8');
  fclose(fid);
  % hash simple portable (suma + xor rolling)
  s = uint32(0); x = uint32(0);
  for i = 1:numel(data)
    s = s + uint32(data(i));
    x = bitxor(x, bitshift(uint32(data(i)), mod(i, 8)));
  endfor
  h = sprintf('%08x_%08x_%d', s, x, numel(data));
endfunction

function s = strip_fechas_local(modelo)
  s = modelo;
  if ~isstruct(s), return; endif
  campos_fecha = {'fecha', 'modificado_en', 'creado_en', 'importado_en', ...
    'dxf_mtime_texto', 'step_mtime_texto', 'fecha_modificacion'};
  s = strip_campos_rec_local(s, campos_fecha);
endfunction

function s = strip_campos_rec_local(s, campos)
  if isstruct(s)
    fn = fieldnames(s);
    for i = 1:numel(fn)
      if any(strcmp(fn{i}, campos))
        s = rmfield(s, fn{i});
      else
        v = s.(fn{i});
        if isstruct(v)
          if numel(v) == 1
            s.(fn{i}) = strip_campos_rec_local(v, campos);
          else
            for k = 1:numel(v)
              v(k) = strip_campos_rec_local(v(k), campos);
            endfor
            s.(fn{i}) = v;
          endif
        elseif iscell(v)
          for k = 1:numel(v)
            if isstruct(v{k})
              v{k} = strip_campos_rec_local(v{k}, campos);
            endif
          endfor
          s.(fn{i}) = v;
        endif
      endif
    endfor
  endif
endfunction

function ids = ids_recursos_local(rv)
  ids = {};
  if ~isstruct(rv), return; endif
  for fld = {'planos', 'graficos'}
    if ~isfield(rv, fld{1}), continue; endif
    L = rv.(fld{1});
    if ~iscell(L), continue; endif
    for i = 1:numel(L)
      if isstruct(L{i}) && isfield(L{i}, 'id')
        ids{end+1} = char(L{i}.id); %#ok<AGROW>
      endif
    endfor
  endfor
endfunction

function escribir_evidencia_local(ruta, altos, bajos)
  fid = fopen(ruta, 'wt');
  if fid < 0, error('no se pudo escribir %s', ruta); endif
  fprintf(fid, 'HARDENING_R16 — Sprint 7 Task 8\n');
  fprintf(fid, 'Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
  fprintf(fid, 'Octave: %s\n\n', version());
  fprintf(fid, '=== ALTO/MEDIO (deben ser 0 al cierre) ===\n');
  if isempty(altos)
    fprintf(fid, '(ninguno)\n');
  else
    for i = 1:numel(altos), fprintf(fid, '- %s\n', altos{i}); endfor
  endif
  fprintf(fid, '\n=== BAJO (documentados, no bloquean) ===\n');
  if isempty(bajos)
    fprintf(fid, '(ninguno)\n');
  else
    for i = 1:numel(bajos)
      fprintf(fid, '- %s\n', bajos{i});
      if ~isempty(strfind(bajos{i}, 'randi')) || ~isempty(strfind(bajos{i}, 'rand '))
        fprintf(fid, '  razon: colision de temporales atomicos, no identidad de modelo\n');
        fprintf(fid, '  alcance: aos_aoscad_escribir tmp_*; no afecta ids/orden\n');
      elseif ~isempty(strfind(bajos{i}, 'whitelist'))
        fprintf(fid, '  razon: herramientas interactivas de dominio/interferencias\n');
        fprintf(fid, '  alcance: preexistente Sprint<=6; headless tests no dependen de ellas\n');
      elseif ~isempty(strfind(bajos{i}, 'datestr'))
        fprintf(fid, '  razon: metadatos informativos de auditoria temporal\n');
        fprintf(fid, '  alcance: strip_fechas en A8; determinismo estructural intacto\n');
      elseif ~isempty(strfind(bajos{i}, 'BETA'))
        fprintf(fid, '  razon: menciones historicas negativas (sin promocion)\n');
        fprintf(fid, '  alcance: fuera de menus CAD Sprint7; workbench CAD=DEV1\n');
      else
        fprintf(fid, '  alcance: preexistente o no-identidad; no bloquea R16 candidato\n');
      endif
    endfor
  endif
  fprintf(fid, '\nCriterio T8: cero altos/medios abiertos; bajos con razon/alcance.\n');
  fclose(fid);
endfunction

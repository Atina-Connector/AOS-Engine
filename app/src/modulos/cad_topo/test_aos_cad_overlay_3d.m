function ok = test_aos_cad_overlay_3d()
% TEST_AOS_CAD_OVERLAY_3D Overlay de tablas_resultados sobre escena 3D (Sprint 6).
% valor exacto, SIN_DATO, PNG headless, n_objetos_dibujados sin overlay intacto.
% Headless. Sin AOS_CAD_SKIP_VISOR.
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

  fprintf('\n=== test_aos_cad_overlay_3d ===\n');

  vis_anterior = get(0, 'defaultfigurevisible');
  set(0, 'defaultfigurevisible', 'off');

  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA fixture: %s\n', dxf);
    ok = false;
    set(0, 'defaultfigurevisible', vis_anterior);
    fprintf(2, 'RESULTADO: test_aos_cad_overlay_3d NO APROBADO\n');
    return;
  endif

  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_overlay_3d');
  if exist(tmpdir, 'dir') ~= 7
    mkdir(tmpdir);
  endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    try
      ok = check_local(ok, aos_cad_importar_dxf(dxf, true), 'import DXF');
      aos_cad_construir_topologia(0.05, true);
      try
        aos_cad_eval_hidraulica_demo(true);
      catch err
        fprintf(2, 'FALLO eval hidraulica: %s\n', err.message);
        ok = false;
      end_try_catch

      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, isfield(modelo, 'tablas_resultados') ...
        && isstruct(modelo.tablas_resultados), 'tablas_resultados presentes');

      fuente = struct();
      fuente.cad_topologia = CONFIG_ACTIVA.cad_topologia;
      opts = struct('incluir_pozo', false, 'incluir_red', true, 'incluir_step', false);
      [esc0, ~] = aos_cad_escena_3d(fuente, opts);
      ok = check_local(ok, isstruct(esc0) && esc0.n_objetos > 0, 'escena base');

      % Render sin overlay (referencia R14 / default)
      png0 = fullfile(tmpdir, 'overlay_sin.png');
      if exist(png0, 'file') == 2, delete(png0); endif
      [info0, h0] = aos_cad_visor_3d(esc0, struct('visible', false, 'png', png0));
      n_dib0 = info0.n_objetos_dibujados;
      ok = check_local(ok, n_dib0 > 0, 'render sin overlay n_objetos_dibujados > 0');
      ok = check_local(ok, isempty(h0) || ~ishandle(h0), 'figura sin overlay cerrada');

      % Aplicar overlay
      [esc_ov, items_ov] = aos_cad_overlay_resultados(esc0, modelo.tablas_resultados);
      ok = check_local(ok, esc_ov.n_objetos == esc0.n_objetos, ...
        'overlay no cambia n_objetos');

      % valor exacto vs tablas_resultados
      mapa_p = mapa_presion_local(modelo.tablas_resultados);
      mapa_q = mapa_caudal_local(modelo.tablas_resultados);
      n_ok_valor = 0;
      n_sin_dato = 0;
      for i = 1:numel(esc_ov.objetos)
        o = esc_ov.objetos{i};
        if ~isstruct(o) || ~isfield(o, 'tipo'), continue; endif
        tipo = upper(char(o.tipo));
        oid = '';
        if isfield(o, 'id'), oid = char(o.id); endif
        if ~isfield(o, 'overlay') || ~isstruct(o.overlay)
          if strcmp(tipo, 'NODO') || strcmp(tipo, 'TRAMO')
            ok = check_local(ok, false, sprintf('objeto %s sin overlay', oid));
          endif
          continue;
        endif
        ov = o.overlay;
        if strcmp(tipo, 'NODO')
          key = safe_key_local(oid);
          if isfield(mapa_p, key)
            ok = check_local(ok, strcmp(char(ov.estado), 'OK') ...
              && isequal(ov.valor, mapa_p.(key)), ...
              sprintf('NODO %s overlay.valor exacto', oid));
            n_ok_valor = n_ok_valor + 1;
          else
            ok = check_local(ok, strcmp(char(ov.estado), 'SIN_DATO') ...
              && isempty(ov.valor), ...
              sprintf('NODO %s SIN_DATO', oid));
            n_sin_dato = n_sin_dato + 1;
          endif
        elseif strcmp(tipo, 'TRAMO')
          key = safe_key_local(oid);
          if isfield(mapa_q, key)
            ok = check_local(ok, strcmp(char(ov.estado), 'OK') ...
              && isequal(ov.valor, mapa_q.(key)), ...
              sprintf('TRAMO %s overlay.valor exacto', oid));
            n_ok_valor = n_ok_valor + 1;
          else
            ok = check_local(ok, strcmp(char(ov.estado), 'SIN_DATO') ...
              && isempty(ov.valor), ...
              sprintf('TRAMO %s SIN_DATO', oid));
            n_sin_dato = n_sin_dato + 1;
          endif
        endif
      endfor
      ok = check_local(ok, n_ok_valor >= 1, 'al menos un overlay.valor OK');

      % Caso SIN_DATO explicito: objeto sin fila en tablas
      esc_extra = esc0;
      o_extra = esc_extra.objetos{1};
      o_extra.id = 'NODO_SIN_RESULTADO_XYZ';
      o_extra.tipo = 'NODO';
      esc_extra.objetos{end+1} = o_extra;
      esc_extra.n_objetos = numel(esc_extra.objetos);
      [esc_sd, items_sd] = aos_cad_overlay_resultados(esc_extra, modelo.tablas_resultados);
      found_sd = false;
      for i = 1:numel(esc_sd.objetos)
        o = esc_sd.objetos{i};
        if isstruct(o) && isfield(o, 'id') ...
            && strcmp(char(o.id), 'NODO_SIN_RESULTADO_XYZ') ...
            && isfield(o, 'overlay') && strcmp(char(o.overlay.estado), 'SIN_DATO')
          found_sd = true;
          ok = check_local(ok, isempty(o.overlay.valor), ...
            'SIN_DATO no rellena valor con 0');
          break;
        endif
      endfor
      ok = check_local(ok, found_sd, 'objeto sin resultado queda SIN_DATO');
      ok = check_local(ok, tiene_codigo_local(items_sd, 'OVERLAY_SIN_DATO'), ...
        'item OVERLAY_SIN_DATO');

      % PNG headless con overlay
      png1 = fullfile(tmpdir, 'overlay_con.png');
      if exist(png1, 'file') == 2, delete(png1); endif
      [info1, h1] = aos_cad_visor_3d(esc_ov, struct('visible', false, 'png', png1));
      ok = check_local(ok, exist(png1, 'file') == 2 || ...
        (~isempty(info1.png) && exist(info1.png, 'file') == 2), ...
        'PNG headless con overlay generado');
      ok = check_local(ok, isempty(h1) || ~ishandle(h1), 'figura overlay cerrada');
      ok = check_local(ok, ~info1.visible && ~info1.figura_abierta, ...
        'visor overlay headless');

      % Default render (sin overlay) n_objetos_dibujados sin cambio vs referencia
      [info0b, ~] = aos_cad_visor_3d(esc0, struct('visible', false));
      ok = check_local(ok, info0b.n_objetos_dibujados == n_dib0, ...
        'default render n_objetos_dibujados unchanged vs no-overlay');
      % Overlay no debe alterar conteo de dibujados del mismo set de objetos
      ok = check_local(ok, info1.n_objetos_dibujados == n_dib0, ...
        'con overlay mismo n_objetos_dibujados');

      if exist(png0, 'file') == 2, delete(png0); endif
      if exist(png1, 'file') == 2, delete(png1); endif

    catch err
      fprintf(2, 'FALLO excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
    set(0, 'defaultfigurevisible', vis_anterior);
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_overlay_3d APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_overlay_3d NO APROBADO\n');
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

function mapa = mapa_presion_local(tr)
  mapa = struct();
  if ~isstruct(tr) || ~isfield(tr, 'nodos'), return; endif
  filas = tr.nodos;
  if ~iscell(filas), filas = num2cell(filas); endif
  for i = 1:numel(filas)
    r = filas{i};
    if ~isstruct(r) || ~isfield(r, 'id') || ~isfield(r, 'presion_Pa'), continue; endif
    if ~isnumeric(r.presion_Pa) || isempty(r.presion_Pa) || ~isfinite(r.presion_Pa(1))
      continue;
    endif
    mapa.(safe_key_local(char(r.id))) = double(r.presion_Pa(1));
  endfor
endfunction

function mapa = mapa_caudal_local(tr)
  mapa = struct();
  if ~isstruct(tr) || ~isfield(tr, 'tramos'), return; endif
  filas = tr.tramos;
  if ~iscell(filas), filas = num2cell(filas); endif
  for i = 1:numel(filas)
    r = filas{i};
    if ~isstruct(r) || ~isfield(r, 'id'), continue; endif
    if ~isfield(r, 'caudal_liquido_m3s') || ~isnumeric(r.caudal_liquido_m3s) ...
        || isempty(r.caudal_liquido_m3s) || ~isfinite(r.caudal_liquido_m3s(1))
      continue;
    endif
    mapa.(safe_key_local(char(r.id))) = double(r.caudal_liquido_m3s(1));
  endfor
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction

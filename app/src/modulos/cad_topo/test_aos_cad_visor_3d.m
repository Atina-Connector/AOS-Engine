function ok = test_aos_cad_visor_3d()
% TEST_AOS_CAD_VISOR_3D Smoke escena/visor/seleccion 3D (Sprint 5 V1-V6).
% Headless obligatorio: defaultfigurevisible off. NO usa AOS_CAD_SKIP_VISOR.
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

  fprintf('\n=== test_aos_cad_visor_3d ===\n');

  % Headless: nunca abrir ventana visible; no setear AOS_CAD_SKIP_VISOR.
  vis_anterior = get(0, 'defaultfigurevisible');
  set(0, 'defaultfigurevisible', 'off');

  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  for f = {dxf, step}
    if exist(f{1}, 'file') ~= 2
      fprintf(2, 'FALTA fixture: %s\n', f{1});
      ok = false;
      set(0, 'defaultfigurevisible', vis_anterior);
      fprintf(2, 'RESULTADO: test_aos_cad_visor_3d NO APROBADO\n');
      return;
    endif
  endfor

  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_visor_3d');
  if exist(tmpdir, 'dir') ~= 7
    mkdir(tmpdir);
  endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();

    % ---------- preparar fuente DXF + STEP ----------
    if ~aos_cad_importar_dxf(dxf, true)
      ok = check_local(ok, false, 'import DXF red ramificada');
      report_final_local(ok);
      return;
    endif
    aos_cad_construir_topologia(0.05, true);
    if ~aos_cad_importar_step(step, true)
      ok = check_local(ok, false, 'import STEP equipment');
      report_final_local(ok);
      return;
    endif

    fuente = struct();
    fuente.cad_topologia = CONFIG_ACTIVA.cad_topologia;
    opts_esc = struct('incluir_pozo', false, 'incluir_red', true, 'incluir_step', true);

    % ---------- V1 escena compuesta ----------
    try
      [esc1, ~] = aos_cad_escena_3d(fuente, opts_esc);
      ok = check_local(ok, isstruct(esc1) && isfield(esc1, 'objetos'), 'V1 escena struct');
      n_tramo = contar_tipo_local(esc1, 'TRAMO');
      n_nodo = contar_tipo_local(esc1, 'NODO');
      n_eq = contar_tipo_local(esc1, 'EQUIPO_3D');
      ok = check_local(ok, n_tramo > 0, 'V1 hay TRAMO');
      ok = check_local(ok, n_nodo > 0, 'V1 hay NODO');
      ok = check_local(ok, n_eq > 0, 'V1 hay EQUIPO_3D');
      ok = check_local(ok, todos_con_asset_id_local(esc1), ...
        'V1 todos los objetos con asset_id');
      ok = check_local(ok, strcmp(esc1.unidades, 'm'), 'V1 unidades m');
      ok = check_local(ok, bbox_finita_local(esc1.bbox_global), ...
        'V1 bbox_global finita');
    catch err
      fprintf(2, 'FALLO V1 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- V2 determinismo ----------
    try
      [esc_a, ~] = aos_cad_escena_3d(fuente, opts_esc);
      [esc_b, ~] = aos_cad_escena_3d(fuente, opts_esc);
      ok = check_local(ok, isequal(esc_a, esc_b), ...
        'V2 dos construcciones isequal');
    catch err
      fprintf(2, 'FALLO V2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- V3 render headless ----------
    try
      if ~exist('esc1', 'var') || ~isstruct(esc1)
        [esc1, ~] = aos_cad_escena_3d(fuente, opts_esc);
      endif
      png = fullfile(tmpdir, 'visor_3d_smoke.png');
      if exist(png, 'file') == 2
        delete(png);
      endif
      [info, h] = aos_cad_visor_3d(esc1, struct('visible', false, 'png', png));
      ok = check_local(ok, isstruct(info) && info.n_objetos_dibujados > 0, ...
        'V3 n_objetos_dibujados > 0');
      ok = check_local(ok, exist(png, 'file') == 2 || ...
        (~isempty(info.png) && exist(info.png, 'file') == 2), ...
        'V3 PNG generado');
      ok = check_local(ok, isempty(h) || ~ishandle(h), ...
        'V3 figura cerrada');
      ok = check_local(ok, ~info.visible && ~info.figura_abierta, ...
        'V3 headless (visible off, figura cerrada)');
    catch err
      fprintf(2, 'FALLO V3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- V4 escena vacia ----------
    try
      [esc0, ~] = aos_cad_escena_3d(struct(), struct( ...
        'incluir_pozo', false, 'incluir_red', false, 'incluir_step', false));
      ok = check_local(ok, esc0.n_objetos == 0, 'V4 cero objetos');
      [info0, h0] = aos_cad_visor_3d(esc0, struct('visible', false));
      ok = check_local(ok, info0.vacia && info0.n_objetos_dibujados == 0, ...
        'V4 visor informa vacia');
      ok = check_local(ok, isempty(h0) && ~info0.figura_abierta, ...
        'V4 sin figura abierta');
    catch err
      fprintf(2, 'FALLO V4 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- V5 separacion escena-render (inspeccion de fuente) ----------
    try
      f_esc = which('aos_cad_escena_3d');
      f_vis = which('aos_cad_visor_3d');
      ok = check_local(ok, exist(f_esc, 'file') == 2 && exist(f_vis, 'file') == 2, ...
        'V5 archivos escena/visor en path');
      raw_esc = fileread_local(f_esc);
      raw_vis = fileread_local(f_vis);
      % Solo cuerpo de codigo (sin comentarios de cabecera): quitar lineas % 
      cuerpo_esc = cuerpo_sin_comentarios_local(raw_esc);
      cuerpo_vis = cuerpo_sin_comentarios_local(raw_vis);
      graficos = {'figure(', 'plot(', 'plot3(', 'print(', 'surf(', 'mesh(', ...
        'axes(', 'clf(', 'close(', 'imagesc(', 'patch('};
      esc_limpia = true;
      for i = 1:numel(graficos)
        if ~isempty(strfind(cuerpo_esc, graficos{i}))
          esc_limpia = false;
          fprintf(2, 'FALLO V5 escena contiene llamada grafica: %s\n', graficos{i});
          break;
        endif
      endfor
      ok = check_local(ok, esc_limpia, 'V5 escena sin llamadas graficas');

      fis_uni = {'factor_a_metros', 'aos_cad_hidraulica', 'presion', 'caudal', ...
        'perdida', 'friccion', 'reynolds', 'darcy', 'SI_UNIT'};
      vis_limpia = true;
      for i = 1:numel(fis_uni)
        if ~isempty(strfind(cuerpo_vis, fis_uni{i}))
          vis_limpia = false;
          fprintf(2, 'FALLO V5 visor contiene fisica/unidades: %s\n', fis_uni{i});
          break;
        endif
      endfor
      ok = check_local(ok, vis_limpia, 'V5 visor sin fisica ni unidades');
    catch err
      fprintf(2, 'FALLO V5 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- V6 seleccion ----------
    try
      if ~exist('esc1', 'var') || ~isstruct(esc1)
        [esc1, ~] = aos_cad_escena_3d(fuente, opts_esc);
      endif
      [sel_tipo, items_t] = aos_cad_escena_seleccionar(esc1, struct('tipo', 'EQUIPO_3D'));
      n_eq_esc = contar_tipo_local(esc1, 'EQUIPO_3D');
      ok = check_local(ok, sel_tipo.n == n_eq_esc && n_eq_esc > 0, ...
        'V6 seleccion por tipo EQUIPO_3D conteo');
      ok = check_local(ok, isempty(items_t), 'V6 tipo con coincidencias sin item vacio');

      aid = primer_asset_id_local(esc1);
      ok = check_local(ok, ~isempty(aid), 'V6 hay asset_id para seleccionar');
      if ~isempty(aid)
        [sel_aid, items_a] = aos_cad_escena_seleccionar(esc1, struct('asset_id', aid));
        ok = check_local(ok, sel_aid.n >= 1, 'V6 seleccion por asset_id');
        ok = check_local(ok, isempty(items_a), 'V6 asset_id con coincidencias sin item vacio');
        for k = 1:numel(sel_aid.objetos)
          ok = check_local(ok, strcmp(char(sel_aid.objetos{k}.asset_id), aid), ...
            sprintf('V6 objeto[%d] asset_id coincide', k));
        endfor
      endif

      [sel_vacia, items_v] = aos_cad_escena_seleccionar(esc1, ...
        struct('asset_id', 'ASSET_INEXISTENTE_XYZ_999'));
      ok = check_local(ok, sel_vacia.n == 0, 'V6 seleccion vacia n=0');
      ok = check_local(ok, tiene_codigo_local(items_v, 'ESCENA_SELECCION_VACIA'), ...
        'V6 item ESCENA_SELECCION_VACIA');
    catch err
      fprintf(2, 'FALLO V6 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- V7 aditivo Sprint 6: color_rgb + n_objetos default intacto ----------
    try
      if ~exist('esc1', 'var') || ~isstruct(esc1)
        [esc1, ~] = aos_cad_escena_3d(fuente, opts_esc);
      endif
      n_obj_default = esc1.n_objetos;
      [esc_def2, ~] = aos_cad_escena_3d(fuente, opts_esc);
      ok = check_local(ok, esc_def2.n_objetos == n_obj_default, ...
        'V7 escena default n_objetos sin cambio');

      % Sin incluir_puertos (default): no aparecen PUERTO/CONEXION
      ok = check_local(ok, contar_tipo_local(esc_def2, 'PUERTO') == 0 ...
        && contar_tipo_local(esc_def2, 'CONEXION') == 0, ...
        'V7 default sin PUERTO/CONEXION');

      esc_col = esc1;
      if ~isempty(esc_col.objetos)
        o0 = esc_col.objetos{1};
        o0.color_rgb = [0.2, 0.8, 0.3];
        esc_col.objetos{1} = o0;
      endif
      png_c = fullfile(tmpdir, 'visor_3d_color_rgb.png');
      if exist(png_c, 'file') == 2, delete(png_c); endif
      [info_c, h_c] = aos_cad_visor_3d(esc_col, struct('visible', false, 'png', png_c));
      ok = check_local(ok, isstruct(info_c) && info_c.n_objetos_dibujados > 0 ...
        && info_c.n_objetos_dibujados == esc_col.n_objetos, ...
        'V7 color_rgb path n_objetos_dibujados = n_objetos');
      ok = check_local(ok, exist(png_c, 'file') == 2 || ...
        (~isempty(info_c.png) && exist(info_c.png, 'file') == 2), ...
        'V7 PNG color_rgb generado');
      ok = check_local(ok, isempty(h_c) || ~ishandle(h_c), 'V7 figura color_rgb cerrada');
      if exist(png_c, 'file') == 2, delete(png_c); endif
    catch err
      fprintf(2, 'FALLO V7 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
    set(0, 'defaultfigurevisible', vis_anterior);
  end_unwind_protect

  report_final_local(ok);
endfunction

function report_final_local(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_visor_3d APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_visor_3d NO APROBADO\n');
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

function n = contar_tipo_local(escena, tipo)
  n = 0;
  if ~isstruct(escena) || ~isfield(escena, 'objetos'), return; endif
  for i = 1:numel(escena.objetos)
    o = escena.objetos{i};
    if isstruct(o) && isfield(o, 'tipo') && strcmp(char(o.tipo), tipo)
      n = n + 1;
    endif
  endfor
endfunction

function tf = todos_con_asset_id_local(escena)
  tf = false;
  if ~isstruct(escena) || ~isfield(escena, 'objetos') || isempty(escena.objetos)
    return;
  endif
  for i = 1:numel(escena.objetos)
    o = escena.objetos{i};
    if ~isstruct(o) || ~isfield(o, 'asset_id') || isempty(char(o.asset_id))
      return;
    endif
  endfor
  tf = true;
endfunction

function aid = primer_asset_id_local(escena)
  aid = '';
  if ~isstruct(escena) || ~isfield(escena, 'objetos'), return; endif
  for i = 1:numel(escena.objetos)
    o = escena.objetos{i};
    if isstruct(o) && isfield(o, 'asset_id') && ~isempty(o.asset_id)
      aid = char(o.asset_id);
      return;
    endif
  endfor
endfunction

function tf = bbox_finita_local(bb)
  tf = false;
  if ~isstruct(bb), return; endif
  req = {'xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'};
  for i = 1:numel(req)
    if ~isfield(bb, req{i}) || ~isfinite(bb.(req{i})), return; endif
  endfor
  tf = true;
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

function raw = fileread_local(ruta)
  fid = fopen(ruta, 'rt');
  if fid < 0
    raw = '';
    return;
  endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
endfunction

function cuerpo = cuerpo_sin_comentarios_local(raw)
  % Elimina lineas de comentario completo y colas "% ..." para inspeccion.
  lineas = strsplit(raw, {"\n", "\r"});
  out = {};
  for i = 1:numel(lineas)
    ln = lineas{i};
    % quitar comentario de linea (respetando strings simples no critico aqui)
    p = strfind(ln, '%');
    if ~isempty(p)
      ln = ln(1:p(1)-1);
    endif
    if ~isempty(strtrim(ln))
      out{end+1} = ln; %#ok<AGROW>
    endif
  endfor
  if isempty(out)
    cuerpo = '';
  else
    cuerpo = out{1};
    for i = 2:numel(out)
      cuerpo = [cuerpo, char(10), out{i}]; %#ok<AGROW>
    endfor
  endif
endfunction

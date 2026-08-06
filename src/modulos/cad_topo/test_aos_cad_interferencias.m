function ok = test_aos_cad_interferencias()
% TEST_AOS_CAD_INTERFERENCIAS Interferencias AABB (Sprint 6).
% Caso colision (0.25 m3) + caso limpio + determinismo + bbox indeterminada.
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

  fprintf('\n=== test_aos_cad_interferencias ===\n');

  step_col = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_interferencia.step');
  step_lim = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
  for f = {step_col, step_lim}
    if exist(f{1}, 'file') ~= 2
      fprintf(2, 'FALTA fixture: %s\n', f{1});
      ok = false;
      fprintf(2, 'RESULTADO: test_aos_cad_interferencias NO APROBADO\n');
      return;
    endif
  endfor

  vol_esperado = 0.25;
  prev = CONFIG_ACTIVA;
  unwind_protect
    % ---------- 1) Caso con colision conocida ----------
    try
      CONFIG_ACTIVA = struct();
      ok = check_local(ok, aos_cad_importar_step(step_col, true), ...
        'import STEP interferencia');
      fuente = struct();
      fuente.cad_topologia = CONFIG_ACTIVA.cad_topologia;
      opts = struct('incluir_pozo', false, 'incluir_red', false, 'incluir_step', true);
      [esc, ~] = aos_cad_escena_3d(fuente, opts);
      ok = check_local(ok, isstruct(esc) && esc.n_objetos >= 2, ...
        'escena colision con >= 2 objetos');

      [tabla1, items1] = aos_cad_interferencias(esc);
      ok = check_local(ok, iscell(tabla1) && numel(tabla1) == 1, ...
        'colision: exactamente 1 par');
      if numel(tabla1) == 1 && isstruct(tabla1{1})
        fila = tabla1{1};
        ok = check_local(ok, strcmp(char(fila.tipo), 'SOLAPE'), 'colision tipo SOLAPE');
        ok = check_local(ok, isfinite(fila.volumen_solape_m3) ...
          && abs(fila.volumen_solape_m3 - vol_esperado) < 1e-9, ...
          sprintf('volumen_solape_m3 = 0.25 (got %.12g)', fila.volumen_solape_m3));
        ok = check_local(ok, fila.distancia_m == 0, 'distancia_m = 0 en solape');
      endif

      % Determinismo isequal
      [tabla2, items2] = aos_cad_interferencias(esc);
      ok = check_local(ok, isequal(tabla1, tabla2), 'determinismo isequal tabla');
      ok = check_local(ok, isequal(items1, items2), 'determinismo isequal items');
    catch err
      fprintf(2, 'FALLO colision excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- 2) Caso limpio ----------
    try
      CONFIG_ACTIVA = struct();
      ok = check_local(ok, aos_cad_importar_step(step_lim, true), ...
        'import STEP sin ensamble');
      fuente = struct();
      fuente.cad_topologia = CONFIG_ACTIVA.cad_topologia;
      opts = struct('incluir_pozo', false, 'incluir_red', false, 'incluir_step', true);
      [esc_l, ~] = aos_cad_escena_3d(fuente, opts);
      [tabla_l, ~] = aos_cad_interferencias(esc_l);
      ok = check_local(ok, iscell(tabla_l) && numel(tabla_l) == 0, ...
        'limpio: 0 pares');
    catch err
      fprintf(2, 'FALLO limpio excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- 3) Bbox indeterminada -> item, no cero ----------
    try
      esc_ind = struct();
      esc_ind.objetos = { ...
        struct('tipo', 'EQUIPO_3D', 'id', 'OK1', 'asset_id', 'AID_OK1', ...
          'geometry_id', 'GID_OK1', ...
          'bbox', struct('xmin', 0, 'xmax', 1, 'ymin', 0, 'ymax', 1, ...
            'zmin', 0, 'zmax', 1)), ...
        struct('tipo', 'EQUIPO_3D', 'id', 'BAD', 'asset_id', 'AID_BAD', ...
          'geometry_id', 'GID_BAD', ...
          'bbox', struct('xmin', NaN, 'xmax', 1, 'ymin', 0, 'ymax', 1, ...
            'zmin', 0, 'zmax', 1)), ...
        struct('tipo', 'EQUIPO_3D', 'id', 'OK2', 'asset_id', 'AID_OK2', ...
          'geometry_id', 'GID_OK2', ...
          'bbox', struct('xmin', 0.5, 'xmax', 1.5, 'ymin', 0.5, 'ymax', 1.5, ...
            'zmin', 0.5, 'zmax', 1.5))};
      esc_ind.n_objetos = 3;
      [tabla_i, items_i] = aos_cad_interferencias(esc_ind);
      ok = check_local(ok, tiene_codigo_local(items_i, 'INTERFERENCIA_BBOX_INDETERMINADA'), ...
        'item INTERFERENCIA_BBOX_INDETERMINADA');
      % El objeto BAD no aporta pares (omitido); OK1-OK2 si solapan
      for i = 1:numel(tabla_i)
        f = tabla_i{i};
        ok = check_local(ok, ~strcmp(char(f.asset_a), 'AID_BAD') ...
          && ~strcmp(char(f.asset_b), 'AID_BAD'), ...
          sprintf('par[%d] no involucra bbox indeterminada', i));
      endfor
      % No se inventa volumen 0 para el indeterminado como interferencia
      ok = check_local(ok, true, 'bbox indeterminada omitida (no forzada a 0)');
    catch err
      fprintf(2, 'FALLO bbox indeterminada excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_interferencias APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_interferencias NO APROBADO\n');
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

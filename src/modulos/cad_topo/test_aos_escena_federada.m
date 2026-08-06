function ok = test_aos_escena_federada()
% TEST_AOS_ESCENA_FEDERADA Escena federada pozo+red+STEP (Sprint 6).
% n_objetos = suma; sin colision de id; asset_id compartido como item; seleccion.
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

  fprintf('\n=== test_aos_escena_federada ===\n');

  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  for f = {dxf, step}
    if exist(f{1}, 'file') ~= 2
      fprintf(2, 'FALTA fixture: %s\n', f{1});
      ok = false;
      fprintf(2, 'RESULTADO: test_aos_escena_federada NO APROBADO\n');
      return;
    endif
  endfor

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    try
      ok = check_local(ok, aos_cad_importar_dxf(dxf, true), 'import DXF');
      aos_cad_construir_topologia(0.05, true);
      ok = check_local(ok, aos_cad_importar_step(step, true), 'import STEP');

      cad = CONFIG_ACTIVA.cad_topologia;
      survey = struct();
      survey.MD = [0; 50; 100];
      survey.TVD = [0; 50; 100];
      survey.inclinacion = [0; 0; 0];
      survey.azimut = [0; 0; 0];

      % Escenas individuales (mismo criterio que federada)
      opts_red = struct('incluir_red', true, 'incluir_pozo', false, ...
        'incluir_step', false, 'usar_geometria_activa', false);
      opts_pozo = struct('incluir_red', false, 'incluir_pozo', true, ...
        'incluir_step', false, 'usar_geometria_activa', false);
      opts_step = struct('incluir_red', false, 'incluir_pozo', false, ...
        'incluir_step', true, 'usar_geometria_activa', false);

      [esc_red, ~] = aos_cad_escena_3d(cad, opts_red);
      [esc_pozo, ~] = aos_cad_escena_3d(struct('survey', survey), opts_pozo);
      indice = [];
      if isfield(cad, 'step_indice_geometrico')
        indice = cad.step_indice_geometrico;
      endif
      [esc_step, ~] = aos_cad_escena_3d(struct('indice_geometrico', indice), opts_step);

      n_sum = esc_red.n_objetos + esc_pozo.n_objetos + esc_step.n_objetos;
      ok = check_local(ok, n_sum >= 3, 'suma individual >= 3');

      % Plantar asset_id compartido red <-> instalaciones (sin fusion silenciosa)
      aid_compartido = '';
      if isstruct(esc_red) && isfield(esc_red, 'objetos')
        for i = 1:numel(esc_red.objetos)
          o = esc_red.objetos{i};
          if isstruct(o) && isfield(o, 'asset_id') && ~isempty(o.asset_id)
            aid_compartido = char(o.asset_id);
            break;
          endif
        endfor
      endif
      ok = check_local(ok, ~isempty(aid_compartido), 'hay asset_id de red para plantar');

      indice_dup = indice;
      if isstruct(indice_dup) && isfield(indice_dup, 'ocurrencias') ...
          && ~isempty(indice_dup.ocurrencias)
        oc0 = indice_dup.ocurrencias{1};
        if ~isstruct(oc0), oc0 = struct(); endif
        oc0.asset_id = aid_compartido;
        indice_dup.ocurrencias{1} = oc0;
      endif

      fuentes = struct();
      fuentes.red = cad;
      fuentes.pozo = survey;
      fuentes.instalaciones = indice_dup;

      [esc_fed, items_fed] = aos_escena_federada(fuentes);
      ok = check_local(ok, isstruct(esc_fed) && isfield(esc_fed, 'federada') ...
        && esc_fed.federada, 'escena federada flag');
      ok = check_local(ok, esc_fed.n_objetos == n_sum, ...
        sprintf('n_objetos federada = suma (%d)', n_sum));

      % Sin colision de id
      ids = {};
      for i = 1:numel(esc_fed.objetos)
        o = esc_fed.objetos{i};
        if isstruct(o) && isfield(o, 'id')
          ids{end+1} = char(o.id); %#ok<AGROW>
        endif
      endfor
      ok = check_local(ok, numel(ids) == numel(unique(ids)), 'ids sin colision');

      % Prefijo FUENTE: en ids
      pref_ok = true;
      for i = 1:numel(ids)
        if isempty(strfind(ids{i}, ':'))
          pref_ok = false;
          break;
        endif
      endfor
      ok = check_local(ok, pref_ok, 'ids namespaced FUENTE:id_local');

      % asset_id compartido reportado (no fusionado)
      ok = check_local(ok, tiene_codigo_local(items_fed, 'FEDERACION_ASSET_DUPLICADO'), ...
        'item FEDERACION_ASSET_DUPLICADO');

      n_aid = 0;
      for i = 1:numel(esc_fed.objetos)
        o = esc_fed.objetos{i};
        if isstruct(o) && isfield(o, 'asset_id') ...
            && strcmp(char(o.asset_id), aid_compartido)
          n_aid = n_aid + 1;
        endif
      endfor
      ok = check_local(ok, n_aid >= 2, ...
        'asset_id compartido presente en >= 2 objetos (sin fusion)');

      % Seleccion sigue funcionando
      [sel, items_s] = aos_cad_escena_seleccionar(esc_fed, ...
        struct('asset_id', aid_compartido));
      ok = check_local(ok, sel.n == n_aid && n_aid >= 2, ...
        'seleccion por asset_id devuelve todas las ocurrencias');
      ok = check_local(ok, isempty(items_s), 'seleccion con coincidencias sin item vacio');

      [sel_f, ~] = aos_cad_escena_seleccionar(esc_fed, ...
        struct('fuente_federada', 'RED'));
      ok = check_local(ok, sel_f.n == esc_red.n_objetos, ...
        'seleccion aditiva por fuente_federada RED');

    catch err
      fprintf(2, 'FALLO excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_escena_federada APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_escena_federada NO APROBADO\n');
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

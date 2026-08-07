function ok = test_aos_cad_puertos_contrato()
% TEST_AOS_CAD_PUERTOS_CONTRATO Dos puertos/tramo, asset_id coherente, SI, sin 3D.
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

  fprintf('\n=== test_aos_cad_puertos_contrato ===\n');

  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    struct('id', 'N001', 'x', 0, 'y', 0, 'z', 0, 'tipo', 'JUNCTION'), ...
    struct('id', 'N002', 'x', 10, 'y', 0, 'z', 1.5, 'tipo', 'JUNCTION'), ...
    struct('id', 'N003', 'x', 20, 'y', 0, 'z', 0, 'tipo', 'JUNCTION')};
  modelo.tablas_entrada.tramos = { ...
    struct('id', 'T001', 'nodo_o', 'N001', 'nodo_d', 'N002', ...
      'x1', 0, 'y1', 0, 'x2', 10, 'y2', 0, 'diametro_m', 0.1), ...
    struct('id', 'T002', 'nodo_o', 'N002', 'nodo_d', 'N003', ...
      'x1', 10, 'y1', 0, 'x2', 20, 'y2', 0, 'diametro_m', 0.1)};

  [modelo, ~] = aos_cad_asignar_asset_ids(modelo);
  [modelo, ~] = aos_cad_puertos_derivar(modelo);

  puertos = modelo.tablas_entrada.puertos;
  n_tr = numel(modelo.tablas_entrada.tramos);
  ok = check_local(ok, numel(puertos) == 2 * n_tr, 'exactamente 2 puertos por tramo');

  % asset_id_componente coherente con tramos
  for i = 1:n_tr
    tr = modelo.tablas_entrada.tramos{i};
    aid = '';
    if isfield(tr, 'asset_id'), aid = char(tr.asset_id); endif
    ok = check_local(ok, ~isempty(aid), sprintf('tramo %s tiene asset_id', tr.id));
    p_ent = [];
    p_sal = [];
    for j = 1:numel(puertos)
      if strcmp(puertos{j}.id, [tr.id '_ENTRADA']), p_ent = puertos{j}; endif
      if strcmp(puertos{j}.id, [tr.id '_SALIDA']), p_sal = puertos{j}; endif
    endfor
    ok = check_local(ok, ~isempty(p_ent) && ~isempty(p_sal), ...
      sprintf('puertos ENTRADA/SALIDA de %s', tr.id));
    if ~isempty(p_ent) && ~isempty(p_sal)
      ok = check_local(ok, strcmp(p_ent.tipo, 'ENTRADA') && strcmp(p_sal.tipo, 'SALIDA'), ...
        sprintf('tipos ENTRADA/SALIDA %s', tr.id));
      ok = check_local(ok, strcmp(char(p_ent.asset_id_componente), aid) ...
        && strcmp(char(p_sal.asset_id_componente), aid), ...
        sprintf('asset_id_componente coherente %s', tr.id));
      ok = check_local(ok, strcmp(char(p_ent.nodo_ref), char(tr.nodo_o)) ...
        && strcmp(char(p_sal.nodo_ref), char(tr.nodo_d)), ...
        sprintf('nodo_ref o/d %s', tr.id));
    endif
  endfor

  % Posiciones en SI (metros numericos finitos)
  for j = 1:numel(puertos)
    p = puertos{j};
    ok = check_local(ok, isfield(p, 'posicion') && isstruct(p.posicion) ...
      && isfield(p.posicion, 'x') && isfield(p.posicion, 'y') && isfield(p.posicion, 'z') ...
      && isnumeric(p.posicion.x) && isfinite(p.posicion.x) ...
      && isnumeric(p.posicion.y) && isfinite(p.posicion.y) ...
      && isnumeric(p.posicion.z) && isfinite(p.posicion.z), ...
      sprintf('posicion SI %s', p.id));
  endfor
  % Extremos T001: (0,0,*) y (10,0,*)
  for j = 1:numel(puertos)
    if strcmp(puertos{j}.id, 'T001_ENTRADA')
      ok = check_local(ok, abs(puertos{j}.posicion.x) < 1e-12 ...
        && abs(puertos{j}.posicion.y) < 1e-12, 'T001_ENTRADA en origen');
    endif
    if strcmp(puertos{j}.id, 'T001_SALIDA')
      ok = check_local(ok, abs(puertos{j}.posicion.x - 10) < 1e-12, 'T001_SALIDA x=10');
    endif
  endfor

  % Sin campos 3D (interferencias / mesh / transform / conexion_3d)
  prohibidos = {'mesh', 'mesh_id', 'transform', 'matriz', 'interferencia', ...
                'bbox_3d', 'conexion_3d', 'placement', 'solid_id', 'brep'};
  for j = 1:numel(puertos)
    fn = fieldnames(puertos{j});
    for k = 1:numel(fn)
      if any(strcmpi(fn{k}, prohibidos))
        fprintf(2, 'FALLO  puerto %s tiene campo 3D %s\n', puertos{j}.id, fn{k});
        ok = false;
      endif
    endfor
  endfor
  if ok
    fprintf('OK  sin campos 3D en puertos\n');
  endif

  % Fixture real DXF (si disponible): import debe poblar puertos
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells.dxf');
  if exist(dxf, 'file') == 2
    global CONFIG_ACTIVA;
    prev = CONFIG_ACTIVA;
    unwind_protect
      CONFIG_ACTIVA = struct();
      if aos_cad_importar_dxf(dxf, true)
        m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        ntr = numel(m.tablas_entrada.tramos);
        npu = 0;
        if isfield(m.tablas_entrada, 'puertos')
          npu = numel(m.tablas_entrada.puertos);
        endif
        ok = check_local(ok, npu == 2 * ntr && ntr >= 1, ...
          'import DXF: 2 puertos por tramo');
      endif
    unwind_protect_cleanup
      CONFIG_ACTIVA = prev;
    end_unwind_protect
  endif

  % ---------- Aditivo Sprint 6: contrato Sprint 2 no se degrada ----------
  try
    snap = modelo.tablas_entrada.puertos;
    [p3, ~] = aos_cad_puertos_3d(modelo);
    ok = check_local(ok, isequal(modelo.tablas_entrada.puertos, snap), ...
      'S6: puertos_3d no muta tablas_entrada.puertos');
    ok = check_local(ok, isstruct(p3) && p3.n == numel(snap), ...
      'S6: puertos_3d.n = contrato Sprint 2');
    % Campos del contrato siguen presentes (sin campos 3D en tablas_entrada)
    for j = 1:numel(modelo.tablas_entrada.puertos)
      p = modelo.tablas_entrada.puertos{j};
      ok = check_local(ok, isfield(p, 'id') && isfield(p, 'tipo') ...
        && isfield(p, 'asset_id_componente') && isfield(p, 'nodo_ref') ...
        && isfield(p, 'posicion') && isfield(p, 'estado_conexion'), ...
        sprintf('S6 contrato campos %s', p.id));
      ok = check_local(ok, ~isfield(p, 'geometry_id') && ~isfield(p, 'posicion_resuelta'), ...
        sprintf('S6 contrato sin campos 3D materializados %s', p.id));
    endfor
  catch err
    fprintf(2, 'FALLO S6 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  if ok
    fprintf('RESULTADO: test_aos_cad_puertos_contrato APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_puertos_contrato NO APROBADO\n');
  endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO  %s\n', msg);
    ok = false;
  endif
endfunction

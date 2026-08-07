function ok = test_aos_cad_puertos_conexiones()
% TEST_AOS_CAD_PUERTOS_CONEXIONES Puertos/conexiones 3D + validador (Sprint 6).
% Fixture: demo_aos_red_ramificada.dxf. Headless. Sin AOS_CAD_SKIP_VISOR.
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

  fprintf('\n=== test_aos_cad_puertos_conexiones ===\n');

  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA fixture: %s\n', dxf);
    ok = false;
    fprintf(2, 'RESULTADO: test_aos_cad_puertos_conexiones NO APROBADO\n');
    return;
  endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();

    try
      ok = check_local(ok, aos_cad_importar_dxf(dxf, true), 'import DXF red ramificada');
      aos_cad_construir_topologia(0.05, true);
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, isstruct(modelo) && isfield(modelo, 'tablas_entrada'), ...
        'modelo con tablas_entrada');

      % Snapshot contrato Sprint 2 (no debe mutar)
      puertos_s2 = {};
      if isfield(modelo.tablas_entrada, 'puertos')
        puertos_s2 = modelo.tablas_entrada.puertos;
      endif
      n_tr = 0;
      if isfield(modelo.tablas_entrada, 'tramos')
        n_tr = numel(modelo.tablas_entrada.tramos);
      endif
      ok = check_local(ok, n_tr >= 1 && numel(puertos_s2) == 2 * n_tr, ...
        'Sprint 2: 2 puertos por tramo antes de 3D');

      % ---------- A: puertos 3D con posicion finita ----------
      [p3, items_p] = aos_cad_puertos_3d(modelo);
      ok = check_local(ok, isstruct(p3) && p3.n == 2 * n_tr, ...
        'puertos_3d.n = 2 * n_tramos');
      ok = check_local(ok, strcmp(p3.unidades, 'm'), 'puertos_3d unidades m');

      n_finitos = 0;
      for i = 1:numel(p3.lista)
        p = p3.lista{i};
        if isstruct(p) && isfield(p, 'posicion_resuelta') && p.posicion_resuelta ...
            && isfield(p, 'posicion') && isstruct(p.posicion) ...
            && isnumeric(p.posicion.x) && isfinite(p.posicion.x(1)) ...
            && isnumeric(p.posicion.y) && isfinite(p.posicion.y(1)) ...
            && isnumeric(p.posicion.z) && isfinite(p.posicion.z(1))
          n_finitos = n_finitos + 1;
        endif
      endfor
      ok = check_local(ok, n_finitos == 2 * n_tr, ...
        '2 puertos/tramo con posicion 3D finita');
      ok = check_local(ok, ~tiene_codigo_local(items_p, 'PUERTO_3D_SIN_POSICION'), ...
        'fixture sano sin PUERTO_3D_SIN_POSICION');

      % Contrato Sprint 2 intacto tras materializar
      modelo2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, isequal(modelo2.tablas_entrada.puertos, puertos_s2), ...
        'tablas_entrada.puertos Sprint 2 intacto');

      % ---------- B: emparejamiento por nodo_ref ----------
      [tabla, items_c] = aos_cad_conexiones_3d(p3);
      ok = check_local(ok, iscell(tabla) && numel(tabla) >= 1, 'tabla_conexiones no vacia');

      n_conectada = 0;
      n_abierta = 0;
      emparejamiento_ok = true;
      for i = 1:numel(tabla)
        c = tabla{i};
        if ~isstruct(c) || ~isfield(c, 'estado'), continue; endif
        est = char(c.estado);
        if strcmp(est, 'CONECTADA')
          n_conectada = n_conectada + 1;
          % Ambos puertos deben compartir el nodo_ref de la conexion
          pa = encontrar_puerto_local(p3.lista, c.puerto_a);
          pb = encontrar_puerto_local(p3.lista, c.puerto_b);
          if isempty(pa) || isempty(pb)
            emparejamiento_ok = false;
          elseif ~isempty(c.nodo_ref)
            if ~strcmp(char(pa.nodo_ref), char(c.nodo_ref)) ...
                || ~strcmp(char(pb.nodo_ref), char(c.nodo_ref))
              emparejamiento_ok = false;
            endif
          endif
          ok = check_local(ok, length(c.id) >= 4 && strcmp(c.id(1:4), 'CNX_'), ...
            sprintf('clave CNX_ en %s', c.id));
        elseif strcmp(est, 'ABIERTA')
          n_abierta = n_abierta + 1;
        endif
      endfor
      ok = check_local(ok, n_conectada >= 1, 'al menos una CONECTADA por nodo_ref');
      ok = check_local(ok, emparejamiento_ok, 'emparejamiento CONECTADA por nodo_ref');

      % Prefijos PTO_ en por_id
      fn_pto = fieldnames(p3.por_id);
      ok = check_local(ok, numel(fn_pto) == p3.n, 'por_id cubre todos los puertos');
      pref_ok = true;
      for i = 1:numel(fn_pto)
        if length(fn_pto{i}) < 4 || ~strcmp(fn_pto{i}(1:4), 'PTO_')
          pref_ok = false;
          break;
        endif
      endfor
      ok = check_local(ok, pref_ok, 'claves PTO_* en por_id');

      % ---------- C: consistencia con aristas 2D (fixture sano) ----------
      [rep, items_v] = aos_cad_validar_conectividad_3d(tabla, modelo, ...
        struct('puertos_3d', p3));
      ok = check_local(ok, isstruct(rep) && rep.n_inconsistentes == 0, ...
        'fixture sano: 0 CONEXION_3D_INCONSISTENTE_2D');
      ok = check_local(ok, ~tiene_codigo_local(items_v, 'CONEXION_3D_INCONSISTENTE_2D'), ...
        'items sin inconsistencia 2D');

      % ---------- D: caso manipulado ----------
      tabla_bad = tabla;
      idx_cnx = 0;
      for i = 1:numel(tabla_bad)
        if isstruct(tabla_bad{i}) && isfield(tabla_bad{i}, 'estado') ...
            && strcmp(char(tabla_bad{i}.estado), 'CONECTADA')
          idx_cnx = i;
          break;
        endif
      endfor
      ok = check_local(ok, idx_cnx > 0, 'hay CONECTADA para manipular');
      if idx_cnx > 0
        tabla_bad{idx_cnx}.nodo_ref = 'NODO_FANTASMA_XYZ_999';
        [rep_bad, items_bad] = aos_cad_validar_conectividad_3d(tabla_bad, modelo, ...
          struct('puertos_3d', p3));
        ok = check_local(ok, rep_bad.n_inconsistentes >= 1, ...
          'manipulado: n_inconsistentes >= 1');
        ok = check_local(ok, tiene_codigo_local(items_bad, 'CONEXION_3D_INCONSISTENTE_2D'), ...
          'manipulado: item CONEXION_3D_INCONSISTENTE_2D');
      endif

      % Sprint 2 intacto al final
      modelo3 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, isequal(modelo3.tablas_entrada.puertos, puertos_s2), ...
        'Sprint 2 puertos intactos al cierre');

    catch err
      fprintf(2, 'FALLO excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_puertos_conexiones APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_puertos_conexiones NO APROBADO\n');
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

function p = encontrar_puerto_local(lista, pid)
  p = [];
  if isempty(lista) || isempty(pid), return; endif
  pid = char(pid);
  for i = 1:numel(lista)
    if isstruct(lista{i}) && isfield(lista{i}, 'id') ...
        && strcmp(char(lista{i}.id), pid)
      p = lista{i};
      return;
    endif
  endfor
endfunction

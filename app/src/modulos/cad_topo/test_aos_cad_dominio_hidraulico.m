function ok = test_aos_cad_dominio_hidraulico()
% Prueba camino selectivo sobre una red con dos recorridos posibles.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_dominio_hidraulico ===\n');
  prev = CONFIG_ACTIVA;
  unwind_protect
    modelo = modelo_loop_local();
    [dominio, modelo, caminos] = aos_cad_hidraulica_dominio_programatico( ...
      modelo, 'N1', 'N4', 1);
    ok = check_local(ok, numel(caminos) == 2, ...
      'detecta dos caminos alternativos');
    ok = check_local(ok, strcmp(dominio.tipo, 'SELECTED_PATH'), ...
      'selecciona un camino simple');
    ok = check_local(ok, numel(dominio.tramos_seleccionados) == 2, ...
      'dominio contiene dos tramos');

    CONFIG_ACTIVA = struct('cad_topologia', struct('modelo_aoscad', modelo));
    aos_cad_hidraulica_dominio_definir_condiciones(20, 100, 0, true);
    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_pq, ~] = aos_cad_hidraulica_dominio_activo(modelo);
    ok = check_local(ok, strcmp(dom_pq.condicion_extremos, 'P_INICIO_Q_FIN'), ...
      'modo default P_INICIO_Q_FIN');
    cfg = aos_cad_hidraulica_defaults(modelo);
    red = aos_cad_hidraulica_preparar(modelo, cfg);
    ok = check_local(ok, numel(red.nodos) == 3, ...
      'filtra tres nodos del camino');
    ok = check_local(ok, numel(red.tramos) == 2, ...
      'filtra dos tramos del camino');
    ok = check_local(ok, ~red.tiene_lazos, 'camino filtrado sin lazo');

    resultados = aos_cad_hidraulica_ejecutar(true);
    ok = check_local(ok, numel(resultados.tramos) == 2, ...
      'solver ejecuta solo el dominio');
    ok = check_local(ok, ...
      strcmp(resultados.resumen{1}.dominio_hidraulico_tipo, 'SELECTED_PATH'), ...
      'resultado registra tipo de dominio');

    % Modos nuevos Sprint 3
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    aos_cad_hidraulica_dominio_definir_condiciones('Q_INICIO_P_FIN', 100, 18, 0, true);
    modelo_qp = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_qp, ~] = aos_cad_hidraulica_dominio_activo(modelo_qp);
    ok = check_local(ok, strcmp(dom_qp.condicion_extremos, 'Q_INICIO_P_FIN'), ...
      'modo Q_INICIO_P_FIN definido');
    res_qp = aos_cad_hidraulica_ejecutar(true);
    ok = check_local(ok, numel(res_qp.tramos) == 2, 'Q_INICIO_P_FIN ejecuta dominio');

    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    aos_cad_hidraulica_dominio_definir_condiciones('P_INICIO_P_FIN', 20, 19.5, 0, true);
    modelo_pp = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_pp, ~] = aos_cad_hidraulica_dominio_activo(modelo_pp);
    ok = check_local(ok, strcmp(dom_pp.condicion_extremos, 'P_INICIO_P_FIN'), ...
      'modo P_INICIO_P_FIN definido');
    cfg_pp = aos_cad_hidraulica_defaults(modelo_pp);
    cfg_pp.tol_presion_Pa = 10;
    [modelo_pp, res_pp] = aos_cad_hidraulica_dominio_resolver_pp(modelo_pp, cfg_pp, true);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_pp;
    ok = check_local(ok, isfield(res_pp, 'tramos') && numel(res_pp.tramos) == 2, ...
      'P_INICIO_P_FIN resuelve dominio');

    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dominio_loop, modelo] = aos_cad_hidraulica_dominio_programatico( ...
      modelo, 'N1', 'N4', 'TODOS');
    ok = check_local(ok, strcmp(dominio_loop.tipo, 'LOOP_SUBNETWORK'), ...
      'anillo queda persistido');
    ok = check_local(ok, strcmp(dominio_loop.estado_solver, 'LISTO_LAZO_KIRCHHOFF'), ...
      'estado_solver LISTO_LAZO_KIRCHHOFF');
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    aos_cad_hidraulica_dominio_definir_condiciones(20, 100, 0, true);
    ok_val_loop = aos_cad_hidraulica_dominio_validar(true);
    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    ok = check_local(ok, ok_val_loop, 'validar acepta anillo');
    ok = check_local(ok, tiene_codigo_local(modelo, 'HID_LAZO_MODO_CONDICION_OK'), ...
      'item HID_LAZO_MODO_CONDICION_OK');
    red_loop = aos_cad_hidraulica_preparar( ...
      modelo, aos_cad_hidraulica_defaults(modelo));
    ok = check_local(ok, red_loop.requiere_solver_lazos, ...
      'preparar marca requiere_solver_lazos');
    [modelo_loop, res_loop] = aos_cad_hidraulica_resolver( ...
      modelo, aos_cad_hidraulica_defaults(modelo), true);
    ok = check_local(ok, isfield(res_loop, 'resumen') && ...
      logical(res_loop.resumen{1}.convergio), ...
      'anillo se ejecuta y converge');
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_dominio_hidraulico APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_dominio_hidraulico NO APROBADO\n');
  endif
endfunction

function tf = tiene_codigo_local(modelo, codigo)
  tf = false;
  if ~isstruct(modelo) || ~isfield(modelo, 'validaciones') || ...
      ~isfield(modelo.validaciones, 'items')
    return;
  endif
  items = modelo.validaciones.items;
  if isstruct(items), items = num2cell(items); endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo)
      tf = true; return;
    endif
  endfor
endfunction

function modelo = modelo_loop_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), ...
    nodo_local('N2', 100, 50), ...
    nodo_local('N3', 100, -50), ...
    nodo_local('N4', 200, 0)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 50), ...
    tramo_local('T2', 'N2', 'N4', 100, 50, 200, 0), ...
    tramo_local('T3', 'N1', 'N3', 0, 0, 100, -50), ...
    tramo_local('T4', 'N3', 'N4', 100, -50, 200, 0)};
  modelo.tablas_entrada.condiciones_borde = {};
endfunction

function nodo = nodo_local(id, x, y)
  nodo = struct('id', id, 'x', x, 'y', y, 'z', 0, 'tipo', 'JUNCTION');
endfunction

function tramo = tramo_local(id, nodo_o, nodo_d, x1, y1, x2, y2)
  tramo = struct( ...
    'id', id, ...
    'nodo_o', nodo_o, ...
    'nodo_d', nodo_d, ...
    'x1', x1, ...
    'y1', y1, ...
    'x2', x2, ...
    'y2', y2, ...
    'longitud_m', hypot(x2-x1, y2-y1), ...
    'diametro_m', 0.1016, ...
    'rugosidad', 4.5e-5, ...
    'modelo_hidraulico', 'MONOFASICO_DARCY');
endfunction

function ok = check_local(ok, condicion, mensaje)
  if condicion
    fprintf('OK  %s\n', mensaje);
  else
    fprintf(2, 'FALLO  %s\n', mensaje);
    ok = false;
  endif
endfunction

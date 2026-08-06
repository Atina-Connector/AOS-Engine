function ok = test_aos_cad_dominio_condiciones()
% TEST_AOS_CAD_DOMINIO_CONDICIONES Modos P-Q / Q-P / P-P (Sprint 3 C).
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_dominio_condiciones ===\n');

  ok = check_local(ok, exist('aos_cad_hidraulica_dominio_definir_condiciones', 'file') == 2, ...
    'definir_condiciones en path');
  ok = check_local(ok, exist('aos_cad_hidraulica_dominio_validar', 'file') == 2, ...
    'dominio_validar en path');
  ok = check_local(ok, exist('aos_cad_hidraulica_dominio_resolver_pp', 'file') == 2, ...
    'dominio_resolver_pp en path');
  if ~ok, report_final(ok); return; endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    % --- P_INICIO_Q_FIN: regresion del modo default ---
    modelo = modelo_camino_local();
    [dominio, modelo] = aos_cad_hidraulica_dominio_programatico(modelo, 'N1', 'N3', 1);
    CONFIG_ACTIVA = struct('cad_topologia', struct('modelo_aoscad', modelo));
    aos_cad_hidraulica_dominio_definir_condiciones(20, 100, 0, true);
    modelo_pq = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_pq, ~] = aos_cad_hidraulica_dominio_activo(modelo_pq);
    ok = check_local(ok, strcmp(dom_pq.condicion_extremos, 'P_INICIO_Q_FIN'), ...
      'modo default P_INICIO_Q_FIN');
    res_pq = aos_cad_hidraulica_ejecutar(true);
    ok = check_local(ok, numel(res_pq.tramos) >= 1, 'P_INICIO_Q_FIN ejecuta');
    P_root_pq = NaN;
    for i = 1:numel(res_pq.nodos)
      if isfield(res_pq.nodos{i}, 'es_referencia_presion') && ...
          res_pq.nodos{i}.es_referencia_presion
        P_root_pq = res_pq.nodos{i}.presion_Pa;
      endif
    endfor
    ok = check_local(ok, abs(P_root_pq - 20e5) / 20e5 <= 1e-9, ...
      'P_INICIO_Q_FIN P_inicio exacta');

    % Misma llamada con modo explicito debe coincidir
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    aos_cad_hidraulica_dominio_definir_condiciones('P_INICIO_Q_FIN', 20, 100, 0, true);
    res_pq2 = aos_cad_hidraulica_ejecutar(true);
    ok = check_local(ok, abs(res_pq.tramos{1}.P_out_Pa - res_pq2.tramos{1}.P_out_Pa) ...
      / max(abs(res_pq.tramos{1}.P_out_Pa), 1) <= 1e-9, ...
      'P_INICIO_Q_FIN explicito = legacy');

    % --- Q_INICIO_P_FIN ---
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    aos_cad_hidraulica_dominio_definir_condiciones('Q_INICIO_P_FIN', 100, 18, 0, true);
    modelo_qp = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_qp, ~] = aos_cad_hidraulica_dominio_activo(modelo_qp);
    ok = check_local(ok, strcmp(dom_qp.condicion_extremos, 'Q_INICIO_P_FIN'), ...
      'modo Q_INICIO_P_FIN');
    res_qp = aos_cad_hidraulica_ejecutar(true);
    P_fin = presion_nodo_local(res_qp, 'N3');
    ok = check_local(ok, isfinite(P_fin) && abs(P_fin - 18e5) / 18e5 <= 1e-6, ...
      'Q_INICIO_P_FIN P_fin impuesta');

    % --- P_INICIO_P_FIN converge ---
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    aos_cad_hidraulica_dominio_definir_condiciones('P_INICIO_P_FIN', 20, 19.5, 0, true);
    modelo_pp = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_pp, ~] = aos_cad_hidraulica_dominio_activo(modelo_pp);
    ok = check_local(ok, strcmp(dom_pp.condicion_extremos, 'P_INICIO_P_FIN'), ...
      'modo P_INICIO_P_FIN');
    cfg = aos_cad_hidraulica_defaults(modelo_pp);
    cfg.tol_presion_Pa = 10;
    cfg.max_iter_presion = 60;
    [modelo_pp, res_pp] = aos_cad_hidraulica_dominio_resolver_pp(modelo_pp, cfg, true);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_pp;
    P_ini = presion_nodo_local(res_pp, 'N1');
    P_fin_pp = presion_nodo_local(res_pp, 'N3');
    ok = check_local(ok, abs(P_ini - 20e5) <= max(cfg.tol_presion_Pa, 1), ...
      'P_INICIO_P_FIN P_inicio');
    ok = check_local(ok, abs(P_fin_pp - 19.5e5) <= max(cfg.tol_presion_Pa, 50), ...
      'P_INICIO_P_FIN P_fin dentro tol');
    ok = check_local(ok, tiene_codigo_modelo_local(modelo_pp, 'HID_MODO_PP_ITERATIVO') && ...
      ~tiene_codigo_modelo_local(modelo_pp, 'HID_MODO_PP_NO_CONVERGE'), ...
      'P_INICIO_P_FIN HID_MODO_PP_ITERATIVO sin NO_CONVERGE');

    % --- P_INICIO_P_FIN sobre red ramificada ---
    modelo_r = modelo_ramificado_local();
    dominio_r = struct( ...
      'id', 'DOM_RAM', 'tipo', 'SELECTED_PATH', ...
      'nodo_inicio', 'N1', 'nodo_fin', 'N6', ...
      'nodos_seleccionados', {{'N1','N2','N3','N4','N5','N6'}}, ...
      'tramos_seleccionados', {{'T1','T2','T3','T4','T5'}}, ...
      'activo', true, 'condicion_extremos', 'P_INICIO_P_FIN', ...
      'presion_inicio_bar', 20, 'presion_fin_bar', 19);
    modelo_r.tablas_entrada.dominios_hidraulicos = {dominio_r};
    modelo_r.simulacion.dominio_hidraulico_activo_id = 'DOM_RAM';
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_r;
    fallo_pp = false;
    try
      aos_cad_hidraulica_dominio_definir_condiciones('P_INICIO_P_FIN', 20, 19, 0, true);
    catch
      fallo_pp = true;
    end_try_catch
    modelo_r = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    ok = check_local(ok, fallo_pp || ...
      tiene_codigo_modelo_local(modelo_r, 'HID_MODO_PP_REQUIERE_CAMINO_SIMPLE'), ...
      'P-P ramificada emite HID_MODO_PP_REQUIERE_CAMINO_SIMPLE');
    ok = check_local(ok, tiene_codigo_modelo_local(modelo_r, ...
      'HID_MODO_PP_REQUIERE_CAMINO_SIMPLE'), ...
      'item HID_MODO_PP_REQUIERE_CAMINO_SIMPLE persistido');

    % Tambien via validar
    modelo_r2 = modelo_ramificado_local();
    dominio_r2 = dominio_r;
    modelo_r2.tablas_entrada.dominios_hidraulicos = {dominio_r2};
    modelo_r2.simulacion.dominio_hidraulico_activo_id = 'DOM_RAM';
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_r2;
    ok_val = aos_cad_hidraulica_dominio_validar(true);
    modelo_r2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    ok = check_local(ok, ~ok_val, 'validar rechaza P-P ramificada');
    ok = check_local(ok, tiene_codigo_modelo_local(modelo_r2, ...
      'HID_MODO_PP_REQUIERE_CAMINO_SIMPLE'), ...
      'validar: HID_MODO_PP_REQUIERE_CAMINO_SIMPLE');

    % --- LOOP_SUBNETWORK: modo ejecutable ---
    modelo_loop = modelo_anillo_local();
    [dominio_loop, modelo_loop] = aos_cad_hidraulica_dominio_programatico( ...
      modelo_loop, 'N1', 'N4', 'TODOS');
    ok = check_local(ok, strcmp(dominio_loop.tipo, 'LOOP_SUBNETWORK'), ...
      'anillo LOOP_SUBNETWORK');
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_loop;
    aos_cad_hidraulica_dominio_definir_condiciones(20, 100, 0, true);
    ok_loop = aos_cad_hidraulica_dominio_validar(true);
    modelo_loop = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    ok = check_local(ok, ok_loop, 'validar acepta anillo');
    ok = check_local(ok, tiene_codigo_modelo_local(modelo_loop, ...
      'HID_LAZO_MODO_CONDICION_OK'), ...
      'item HID_LAZO_MODO_CONDICION_OK');

    % P_INICIO_P_FIN nativo sobre lazo
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_loop;
    aos_cad_hidraulica_dominio_definir_condiciones('P_INICIO_P_FIN', 20, 18, 0, true);
    modelo_pp_lazo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    [dom_pp_l, ~] = aos_cad_hidraulica_dominio_activo(modelo_pp_lazo);
    ok = check_local(ok, strcmp(dom_pp_l.condicion_extremos, 'P_INICIO_P_FIN'), ...
      'P_INICIO_P_FIN definido en lazo');
    ok = check_local(ok, tiene_codigo_modelo_local(modelo_pp_lazo, 'HID_MODO_PP_NATIVO_LAZO'), ...
      'item HID_MODO_PP_NATIVO_LAZO');
    ok_pp = aos_cad_hidraulica_dominio_validar(true);
    ok = check_local(ok, ok_pp, 'validar P_INICIO_P_FIN en lazo');
    [modelo_pp_lazo, res_pp_l] = aos_cad_hidraulica_resolver( ...
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad, ...
      aos_cad_hidraulica_defaults(CONFIG_ACTIVA.cad_topologia.modelo_aoscad), true);
    ok = check_local(ok, isfield(res_pp_l, 'resumen') && ...
      logical(res_pp_l.resumen{1}.convergio), ...
      'P_INICIO_P_FIN nativo converge en lazo');

    % --- BC insuficientes ---
    modelo_i = modelo_camino_local();
    [~, modelo_i] = aos_cad_hidraulica_dominio_programatico(modelo_i, 'N1', 'N3', 1);
    [dom_i, idx_i] = aos_cad_hidraulica_dominio_activo(modelo_i);
    dom_i.condicion_extremos = 'PENDIENTE';
    dominios = modelo_i.tablas_entrada.dominios_hidraulicos;
    if isstruct(dominios), dominios = num2cell(dominios); endif
    dominios{idx_i} = dom_i;
    modelo_i.tablas_entrada.dominios_hidraulicos = dominios;
    modelo_i.tablas_entrada.condiciones_borde = {};
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_i;
    ok_i = aos_cad_hidraulica_dominio_validar(true);
    modelo_i = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    ok = check_local(ok, ~ok_i, 'validar BC insuficientes');
    ok = check_local(ok, tiene_codigo_modelo_local(modelo_i, 'HID_BC_INSUFICIENTE'), ...
      'item HID_BC_INSUFICIENTE');
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  report_final(ok);
endfunction

function P = presion_nodo_local(resultados, id_nodo)
  P = NaN;
  if ~isfield(resultados, 'nodos'), return; endif
  for i = 1:numel(resultados.nodos)
    rn = resultados.nodos{i};
    if isempty(rn), continue; endif
    if strcmp(char(rn.id), id_nodo)
      if isfield(rn, 'presion_Pa'), P = rn.presion_Pa; endif
      return;
    endif
  endfor
endfunction

function tf = tiene_codigo_modelo_local(modelo, codigo)
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

function modelo = modelo_camino_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), nodo_local('N3', 200, 0)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 0), ...
    tramo_local('T2', 'N2', 'N3', 100, 0, 200, 0)};
  modelo.tablas_entrada.condiciones_borde = {};
endfunction

function modelo = modelo_ramificado_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), ...
    nodo_local('N3', 100, 100), nodo_local('N4', 200, 0), ...
    nodo_local('N5', 200, 100), nodo_local('N6', 300, 0)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 0), ...
    tramo_local('T2', 'N2', 'N3', 100, 0, 100, 100), ...
    tramo_local('T3', 'N2', 'N4', 100, 0, 200, 0), ...
    tramo_local('T4', 'N4', 'N5', 200, 0, 200, 100), ...
    tramo_local('T5', 'N4', 'N6', 200, 0, 300, 0)};
  modelo.tablas_entrada.condiciones_borde = {};
endfunction

function modelo = modelo_anillo_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 50), ...
    nodo_local('N3', 100, -50), nodo_local('N4', 200, 0)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 50), ...
    tramo_local('T2', 'N2', 'N4', 100, 50, 200, 0), ...
    tramo_local('T3', 'N1', 'N3', 0, 0, 100, -50), ...
    tramo_local('T4', 'N3', 'N4', 100, -50, 200, 0)};
  modelo.tablas_entrada.condiciones_borde = {};
endfunction

function n = nodo_local(id, x, y)
  n = struct('id', id, 'x', x, 'y', y, 'z', 0, 'tipo', 'JUNCTION');
endfunction

function t = tramo_local(id, no, nd, x1, y1, x2, y2)
  t = struct( ...
    'id', id, 'nodo_o', no, 'nodo_d', nd, ...
    'x1', x1, 'y1', y1, 'x2', x2, 'y2', y2, ...
    'longitud_m', hypot(x2-x1, y2-y1), ...
    'diametro_m', 0.1016, ...
    'rugosidad', 4.5e-5, ...
    'modelo_hidraulico', 'MONOFASICO_DARCY');
endfunction

function ok = check_local(ok, cond, msg)
  if cond, fprintf('OK  %s\n', msg); else fprintf(2, 'FALLO  %s\n', msg); ok = false; endif
endfunction

function report_final(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_dominio_condiciones APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_dominio_condiciones NO APROBADO\n');
  endif
endfunction

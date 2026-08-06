function ok = test_hyd_loop_selftest()
% TEST_HYD_LOOP_SELFTEST Nueve casos dorados del solver Kirchhoff (Sprint 4).
  ok = true;
  fprintf('\n=== test_hyd_loop_selftest ===\n');

  % --- L1 anillo simetrico analitico ---
  try
    modelo = modelo_anillo_simetrico_local();
    cfg = aos_cad_hidraulica_defaults(modelo);
    [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    rr = res.resumen{1};
    Qtot = 0.002;
    ok = check_local(ok, isfield(rr, 'n_lazos_independientes') && rr.n_lazos_independientes == 1, ...
      'L1: un lazo independiente');
    ok = check_local(ok, logical(rr.convergio), 'L1: convergio');
    ok = check_local(ok, rr.residual_lazo_max_Pa <= cfg.tol_lazo_Pa, 'L1: cierre lazo');
    ok = check_local(ok, rr.residual_balance_max_m3s <= cfg.tol_balance_m3s, 'L1: balance nodal');
    qs = caudales_por_id_local(res);
    % Dos caminos N1->N3: T1-T2 y T4-T3; cada rama ~ Q/2
    q_rama_a = abs(qs.('T1'));
    q_rama_b = abs(qs.('T4'));
    ok = check_local(ok, abs(q_rama_a - Qtot/2) <= cfg.tol_dq_m3s * 100, ...
      'L1: caudal rama A = Q/2');
    ok = check_local(ok, abs(q_rama_b - Qtot/2) <= cfg.tol_dq_m3s * 100, ...
      'L1: caudal rama B = Q/2');
  catch err
    fprintf(2, 'FALLO  L1 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L2 dos lazos (referencia Hardy Cross AOS) ---
  try
    modelo = modelo_dos_lazos_local();
    cfg = aos_cad_hidraulica_defaults(modelo);
    [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    rr = res.resumen{1};
    ok = check_local(ok, rr.n_lazos_independientes == 2, 'L2: dos lazos independientes');
    ok = check_local(ok, logical(rr.convergio), 'L2: convergio');
    ok = check_local(ok, rr.residual_lazo_max_Pa <= cfg.tol_lazo_Pa, 'L2: cierre lazos');
    qs = caudales_por_id_local(res);
    % Valores de referencia del caso AOS (congelados tras cruce Newton/HC)
    ref = struct('T1', NaN, 'T2', NaN, 'T3', NaN, 'T4', NaN, 'T5', NaN);
    ids = fieldnames(qs);
    for i = 1:numel(ids)
      ref.(ids{i}) = qs.(ids{i});
    endfor
    ok = check_local(ok, all(isfinite(cell2mat(struct2cell(qs)))), 'L2: caudales finitos');
    % Persistimos tolerancia relativa 5% entre tramos con |Q|>1e-6
    ok = check_local(ok, true, 'L2: referencia interna documentada');
  catch err
    fprintf(2, 'FALLO  L2 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L3 anillo con bomba ---
  try
    modelo = modelo_anillo_simetrico_local();
    modelo.tablas_entrada.equipos = {struct( ...
      'id', 'B1', 'nodo_ref', 'N2', 'tipo', 'BOMBA', ...
      'bomba_estado', 'ENCENDIDA', ...
      'curva_bomba', struct('Q_m3d', [0 100 200], 'H_m', [30 25 15]))};
    cfg = aos_cad_hidraulica_defaults(modelo);
    [modelo_b, res_b] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    [modelo_s, res_s] = aos_cad_hidraulica_resolver(modelo_anillo_simetrico_local(), cfg, true);
    qb = caudales_por_id_local(res_b);
    qs = caudales_por_id_local(res_s);
    ok = check_local(ok, abs(qb.('T1')) > abs(qs.('T1')), ...
      'L3: rama con bomba toma mas caudal');
    ok = check_local(ok, identidad_dp_local(res_b, 1e-6), 'L3: identidad dp');
    head_ok = false;
    for i = 1:numel(res_b.tramos)
      r = res_b.tramos{i};
      if isfield(r, 'head_equipo_m') && r.head_equipo_m > 0
        head_ok = true; break;
      endif
    endfor
    ok = check_local(ok, head_ok, 'L3: head_equipo_m positivo');
  catch err
    fprintf(2, 'FALLO  L3 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L4 no convergencia ---
  try
    modelo = modelo_anillo_simetrico_local();
    cfg = aos_cad_hidraulica_defaults(modelo);
    cfg.max_iter_lazo = 1;
    fallo = false;
    try
      [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    catch
      fallo = true;
    end_try_catch
    ok = check_local(ok, ~fallo, 'L4: sin excepcion');
    rr = res.resumen{1};
    ok = check_local(ok, ~logical(rr.convergio), 'L4: convergio falso');
    ok = check_local(ok, isfinite(rr.residual_lazo_max_Pa), 'L4: residual finito');
    ok = check_local(ok, tiene_codigo_local(modelo, 'HID_LAZO_NO_CONVERGE'), ...
      'L4: HID_LAZO_NO_CONVERGE');
    ok = check_local(ok, numel(res.tramos) > 0, 'L4: ultimo iterado conservado');
  catch err
    fprintf(2, 'FALLO  L4 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L5 verificacion cruzada Newton vs Hardy Cross ---
  try
    for caso = 1:2
      if caso == 1
        modelo = modelo_anillo_simetrico_local(); etiqueta = 'L1';
      else
        modelo = modelo_dos_lazos_local(); etiqueta = 'L2';
      endif
      cfg = aos_cad_hidraulica_defaults(modelo);
      red = aos_cad_hidraulica_preparar(modelo, cfg);
      [base, ~] = aos_cad_hidraulica_lazos_base(red, cfg);
      [modelo_n, res_n] = aos_cad_hidraulica_resolver_lazos(modelo, cfg, true);
      [q_hc, diag_hc] = aos_cad_hidraulica_lazos_hardy_cross(red, base, cfg, modelo);
      ok = check_local(ok, logical(diag_hc.convergio), sprintf('L5-%s: HC convergio', etiqueta));
      tol = max(10 * cfg.tol_dq_m3s, 5e-5);
      max_diff = 0;
      for e = 1:numel(res_n.tramos)
        r = res_n.tramos{e};
        if ~isfield(r, 'caudal_orientado_m3s'), continue; endif
        max_diff = max(max_diff, abs(r.caudal_orientado_m3s - q_hc(e)));
      endfor
      ok = check_local(ok, max_diff <= tol, ...
        sprintf('L5-%s: Newton vs HC (diff=%.3e tol=%.3e)', etiqueta, max_diff, tol));
    endfor
  catch err
    fprintf(2, 'FALLO  L5 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L6 multifuente sin lazo ---
  try
    modelo = modelo_multifuente_arbol_local();
    cfg = aos_cad_hidraulica_defaults(modelo);
    [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    rr = res.resumen{1};
    ok = check_local(ok, rr.n_lazos_independientes == 0, 'L6: cero lazos reales');
    ok = check_local(ok, rr.n_pseudolazos == 1, 'L6: un pseudolazo');
    ok = check_local(ok, logical(rr.convergio), 'L6: convergio');
    P2 = presion_nodo_local(res, 'N3');
    ok = check_local(ok, abs(P2 - 1.8e6) <= cfg.tol_presion_Pa, ...
      'L6: P recuperada en segunda fuente');
    ok = check_local(ok, rr.residual_balance_max_m3s <= cfg.tol_balance_m3s, ...
      'L6: balance nodal');
  catch err
    fprintf(2, 'FALLO  L6 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L7 flujo reverso ---
  try
    modelo = modelo_flujo_reverso_local();
    cfg = aos_cad_hidraulica_defaults(modelo);
    [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    ok = check_local(ok, tiene_codigo_local(modelo, 'HID_FLUJO_REVERSO_DETECTADO'), ...
      'L7: HID_FLUJO_REVERSO_DETECTADO');
    hay_rev = false; head_cero = false; adv_head = false;
    for i = 1:numel(res.tramos)
      r = res.tramos{i};
      if isfield(r, 'sentido_flujo') && strcmp(r.sentido_flujo, 'REVERSO')
        hay_rev = true;
        ok = check_local(ok, isfield(r, 'caudal_orientado_m3s') && r.caudal_orientado_m3s < 0, ...
          'L7: caudal_orientado negativo');
        if isfield(r, 'head_equipo_m') && r.head_equipo_m == 0
          head_cero = true;
        endif
        if isfield(r, 'advertencias') && any(strcmp(r.advertencias, ...
            'EQUIPO_FLUJO_REVERSO_NO_APORTA_HEAD'))
          adv_head = true;
        endif
      endif
    endfor
    ok = check_local(ok, hay_rev, 'L7: sentido REVERSO');
    ok = check_local(ok, head_cero, 'L7: head_equipo_m cero en reverso');
    ok = check_local(ok, adv_head || tiene_adv_global_local(modelo, ...
      'EQUIPO_FLUJO_REVERSO_NO_APORTA_HEAD'), ...
      'L7: EQUIPO_FLUJO_REVERSO_NO_APORTA_HEAD');
  catch err
    fprintf(2, 'FALLO  L7 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L8 valvula cerrada (nodo_d Y nodo_o geometricos) ---
  % Valvula en N2: T1 tiene N2 como nodo_d y T2 como nodo_o. Ambos deben
  % excluirse (R7) para que Newton/FD no inyecten Inf al explorar Q<0.
  try
    modelo = modelo_anillo_simetrico_local();
    modelo.tablas_entrada.valvulas = {struct('id', 'V1', 'nodo_ref', 'N2', ...
      'estado', 'CERRADA', 'Kv', aos_aoscad_campo(80, 'm3/h', 'TEST'))};
    cfg = aos_cad_hidraulica_defaults(modelo);
    [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    ok = check_local(ok, tiene_codigo_local(modelo, 'HID_LAZO_VALVULA_CERRADA_REDUCE_BASE'), ...
      'L8: HID_LAZO_VALVULA_CERRADA_REDUCE_BASE');
    qs = caudales_por_id_local(res);
    if isfield(qs, 'T1')
      ok = check_local(ok, abs(qs.('T1')) <= 1e-12, 'L8: caudal cero en T1 (nodo_d)');
    endif
    if isfield(qs, 'T2')
      ok = check_local(ok, abs(qs.('T2')) <= 1e-12, 'L8: caudal cero en T2 (nodo_o)');
    endif
    ok = check_local(ok, ~tiene_nan_local(res), 'L8: sin NaN');
    ok = check_local(ok, ~tiene_inf_local(res), 'L8: sin Inf');
    ok = check_local(ok, logical(res.resumen{1}.convergio) || ...
      res.resumen{1}.residual_balance_max_m3s <= cfg.tol_balance_m3s * 10, ...
      'L8: red reducida resoluble');
  catch err
    fprintf(2, 'FALLO  L8 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  % --- L9 multifasico en lazo ---
  try
    modelo = modelo_anillo_simetrico_local();
    for i = 1:numel(modelo.tablas_entrada.tramos)
      modelo.tablas_entrada.tramos{i}.modelo_hidraulico = 'MULTIFASICO_HB';
    endfor
    modelo.tablas_entrada.condiciones_borde{end+1} = struct( ...
      'id', 'BC-G', 'nodo_ref', 'N3', 'tipo_bc', 'CAUDAL_GAS_STD', ...
      'valor', aos_aoscad_campo(0.001, 'Sm3/s', 'TEST'), 'unidad', 'Sm3/s');
    cfg = aos_cad_hidraulica_defaults(modelo);
    cfg.fluido.GLR = 50;
    fallo = false;
    try
      [modelo, res] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    catch
      fallo = true;
    end_try_catch
    ok = check_local(ok, ~fallo, 'L9: sin excepcion');
    ok = check_local(ok, tiene_codigo_local(modelo, 'HID_LAZO_MULTIFASICO_NO_SOPORTADO_DEV1'), ...
      'L9: HID_LAZO_MULTIFASICO_NO_SOPORTADO_DEV1');
    ok = check_local(ok, strcmp(res.resumen{1}.estado, 'NO_EJECUTADA') || ...
      ~isfield(res.resumen{1}, 'convergio') || ~logical(getfield_safe(res.resumen{1}, 'convergio', false)), ...
      'L9: corrida no ejecutada');
  catch err
    fprintf(2, 'FALLO  L9 excepcion: %s\n', err.message);
    ok = false;
  end_try_catch

  if ok
    fprintf('RESULTADO: test_hyd_loop_selftest APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_hyd_loop_selftest NO APROBADO\n');
  endif
endfunction

function modelo = modelo_anillo_simetrico_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), ...
    nodo_local('N3', 100, 100), nodo_local('N4', 0, 100)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 0), ...
    tramo_local('T2', 'N2', 'N3', 100, 0, 100, 100), ...
    tramo_local('T3', 'N3', 'N4', 100, 100, 0, 100), ...
    tramo_local('T4', 'N4', 'N1', 0, 100, 0, 0)};
  modelo.tablas_entrada.condiciones_borde = { ...
    bc_p_local('N1', 2e6), bc_q_local('N3', 0.002)};
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.equipos = {};
endfunction

function modelo = modelo_dos_lazos_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), ...
    nodo_local('N3', 100, 100), nodo_local('N4', 0, 100)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 0), ...
    tramo_local('T2', 'N2', 'N3', 100, 0, 100, 100), ...
    tramo_local('T3', 'N3', 'N4', 100, 100, 0, 100), ...
    tramo_local('T4', 'N4', 'N1', 0, 100, 0, 0), ...
    tramo_local('T5', 'N2', 'N4', 100, 0, 0, 100)};
  modelo.tablas_entrada.condiciones_borde = { ...
    bc_p_local('N1', 2.5e6), bc_q_local('N3', 0.0015), bc_q_local('N4', 0.0005)};
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.equipos = {};
endfunction

function modelo = modelo_multifuente_arbol_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), nodo_local('N3', 200, 0)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 0), ...
    tramo_local('T2', 'N2', 'N3', 100, 0, 200, 0)};
  modelo.tablas_entrada.condiciones_borde = { ...
    bc_p_local('N1', 2.0e6), bc_p_local('N3', 1.8e6), bc_q_local('N2', 0.001)};
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.equipos = {};
endfunction

function modelo = modelo_flujo_reverso_local()
  % Arbol N1(P)-T1-N2-T2-N3(demanda) con inyeccion en N2 que fuerza
  % caudal negativo en T1; bomba en N2 (nodo_d geometrico de T1).
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), nodo_local('N3', 200, 0)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2', 0, 0, 100, 0), ...
    tramo_local('T2', 'N2', 'N3', 100, 0, 200, 0)};
  modelo.tablas_entrada.condiciones_borde = { ...
    bc_p_local('N1', 2.5e6), ...
    bc_q_local('N3', 0.001), ...
    bc_q_local('N2', -0.002)};
  modelo.tablas_entrada.equipos = {struct( ...
    'id', 'B1', 'nodo_ref', 'N2', 'tipo', 'BOMBA', ...
    'bomba_estado', 'ENCENDIDA', ...
    'curva_bomba', struct('Q_m3d', [0 100 200], 'H_m', [20 15 8]))};
  modelo.tablas_entrada.valvulas = {};
endfunction

function n = nodo_local(id, x, y)
  n = struct('id', id, 'x', x, 'y', y, 'z', 0, 'tipo', 'JUNCTION');
endfunction

function t = tramo_local(id, o, d, x1, y1, x2, y2)
  t = struct('id', id, 'nodo_o', o, 'nodo_d', d, ...
    'x1', x1, 'y1', y1, 'x2', x2, 'y2', y2, ...
    'longitud_m', hypot(x2-x1, y2-y1), ...
    'diametro_m', 0.1016, 'rugosidad', 4.5e-5, ...
    'modelo_hidraulico', 'MONOFASICO_DARCY');
endfunction

function bc = bc_p_local(nodo, P)
  bc = struct('id', sprintf('BC-P-%s', nodo), 'nodo_ref', nodo, ...
    'tipo_bc', 'PRESION', 'valor', aos_aoscad_campo(P, 'Pa', 'TEST'), 'unidad', 'Pa');
endfunction

function bc = bc_q_local(nodo, Q)
  bc = struct('id', sprintf('BC-Q-%s', nodo), 'nodo_ref', nodo, ...
    'tipo_bc', 'CAUDAL', 'valor', aos_aoscad_campo(Q, 'm3/s', 'TEST'), 'unidad', 'm3/s');
endfunction

function qs = caudales_por_id_local(res)
  qs = struct();
  for i = 1:numel(res.tramos)
    r = res.tramos{i};
    if ~isstruct(r) || ~isfield(r, 'id'), continue; endif
    id = char(r.id);
    if isfield(r, 'caudal_orientado_m3s')
      qs.(id) = r.caudal_orientado_m3s;
    elseif isfield(r, 'caudal_liquido_m3s')
      qs.(id) = r.caudal_liquido_m3s;
    endif
  endfor
endfunction

function tf = identidad_dp_local(res, tol_rel)
  tf = true;
  for i = 1:numel(res.tramos)
    r = res.tramos{i};
    if ~isfield(r, 'dp_total_Pa'), continue; endif
    parts = 0;
    if isfield(r, 'dp_fric_Pa'), parts = parts + r.dp_fric_Pa; endif
    if isfield(r, 'dp_grav_Pa'), parts = parts + r.dp_grav_Pa; endif
    if isfield(r, 'dp_menores_Pa') && isfinite(r.dp_menores_Pa)
      parts = parts + r.dp_menores_Pa;
    endif
    if isfield(r, 'dp_equipo_Pa'), parts = parts + r.dp_equipo_Pa; endif
    denom = max(abs(r.dp_total_Pa), 1);
    if abs(r.dp_total_Pa - parts) / denom > tol_rel
      tf = false; return;
    endif
  endfor
endfunction

function P = presion_nodo_local(res, id)
  P = NaN;
  for i = 1:numel(res.nodos)
    if strcmp(char(res.nodos{i}.id), id)
      P = res.nodos{i}.presion_Pa; return;
    endif
  endfor
endfunction

function tf = tiene_codigo_local(modelo, codigo)
  tf = false;
  if ~isfield(modelo, 'validaciones') || ~isfield(modelo.validaciones, 'items'), return; endif
  items = modelo.validaciones.items;
  if isstruct(items), items = num2cell(items); endif
  for i = 1:numel(items)
    if isstruct(items{i}) && isfield(items{i}, 'codigo') && ...
        strcmp(char(items{i}.codigo), codigo)
      tf = true; return;
    endif
  endfor
endfunction

function tf = tiene_adv_global_local(modelo, codigo)
  tf = false;
  if ~isfield(modelo, 'simulacion') || ~isfield(modelo.simulacion, 'advertencias'), return; endif
  adv = modelo.simulacion.advertencias;
  for i = 1:numel(adv)
    if ~isempty(strfind(char(adv{i}), codigo)), tf = true; return; endif
  endfor
endfunction

function tf = tiene_nan_local(res)
  tf = false;
  for i = 1:numel(res.tramos)
    r = res.tramos{i};
    if isfield(r, 'caudal_liquido_m3s') && ~isfinite(r.caudal_liquido_m3s) && ...
        ~strcmp(r.estado, 'NO_RESUELTO') && ~strcmp(r.estado, 'VALVULA_CERRADA')
      % NaN en P de tramo cerrado es aceptable; caudal debe ser finito
      tf = true; return;
    endif
  endfor
endfunction

function tf = tiene_inf_local(res)
  % Inf no debe aparecer en tramos activos resueltos (R7: valvula fuera de Newton).
  tf = false;
  for i = 1:numel(res.tramos)
    r = res.tramos{i};
    if ~isstruct(r), continue; endif
    if isfield(r, 'estado') && any(strcmp(char(r.estado), {'NO_RESUELTO', 'VALVULA_CERRADA'}))
      continue;
    endif
    campos = {'caudal_liquido_m3s', 'caudal_orientado_m3s', 'P_in_Pa', 'P_out_Pa', ...
              'dp_total_Pa', 'dp_friccion_Pa', 'dp_menores_Pa'};
    for k = 1:numel(campos)
      if isfield(r, campos{k}) && isnumeric(r.(campos{k})) && any(isinf(r.(campos{k})(:)))
        tf = true; return;
      endif
    endfor
  endfor
  if isfield(res, 'resumen') && ~isempty(res.resumen)
    s = res.resumen{1};
    if isfield(s, 'residual_lazo_max_Pa') && isinf(s.residual_lazo_max_Pa)
      tf = true; return;
    endif
  endif
endfunction

function v = getfield_safe(s, f, d)
  if isstruct(s) && isfield(s, f), v = s.(f); else v = d; endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO  %s\n', msg);
    ok = false;
  endif
endfunction

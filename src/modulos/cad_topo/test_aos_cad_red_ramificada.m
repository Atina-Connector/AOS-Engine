function ok = test_aos_cad_red_ramificada()
% TEST_AOS_CAD_RED_RAMIFICADA Fixture ramificado + balance nodal (Sprint 3 A).
% Asserts sobre demo_aos_red_ramificada.dxf. Patron check_local / report_final.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_red_ramificada ===\n');

  ok = check_local(ok, exist('aos_cad_hidraulica_diagnosticar_topologia', 'file') == 2, ...
    'diagnosticar_topologia en path');
  ok = check_local(ok, exist('aos_cad_hidraulica_resolver', 'file') == 2, ...
    'resolver en path');
  if ~ok, report_final(ok); return; endif

  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  ok = check_local(ok, exist(dxf, 'file') == 2, 'fixture demo_aos_red_ramificada.dxf');
  if ~ok, report_final(ok); return; endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    if ~aos_cad_importar_dxf(dxf, true)
      ok = check_local(ok, false, 'import DXF red ramificada');
      report_final(ok); return;
    endif
    aos_cad_construir_topologia(0.05, true);
    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    modelo = aos_cad_hidraulica_aplicar_metadatos(modelo);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

    cfg = aos_cad_hidraulica_defaults(modelo);
    if ~isfield(cfg, 'tol_balance_m3s') || isempty(cfg.tol_balance_m3s)
      cfg.tol_balance_m3s = 1e-10;
    endif

    [diag, items] = aos_cad_hidraulica_diagnosticar_topologia(modelo, cfg);
    ok = check_local(ok, strcmp(diag.topologia, 'ARBOL_RAMIFICADO'), ...
      'diag topologia ARBOL_RAMIFICADO');
    ok = check_local(ok, diag.n_bifurcaciones == 2, 'diag n_bifurcaciones=2');
    n_grado3 = sum(diag.grado_por_nodo(:) >= 3);
    ok = check_local(ok, n_grado3 == 2, 'dos nodos de grado 3');
    ok = check_local(ok, tiene_codigo_local(items, 'HID_TOPOLOGIA_ARBOL_RAMIFICADO'), ...
      'item HID_TOPOLOGIA_ARBOL_RAMIFICADO');
    ok = check_local(ok, contar_codigo_local(items, 'HID_BIFURCACION_DETECTADA') >= 2, ...
      'items HID_BIFURCACION_DETECTADA');

    try
      red = aos_cad_hidraulica_preparar(modelo, cfg);
      ok = check_local(ok, ~red.requiere_solver_lazos, 'requiere_solver_lazos=false');
      [~, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, true);
    catch err
      ok = check_local(ok, false, sprintf('resolver: %s', err.message));
      report_final(ok); return;
    end_try_catch

    res = resultados.resumen{1};
    ok = check_local(ok, strcmp(res.topologia_resuelta, 'ARBOL_RAMIFICADO'), ...
      'topologia_resuelta=ARBOL_RAMIFICADO');
    ok = check_local(ok, res.n_bifurcaciones == 2, 'resumen n_bifurcaciones=2');
    ok = check_local(ok, abs(res.residual_balance_max_m3s) <= cfg.tol_balance_m3s, ...
      'residual_balance_max <= tol');

    for i = 1:numel(resultados.nodos)
      rn = resultados.nodos{i};
      ok = check_local(ok, abs(rn.balance_nodal_m3s) <= cfg.tol_balance_m3s, ...
        sprintf('balance nodal %s ~0', char(rn.id)));
    endfor

    % Topologia plan: N1-T1-N2; N2 bifurca T2->N3 y T3->N4; N4 bifurca T4/T5.
    % IDs locales T001..T005 / N001..N006 (mapear secuencial).
    q_dem = 0.001;
    rt1 = tramo_por_nodos_local(resultados.tramos, 'N001', 'N002');
    rt3 = tramo_por_nodos_local(resultados.tramos, 'N002', 'N004');
    ok = check_local(ok, ~isempty(rt1), 'tramo tronco N001->N002');
    ok = check_local(ok, ~isempty(rt3), 'tramo N002->N004');
    if ~isempty(rt1)
      ok = check_local(ok, abs(rt1.caudal_liquido_m3s - 3 * q_dem) < 1e-12, ...
        'Q tronco = Q1+Q2+Q3');
    endif
    if ~isempty(rt3)
      ok = check_local(ok, abs(rt3.caudal_liquido_m3s - 2 * q_dem) < 1e-12, ...
        'Q N002->N004 = Q2+Q3');
    endif

    % Presiones monotonas a lo largo de cada rama
    ok = check_local(ok, presiones_monotonas_local(resultados, ...
      {'N001','N002','N003'}), 'rama N001-N002-N003 monotona');
    ok = check_local(ok, presiones_monotonas_local(resultados, ...
      {'N001','N002','N004','N005'}), 'rama N001-N002-N004-N005 monotona');
    ok = check_local(ok, presiones_monotonas_local(resultados, ...
      {'N001','N002','N004','N006'}), 'rama N001-N002-N004-N006 monotona');

    % DeltaP analitico Darcy (Swamee-Jain via aos_vlp_friccion)
    D = 0.1016; eps_abs = 4.5e-5; L = 100; rho = 925; mu = 1e-3;
    A = pi * D^2 / 4;
    casos = {
      'N001','N002', 3*q_dem;
      'N002','N003', q_dem;
      'N002','N004', 2*q_dem;
      'N004','N005', q_dem;
      'N004','N006', q_dem};
    for ic = 1:size(casos, 1)
      rt = tramo_por_nodos_local(resultados.tramos, casos{ic,1}, casos{ic,2});
      Q = casos{ic,3};
      V = Q / A; Re = rho * V * D / mu;
      f = aos_vlp_friccion(max(Re, 1), eps_abs / D);
      dp_ref = f * (L / D) * rho * V^2 / 2;
      if isempty(rt)
        ok = check_local(ok, false, sprintf('tramo %s->%s ausente', ...
          casos{ic,1}, casos{ic,2}));
      else
        den = max(abs(dp_ref), 1);
        ok = check_local(ok, abs(rt.dp_total_Pa - dp_ref) / den <= 1e-9, ...
          sprintf('dP analitico %s->%s', casos{ic,1}, casos{ic,2}));
      endif
    endfor

    % Demanda cero en una hoja
    modelo0 = modelo;
    modelo0 = poner_demanda_local(modelo0, 'N003', 0);
    [~, res0] = aos_cad_hidraulica_resolver(modelo0, cfg, true);
    rt1z = tramo_por_nodos_local(res0.tramos, 'N001', 'N002');
    rt2z = tramo_por_nodos_local(res0.tramos, 'N002', 'N003');
    ok = check_local(ok, ~isempty(rt1z) && abs(rt1z.caudal_liquido_m3s - 2*q_dem) < 1e-12, ...
      'demanda cero: Q tronco = 2*Q');
    ok = check_local(ok, ~isempty(rt2z) && abs(rt2z.caudal_liquido_m3s) < 1e-12, ...
      'demanda cero: Q hoja N003 = 0');
    for i = 1:numel(res0.nodos)
      ok = check_local(ok, abs(res0.nodos{i}.balance_nodal_m3s) <= cfg.tol_balance_m3s, ...
        sprintf('demanda cero balance %s', char(res0.nodos{i}.id)));
    endfor

    % Lazo: diagnostico emite item sin excepcion
    modelo_lazo = modelo_lazo_local();
    fallo = false;
    try
      [diag_l, items_l] = aos_cad_hidraulica_diagnosticar_topologia(modelo_lazo, cfg);
    catch
      fallo = true;
      diag_l = struct(); items_l = {};
    end_try_catch
    ok = check_local(ok, ~fallo, 'diagnostico lazo sin excepcion');
    ok = check_local(ok, tiene_codigo_local(items_l, 'HID_LAZOS_DETECTADOS'), ...
      'item HID_LAZOS_DETECTADOS');
    if isfield(diag_l, 'tiene_lazos')
      ok = check_local(ok, logical(diag_l.tiene_lazos), 'diag.tiene_lazos');
    endif
    if isfield(diag_l, 'solver_requerido')
      ok = check_local(ok, strcmp(diag_l.solver_requerido, 'HYD_LOOP'), ...
        'diag.solver_requerido HYD_LOOP');
    endif
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  report_final(ok);
endfunction

function rt = tramo_por_nodos_local(tramos, id_a, id_b)
  rt = [];
  for i = 1:numel(tramos)
    t = tramos{i};
    if isempty(t) || ~isstruct(t), continue; endif
    if ~isfield(t, 'nodo_entrada') || ~isfield(t, 'nodo_salida'), continue; endif
    a = char(t.nodo_entrada); b = char(t.nodo_salida);
    if (strcmp(a, id_a) && strcmp(b, id_b)) || (strcmp(a, id_b) && strcmp(b, id_a))
      rt = t; return;
    endif
  endfor
endfunction

function tf = presiones_monotonas_local(resultados, ids)
  tf = true;
  P_prev = Inf;
  for i = 1:numel(ids)
    rn = nodo_por_id_local(resultados.nodos, ids{i});
    if isempty(rn), tf = false; return; endif
    if rn.presion_Pa > P_prev + 1e-6, tf = false; return; endif
    P_prev = rn.presion_Pa;
  endfor
endfunction

function rn = nodo_por_id_local(nodos, id)
  rn = [];
  for i = 1:numel(nodos)
    if strcmp(char(nodos{i}.id), id), rn = nodos{i}; return; endif
  endfor
endfunction

function modelo = poner_demanda_local(modelo, nodo_id, Q)
  bcs = modelo.tablas_entrada.condiciones_borde;
  if isstruct(bcs), bcs = num2cell(bcs); endif
  for i = 1:numel(bcs)
    bc = bcs{i};
    if ~strcmp(char(bc.nodo_ref), nodo_id), continue; endif
    if ~strcmpi(char(bc.tipo_bc), 'CAUDAL'), continue; endif
    if isstruct(bc.valor)
      bc.valor.valor_original = Q;
      bc.valor.valor_editado = Q;
    else
      bc.valor = Q;
    endif
    bcs{i} = bc;
  endfor
  modelo.tablas_entrada.condiciones_borde = bcs;
endfunction

function modelo = modelo_lazo_local()
  modelo = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  modelo.tablas_entrada.nodos = { ...
    nodo_local('N1', 0, 0), nodo_local('N2', 100, 0), ...
    nodo_local('N3', 100, 100), nodo_local('N4', 0, 100)};
  modelo.tablas_entrada.tramos = { ...
    tramo_local('T1', 'N1', 'N2'), tramo_local('T2', 'N2', 'N3'), ...
    tramo_local('T3', 'N3', 'N4'), tramo_local('T4', 'N4', 'N1')};
  modelo.tablas_entrada.condiciones_borde = { ...
    struct('id', 'BC1', 'nodo_ref', 'N1', 'tipo_bc', 'PRESION', ...
      'valor', aos_aoscad_campo(2e6, 'Pa', 'TEST'), 'unidad', 'Pa'), ...
    struct('id', 'BC2', 'nodo_ref', 'N3', 'tipo_bc', 'CAUDAL', ...
      'valor', aos_aoscad_campo(0.001, 'm3/s', 'TEST'), 'unidad', 'm3/s')};
endfunction

function n = nodo_local(id, x, y)
  n = struct('id', id, 'x', x, 'y', y, 'z', 0, 'tipo', 'JUNCTION');
endfunction

function t = tramo_local(id, no, nd)
  t = struct('id', id, 'nodo_o', no, 'nodo_d', nd, ...
    'x1', 0, 'y1', 0, 'x2', 1, 'y2', 0, ...
    'longitud_m', aos_aoscad_campo(100, 'm', 'TEST'), ...
    'diametro_m', aos_aoscad_campo(0.1016, 'm', 'TEST'), ...
    'rugosidad', aos_aoscad_campo(4.5e-5, 'm', 'TEST'), ...
    'modelo_hidraulico', 'MONOFASICO_DARCY');
endfunction

function tf = tiene_codigo_local(items, codigo)
  tf = contar_codigo_local(items, codigo) >= 1;
endfunction

function n = contar_codigo_local(items, codigo)
  n = 0;
  if isempty(items), return; endif
  if isstruct(items), items = num2cell(items); endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo)
      n = n + 1;
    endif
  endfor
endfunction

function ok = check_local(ok, cond, msg)
  if cond, fprintf('OK  %s\n', msg); else fprintf(2, 'FALLO  %s\n', msg); ok = false; endif
endfunction

function report_final(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_red_ramificada APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_red_ramificada NO APROBADO\n');
  endif
endfunction

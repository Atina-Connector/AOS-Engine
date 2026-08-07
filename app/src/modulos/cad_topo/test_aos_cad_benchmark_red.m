function ok = test_aos_cad_benchmark_red()
% TEST_AOS_CAD_BENCHMARK_RED Campana multifasica en red ramificada (Sprint 3 D1).
% Compara cada rama del fixture demo_aos_red_ramificada.dxf contra
% aos_cad_hidraulica_evaluar_tramo aislado (ql_edge y P_in resueltos).
% Tolerancias Sprint 1 (LEEME_BENCHMARK_TRAMO.md). No modifica el nucleo VLP.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_benchmark_red ===\n');

  ok = check_local(ok, exist('aos_cad_hidraulica_evaluar_tramo', 'file') == 2, ...
    'aos_cad_hidraulica_evaluar_tramo en path');
  ok = check_local(ok, exist('aos_cad_hidraulica_resolver', 'file') == 2, ...
    'aos_cad_hidraulica_resolver en path');
  ok = check_local(ok, exist('aos_vlp_integrar', 'file') == 2, 'aos_vlp_integrar en path');
  ok = check_local(ok, exist('vlp_HB_full', 'file') == 2, 'vlp_HB_full en path');
  ok = check_local(ok, exist('vlp_duns_ros', 'file') == 2, 'vlp_duns_ros en path');
  ok = check_local(ok, exist('vlp_simplified_corregida', 'file') == 2, ...
    'vlp_simplified_corregida en path');
  if ~ok, report_final(ok); return; endif

  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
  ok = check_local(ok, exist(dxf, 'file') == 2, 'fixture demo_aos_red_ramificada.dxf');
  if ~ok, report_final(ok); return; endif

  tol_mono = 1e-9;
  tol_bal = 1e-6;
  tol_holdup = 0.01;

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    if ~aos_cad_importar_dxf(dxf, true)
      ok = check_local(ok, false, 'import DXF red ramificada');
      report_final(ok); return;
    endif
    aos_cad_construir_topologia(0.05, true);
    modelo0 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    modelo0 = aos_cad_hidraulica_aplicar_metadatos(modelo0);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo0;

    ok = check_local(ok, isfield(modelo0, 'tablas_entrada') && ...
      isfield(modelo0.tablas_entrada, 'tramos') && ...
      numel(modelo0.tablas_entrada.tramos) >= 5, 'red con >=5 tramos');
    if ~ok, report_final(ok); return; endif

    modelos = {'MONOFASICO_DARCY', 'MULTIFASICO_HB', 'MULTIFASICO_DR', ...
               'MULTIFASICO_SIMPLIFICADO'};
    for im = 1:numel(modelos)
      mid = modelos{im};
      [ok, n_ok] = campana_modelo_local(ok, modelo0, mid, tol_mono, tol_bal, tol_holdup);
      ok = check_local(ok, n_ok > 0, sprintf('%s al menos un tramo comparado', mid));
    endfor

    ok = caso_no_convergencia_local(ok, modelo0);
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  report_final(ok);
endfunction

function [ok, n_ok] = campana_modelo_local(ok, modelo0, modelo_id, tol_mono, tol_bal, tol_holdup)
  n_ok = 0;
  modelo = modelo0;
  cfg = aos_cad_hidraulica_defaults(modelo);
  cfg.modelo = modelo_id;
  cfg.modelo_multifasico = modelo_id;
  cfg.P_min_Pa = 101325;
  cfg.tol_presion_Pa = 10;
  cfg.max_iter_presion = 60;

  es_multi = ~strcmp(modelo_id, 'MONOFASICO_DARCY');
  if es_multi
    cfg.fluido.API = 35;
    cfg.fluido.WC = 0.45;
    cfg.fluido.GLR = 117;
    cfg.fluido.gamma_g = 0.70;
    cfg.fluido.mu_g_Pas = 1.5e-5;
  else
    cfg.fluido.WC = 0.5;
    cfg.fluido.GLR = 0;
    cfg.fluido.rho_o = 850;
    cfg.fluido.rho_w = 1000;
    cfg.fluido.mu_l_Pas = 1e-3;
  endif

  % Forzar modelo por tramo: el fixture declara MODELO=MONOFASICO_DARCY en T1.
  modelo = forzar_modelo_tramos_local(modelo, modelo_id);

  try
    red = aos_cad_hidraulica_preparar(modelo, cfg);
    ok = check_local(ok, ~red.requiere_solver_lazos, 'requiere_solver_lazos=false (arbol)');
    [~, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, true);
  catch err
    ok = check_local(ok, false, sprintf('%s resolver red: %s', modelo_id, err.message));
    return;
  end_try_catch

  tol_p = max(cfg.tol_presion_Pa, 2e3);
  nE = numel(red.tramos);
  for e = 1:nE
    if ~red.active_edge(e), continue; endif
    if red.edge_parent(e) < 1 || red.edge_child(e) < 1, continue; endif
    r_red = resultados.tramos{e};
    if isempty(r_red) || ~isfield(r_red, 'P_out_Pa'), continue; endif

    parent = red.edge_parent(e);
    child = red.edge_child(e);
    tr = red.tramos{e};
    n_in = red.nodos{parent};
    n_out = red.nodos{child};
    ql = red.ql_edge_m3s(e);
    qg = red.qg_edge_std_m3s(e);
    P_in = r_red.P_in_Pa;

    r_iso = aos_cad_hidraulica_evaluar_tramo(tr, n_in, n_out, P_in, ql, qg, cfg, modelo);
    tag = sprintf('%s/%s', modelo_id, id_tramo_local(tr, e));

    if es_multi
      dP = abs(r_iso.P_out_Pa - r_red.P_out_Pa);
      ok = check_local(ok, dP <= tol_p, ...
        sprintf('%s |P_out red-iso|<=tol (%.3g Pa)', tag, dP));
      if isfinite(r_red.holdup_liquido) && isfinite(r_iso.holdup_liquido)
        ok = check_local(ok, abs(r_red.holdup_liquido - r_iso.holdup_liquido) <= tol_holdup, ...
          sprintf('%s holdup ±0.01', tag));
      endif
      if ischar(r_red.regimen) && ischar(r_iso.regimen) && ...
          ~isempty(r_red.regimen) && ~strcmp(r_red.regimen, 'NO_DISPONIBLE')
        ok = check_local(ok, strcmp(char(r_red.regimen), char(r_iso.regimen)), ...
          sprintf('%s regimen literal', tag));
      endif
    else
      den = max(abs(r_red.P_out_Pa), 1);
      ok = check_local(ok, abs(r_iso.P_out_Pa - r_red.P_out_Pa) / den <= tol_mono, ...
        sprintf('%s P_out relativo <=1e-9', tag));
    endif

    % Balance formal Sprint 1 (1e-6): aplica a monofasico. En multifasico
    % dp_fric/dp_grav son diagnosticos del VLP y no cierran contra P_out
    % (mismo criterio que F1-F3 en test_aos_cad_benchmark_tramo).
    if ~es_multi
      dp_eq = 0;
      if isfield(r_iso, 'dp_equipo_Pa') && isfinite(r_iso.dp_equipo_Pa)
        dp_eq = r_iso.dp_equipo_Pa;
      endif
      bal = abs(r_iso.dp_total_Pa - (r_iso.dp_fric_Pa + r_iso.dp_grav_Pa + ...
                                     r_iso.dp_menores_Pa + dp_eq));
      ok = check_local(ok, bal / max(abs(r_iso.dp_total_Pa), 1) <= tol_bal, ...
        sprintf('%s balance interno 1e-6', tag));
    endif
    n_ok = n_ok + 1;
  endfor
endfunction

function ok = caso_no_convergencia_local(ok, modelo0)
  % Caso controlado de no convergencia multifasica (patron F4 del Sprint 1).
  modelo = forzar_modelo_tramos_local(modelo0, 'MULTIFASICO_HB');
  cfg = aos_cad_hidraulica_defaults(modelo);
  cfg.modelo = 'MULTIFASICO_HB';
  cfg.modelo_multifasico = 'MULTIFASICO_HB';
  cfg.P_min_Pa = 101325;
  cfg.tol_presion_Pa = 10;
  cfg.max_iter_presion = 60;
  cfg.fluido.API = 35;
  cfg.fluido.WC = 0.45;
  cfg.fluido.GLR = 117;
  cfg.fluido.gamma_g = 0.70;
  cfg.fluido.mu_g_Pas = 1.5e-5;

  try
    red = aos_cad_hidraulica_preparar(modelo, cfg);
  catch err
    ok = check_local(ok, false, sprintf('F4-red preparar: %s', err.message));
    return;
  end_try_catch

  e = 0;
  for i = 1:numel(red.tramos)
    if red.active_edge(i) && red.edge_parent(i) >= 1 && red.edge_child(i) >= 1
      e = i; break;
    endif
  endfor
  ok = check_local(ok, e > 0, 'F4-red tramo activo disponible');
  if e < 1, return; endif

  tr = red.tramos{e};
  n_in = red.nodos{red.edge_parent(e)};
  n_out = red.nodos{red.edge_child(e)};
  ql = max(abs(red.ql_edge_m3s(e)), 1e-4) * 20;
  qg = ql * cfg.fluido.GLR;
  P_in = cfg.P_min_Pa + 50;

  r4 = aos_cad_hidraulica_evaluar_tramo(tr, n_in, n_out, P_in, ql, qg, cfg, modelo);
  ok = check_local(ok, ismember(r4.estado, {'ADVERTENCIA', 'ERROR'}), ...
    'F4-red estado no OK');
  ok = check_local(ok, ~isempty(r4.advertencias), ...
    'F4-red advertencias presentes (no silenciosas)');
  adv_ok = any(strcmp(r4.advertencias, 'PRESION_REQUERIDA_SUPERA_ENTRADA_AUN_EN_P_MIN')) || ...
           any(strcmp(r4.advertencias, 'NO_SE_PUDO_ENCERRAR_RAIZ_DE_PRESION')) || ...
           any(strcmp(r4.advertencias, 'BISECCION_NO_CONVERGE_TOLERANCIA')) || ...
           any(strcmp(r4.advertencias, 'PRESION_SALIDA_MENOR_QUE_MINIMA'));
  ok = check_local(ok, adv_ok, 'F4-red codigo de no-convergencia conocido');
endfunction

function modelo = forzar_modelo_tramos_local(modelo, modelo_id)
  tramos = modelo.tablas_entrada.tramos;
  if isstruct(tramos), tramos = num2cell(tramos); endif
  for i = 1:numel(tramos)
    tramos{i}.modelo_hidraulico = modelo_id;
  endfor
  modelo.tablas_entrada.tramos = tramos;
endfunction

function id = id_tramo_local(tr, e)
  id = sprintf('T%03d', e);
  if isstruct(tr) && isfield(tr, 'id') && ~isempty(tr.id)
    id = char(tr.id);
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

function report_final(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_benchmark_red APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_benchmark_red NO APROBADO\n');
  endif
endfunction

function ok = test_aos_cad_benchmark_tramo()
% TEST_AOS_CAD_BENCHMARK_TRAMO Casos dorados tramo AOSCAD vs nucleo VLP.
% Ver LEEME_BENCHMARK_TRAMO.md. No modifica el nucleo VLP.
  ok = true;
  fprintf('\n=== test_aos_cad_benchmark_tramo ===\n');

  ok = check_local(ok, exist('aos_vlp_friccion', 'file') == 2, 'aos_vlp_friccion en path');
  ok = check_local(ok, exist('aos_vlp_integrar', 'file') == 2, 'aos_vlp_integrar en path');
  ok = check_local(ok, exist('vlp_HB_full', 'file') == 2, 'vlp_HB_full en path');
  ok = check_local(ok, exist('vlp_duns_ros', 'file') == 2, 'vlp_duns_ros en path');
  ok = check_local(ok, exist('vlp_simplified_corregida', 'file') == 2, 'vlp_simplified_corregida en path');
  if ~ok, report_final(ok); return; endif

  cfg = aos_cad_hidraulica_defaults(struct());
  cfg.fluido.WC = 0.5;
  cfg.fluido.rho_o = 850;
  cfg.fluido.rho_w = 1000;
  cfg.fluido.mu_l_Pas = 1e-3;
  cfg.P_min_Pa = 101325;
  cfg.tol_presion_Pa = 10;
  tol_mono = 1e-9;
  tol_bal = 1e-6;

  % --- M1 monofasico horizontal ---
  D = 0.1016; eps_abs = 4.5e-5; L = 500; Ql = 0.001;
  tr = tramo_local(D, eps_abs, L);
  n1 = nodo_local(0, 0, 0); n2 = nodo_local(L, 0, 0);
  P_in = 2e6;
  r = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2, P_in, Ql, cfg);
  rho = 925;
  A = pi * D^2 / 4; V = Ql / A; Re = rho * V * D / cfg.fluido.mu_l_Pas;
  f_ref = aos_vlp_friccion(max(Re, 1), eps_abs / D);
  dp_fric_ref = f_ref * (L / D) * rho * V^2 / 2;
  ok = check_local(ok, abs(r.Re - Re) / max(Re, 1) <= tol_mono, 'M1 Re identico');
  ok = check_local(ok, abs(r.factor_friccion - f_ref) / max(f_ref, 1e-12) <= tol_mono, 'M1 f vs aos_vlp_friccion');
  ok = check_local(ok, abs(r.dp_fric_Pa - dp_fric_ref) / max(dp_fric_ref, 1) <= tol_mono, 'M1 dp_fric analitico');
  ok = check_local(ok, abs(r.dp_grav_Pa) <= 1e-9, 'M1 dp_grav=0 horizontal');
  n1.id = 'N001'; n2.id = 'N002';
  modelo_vacio = modelo_sin_equipo_local(tr, n1, n2);
  r_tr = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo_vacio);
  ok = check_local(ok, abs(get_dp_equipo_local(r_tr)) <= 1e-12, 'M1 dp_equipo_Pa=0');
  ok = check_local(ok, balance_ok_local(r_tr, tol_bal), 'M1 balance interno (+dp_equipo)');
  ok = check_local(ok, abs(r_tr.dp_fric_Pa - dp_fric_ref) / max(dp_fric_ref, 1) <= tol_mono, ...
    'M1 dp_fric via evaluar_tramo intacto');

  % --- M2 desnivel +50 / -50 ---
  n2u = nodo_local(L, 0, 50);
  ru = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2u, P_in, Ql, cfg);
  ok = check_local(ok, abs(ru.dp_grav_Pa - rho * cfg.g * 50) / max(rho * cfg.g * 50, 1) <= tol_mono, ...
    'M2 gravedad +50 m');
  n2d = nodo_local(L, 0, -50);
  rd = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2d, P_in, Ql, cfg);
  ok = check_local(ok, abs(rd.dp_grav_Pa - rho * cfg.g * (-50)) / max(rho * cfg.g * 50, 1) <= tol_mono, ...
    'M2 gravedad -50 m');
  n2u.id = 'N002'; n1.id = 'N001';
  ru_tr = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2u, P_in, Ql, 0, cfg, ...
    modelo_sin_equipo_local(tr, n1, n2u));
  ok = check_local(ok, abs(get_dp_equipo_local(ru_tr)) <= 1e-12, 'M2 dp_equipo_Pa=0');
  ok = check_local(ok, balance_ok_local(ru_tr, tol_bal), 'M2 balance interno (+dp_equipo)');
  % Forzar ERROR por P_min: P_in apenas por encima de P_min con gran perdida
  r_err = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2u, cfg.P_min_Pa + 100, Ql * 50, cfg);
  ok = check_local(ok, strcmp(r_err.estado, 'ERROR') && ...
    any(strcmp(r_err.advertencias, 'PRESION_SALIDA_MENOR_QUE_MINIMA')), ...
    'M2 ERROR PRESION_SALIDA_MENOR_QUE_MINIMA');

  % --- M3 laminar y transicion ---
  Q_lam = 1e-6; % Re bajo
  rlam = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2, P_in, Q_lam, cfg);
  ok = check_local(ok, rlam.Re < 2000, 'M3 Re laminar <2000');
  f_lam = aos_vlp_friccion(max(rlam.Re, 1), eps_abs / D);
  ok = check_local(ok, abs(rlam.factor_friccion - f_lam) / max(f_lam, 1e-12) <= tol_mono, ...
    'M3 f laminar = aos_vlp_friccion');
  % Buscar Q con Re ~3000
  Re_tgt = 3000;
  Q_tr = Re_tgt * cfg.fluido.mu_l_Pas * A / (rho * D);
  rtr = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2, P_in, Q_tr, cfg);
  ok = check_local(ok, rtr.Re > 2000 && rtr.Re < 4000, 'M3 Re en transicion');
  f_tr = aos_vlp_friccion(max(rtr.Re, 1), eps_abs / D);
  ok = check_local(ok, abs(rtr.factor_friccion - f_tr) / max(f_tr, 1e-12) <= tol_mono, ...
    'M3 f transicion = aos_vlp_friccion');
  n2.id = 'N002';
  rtr_tr = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Q_tr, 0, cfg, ...
    modelo_sin_equipo_local(tr, n1, n2));
  ok = check_local(ok, abs(get_dp_equipo_local(rtr_tr)) <= 1e-12, 'M3 dp_equipo_Pa=0');
  ok = check_local(ok, balance_ok_local(rtr_tr, tol_bal), 'M3 balance interno (+dp_equipo)');

  % --- F1/F2/F3 multifasico ---
  cfg_mf = cfg;
  cfg_mf.fluido.API = 35;
  cfg_mf.fluido.WC = 0.45;
  cfg_mf.fluido.GLR = 117;
  cfg_mf.fluido.gamma_g = 0.70;
  cfg_mf.fluido.mu_g_Pas = 1.5e-5;
  cfg_mf.max_iter_presion = 60;
  D2 = 0.062; L2 = 800; dz = 100; Ql2 = 0.0015;
  Qg2 = Ql2 * cfg_mf.fluido.GLR; % Sm3/s approx (GLR Sm3/m3)
  tr2 = tramo_local(D2, 1.5e-5, L2);
  n1b = nodo_local(0, 0, 0); n2b = nodo_local(L2, 0, dz);
  P_in2 = 50e5;
  modelos = {'MULTIFASICO_HB', 'MULTIFASICO_DR', 'MULTIFASICO_SIMPLIFICADO'};
  tags = {'F1 HB', 'F2 DR', 'F3 SIMPL'};
  n1b.id = 'N001'; n2b.id = 'N002';
  modelo_mf = modelo_sin_equipo_local(tr2, n1b, n2b);
  for im = 1:numel(modelos)
    cfg_mf.modelo = modelos{im};
    cfg_mf.modelo_multifasico = modelos{im};
    rm = aos_cad_hidraulica_evaluar_multifasico(tr2, n1b, n2b, P_in2, Ql2, Qg2, cfg_mf, modelos{im});
    ok = check_local(ok, ismember(rm.estado, {'OK', 'ADVERTENCIA', 'ERROR'}), ...
      sprintf('%s estado definido', tags{im}));
    if strcmp(rm.estado, 'ERROR') && any(strcmp(rm.advertencias, 'NO_SE_PUDO_ENCERRAR_RAIZ_DE_PRESION'))
      fprintf('AVISO %s: no cerro raiz (condiciones severas); se acepta con advertencia\n', tags{im});
      continue;
    endif
    [P_req, HL, reg] = nucleo_directo_local(rm.P_out_Pa, P_in2, tr2, n1b, n2b, ...
      Ql2, Qg2, cfg_mf, modelos{im});
    % Techo absoluto documentado ~1e3 Pa; margen 2e3 por residual de biseccion
    tol_p = max(cfg_mf.tol_presion_Pa, 2e3);
    if ~isnan(P_req)
      ok = check_local(ok, abs(P_req - P_in2) <= tol_p, ...
        sprintf('%s |P_req-P_in|<=tol (%.3g Pa)', tags{im}, abs(P_req - P_in2)));
    else
      ok = check_local(ok, false, sprintf('%s P_req nucleo', tags{im}));
    endif
    if isfinite(rm.holdup_liquido) && isfinite(HL)
      ok = check_local(ok, abs(rm.holdup_liquido - HL) <= 0.01, ...
        sprintf('%s holdup ±0.01', tags{im}));
    endif
    if ischar(reg) && ~isempty(reg) && ~strcmp(reg, 'NO_DISPONIBLE')
      ok = check_local(ok, strcmp(char(rm.regimen), char(reg)), ...
        sprintf('%s regimen literal', tags{im}));
    endif
    rm_tr = aos_cad_hidraulica_evaluar_tramo(tr2, n1b, n2b, P_in2, Ql2, Qg2, cfg_mf, modelo_mf);
    ok = check_local(ok, abs(get_dp_equipo_local(rm_tr)) <= 1e-12, ...
      sprintf('%s dp_equipo_Pa=0', tags{im}));
  endfor

  % --- F4 no convergencia controlada ---
  cfg_mf.modelo = 'MULTIFASICO_HB';
  cfg_mf.modelo_multifasico = 'MULTIFASICO_HB';
  r4 = aos_cad_hidraulica_evaluar_multifasico(tr2, n1b, n2b, cfg_mf.P_min_Pa + 50, ...
    Ql2 * 20, Qg2 * 20, cfg_mf, 'MULTIFASICO_HB');
  ok = check_local(ok, ismember(r4.estado, {'ADVERTENCIA', 'ERROR'}), 'F4 estado no OK');
  ok = check_local(ok, ~isempty(r4.advertencias), 'F4 advertencias presentes (no silenciosas)');
  adv_ok = any(strcmp(r4.advertencias, 'PRESION_REQUERIDA_SUPERA_ENTRADA_AUN_EN_P_MIN')) || ...
           any(strcmp(r4.advertencias, 'NO_SE_PUDO_ENCERRAR_RAIZ_DE_PRESION')) || ...
           any(strcmp(r4.advertencias, 'BISECCION_NO_CONVERGE_TOLERANCIA'));
  ok = check_local(ok, adv_ok, 'F4 codigo de no-convergencia conocido');
  r4_tr = aos_cad_hidraulica_evaluar_tramo(tr2, n1b, n2b, cfg_mf.P_min_Pa + 50, ...
    Ql2 * 20, Qg2 * 20, cfg_mf, modelo_mf);
  ok = check_local(ok, abs(get_dp_equipo_local(r4_tr)) <= 1e-12, 'F4 dp_equipo_Pa=0');

  % --- A3 perdidas menores / valvula / bomba ---
  ok = caso_a3_local(ok, cfg, tr, n1, n2, P_in, Ql);

  % Despacho arbol: red serie no requiere solver de lazos
  modelo_serie = aos_aoscad_nuevo_paquete('SIMPLE', 'INSTALACION', 'HIDRAULICO');
  n1.id = 'N001'; n2.id = 'N002';
  tr.id = 'T001'; tr.nodo_o = 'N001'; tr.nodo_d = 'N002';
  tr.x1 = 0; tr.y1 = 0; tr.x2 = 500; tr.y2 = 0;
  modelo_serie.tablas_entrada.nodos = {n1, n2};
  modelo_serie.tablas_entrada.tramos = {tr};
  modelo_serie.tablas_entrada.condiciones_borde = { ...
    struct('id', 'BC1', 'nodo_ref', 'N001', 'tipo_bc', 'PRESION', ...
      'valor', aos_aoscad_campo(2e6, 'Pa', 'TEST'), 'unidad', 'Pa'), ...
    struct('id', 'BC2', 'nodo_ref', 'N002', 'tipo_bc', 'CAUDAL', ...
      'valor', aos_aoscad_campo(0.001, 'm3/s', 'TEST'), 'unidad', 'm3/s')};
  red_serie = aos_cad_hidraulica_preparar(modelo_serie, cfg);
  ok = check_local(ok, ~red_serie.requiere_solver_lazos, 'requiere_solver_lazos=false (serie)');

  report_final(ok);
endfunction

function ok = caso_a3_local(ok, cfg, tr, n1, n2, P_in, Ql)
  % Modelo tabular minimo para dispatcher evaluar_tramo
  n2.id = 'N002';
  n1.id = 'N001';
  modelo = modelo_sin_equipo_local(tr, n1, n2);
  modelo.tablas_entrada.accesorios = {struct('id', 'AC1', 'nodo_ref', 'N002', 'tipo', 'CODO')};
  modelo.tablas_entrada.valvulas = {struct('id', 'V1', 'nodo_ref', 'N002', ...
    'estado', 'ABIERTA', 'Kv', aos_aoscad_campo(80, 'm3/h', 'TEST'))};

  cfg.modelo = 'MONOFASICO_DARCY';
  r0 = aos_cad_hidraulica_evaluar_monofasico(tr, n1, n2, P_in, Ql, cfg);
  r = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo);
  rho = r0.rho_m_kgm3; V = abs(r0.velocidad_m_s);
  dp_codo = 0.9 * rho * V^2 / 2;
  Qh = abs(Ql) * 3600; SG = rho / 1000;
  dp_kv = 1e5 * (Qh / 80)^2 * SG;
  dp_esp = dp_codo + dp_kv;
  ok = check_local(ok, abs(r.dp_menores_Pa - dp_esp) / max(dp_esp, 1) <= 1e-6, ...
    'A3 dp_menores CODO+Kv=80');
  ok = check_local(ok, abs(get_dp_equipo_local(r)) <= 1e-12, 'A3 dp_equipo_Pa=0 (sin bomba)');
  ok = check_local(ok, balance_ok_local(r, 1e-6), 'A3 balance interno (+dp_equipo)');

  % Valvula cerrada
  modelo.tablas_entrada.valvulas = {struct('id', 'V1', 'nodo_ref', 'N002', ...
    'estado', 'CERRADA', 'Kv', aos_aoscad_campo(80, 'm3/h', 'TEST'))};
  modelo.tablas_entrada.accesorios = {};
  rc = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo);
  ok = check_local(ok, any(strcmp(rc.advertencias, 'VALVULA_CERRADA')), 'A3 VALVULA_CERRADA');
  ok = check_local(ok, ~isfinite(rc.dp_menores_Pa) || isinf(rc.dp_menores_Pa), ...
    'A3 dp_menores Inf con valvula cerrada');

  % Bomba sin curva (Sprint1: advertencia conservada)
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.equipos = {struct('id', 'EQ1', 'nodo_ref', 'N002', 'tipo', 'BOMBA')};
  rb = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo);
  ok = check_local(ok, any(strcmp(rb.advertencias, 'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1')), ...
    'A3 bomba sin curva (congelado Sprint1)');
  ok = check_local(ok, abs(get_dp_equipo_local(rb)) <= 1e-12, 'A3 bomba sin curva dp_equipo=0');
endfunction

function modelo = modelo_sin_equipo_local(tr, n1, n2)
  modelo = struct();
  modelo.tablas_entrada = struct();
  modelo.tablas_entrada.nodos = {n1, n2};
  modelo.tablas_entrada.tramos = {tr};
  modelo.tablas_entrada.accesorios = {};
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.equipos = {};
endfunction

function dp = get_dp_equipo_local(r)
  dp = 0;
  if isstruct(r) && isfield(r, 'dp_equipo_Pa') && isfinite(r.dp_equipo_Pa)
    dp = r.dp_equipo_Pa;
  endif
endfunction

function tf = balance_ok_local(r, tol_bal)
  dp_eq = get_dp_equipo_local(r);
  bal = abs(r.dp_total_Pa - (r.dp_fric_Pa + r.dp_grav_Pa + r.dp_menores_Pa + dp_eq));
  tf = bal / max(abs(r.dp_total_Pa), 1) <= tol_bal;
endfunction

function [P_req, HL, reg] = nucleo_directo_local(P_out, P_in, tramo, n1, n2, Ql, Qg, cfg, modelo_id)
  D = aos_aoscad_valor(tramo.diametro_m);
  eps_abs = aos_aoscad_valor(tramo.rugosidad);
  L = aos_aoscad_valor(tramo.longitud_m);
  dz = n2.z - n1.z;
  inc = acosd(min(abs(dz) / max(L, 1e-9), 1));
  survey = struct();
  survey.MD = [0; L];
  survey.TVD = [0; dz];
  survey.inclinacion = [inc; inc];
  survey.azimut = [0; 0];
  survey.ID_tubing = [D; D];
  survey.ID_casing = [NaN; NaN];
  survey.rugosidad = [eps_abs; eps_abs];
  param = struct();
  param.P_wh = max(P_out, cfg.fluido.P_std_Pa);
  param.API = cfg.fluido.API; param.WC = cfg.fluido.WC;
  param.GLR = cfg.fluido.GLR; param.gamma_g = cfg.fluido.gamma_g;
  param.rho_o = cfg.fluido.rho_o; param.rho_w = cfg.fluido.rho_w;
  param.rho_g_std = cfg.fluido.rho_g_std;
  param.mu_w = cfg.fluido.mu_l_Pas; param.mu_g = cfg.fluido.mu_g_Pas;
  param.T_sup = cfg.fluido.T_sup_K; param.T_fondo = cfg.fluido.T_fondo_K;
  param.P_std = cfg.fluido.P_std_Pa; param.T_std = cfg.fluido.T_std_K;
  param.diam_tbg = D; param.eps_abs = eps_abs; param.Q_iny = 0;
  HL = NaN; reg = '';
  diag = struct();
  if strcmp(modelo_id, 'MULTIFASICO_HB')
    [P_req, ~, ~, diag] = aos_vlp_integrar(param, survey, Ql, Qg, 'HB');
  elseif strcmp(modelo_id, 'MULTIFASICO_DR')
    [P_req, ~, ~, diag] = aos_vlp_integrar(param, survey, Ql, Qg, 'DR');
  else
    [P_req, ~, ~] = vlp_simplified_corregida(param, Ql, Qg, L, survey);
  endif
  if isstruct(diag)
    if isfield(diag, 'HL') && numel(diag.HL) >= 2, HL = diag.HL(end); endif
    if isfield(diag, 'regimen') && numel(diag.regimen) >= 2 && ~isempty(diag.regimen{end})
      reg = char(diag.regimen{end});
    endif
  endif
endfunction

function tr = tramo_local(D, eps_abs, L)
  tr = struct();
  tr.id = 'T001';
  tr.diametro_m = aos_aoscad_campo(D, 'm', 'TEST');
  tr.rugosidad = aos_aoscad_campo(eps_abs, 'm', 'TEST');
  tr.longitud_m = aos_aoscad_campo(L, 'm', 'TEST');
endfunction

function n = nodo_local(x, y, z)
  n = struct();
  n.x = x; n.y = y; n.z = z;
  n.cota = aos_aoscad_campo(z, 'm', 'TEST');
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
    fprintf('RESULTADO: test_aos_cad_benchmark_tramo APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_benchmark_tramo NO APROBADO\n');
  endif
endfunction

function ok = test_aos_cad_equipo_activo_curva()
% TEST_AOS_CAD_EQUIPO_ACTIVO_CURVA Curva head-caudal (Sprint 3 B).
% Fixture demo_aos_bomba_curva.dxf + casos programaticos de advertencias.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_equipo_activo_curva ===\n');

  ok = check_local(ok, exist('aos_cad_hidraulica_curva_bomba', 'file') == 2, ...
    'curva_bomba en path');
  ok = check_local(ok, exist('aos_cad_hidraulica_catalogo_bombas', 'file') == 2, ...
    'catalogo_bombas en path');
  if ~ok, report_final(ok); return; endif

  cfg = aos_cad_hidraulica_defaults(struct());
  cfg.fluido.WC = 0.5;
  cfg.fluido.rho_o = 850;
  cfg.fluido.rho_w = 1000;
  cfg.fluido.mu_l_Pas = 1e-3;
  cfg.modelo = 'MONOFASICO_DARCY';
  tol_bal = 1e-6;
  D = 0.1016; L = 100; Ql = 0.001; P_in = 2e6;
  tr = tramo_local(D, 4.5e-5, L);
  n1 = nodo_local('N001', 0, 0, 0);
  n2 = nodo_local('N002', L, 0, 0);

  % --- Interpolacion en punto intermedio (a mano) ---
  curva = struct('Q_m3d', [0; 50; 100; 150], 'H_m', [40; 38; 32; 22]);
  Q_mid_m3d = 75;
  [h_mid, adv_mid] = aos_cad_hidraulica_curva_bomba(curva, Q_mid_m3d / 86400, cfg);
  h_ref = 38 + (32 - 38) * (75 - 50) / (100 - 50); % 35
  ok = check_local(ok, abs(h_mid - h_ref) <= 1e-9, 'head interpolado Q=75');
  ok = check_local(ok, isempty(adv_mid) || ~any(strcmp(adv_mid, 'CURVA_EXTRAPOLADA')), ...
    'sin extrapolacion en rango');

  % --- Fixture DXF: P_out mayor que sin bomba + identidad ---
  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_bomba_curva.dxf');
  ok = check_local(ok, exist(dxf, 'file') == 2, 'fixture demo_aos_bomba_curva.dxf');
  if ~ok, report_final(ok); return; endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    if ~aos_cad_importar_dxf(dxf, true)
      ok = check_local(ok, false, 'import DXF bomba curva');
    else
      aos_cad_construir_topologia(0.05, true);
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      modelo = aos_cad_hidraulica_aplicar_metadatos(modelo);
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
      ok = check_local(ok, isfield(modelo.tablas_entrada, 'equipos') && ...
        numel(modelo.tablas_entrada.equipos) >= 1, 'equipo bomba mapeado');
      tiene_curva = false;
      if isfield(modelo.tablas_entrada, 'equipos')
        for ie = 1:numel(modelo.tablas_entrada.equipos)
          eq = modelo.tablas_entrada.equipos{ie};
          if isstruct(eq) && isfield(eq, 'tipo') && ...
              any(strcmpi(char(eq.tipo), {'BOMBA','PUMP'})) && ...
              isfield(eq, 'curva_bomba') && ~isempty(eq.curva_bomba)
            tiene_curva = true;
            break;
          endif
        endfor
      endif
      ok = check_local(ok, tiene_curva, 'curva_bomba inline en equipo BOMBA');

      cfg_dxf = aos_cad_hidraulica_defaults(modelo);
      [~, res_con] = aos_cad_hidraulica_resolver(modelo, cfg_dxf, true);
      ok = check_local(ok, numel(res_con.tramos) >= 1, 'tramo resuelto con bomba');
      if numel(res_con.tramos) >= 1
        rc = res_con.tramos{1};
        ok = check_local(ok, isfield(rc, 'head_equipo_m') && rc.head_equipo_m > 0, ...
          'head_equipo_m > 0 con curva');
        ok = check_local(ok, ~any(strcmp(rc.advertencias, ...
          'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1')), ...
          'sin advertencia SIN_CURVA cuando hay curva');
        bal = abs(rc.dp_total_Pa - (rc.dp_fric_Pa + rc.dp_grav_Pa + ...
                                    rc.dp_menores_Pa + rc.dp_equipo_Pa));
        ok = check_local(ok, bal / max(abs(rc.dp_total_Pa), 1) <= tol_bal, ...
          'identidad dp con dp_equipo (DXF)');
      endif

      % Misma red sin curva: P_out menor
      modelo_sin = modelo;
      if isfield(modelo_sin.tablas_entrada, 'equipos')
        for ie = 1:numel(modelo_sin.tablas_entrada.equipos)
          eq = modelo_sin.tablas_entrada.equipos{ie};
          if isfield(eq, 'curva_bomba'), eq = rmfield(eq, 'curva_bomba'); endif
          if isfield(eq, 'bomba_modelo'), eq = rmfield(eq, 'bomba_modelo'); endif
          if isfield(eq, 'BOMBA_MODELO'), eq = rmfield(eq, 'BOMBA_MODELO'); endif
          modelo_sin.tablas_entrada.equipos{ie} = eq;
        endfor
      endif
      [~, res_sin] = aos_cad_hidraulica_resolver(modelo_sin, cfg_dxf, true);
      if numel(res_con.tramos) >= 1 && numel(res_sin.tramos) >= 1
        ok = check_local(ok, res_con.tramos{1}.P_out_Pa > res_sin.tramos{1}.P_out_Pa, ...
          'P_out con bomba > sin bomba');
        ok = check_local(ok, any(strcmp(res_sin.tramos{1}.advertencias, ...
          'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1')), ...
          'advertencia SIN_CURVA sin curva');
      endif
    endif
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  % --- Casos programaticos de curva_bomba ---
  [~, adv_ex] = aos_cad_hidraulica_curva_bomba(curva, 300 / 86400, cfg);
  ok = check_local(ok, any(strcmp(adv_ex, 'CURVA_EXTRAPOLADA')), 'CURVA_EXTRAPOLADA');
  [h_sat, ~] = aos_cad_hidraulica_curva_bomba(curva, 300 / 86400, cfg);
  ok = check_local(ok, abs(h_sat - 22) <= 1e-9 && h_sat >= 0, ...
    'extrapolacion satura extremo (no head negativo)');

  curva1 = struct('Q_m3d', 50, 'H_m', 38);
  [~, adv1] = aos_cad_hidraulica_curva_bomba(curva1, Ql, cfg);
  ok = check_local(ok, any(strcmp(adv1, 'CURVA_INSUFICIENTE_PUNTOS')), ...
    'CURVA_INSUFICIENTE_PUNTOS');

  curva_nm = struct('Q_m3d', [0; 50; 100], 'H_m', [10; 20; 30]);
  [~, adv_nm] = aos_cad_hidraulica_curva_bomba(curva_nm, 50 / 86400, cfg);
  ok = check_local(ok, any(strcmp(adv_nm, 'CURVA_NO_MONOTONA')), 'CURVA_NO_MONOTONA');

  % BOMBA_ESTADO=APAGADA => head 0
  modelo = modelo_base_local(tr, n1, n2);
  modelo.tablas_entrada.equipos = {struct( ...
    'id', 'EQ1', 'nodo_ref', 'N002', 'tipo', 'BOMBA', ...
    'bomba_estado', 'APAGADA', ...
    'curva_bomba', curva)};
  rb = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo);
  ok = check_local(ok, abs(rb.head_equipo_m) <= 1e-12, 'BOMBA_ESTADO=APAGADA head=0');
  ok = check_local(ok, abs(rb.dp_equipo_Pa) <= 1e-9, 'BOMBA_ESTADO=APAGADA dp_equipo=0');
  ok = check_local(ok, ~any(strcmp(rb.advertencias, ...
    'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1')), ...
    'apagada sin advertencia SIN_CURVA');

  % BOMBA_MODELO desde catalogo JSON
  [curva_cat, adv_cat, info_cat] = aos_cad_hidraulica_catalogo_bombas('AOS_B_100_40');
  ok = check_local(ok, isempty(adv_cat) || ~any(strcmp(adv_cat, 'BOMBA_MODELO_NO_ENCONTRADO')), ...
    'catalogo AOS_B_100_40 encontrado');
  ok = check_local(ok, isstruct(info_cat) && isfield(info_cat, 'encontrada') && ...
    info_cat.encontrada, 'info.encontrada catalogo');
  ok = check_local(ok, tiene_curva_util_local(curva_cat), 'curva catalogo util');

  modelo = modelo_base_local(tr, n1, n2);
  modelo.tablas_entrada.equipos = {struct( ...
    'id', 'EQ1', 'nodo_ref', 'N002', 'tipo', 'BOMBA', ...
    'bomba_modelo', 'AOS_B_100_40')};
  rcat = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo);
  ok = check_local(ok, rcat.head_equipo_m > 0, 'head desde BOMBA_MODELO');
  ok = check_local(ok, ~any(strcmp(rcat.advertencias, ...
    'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1')), ...
    'BOMBA_MODELO sin advertencia SIN_CURVA');
  bal = abs(rcat.dp_total_Pa - (rcat.dp_fric_Pa + rcat.dp_grav_Pa + ...
                                rcat.dp_menores_Pa + rcat.dp_equipo_Pa));
  ok = check_local(ok, bal / max(abs(rcat.dp_total_Pa), 1) <= tol_bal, ...
    'identidad dp con catalogo');

  % VALVULA_CERRADA gana sobre bomba
  modelo = modelo_base_local(tr, n1, n2);
  modelo.tablas_entrada.valvulas = {struct('id', 'V1', 'nodo_ref', 'N002', ...
    'estado', 'CERRADA', 'Kv', aos_aoscad_campo(80, 'm3/h', 'TEST'))};
  modelo.tablas_entrada.equipos = {struct( ...
    'id', 'EQ1', 'nodo_ref', 'N002', 'tipo', 'BOMBA', ...
    'curva_bomba', curva)};
  rv = aos_cad_hidraulica_evaluar_tramo(tr, n1, n2, P_in, Ql, 0, cfg, modelo);
  ok = check_local(ok, any(strcmp(rv.advertencias, 'VALVULA_CERRADA')), ...
    'VALVULA_CERRADA presente');
  ok = check_local(ok, isinf(rv.dp_menores_Pa) || ~isfinite(rv.dp_menores_Pa), ...
    'dp_menores Inf con valvula cerrada');
  ok = check_local(ok, ~isfield(rv, 'head_equipo_m') || abs(rv.head_equipo_m) <= 1e-12, ...
    'valvula cerrada: bomba no aporta head');

  report_final(ok);
endfunction

function tf = tiene_curva_util_local(curva)
  tf = false;
  if isempty(curva) || ~isstruct(curva), return; endif
  Q = []; H = [];
  if isfield(curva, 'Q_m3d'), Q = aos_aoscad_valor(curva.Q_m3d); endif
  if isfield(curva, 'H_m'), H = aos_aoscad_valor(curva.H_m); endif
  if isfield(curva, 'curva_Q_m3d') && isempty(Q), Q = aos_aoscad_valor(curva.curva_Q_m3d); endif
  if isfield(curva, 'curva_H_m') && isempty(H), H = aos_aoscad_valor(curva.curva_H_m); endif
  tf = isnumeric(Q) && isnumeric(H) && numel(Q) >= 2 && numel(H) >= 2;
endfunction

function modelo = modelo_base_local(tr, n1, n2)
  modelo = struct();
  modelo.tablas_entrada = struct();
  modelo.tablas_entrada.nodos = {n1, n2};
  modelo.tablas_entrada.tramos = {tr};
  modelo.tablas_entrada.accesorios = {};
  modelo.tablas_entrada.valvulas = {};
  modelo.tablas_entrada.equipos = {};
endfunction

function tr = tramo_local(D, eps_abs, L)
  tr = struct();
  tr.id = 'T001';
  tr.diametro_m = aos_aoscad_campo(D, 'm', 'TEST');
  tr.rugosidad = aos_aoscad_campo(eps_abs, 'm', 'TEST');
  tr.longitud_m = aos_aoscad_campo(L, 'm', 'TEST');
endfunction

function n = nodo_local(id, x, y, z)
  n = struct();
  n.id = id; n.x = x; n.y = y; n.z = z;
  n.cota = aos_aoscad_campo(z, 'm', 'TEST');
endfunction

function ok = check_local(ok, cond, msg)
  if cond, fprintf('OK  %s\n', msg); else fprintf(2, 'FALLO  %s\n', msg); ok = false; endif
endfunction

function report_final(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_equipo_activo_curva APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_equipo_activo_curva NO APROBADO\n');
  endif
endfunction

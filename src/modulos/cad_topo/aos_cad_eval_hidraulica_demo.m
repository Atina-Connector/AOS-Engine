function resultados = aos_cad_eval_hidraulica_demo(silencioso)
% AOS_CAD_EVAL_HIDRAULICA_DEMO Evaluacion hidraulica DEMO del modulo CAD_TOPO.
% NO es el solver oficial de red (src/core). Advertencia: DEMO_NO_SOLVER_OFICIAL.
  global CONFIG_ACTIVA;
  if nargin < 1, silencioso = false; endif

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOS CAD_TOPO: no hay modelo_aoscad. Importe/normalice primero.');
  endif

  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;

  % GALERIAS: sin solver; no inventar resultados hidraulicos de red de pozos
  if isfield(modelo, 'info') && isfield(modelo.info, 'dxf_clase') ...
      && strcmpi(char(modelo.info.dxf_clase), 'GALERIAS')
    resultados = struct('nodos', {{}}, 'tramos', {{}});
    modelo.tablas_resultados = resultados;
    modelo.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
    modelo.simulacion.dominio = 'HIDRAULICO';
    modelo.simulacion.estado = 'EJECUTADA_CON_ADVERTENCIAS';
    modelo.simulacion.parametros_efectivos = struct();
    modelo.simulacion.advertencias = {'GALERIAS_SIN_SOLVER', 'DEMO_NO_SOLVER_OFICIAL'};
    modelo.simulacion.corrida_id = sprintf('GALERIAS_%s', datestr(now, 'yyyymmdd_HHMMSS'));
    modelo.simulacion.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    modelo.validaciones.estado = 'ADVERTENCIA';
    modelo.validaciones.items{end+1} = struct( ...
      'codigo', 'GALERIAS_SIN_SOLVER', ...
      'mensaje', 'Galerias sin solver; no se escriben resultados hidraulicos de pozos.', ...
      'severidad', 'ADVERTENCIA');
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
    CONFIG_ACTIVA.cad_topologia.resultados_demo = resultados;
    if ~silencioso
      fprintf('\n--- SIM GALERIAS (NO-OP) ---\n');
      fprintf('ADVERTENCIA: GALERIAS_SIN_SOLVER — sin caudales/presiones de red de pozos.\n');
    endif
    return;
  endif

  if ~isfield(modelo, 'topologia') || isempty(modelo.topologia) || ...
      ~isfield(modelo.topologia, 'aristas') || isempty(modelo.topologia.aristas)
    aos_cad_construir_topologia(0.05, true);
    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  endif

  nodos = modelo.tablas_entrada.nodos;
  tramos = modelo.tablas_entrada.tramos;
  bcs = modelo.tablas_entrada.condiciones_borde;

  rho = 1000;   % kg/m3
  g = 9.81;
  mu = 1e-3;    % Pa.s
  Q_ref = 0.02; % m3/s default
  P_ref = 1.5e6;

  for i = 1:numel(bcs)
    bc = bcs{i};
    val = aos_aoscad_valor(bc.valor);
    if strcmpi(bc.tipo_bc, 'CAUDAL') && ~isempty(val)
      Q_ref = val;
    elseif strcmpi(bc.tipo_bc, 'PRESION') && ~isempty(val)
      P_ref = val;
    endif
  endfor

  % Asignar caudal por tramo (serie simple / reparto uniforme en ramas)
  nT = max(numel(tramos), 1);
  Q_tramo = ones(1, nT) * (Q_ref / nT);

  res_tramos = {};
  perdida_acum = 0;
  for i = 1:numel(tramos)
    tr = tramos{i};
    D = aos_aoscad_valor(tr.diametro_m);
    if isempty(D) || D <= 0, D = 0.1; endif
    L = aos_aoscad_valor(tr.longitud_m);
    if isempty(L) || L <= 0
      L = hypot(tr.x2 - tr.x1, tr.y2 - tr.y1);
    endif
    eps_r = aos_aoscad_valor(tr.rugosidad);
    if isempty(eps_r), eps_r = 0.045e-3; endif
    Q = Q_tramo(i);
    A = pi * (D/2)^2;
    V = Q / max(A, 1e-12);
    Re = rho * abs(V) * D / mu;
    if Re < 2300
      f = 64 / max(Re, 1);
    else
      % Haaland approx
      invsqrtf = -1.8 * log10((eps_r / D / 3.7)^1.11 + 6.9 / max(Re, 1));
      f = 1 / max(invsqrtf, 1e-6)^2;
    endif
    dp = f * (L / D) * (rho * V * abs(V) / 2);
    dh = dp / (rho * g);
    perdida_acum = perdida_acum + dh;

    rt = struct();
    rt.id = tr.id;
    rt.caudal_m3s = Q;
    rt.dp_Pa = dp;
    rt.velocidad_ms = V;
    rt.perdida_head_m = dh;
    rt.Re = Re;
    rt.f_friction = f;
    res_tramos{end+1} = rt; %#ok<AGROW>
  endfor

  % Presiones nodales: BFS-ish desde BC de presion
  P_map = struct();
  if ~isempty(nodos)
    P_map.(nodos{1}.id) = P_ref;
  endif
  for i = 1:numel(bcs)
    if strcmpi(bcs{i}.tipo_bc, 'PRESION')
      P_map.(bcs{i}.nodo_ref) = aos_aoscad_valor(bcs{i}.valor);
    endif
  endfor

  % Propagar a lo largo de tramos
  changed = true;
  guard = 0;
  while changed && guard < 50
    changed = false;
    guard = guard + 1;
    for i = 1:numel(tramos)
      tr = tramos{i};
      rt = res_tramos{i};
      has_o = isfield(P_map, tr.nodo_o);
      has_d = isfield(P_map, tr.nodo_d);
      if has_o && ~has_d
        P_map.(tr.nodo_d) = P_map.(tr.nodo_o) - rt.dp_Pa;
        changed = true;
      elseif has_d && ~has_o
        P_map.(tr.nodo_o) = P_map.(tr.nodo_d) + rt.dp_Pa;
        changed = true;
      endif
    endfor
  endwhile

  res_nodos = {};
  for i = 1:numel(nodos)
    n = nodos{i};
    rn = struct();
    rn.id = n.id;
    if isfield(P_map, n.id)
      rn.presion_Pa = P_map.(n.id);
    else
      rn.presion_Pa = P_ref;
    endif
    rn.head_m = rn.presion_Pa / (rho * g);
    rn.caudal_m3s = 0;
    % caudal neto aproximado
    for j = 1:numel(tramos)
      if strcmp(tramos{j}.nodo_o, n.id)
        rn.caudal_m3s = rn.caudal_m3s - res_tramos{j}.caudal_m3s;
      elseif strcmp(tramos{j}.nodo_d, n.id)
        rn.caudal_m3s = rn.caudal_m3s + res_tramos{j}.caudal_m3s;
      endif
    endfor
    res_nodos{end+1} = rn; %#ok<AGROW>
  endfor

  resultados = struct();
  resultados.nodos = res_nodos;
  resultados.tramos = res_tramos;

  modelo.tablas_resultados = resultados;
  modelo.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
  modelo.simulacion.dominio = 'HIDRAULICO';
  modelo.simulacion.estado = 'EJECUTADA_CON_ADVERTENCIAS';
  modelo.simulacion.parametros_efectivos = struct( ...
    'rho_kgm3', rho, 'g', g, 'mu_Pas', mu, 'Q_ref_m3s', Q_ref, 'P_ref_Pa', P_ref);
  modelo.simulacion.advertencias = {'DEMO_NO_SOLVER_OFICIAL'};
  modelo.simulacion.corrida_id = sprintf('DEMO_%s', datestr(now, 'yyyymmdd_HHMMSS'));
  modelo.simulacion.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  modelo.validaciones.estado = 'ADVERTENCIA';
  modelo.validaciones.items{end+1} = struct( ...
    'codigo', 'DEMO_NO_SOLVER_OFICIAL', ...
    'mensaje', 'Evaluacion hidraulica demo del modulo; no usa solvers de src/core.', ...
    'severidad', 'ADVERTENCIA');

  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.resultados_demo = resultados;

  if ~silencioso
    fprintf('\n--- SIMULACION HIDRAULICA DEMO ---\n');
    fprintf('motor       : DEMO_NO_SOLVER_OFICIAL\n');
    fprintf('corrida_id  : %s\n', modelo.simulacion.corrida_id);
    fprintf('nodos res   : %d\n', numel(res_nodos));
    fprintf('tramos res  : %d\n', numel(res_tramos));
    if ~isempty(res_tramos)
      fprintf('Q típico    : %.4g m3/s | V=%.3f m/s | dp=%.3g Pa\n', ...
        res_tramos{1}.caudal_m3s, res_tramos{1}.velocidad_ms, res_tramos{1}.dp_Pa);
    endif
    fprintf('ADVERTENCIA: no es el solver oficial de red.\n');
  endif
endfunction

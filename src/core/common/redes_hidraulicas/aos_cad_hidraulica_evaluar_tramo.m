function r = aos_cad_hidraulica_evaluar_tramo(tramo, nodo_in, nodo_out, P_in, Ql, Qg_std, cfg, modelo)
% AOS_CAD_HIDRAULICA_EVALUAR_TRAMO Adaptador comun entre red y motores AOS.
% Sprint3 B4: dp_equipo_Pa / head_equipo_m fuera de dp_menores_Pa.
% Identidad: dp_total = dp_fric + dp_grav + dp_menores + dp_equipo.
  modelo_id = modelo_tramo_local(tramo, cfg, Qg_std);
  if strcmp(modelo_id, 'MONOFASICO_DARCY')
    r = aos_cad_hidraulica_evaluar_monofasico(tramo, nodo_in, nodo_out, P_in, Ql, cfg);
  else
    r = aos_cad_hidraulica_evaluar_multifasico(tramo, nodo_in, nodo_out, ...
                                                P_in, Ql, Qg_std, cfg, modelo_id);
  endif

  [dp_minor, adv_minor] = perdidas_menores_local(modelo, nodo_out, Ql, r);
  r.dp_menores_Pa = dp_minor;
  r.dp_equipo_Pa = 0;
  r.head_equipo_m = 0;

  flujo_reverso = isstruct(cfg) && isfield(cfg, 'sentido_flujo_reverso') && ...
    logical(cfg.sentido_flujo_reverso);

  % VALVULA_CERRADA gana: no se aplica head de bomba (restriccion Sprint 3).
  if isinf(dp_minor)
    r.P_out_Pa = r.P_out_Pa - dp_minor;
    r.dp_total_Pa = r.P_in_Pa - r.P_out_Pa;
    for i = 1:numel(adv_minor), r.advertencias{end+1} = adv_minor{i}; endfor
  elseif flujo_reverso
    % Flujo contra la geometria: el head de equipo no aporta (restriccion Sprint 4).
    for i = 1:numel(adv_minor), r.advertencias{end+1} = adv_minor{i}; endfor
    if hay_bomba_en_nodo_local(modelo, nodo_in)
      r.advertencias{end+1} = 'EQUIPO_FLUJO_REVERSO_NO_APORTA_HEAD';
    endif
    r.P_out_Pa = r.P_out_Pa - dp_minor;
    r.dp_total_Pa = r.P_in_Pa - r.P_out_Pa;
  else
    [dp_eq, head_eq, adv_eq] = aporte_equipos_local(modelo, nodo_out, Ql, r, cfg);
    r.dp_equipo_Pa = dp_eq;
    r.head_equipo_m = head_eq;
    r.P_out_Pa = r.P_out_Pa - dp_minor - dp_eq;
    r.dp_total_Pa = r.P_in_Pa - r.P_out_Pa;
    for i = 1:numel(adv_minor), r.advertencias{end+1} = adv_minor{i}; endfor
    for i = 1:numel(adv_eq), r.advertencias{end+1} = adv_eq{i}; endfor
  endif

  omitir_pmin = isstruct(cfg) && isfield(cfg, 'omitir_chequeo_P_min') && ...
    logical(cfg.omitir_chequeo_P_min);
  if ~omitir_pmin && r.P_out_Pa < cfg.P_min_Pa
    r.estado = 'ERROR';
    r.advertencias{end+1} = 'PRESION_SALIDA_MENOR_QUE_MINIMA';
  elseif ~isempty(r.advertencias) && strcmp(r.estado, 'OK')
    r.estado = 'ADVERTENCIA';
  endif
endfunction

function tf = hay_bomba_en_nodo_local(modelo, nodo)
  tf = false;
  if nargin < 1 || ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada'), return; endif
  nid = char(nodo.id);
  equipos = rows_local(modelo.tablas_entrada, 'equipos');
  for i = 1:numel(equipos)
    eq = equipos{i};
    if ~isfield(eq, 'nodo_ref') || ~strcmp(char(eq.nodo_ref), nid), continue; endif
    tipo = upper(char(getf_local(eq, 'tipo', '')));
    if any(strcmp(tipo, {'BOMBA','PUMP','COMPRESOR','COMPRESSOR'}))
      tf = true; return;
    endif
  endfor
endfunction

function m = modelo_tramo_local(tr, cfg, Qg)
  m = cfg.modelo;
  campos = {'modelo_hidraulico','modelo_vlp','modelo'};
  for i = 1:numel(campos)
    if isstruct(tr) && isfield(tr, campos{i})
      x = tr.(campos{i});
      if isstruct(x), x = aos_aoscad_valor(x); endif
      if ischar(x) && ~isempty(strtrim(x)), m = x; break; endif
    endif
  endfor
  m = normalizar_local(m);
  if strcmp(m, 'AUTOMATICO')
    if abs(Qg) <= 1e-12
      m = 'MONOFASICO_DARCY';
    else
      m = normalizar_local(cfg.modelo_multifasico);
    endif
  endif
  permitidos = {'MONOFASICO_DARCY','MULTIFASICO_HB','MULTIFASICO_DR','MULTIFASICO_SIMPLIFICADO'};
  if ~any(strcmp(m, permitidos))
    error('AOSCAD HID: modelo de tramo no reconocido: %s', m);
  endif
endfunction

function m = normalizar_local(m)
  m = upper(strrep(strrep(strtrim(char(m)), '-', '_'), ' ', '_'));
  if any(strcmp(m, {'HB','HAGEDORN_BROWN'})), m = 'MULTIFASICO_HB'; endif
  if any(strcmp(m, {'DR','DUNS_ROS','DUNS&ROS'})), m = 'MULTIFASICO_DR'; endif
  if any(strcmp(m, {'SIMPLIFICADO','SIMPLE'})), m = 'MULTIFASICO_SIMPLIFICADO'; endif
  if any(strcmp(m, {'DARCY','DARCY_WEISBACH','MONOFASICO'})), m = 'MONOFASICO_DARCY'; endif
  if strcmp(m, 'AUTO'), m = 'AUTOMATICO'; endif
endfunction

function [dp, adv] = perdidas_menores_local(modelo, nodo_out, Ql, r)
  % Solo perdidas pasivas (accesorios / valvulas). Head de equipo va aparte.
  dp = 0; adv = {};
  if nargin < 1 || ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada'), return; endif
  te = modelo.tablas_entrada; nid = char(nodo_out.id);
  rho = r.rho_m_kgm3; if ~isfinite(rho) || rho <= 0, rho = 1000; endif
  V = abs(r.velocidad_m_s);

  accesorios = rows_local(te, 'accesorios');
  for i = 1:numel(accesorios)
    a = accesorios{i};
    if ~isfield(a, 'nodo_ref') || ~strcmp(char(a.nodo_ref), nid), continue; endif
    tipo = upper(char(getf_local(a, 'tipo', '')));
    K = 0;
    if strcmp(tipo, 'CODO'), K = 0.9;
    elseif strcmp(tipo, 'TEE'), K = 1.8;
    elseif strcmp(tipo, 'REDUCCION'), K = 0.5;
    else K = 0.3;
    endif
    dp = dp + K * rho * V^2 / 2;
  endfor

  valvulas = rows_local(te, 'valvulas');
  for i = 1:numel(valvulas)
    v = valvulas{i};
    if ~isfield(v, 'nodo_ref') || ~strcmp(char(v.nodo_ref), nid), continue; endif
    estado = upper(char(valor_texto_local(getf_local(v, 'estado', 'ABIERTA'))));
    if any(strcmp(estado, {'CERRADA','CLOSED'}))
      dp = Inf; adv{end+1} = 'VALVULA_CERRADA'; return;
    endif
    Kv = aos_aoscad_valor(getf_local(v, 'Kv', []));
    if ~isempty(Kv) && isnumeric(Kv) && Kv(1) > 0
      Qh = abs(Ql) * 3600; SG = rho / 1000;
      dp = dp + 1e5 * (Qh / Kv(1))^2 * SG;
    else
      adv{end+1} = 'VALVULA_SIN_KV';
    endif
  endfor
endfunction

function [dp_equipo, head_equipo_m, adv] = aporte_equipos_local(modelo, nodo_out, Ql, r, cfg)
  % Aporte de head de equipos activos. dp_equipo negativo = ganancia de presion.
  dp_equipo = 0; head_equipo_m = 0; adv = {};
  if nargin < 1 || ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada'), return; endif
  te = modelo.tablas_entrada; nid = char(nodo_out.id);
  rho = r.rho_m_kgm3; if ~isfinite(rho) || rho <= 0, rho = 1000; endif
  g = 9.81;
  if isstruct(cfg) && isfield(cfg, 'g') && isfinite(cfg.g) && cfg.g > 0
    g = cfg.g;
  endif

  equipos = rows_local(te, 'equipos');
  for i = 1:numel(equipos)
    eq = equipos{i};
    if ~isfield(eq, 'nodo_ref') || ~strcmp(char(eq.nodo_ref), nid), continue; endif
    tipo = upper(char(getf_local(eq, 'tipo', '')));
    if ~any(strcmp(tipo, {'BOMBA','PUMP','COMPRESOR','COMPRESSOR'})), continue; endif

    estado = estado_bomba_local(eq);
    if any(strcmp(estado, {'APAGADA','OFF','STOPPED'}))
      continue; % head 0, sin advertencia de falta de curva
    endif

    [curva, fuente, adv_res] = resolver_curva_equipo_local(eq);
    for j = 1:numel(adv_res), adv{end+1} = adv_res{j}; endfor %#ok<AGROW>

    if isempty(curva) || ~tiene_curva_util_local(curva)
      adv{end+1} = 'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1'; %#ok<AGROW>
      continue;
    endif

    [h, adv_c, ~] = aos_cad_hidraulica_curva_bomba(curva, Ql, cfg);
    for j = 1:numel(adv_c), adv{end+1} = adv_c{j}; endfor %#ok<AGROW>
    if any(strcmp(adv_c, 'CURVA_INSUFICIENTE_PUNTOS'))
      adv{end+1} = 'EQUIPO_ACTIVO_SIN_CURVA_NO_APORTA_HEAD_DEV1'; %#ok<AGROW>
      continue;
    endif

    head_equipo_m = head_equipo_m + h;
    % dp_equipo negativo = ganancia (no contaminar dp_menores_Pa)
    dp_equipo = dp_equipo - rho * g * h;
    if isempty(fuente), fuente = 'CURVA'; endif %#ok<NASGU>
  endfor
endfunction

function [curva, fuente, adv] = resolver_curva_equipo_local(eq)
  % Precedencia: curva inline > BOMBA_MODELO (catalogo) > sin curva.
  curva = []; fuente = ''; adv = {};

  if isfield(eq, 'curva_bomba') && ~isempty(eq.curva_bomba) && tiene_curva_util_local(eq.curva_bomba)
    curva = eq.curva_bomba;
    fuente = 'INLINE';
    if isstruct(curva) && isfield(curva, 'fuente') && ~isempty(curva.fuente)
      fuente = char(curva.fuente);
    endif
    return;
  endif

  modelo_id = '';
  if isfield(eq, 'bomba_modelo') && ~isempty(eq.bomba_modelo)
    modelo_id = valor_texto_local(eq.bomba_modelo);
  elseif isfield(eq, 'BOMBA_MODELO') && ~isempty(eq.BOMBA_MODELO)
    modelo_id = valor_texto_local(eq.BOMBA_MODELO);
  endif
  if isempty(modelo_id), return; endif

  [curva_cat, adv_cat, info] = aos_cad_hidraulica_catalogo_bombas(modelo_id);
  for j = 1:numel(adv_cat), adv{end+1} = adv_cat{j}; endfor %#ok<AGROW>
  if isstruct(info) && isfield(info, 'encontrada') && info.encontrada ...
      && tiene_curva_util_local(curva_cat)
    curva = curva_cat;
    fuente = 'CATALOGO';
    if isfield(curva_cat, 'fuente') && ~isempty(curva_cat.fuente)
      fuente = char(curva_cat.fuente);
    endif
  endif
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

function estado = estado_bomba_local(eq)
  estado = 'ENCENDIDA';
  if isfield(eq, 'bomba_estado') && ~isempty(eq.bomba_estado)
    estado = upper(char(valor_texto_local(eq.bomba_estado)));
  elseif isfield(eq, 'BOMBA_ESTADO') && ~isempty(eq.BOMBA_ESTADO)
    estado = upper(char(valor_texto_local(eq.BOMBA_ESTADO)));
  elseif isfield(eq, 'estado') && ~isempty(eq.estado)
    estado = upper(char(valor_texto_local(eq.estado)));
  endif
endfunction

function rows = rows_local(s, f)
  rows = {};
  if isstruct(s) && isfield(s, f) && ~isempty(s.(f))
    rows = s.(f); if isstruct(rows), rows = num2cell(rows); endif
  endif
endfunction
function v = getf_local(s, f, d)
  if isstruct(s) && isfield(s, f)
    v = s.(f);
  else
    v = d;
  endif
endfunction
function t = valor_texto_local(v)
  if isstruct(v), v = aos_aoscad_valor(v); endif
  [t, ok] = aos_texto_seguro(v, '');
  if ~ok, t = ''; endif
endfunction

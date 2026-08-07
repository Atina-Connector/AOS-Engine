function V = sens_validar_punto_gl(p, qiny_req, ql, qo, qiny_ef, det, opciones)
% SENS_VALIDAR_PUNTO_GL Decide si un resultado GL puede publicarse.
% Los valores crudos siempre se conservan; los rechazados se publican como NaN.

  if nargin < 7 || ~isstruct(opciones), opciones = struct(); endif
  if nargin < 6 || ~isstruct(det), det = struct(); endif
  if nargin < 1 || ~isstruct(p), p = struct(); endif

  estado = texto_local(det, 'estado', 'SIN_ESTADO');
  estado_u = upper(strtrim(estado));
  preliminar = logico_local(opciones, 'preliminar', false);
  permitir_limite_optimo = logico_local(opciones, 'permitir_limite_optimo', false);

  V = struct('estado', estado, 'convergido', false, 'aceptado', false, ...
    'valido_para_curva', false, 'valido_para_optimo', false, ...
    'es_frontera', false, 'residuo_Pa', NaN, 'tol_residuo_Pa', NaN, ...
    'Ql_max_IPR', NaN, 'motivos_rechazo', {{}}, 'advertencias', {{}}, ...
    'balance', struct(), 'preliminar', preliminar);

  tolP = numero_local(p, 'sens_nodal_tol_P', 0.05e5);
  if isfield(det, 'tol_P') && isnumeric(det.tol_P) && ~isempty(det.tol_P) && isfinite(det.tol_P(1))
    tolP = det.tol_P(1);
  endif
  V.tol_residuo_Pa = max(tolP, 1);

  try
    D = aos_profundidad_inyeccion(p, numero_local(p, 'D_iny', 0));
    [res, bal] = aos_nodal_balance_gl(max(ql, 0), p, max(qiny_req, 0), D);
    V.residuo_Pa = res;
    V.balance = bal;
  catch err
    V.motivos_rechazo{end+1} = ['No se pudo recalcular el residuo nodal: ' err.message];
  end_try_catch

  if isfield(det, 'Ql_max_IPR') && isnumeric(det.Ql_max_IPR) && ~isempty(det.Ql_max_IPR)
    V.Ql_max_IPR = det.Ql_max_IPR(1);
  else
    try
      ip = struct('P_res', numero_local(p,'P_res',0), 'IP', numero_local(p,'IP',0));
      if isfield(p,'P_b'), ip.P_b = p.P_b; endif
      [V.Ql_max_IPR, ~] = ipr(ip, texto_local(p,'modelo_IPR','linear'));
    catch
      V.Ql_max_IPR = NaN;
    end_try_catch
  endif

  es_raiz = any(strcmp(estado_u, {'CRUCE_RESUELTO','CRUCE_APROXIMADO'}));
  es_limite_ipr = strcmp(estado_u, 'LIMITADO_POR_IPR');
  V.convergido = es_raiz;
  V.es_frontera = es_limite_ipr;

  if ~(es_raiz || es_limite_ipr)
    V.motivos_rechazo{end+1} = ['Estado nodal no publicable: ' estado_u '.'];
  endif

  if es_raiz
    if ~isfinite(V.residuo_Pa)
      V.motivos_rechazo{end+1} = 'Residuo nodal no finito.';
    elseif abs(V.residuo_Pa) > V.tol_residuo_Pa * 1.05
      V.motivos_rechazo{end+1} = sprintf('Residuo nodal %.6g Pa supera tolerancia %.6g Pa.', abs(V.residuo_Pa), V.tol_residuo_Pa);
    endif
  elseif es_limite_ipr
    V.advertencias{end+1} = 'Punto limitado por IPR: se muestra como frontera, no como raiz ni optimo interior.';
  endif

  wc = numero_local(p, 'WC', NaN);
  if ~isfinite(wc) || wc < 0 || wc > 1
    V.motivos_rechazo{end+1} = sprintf('WC fuera de dominio [0,1]: %.12g.', wc);
  endif
  if ~isfinite(ql) || ql < -1e-12
    V.motivos_rechazo{end+1} = 'Ql no es finito o es negativo.';
  endif
  if ~isfinite(qo) || qo < -1e-12
    V.motivos_rechazo{end+1} = 'Qo no es finito o es negativo.';
  elseif isfinite(ql) && qo > ql + max(1e-12, 1e-8*max(abs(ql),1))
    V.motivos_rechazo{end+1} = 'Qo supera Ql.';
  endif

  if isfinite(V.Ql_max_IPR) && V.Ql_max_IPR >= 0 && isfinite(ql)
    if ql > V.Ql_max_IPR * (1 + 1e-5) + 1e-12
      V.motivos_rechazo{end+1} = 'Ql supera el maximo de la IPR.';
    endif
  endif

  tq = max(1e-10, 1e-6 * max(abs(qiny_req), 1e-8));
  if ~isfinite(qiny_ef) || abs(qiny_ef - qiny_req) > tq
    V.motivos_rechazo{end+1} = sprintf('Qiny efectivo no coincide con el solicitado (req %.12g, ef %.12g m3/s).', qiny_req, qiny_ef);
  endif

  V.aceptado = isempty(V.motivos_rechazo);
  V.valido_para_curva = V.aceptado;
  V.valido_para_optimo = V.aceptado && V.convergido && ~preliminar;
  if V.es_frontera && ~permitir_limite_optimo
    V.valido_para_optimo = false;
  endif
endfunction

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1))
      v = double(x(1));
    elseif ischar(x)
      y = str2double(x);
      if isfinite(y), v = y; endif
    endif
  endif
endfunction

function t = texto_local(s, campo, defecto)
  t = defecto;
  if isstruct(s) && isfield(s, campo) && ischar(s.(campo)) && ~isempty(s.(campo))
    t = s.(campo);
  endif
endfunction

function tf = logico_local(s, campo, defecto)
  tf = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if islogical(x) && ~isempty(x), tf = x(1); elseif isnumeric(x) && ~isempty(x), tf = x(1) ~= 0; endif
  endif
endfunction

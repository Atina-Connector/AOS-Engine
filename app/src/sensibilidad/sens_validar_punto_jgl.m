function V = sens_validar_punto_jgl(p, qiny_req, sol, opciones)
% SENS_VALIDAR_PUNTO_JGL Decide si un resultado JGL puede publicarse.
% El ultimo iterado de un NO_CONVERGE se conserva como raw, pero no entra
% en la curva ni en el optimizador.

  if nargin < 4 || ~isstruct(opciones), opciones = struct(); endif
  if nargin < 3 || ~isstruct(sol), sol = struct(); endif
  if nargin < 1 || ~isstruct(p), p = struct(); endif

  estado = texto_local(sol, 'estado', 'SIN_ESTADO');
  estado_u = upper(strtrim(estado));
  modo = texto_local(sol, 'modo_utilizado', 'NO_INFORMADO');
  modo_u = upper(strtrim(modo));
  preliminar = logico_local(opciones, 'preliminar', false) || ...
                ~isempty(strfind(modo_u, 'ABREVIADO'));

  ql = numero_local(sol, 'Ql', NaN);
  qo = numero_local(sol, 'Qo', NaN);
  qef = numero_local(sol, 'Qiny', NaN);
  dp = numero_local(sol, 'deltaP', NaN);

  nodal_estado = '';
  if isfield(sol, 'nodal') && isstruct(sol.nodal)
    nodal_estado = texto_local(sol.nodal, 'estado', '');
  endif
  nodal_u = upper(strtrim(nodal_estado));

  V = struct();
  V.estado = estado;
  V.estado_nodal = nodal_estado;
  V.modo = modo;
  V.convergido = false;
  V.aceptado = false;
  V.valido_para_curva = false;
  V.valido_para_optimo = false;
  V.es_frontera = false;
  V.residuo_Pa = NaN;
  V.tol_residuo_Pa = NaN;
  V.Ql_max_IPR = NaN;
  V.motivos_rechazo = {};
  V.advertencias = {};
  V.preliminar = preliminar;
  V.balance = struct();
  V.estado_presion_motriz = 'NO_EVALUADO';
  V.modo_condicion_motriz = 'NO_INFORMADO';
  V.presion_requerida_valida = false;
  V.factibilidad_presion_evaluada = false;
  V.factible_por_presion = false;
  V.presion_apta_para_optimo = true;
  V.P_iny_sup_requerida_Pa = NaN;
  V.P_iny_sup_disponible_Pa = NaN;
  V.margen_presion_superficie_Pa = NaN;

  tol_bar = numero_local(p, 'jgl_tol_P_bar', 0.25);
  V.tol_residuo_Pa = max(0.5e5, 2 * max(tol_bar, 0) * 1e5);

  if isfinite(ql) && isfinite(dp)
    try
      D = aos_profundidad_inyeccion(p, numero_local(p, 'D_iny', 0));
      Ps = calcular_columna_succion(max(ql, 0), p);
      qg_total = max(qiny_req, 0) + max(ql, 0) * max(numero_local(p, 'GLR', 0), 0);
      [Preq, det_vlp] = compute_P_req(p, max(ql, 0), qg_total, D);
      V.residuo_Pa = Ps + dp - Preq;
      V.balance = struct('P_s', Ps, 'P_req', Preq, 'deltaP', dp, ...
                         'residuo', V.residuo_Pa, 'vlp', det_vlp);
    catch err
      V.motivos_rechazo{end+1} = ['No se pudo recalcular el residuo JGL: ' err.message];
    end_try_catch
  endif

  try
    ip = struct('P_res', numero_local(p, 'P_res', 0), ...
                'IP', numero_local(p, 'IP', 0));
    if isfield(p, 'P_b'), ip.P_b = p.P_b; endif
    [V.Ql_max_IPR, ~] = ipr(ip, texto_local(p, 'modelo_IPR', 'linear'));
  catch
    V.Ql_max_IPR = NaN;
  end_try_catch

  qiny_cero = qiny_req <= 1e-12;
  es_natural = any(strcmp(estado_u, {'FLUJO_NATURAL_CALCULADO', 'SIN_FLUJO_NATURAL'}));
  es_raiz_estado = any(strcmp(estado_u, ...
    {'CONVERGIDO', 'CONVERGIDO_NODAL', 'CRUCE_RESUELTO', 'CRUCE_APROXIMADO'}));
  es_raiz_nodal = isempty(nodal_u) || any(strcmp(nodal_u, ...
    {'CONVERGIDO_NODAL', 'CRUCE_RESUELTO', 'CRUCE_APROXIMADO'}));
  es_limite_res = strcmp(estado_u, 'LIMITADO_POR_RESERVORIO') || ...
                  strcmp(nodal_u, 'LIMITADO_POR_RESERVORIO');
  es_limite_vlp = strcmp(estado_u, 'LIMITADO_POR_VLP') || ...
                  strcmp(nodal_u, 'LIMITADO_POR_VLP');

  if qiny_cero && es_natural
    V.convergido = true;
  elseif es_limite_res
    V.es_frontera = true;
    V.advertencias{end+1} = ...
      'Punto limitado por reservorio/IPR: se muestra como frontera y no entra al optimo.';
  elseif es_raiz_estado && es_raiz_nodal
    V.convergido = true;
  else
    V.motivos_rechazo{end+1} = ...
      ['Estado JGL no publicable: ' estado_u ', nodal=' nodal_u '.'];
  endif

  if es_limite_vlp
    V.motivos_rechazo{end+1} = 'No existe cruce nodal por limitacion VLP.';
  endif

  if V.convergido && ~qiny_cero
    if ~isfinite(V.residuo_Pa)
      V.motivos_rechazo{end+1} = 'Residuo JGL no finito.';
    elseif abs(V.residuo_Pa) > V.tol_residuo_Pa
      V.motivos_rechazo{end+1} = sprintf( ...
        'Residuo JGL %.6g Pa supera tolerancia %.6g Pa.', ...
        abs(V.residuo_Pa), V.tol_residuo_Pa);
    endif
  endif

  wc = numero_local(p, 'WC', NaN);
  if ~isfinite(wc) || wc < 0 || wc > 1
    V.motivos_rechazo{end+1} = sprintf('WC fuera de dominio [0,1]: %.12g.', wc);
  endif
  if ~isfinite(ql) || ql < -1e-12
    V.motivos_rechazo{end+1} = 'Ql JGL no es finito o es negativo.';
  endif
  if ~isfinite(qo) || qo < -1e-12
    V.motivos_rechazo{end+1} = 'Qo JGL no es finito o es negativo.';
  elseif isfinite(ql) && qo > ql + max(1e-12, 1e-8 * max(abs(ql), 1))
    V.motivos_rechazo{end+1} = 'Qo JGL supera Ql.';
  endif
  if isfinite(V.Ql_max_IPR) && isfinite(ql) && ...
     ql > V.Ql_max_IPR * (1 + 1e-5) + 1e-12
    V.motivos_rechazo{end+1} = 'Ql JGL supera el maximo de la IPR.';
  endif

  tq = max(1e-10, 1e-6 * max(abs(qiny_req), 1e-8));
  if ~isfinite(qef) || abs(qef - qiny_req) > tq
    V.motivos_rechazo{end+1} = sprintf( ...
      'Qiny JGL efectivo no coincide con solicitado (req %.12g, ef %.12g m3/s).', ...
      qiny_req, qef);
  endif

  if isfield(sol, 'eductor') && isstruct(sol.eductor)
    ee = upper(texto_local(sol.eductor, 'estado', 'SIN_ESTADO_EDUCTOR'));
    if isfield(sol.eductor,'condicion_motriz') && isstruct(sol.eductor.condicion_motriz)
      C = sol.eductor.condicion_motriz;
      V.estado_presion_motriz = texto_local(C,'estado','NO_EVALUADO');
      V.modo_condicion_motriz = texto_local(C,'modo_efectivo','NO_INFORMADO');
      V.presion_requerida_valida = logico_local(C,'presion_requerida_valida',false);
      V.factibilidad_presion_evaluada = logico_local(C,'factibilidad_evaluada',false);
      V.factible_por_presion = logico_local(C,'factible_por_presion',false);
      V.P_iny_sup_requerida_Pa = numero_local(C,'P_iny_sup_requerida_Pa',NaN);
      V.P_iny_sup_disponible_Pa = numero_local(C,'P_iny_sup_disponible_Pa',NaN);
      V.margen_presion_superficie_Pa = numero_local(C,'margen_presion_superficie_Pa',NaN);

      if ~qiny_cero
        modo_pres = upper(V.modo_condicion_motriz);
        if logico_local(C,'bloquea_operacion',false)
          V.motivos_rechazo{end+1} = ['Condicion motriz no factible: ' V.estado_presion_motriz '.'];
        elseif strcmp(modo_pres,'DERIVADA_DESDE_QINY')
          if ~V.factibilidad_presion_evaluada
            V.advertencias{end+1} = ...
              'La presion requerida fue derivada desde Qiny; no se informo presion disponible para verificar factibilidad.';
          elseif ~V.factible_por_presion
            V.advertencias{end+1} = ...
              'El punto es calculable como escenario de diseno, pero supera la presion superficial disponible.';
            V.presion_apta_para_optimo = false;
          endif
        elseif strcmp(modo_pres,'PRESION_DISPONIBLE') && ...
            V.factibilidad_presion_evaluada && ~V.factible_por_presion
          V.motivos_rechazo{end+1} = 'La presion disponible no permite el Qiny solicitado.';
          V.presion_apta_para_optimo = false;
        endif
      endif
    endif
    if qiny_cero
      if ~any(strcmp(ee, {'OK', 'SIN_GAS_MOTRIZ'}))
        V.motivos_rechazo{end+1} = ...
          ['Estado de eductor no valido con Qiny=0: ' ee '.'];
      endif
    elseif ~strcmp(ee, 'OK')
      V.motivos_rechazo{end+1} = ['Estado de eductor no publicable: ' ee '.'];
    endif

    pd = numero_local(sol.eductor, 'pot_disp', NaN);
    pt = numero_local(sol.eductor, 'pot_trans', NaN);
    if isfinite(pd) && isfinite(pt) && pt > pd * (1 + 1e-8)
      V.motivos_rechazo{end+1} = ...
        'Potencia transferida por el eductor supera la disponible.';
    endif
  else
    V.motivos_rechazo{end+1} = 'Solucion JGL sin detalle de eductor.';
  endif

  V.aceptado = isempty(V.motivos_rechazo) && (V.convergido || V.es_frontera);
  V.valido_para_curva = V.aceptado;
  V.valido_para_optimo = V.aceptado && V.convergido && ...
                         ~V.es_frontera && ~preliminar && V.presion_apta_para_optimo;
endfunction

function v = numero_local(s, campo, defecto)
  v = defecto;
  if ~isstruct(s) || ~isfield(s, campo), return; endif
  x = s.(campo);
  if isnumeric(x) && ~isempty(x) && isfinite(x(1))
    v = double(x(1));
  elseif ischar(x)
    y = str2double(x);
    if isfinite(y), v = y; endif
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
  if ~isstruct(s) || ~isfield(s, campo), return; endif
  x = s.(campo);
  if islogical(x) && ~isempty(x)
    tf = x(1);
  elseif isnumeric(x) && ~isempty(x)
    tf = x(1) ~= 0;
  endif
endfunction

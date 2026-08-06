function R = sens_jgl_evaluar_punto(base, qiny, modo, opciones)
% SENS_JGL_EVALUAR_PUNTO Evaluador canonico de un punto JGL.
% Separa el ultimo iterado crudo del valor publicado por sensibilidad.

  if nargin < 4 || ~isstruct(opciones), opciones = struct(); endif
  if nargin < 3 || isempty(modo), modo = 'iterativo'; endif
  if nargin < 2 || isempty(qiny), qiny = 0; endif
  if nargin < 1 || ~isstruct(base), base = struct(); endif

  qiny = max(qiny, 0);
  modo = lower(strtrim(modo));
  if any(strcmp(modo, {'automatico', 'hibrido', 'preciso'}))
    modo = 'iterativo';
  endif
  if any(strcmp(modo, {'simple', 'rapido', 'abreviado', 'movil'}))
    modo = 'directo';
  endif

  p = base;
  n_nodal = numero_local(opciones, 'nodal_n_puntos', ...
                         numero_local(p, 'sens_nodal_n_puntos', 1201));
  n_jgl = numero_local(opciones, 'jgl_n_puntos', ...
                       numero_local(p, 'sens_jgl_n_puntos', 120));
  p.sens_nodal_n_puntos = max(31, min(5001, round(n_nodal)));
  p.sens_jgl_n_puntos = max(31, min(1001, round(n_jgl)));
  p = aos_set_qiny(p, qiny * 86400, 'fijo');
  p = aos_sincronizar_config(p, 'SENS_JGL');
  p = jgl_defaults(p);

  preliminar = logico_local(opciones, 'preliminar', false);
  [firma, firma_texto] = sens_firma_config_gl_jgl(p);

  R = struct();
  R.sistema = 'JGL';
  R.Qiny_solicitado = qiny;
  R.Qiny_efectivo = NaN;
  R.Ql_raw = NaN;
  R.Qo_raw = NaN;
  R.Ql = NaN;
  R.Qo = NaN;
  R.estado = 'ERROR_NO_EJECUTADO';
  R.modo = upper(modo);
  R.convergido = false;
  R.aceptado = false;
  R.valido_para_curva = false;
  R.valido_para_optimo = false;
  R.residuo_Pa = NaN;
  R.motivos_rechazo = {};
  R.advertencias = {};
  R.solucion = struct();
  R.parametros_efectivos = p;
  R.config_firma = firma;
  R.config_firma_texto = firma_texto;
  R.preliminar = preliminar;
  R.estado_presion_motriz = 'NO_EVALUADO';
  R.modo_condicion_motriz = 'NO_INFORMADO';
  R.presion_requerida_valida = false;
  R.factibilidad_presion_evaluada = false;
  R.factible_por_presion = false;
  R.P_iny_sup_requerida_Pa = NaN;
  R.P_iny_sup_disponible_Pa = NaN;
  R.margen_presion_superficie_Pa = NaN;

  try
    if strcmp(modo, 'directo')
      sol = jgl_solver_directo(p, qiny);
    else
      sol = jgl_solver_iterativo(p, qiny);
    endif

    V = sens_validar_punto_jgl(p, qiny, sol, opciones);
    sol.Ql_raw = numero_local(sol, 'Ql', NaN);
    sol.Qo_raw = numero_local(sol, 'Qo', NaN);
    sol.Ql_publicado = NaN;
    sol.Qo_publicado = NaN;
    sol.convergido_sensibilidad = V.convergido;
    sol.aceptado_sensibilidad = V.aceptado;
    sol.valido_para_curva = V.valido_para_curva;
    sol.valido_para_optimo = V.valido_para_optimo;
    sol.residuo_sensibilidad_Pa = V.residuo_Pa;
    sol.motivos_rechazo_sensibilidad = V.motivos_rechazo;
    sol.advertencias_sensibilidad = V.advertencias;
    sol.estado_presion_motriz_sensibilidad = V.estado_presion_motriz;
    sol.modo_condicion_motriz_sensibilidad = V.modo_condicion_motriz;
    sol.presion_requerida_valida_sensibilidad = V.presion_requerida_valida;
    sol.factibilidad_presion_evaluada_sensibilidad = V.factibilidad_presion_evaluada;
    sol.factible_por_presion_sensibilidad = V.factible_por_presion;
    if V.valido_para_curva
      sol.Ql_publicado = sol.Ql_raw;
      sol.Qo_publicado = sol.Qo_raw;
    endif

    R.Qiny_efectivo = numero_local(sol, 'Qiny', NaN);
    R.Ql_raw = sol.Ql_raw;
    R.Qo_raw = sol.Qo_raw;
    R.estado = texto_local(sol, 'estado', 'SIN_ESTADO');
    R.modo = texto_local(sol, 'modo_utilizado', upper(modo));
    R.convergido = V.convergido;
    R.aceptado = V.aceptado;
    R.valido_para_curva = V.valido_para_curva;
    R.valido_para_optimo = V.valido_para_optimo;
    R.residuo_Pa = V.residuo_Pa;
    R.motivos_rechazo = V.motivos_rechazo;
    R.advertencias = V.advertencias;
    R.estado_presion_motriz = V.estado_presion_motriz;
    R.modo_condicion_motriz = V.modo_condicion_motriz;
    R.presion_requerida_valida = V.presion_requerida_valida;
    R.factibilidad_presion_evaluada = V.factibilidad_presion_evaluada;
    R.factible_por_presion = V.factible_por_presion;
    R.P_iny_sup_requerida_Pa = V.P_iny_sup_requerida_Pa;
    R.P_iny_sup_disponible_Pa = V.P_iny_sup_disponible_Pa;
    R.margen_presion_superficie_Pa = V.margen_presion_superficie_Pa;
    if V.valido_para_curva
      R.Ql = sol.Ql_raw;
      R.Qo = sol.Qo_raw;
    endif
    R.solucion = sol;
  catch err
    R.estado = ['ERROR: ' err.message];
    R.motivos_rechazo = {err.message};
    R.solucion = struct('estado', R.estado, 'Ql', NaN, 'Qo', NaN, ...
                        'Qiny', qiny, 'error', err.message);
  end_try_catch
endfunction

function v = numero_local(s, campo, defecto)
  v = defecto;
  if ~isstruct(s) || ~isfield(s, campo), return; endif
  x = s.(campo);
  if isnumeric(x) && ~isempty(x) && isfinite(x(1))
    v = double(x(1));
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

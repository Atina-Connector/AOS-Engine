function R = sens_gl_evaluar_punto(base, qiny, opciones)
% SENS_GL_EVALUAR_PUNTO Evaluador canonico de un punto GL en sensibilidad.
% Usa GL_sim con una fotografia inmutable de configuracion y separa resultado
% crudo de resultado publicable.

  if nargin < 3 || ~isstruct(opciones), opciones = struct(); endif
  if nargin < 2 || isempty(qiny), qiny = 0; endif
  if nargin < 1 || ~isstruct(base), base = struct(); endif
  qiny = max(qiny, 0);

  p = base;
  npts = numero_local(opciones, 'n_puntos', numero_local(p, 'sens_nodal_n_puntos', 1201));
  p.sens_nodal_n_puntos = max(31, min(5001, round(npts)));
  p = aos_set_qiny(p, qiny * 86400, 'fijo');
  p = aos_sincronizar_config(p, 'SENS_GL');

  [firma, firma_texto] = sens_firma_config_gl_jgl(p);
  R = struct('sistema','GL','Qiny_solicitado',qiny,'Qiny_efectivo',NaN, ...
    'Ql_raw',NaN,'Qo_raw',NaN,'Qgas_total_raw',NaN, ...
    'Ql',NaN,'Qo',NaN,'estado','ERROR_NO_EJECUTADO', ...
    'convergido',false,'aceptado',false,'valido_para_curva',false, ...
    'valido_para_optimo',false,'residuo_Pa',NaN, ...
    'motivos_rechazo',{{}},'advertencias',{{}},'diagnostico','', ...
    'detalle',struct(),'parametros_efectivos',p, ...
    'config_firma',firma,'config_firma_texto',firma_texto, ...
    'preliminar',logico_local(opciones,'preliminar',false));

  try
    [ql, qo, qg, qef, diag, det] = GL_sim(p, qiny);
    V = sens_validar_punto_gl(p, qiny, ql, qo, qef, det, opciones);

    R.Qiny_efectivo = qef;
    R.Ql_raw = ql;
    R.Qo_raw = qo;
    R.Qgas_total_raw = qg;
    R.estado = V.estado;
    R.convergido = V.convergido;
    R.aceptado = V.aceptado;
    R.valido_para_curva = V.valido_para_curva;
    R.valido_para_optimo = V.valido_para_optimo;
    R.residuo_Pa = V.residuo_Pa;
    R.motivos_rechazo = V.motivos_rechazo;
    R.advertencias = V.advertencias;
    R.diagnostico = diag;
    det.validacion_sensibilidad = V;
    R.detalle = det;

    if R.valido_para_curva
      R.Ql = ql;
      R.Qo = qo;
    endif
  catch err
    R.estado = ['ERROR: ' err.message];
    R.motivos_rechazo = {err.message};
    R.detalle = struct('error', err.message, 'Qiny_solicitado', qiny);
  end_try_catch
endfunction

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = double(x(1)); endif
  endif
endfunction

function tf = logico_local(s, campo, defecto)
  tf = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if islogical(x) && ~isempty(x), tf = x(1); elseif isnumeric(x) && ~isempty(x), tf = x(1) ~= 0; endif
  endif
endfunction

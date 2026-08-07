function [O, V] = sens_verificar_optimo_polinomico(O, sistema, base, opciones)
% SENS_VERIFICAR_OPTIMO_POLINOMICO Recalcula el candidato con el solver.
% El polinomio solo propone Qiny. La aceptacion final corresponde al mismo
% evaluador canonico utilizado por los puntos de la sensibilidad.

  if nargin < 4 || ~isstruct(opciones), opciones = struct(); endif
  if nargin < 3 || ~isstruct(base), base = struct(); endif
  if nargin < 2 || isempty(sistema), sistema = 'GL'; endif

  V = base_local(sistema);
  % Una llamada accidental desde modo discreto o informativo no debe alterar
  % la recomendacion oficial. En operacion normal esta funcion solo se invoca
  % cuando el usuario eligio POLINOMICO_VERIFICADO.
  if isstruct(O) && isfield(O,'tratamiento_curva') && isstruct(O.tratamiento_curva)
    if ~logico_local(O.tratamiento_curva,'verificar_optimo',false)
      V.estado = 'NO_SOLICITADA';
      O.verificacion_polinomica = V;
      return;
    endif
  endif
  if ~isstruct(O) || ~isfield(O,'candidato_verificacion') || ...
      ~isstruct(O.candidato_verificacion) || ...
      ~isfield(O.candidato_verificacion,'disponible') || ...
      ~O.candidato_verificacion.disponible
    V.estado = 'OPTIMO_POLINOMICO_NO_DISPONIBLE';
    V.motivos_rechazo{end+1} = 'No existe maximo interior por derivada cero apto para verificar.';
    O = restaurar_discreto_local(O, 'OPTIMO_DISCRETO_POLINOMIO_NO_DISPONIBLE');
    O.verificacion_polinomica = V;
    return;
  endif

  C = O.candidato_verificacion;
  q_sm3d = numero_local(C,'qiny_sm3d',NaN);
  if ~isfinite(q_sm3d) || q_sm3d < 0
    V.estado = 'OPTIMO_POLINOMICO_INVALIDO';
    V.motivos_rechazo{end+1} = 'El Qiny estimado no es valido.';
    O = restaurar_discreto_local(O, 'OPTIMO_DISCRETO_POLINOMIO_INVALIDO');
    O.verificacion_polinomica = V;
    return;
  endif
  V.qiny_estimado_sm3d = q_sm3d;
  V.qo_estimado_m3d = numero_local(C,'qo_estimado_m3d',NaN);
  V.ql_estimado_m3d = numero_local(C,'ql_estimado_m3d',NaN);
  q = q_sm3d / 86400;

  try
    if strcmpi(strtrim(sistema),'GL')
      E = sens_gl_evaluar_punto(base, q, opciones);
    else
      modo = texto_local(opciones,'modo','iterativo');
      E = sens_jgl_evaluar_punto(base, q, modo, opciones);
    endif
    V.resultado_solver = E;
    V.estado_solver = texto_local(E,'estado','SIN_ESTADO');
    V.qiny_efectivo_sm3d = numero_local(E,'Qiny_efectivo',NaN) * 86400;
    V.ql_solver_m3d = numero_local(E,'Ql',NaN) * 86400;
    V.qo_solver_m3d = numero_local(E,'Qo',NaN) * 86400;
    V.ql_raw_m3d = numero_local(E,'Ql_raw',NaN) * 86400;
    V.qo_raw_m3d = numero_local(E,'Qo_raw',NaN) * 86400;
    V.residuo_Pa = numero_local(E,'residuo_Pa',NaN);
    V.convergido = logico_local(E,'convergido',false);
    V.aceptado = logico_local(E,'aceptado',false);
    V.valido_para_curva = logico_local(E,'valido_para_curva',false);
    V.valido_para_optimo = logico_local(E,'valido_para_optimo',false);

    V.error_qo_m3d = V.qo_solver_m3d - V.qo_estimado_m3d;
    V.error_ql_m3d = V.ql_solver_m3d - V.ql_estimado_m3d;
    if isfinite(V.qo_estimado_m3d)
      V.error_qo_rel = abs(V.error_qo_m3d) / max(abs(V.qo_estimado_m3d),1e-9);
    endif
    if isfinite(V.ql_estimado_m3d)
      V.error_ql_rel = abs(V.error_ql_m3d) / max(abs(V.ql_estimado_m3d),1e-9);
    endif

    tol_rel = numero_local(opciones,'tolerancia_verificacion_rel',0.05);
    tol_abs = numero_local(opciones,'tolerancia_verificacion_abs_m3d',0.5);
    V.tolerancia_rel = tol_rel;
    V.tolerancia_abs_m3d = tol_abs;
    ajuste_coherente = isfinite(V.qo_solver_m3d) && isfinite(V.qo_estimado_m3d) && ...
      abs(V.error_qo_m3d) <= max(tol_abs, tol_rel*max(abs(V.qo_estimado_m3d),1));
    V.ajuste_coherente = ajuste_coherente;

    if V.valido_para_optimo && V.convergido && ajuste_coherente
      V.estado = 'OPTIMO_POLINOMICO_VERIFICADO';
      V.verificado = true;
      O.recomendado_polinomico_verificado = struct( ...
        'qiny_sm3d',V.qiny_efectivo_sm3d,'ql_m3d',V.ql_solver_m3d, ...
        'qo_m3d',V.qo_solver_m3d,'rendimiento_pct',NaN, ...
        'criterio','MAXIMO_QO_POLINOMICO_DERIVADA_CERO_VERIFICADO_SOLVER');
      O.recomendado = O.recomendado_polinomico_verificado;
      O.estado_recomendacion = 'OPTIMO_POLINOMICO_VERIFICADO';
    elseif V.valido_para_optimo && V.convergido
      V.estado = 'OPTIMO_POLINOMICO_RECHAZADO_POR_DIFERENCIA';
      V.motivos_rechazo{end+1} = 'La corrida fisica difiere del valor polinomico fuera de tolerancia.';
      O = restaurar_discreto_local(O, 'OPTIMO_DISCRETO_POLINOMIO_RECHAZADO_POR_DIFERENCIA');
    else
      V.estado = 'OPTIMO_POLINOMICO_NO_VERIFICADO';
      V.motivos_rechazo{end+1} = 'La corrida fisica no convergio o no es valida para optimo.';
      O = restaurar_discreto_local(O, 'OPTIMO_DISCRETO_POLINOMIO_NO_VERIFICADO');
    endif
  catch err
    V.estado = 'OPTIMO_POLINOMICO_ERROR_VERIFICACION';
    V.motivos_rechazo{end+1} = err.message;
    O = restaurar_discreto_local(O, 'OPTIMO_DISCRETO_ERROR_VERIFICACION_POLINOMICA');
  end_try_catch

  O.verificacion_polinomica = V;
endfunction

function O = restaurar_discreto_local(O, estado)
  tiene_discreto = false;
  if isstruct(O) && isfield(O,'recomendado_discreto') && isstruct(O.recomendado_discreto) && ...
      isfield(O.recomendado_discreto,'qiny_sm3d') && isfinite(O.recomendado_discreto.qiny_sm3d)
    O.recomendado = O.recomendado_discreto;
    tiene_discreto = true;
  endif
  if tiene_discreto
    O.estado_recomendacion = estado;
  else
    O.recomendado = struct();
    actual = texto_local(O,'estado_recomendacion','');
    if isempty(strfind(actual,'OPTIMO_NO_DISPONIBLE'))
      O.estado_recomendacion = strrep(estado,'OPTIMO_DISCRETO','OPTIMO_NO_DISPONIBLE');
    endif
  endif
endfunction

function V = base_local(sistema)
  V = struct('schema','AOS_POLYNOMIAL_OPTIMUM_VERIFICATION_1.0', ...
    'hotfix','SENS-GLJGL-02','sistema',upper(strtrim(sistema)), ...
    'estado','NO_EVALUADO','verificado',false,'qiny_estimado_sm3d',NaN, ...
    'qiny_efectivo_sm3d',NaN,'ql_estimado_m3d',NaN,'qo_estimado_m3d',NaN, ...
    'ql_solver_m3d',NaN,'qo_solver_m3d',NaN,'ql_raw_m3d',NaN,'qo_raw_m3d',NaN, ...
    'error_ql_m3d',NaN,'error_qo_m3d',NaN,'error_ql_rel',NaN,'error_qo_rel',NaN, ...
    'residuo_Pa',NaN,'estado_solver','NO_EVALUADO','convergido',false, ...
    'aceptado',false,'valido_para_curva',false,'valido_para_optimo',false, ...
    'ajuste_coherente',false,'tolerancia_rel',NaN,'tolerancia_abs_m3d',NaN, ...
    'resultado_solver',struct(),'motivos_rechazo',{{}},'advertencias',{{}});
endfunction
function v = numero_local(s,c,d),v=d;if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=double(s.(c)(1));endif,endfunction
function t = texto_local(s,c,d),t=d;if isstruct(s)&&isfield(s,c)&&ischar(s.(c))&&~isempty(s.(c)),t=s.(c);endif,endfunction
function tf = logico_local(s,c,d),tf=d;if isstruct(s)&&isfield(s,c),x=s.(c);if islogical(x)&&~isempty(x),tf=x(1);elseif isnumeric(x)&&~isempty(x),tf=x(1)~=0;endif;endif,endfunction

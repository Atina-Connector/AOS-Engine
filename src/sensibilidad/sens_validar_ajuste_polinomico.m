function V = sens_validar_ajuste_polinomico(Aql, Aqo, Ar, cfg)
% SENS_VALIDAR_AJUSTE_POLINOMICO Valida el conjunto Ql/Qo/rendimiento.
% No corrige ni recorta la curva. Solo declara uso informativo u optimizable.

  if nargin < 4 || ~isstruct(cfg), cfg = struct(); endif
  if nargin < 3 || ~isstruct(Ar), Ar = struct(); endif
  V = struct('schema','AOS_POLYNOMIAL_VALIDATION_1.0','hotfix','SENS-GLJGL-02', ...
    'estado','NO_EVALUADO','apto_informativo',false, ...
    'apto_para_optimizacion',false,'motivos_rechazo',{{}}, ...
    'advertencias',{{}},'limites_fisicos_ok',false, ...
    'coherencia_ql_qo_ok',false,'discontinuidad',false);

  if ~es_fit_local(Aql) || ~es_fit_local(Aqo)
    V.estado = 'AJUSTES_INSUFICIENTES';
    V.motivos_rechazo{end+1} = 'Ql y Qo requieren ajustes informativos validos.';
    return;
  endif

  V.apto_informativo = Aql.apto_informativo && Aqo.apto_informativo;
  V.discontinuidad = Aql.discontinuidad || Aqo.discontinuidad;
  if V.discontinuidad
    V.advertencias{end+1} = 'El ajuste usa un segmento continuo y no une ramas separadas.';
  endif

  xmin = max(Aql.dominio_min,Aqo.dominio_min);
  xmax = min(Aql.dominio_max,Aqo.dominio_max);
  if ~(isfinite(xmin) && isfinite(xmax) && xmax > xmin)
    V.estado = 'DOMINIOS_SIN_INTERSECCION';
    V.motivos_rechazo{end+1} = 'Ql y Qo no comparten un dominio polinomico.';
    return;
  endif
  x = linspace(xmin,xmax,301);
  ql = polyval(Aql.coeficientes_normalizados,(x-Aql.x_centro)/Aql.x_escala);
  qo = polyval(Aqo.coeficientes_normalizados,(x-Aqo.x_centro)/Aqo.x_escala);
  tol = max(1e-6, numero_local(cfg,'tolerancia_m3d',1e-4)*max([max(abs(ql)),max(abs(qo)),1]));

  if any(ql < -tol)
    V.motivos_rechazo{end+1} = 'El polinomio de Ql produce caudales negativos.';
  endif
  if any(qo < -tol)
    V.motivos_rechazo{end+1} = 'El polinomio de Qo produce caudales negativos.';
  endif
  if any(qo > ql + tol)
    V.motivos_rechazo{end+1} = 'El polinomio viola Qo <= Ql.';
  else
    V.coherencia_ql_qo_ok = true;
  endif

  qmax = numero_local(cfg,'Ql_max_m3d',Inf);
  if isfinite(qmax) && any(ql > qmax*(1+1e-5)+tol)
    V.motivos_rechazo{end+1} = 'El polinomio de Ql supera el maximo de la IPR.';
  endif

  V.limites_fisicos_ok = isempty(V.motivos_rechazo);
  aptos_individuales = Aql.apto_para_optimizacion && Aqo.apto_para_optimizacion;
  if isstruct(Ar) && isfield(Ar,'apto_informativo') && Ar.apto_informativo && ...
      isfield(Ar,'apto_para_optimizacion') && ~Ar.apto_para_optimizacion
    V.advertencias{end+1} = 'El ajuste de rendimiento es solo informativo.';
  endif

  V.apto_para_optimizacion = V.apto_informativo && aptos_individuales && ...
    V.limites_fisicos_ok && ~V.discontinuidad;
  if V.apto_para_optimizacion
    V.estado = 'ACEPTADO_PARA_OPTIMIZACION';
  elseif V.apto_informativo
    V.estado = 'ACEPTADO_SOLO_INFORMATIVO';
  else
    V.estado = 'RECHAZADO';
  endif
endfunction

function tf = es_fit_local(A)
  tf = isstruct(A) && isfield(A,'apto_informativo') && A.apto_informativo && ...
       isfield(A,'coeficientes_normalizados') && ~isempty(A.coeficientes_normalizados);
endfunction
function v = numero_local(s,c,d),v=d;if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=double(s.(c)(1));endif,endfunction

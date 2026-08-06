function R = jgl_sensibilidad_parametrica(parametros, qiny_vals, modo)
% JGL_SENSIBILIDAD_PARAMETRICA Malla JGL uniforme y auditable.
% SENS-GLJGL-03 conserva el metodo uniforme e incorpora el contrato de
% presion motriz requerida/disponible por punto.
% Cada curva publicada usa un unico metodo y una unica resolucion.
%
% modo:
%   iterativo / preciso  -> iterativo uniforme, resultado final
%   automatico / hibrido -> iterativo uniforme, resultado final conservador
%   directo / simple     -> directo uniforme, resultado preliminar
%   abreviado / movil    -> directo uniforme reducido, resultado preliminar

  if nargin < 3 || isempty(modo), modo = 'automatico'; endif
  modo_solicitado = lower(strtrim(modo));
  qiny_vals = qiny_vals(:)';
  n = numel(qiny_vals);

  if isstruct(parametros)
    p0 = parametros;
    parametros = cell(1,n);
    for i = 1:n, parametros{i} = p0; endfor
  endif
  if ~iscell(parametros) || numel(parametros) ~= n
    error('jgl_sensibilidad_parametrica: parametros y qiny_vals deben tener igual cantidad de puntos.');
  endif

  if any(strcmp(modo_solicitado, {'iterativo','preciso','automatico','hibrido'}))
    metodo_final = 'iterativo';
    nodal_n = 1201;
    jgl_n = 120;
    preliminar = false;
    if any(strcmp(modo_solicitado, {'automatico','hibrido'}))
      etiqueta_modo = 'SENS01_AUTOMATICO_ITERATIVO_UNIFORME';
    else
      etiqueta_modo = 'SENS01_ITERATIVO_UNIFORME';
    endif
  elseif any(strcmp(modo_solicitado, {'directo','rapido','simple'}))
    metodo_final = 'directo';
    nodal_n = 1201;
    jgl_n = 120;
    preliminar = true;
    etiqueta_modo = 'SENS01_DIRECTO_UNIFORME_PRELIMINAR';
  else
    metodo_final = 'directo';
    nodal_n = 121;
    jgl_n = 81;
    preliminar = true;
    etiqueta_modo = 'SENS01_ABREVIADO_DIRECTO_UNIFORME_PRELIMINAR';
  endif

  soluciones = cell(1,n);
  ql = NaN(1,n); qo = NaN(1,n);
  ql_raw = NaN(1,n); qo_raw = NaN(1,n);
  dp = NaN(1,n); iter = zeros(1,n); qef = NaN(1,n);
  estados = cell(1,n); modos = cell(1,n);
  convergido = false(1,n); aceptado = false(1,n);
  valido_curva = false(1,n); valido_optimo = false(1,n);
  residuo = NaN(1,n); motivos = cell(1,n); advertencias = cell(1,n);
  firmas = cell(1,n);
  Ps_motriz = NaN(1,n); dP_motriz_req = NaN(1,n);
  Pm_req = NaN(1,n); Pm_disp = NaN(1,n); Pm_ef = NaN(1,n);
  Psup_req = NaN(1,n); Psup_disp = NaN(1,n); Psup_ef = NaN(1,n);
  dP_col = NaN(1,n); dP_fric = NaN(1,n); margen_sup = NaN(1,n);
  presion_valida = false(1,n); fact_eval = false(1,n);
  factible_presion = NaN(1,n); estado_presion = cell(1,n);
  modo_presion = cell(1,n); origen_presion = cell(1,n);

  for i = 1:n
    opts = struct('nodal_n_puntos',nodal_n,'jgl_n_puntos',jgl_n,'preliminar',preliminar);
    E = sens_jgl_evaluar_punto(parametros{i},max(qiny_vals(i),0),metodo_final,opts);
    s = E.solucion;
    s.modo_utilizado = etiqueta_modo;
    s.preliminar_sensibilidad = preliminar;
    soluciones{i} = s;

    ql(i) = E.Ql;
    qo(i) = E.Qo;
    ql_raw(i) = E.Ql_raw;
    qo_raw(i) = E.Qo_raw;
    qef(i) = E.Qiny_efectivo;
    estados{i} = E.estado;
    modos{i} = etiqueta_modo;
    convergido(i) = E.convergido;
    aceptado(i) = E.aceptado;
    valido_curva(i) = E.valido_para_curva;
    valido_optimo(i) = E.valido_para_optimo;
    residuo(i) = E.residuo_Pa;
    motivos{i} = E.motivos_rechazo;
    advertencias{i} = E.advertencias;
    firmas{i} = E.config_firma;
    if isstruct(s)
      if isfield(s,'deltaP'), dp(i) = s.deltaP; endif
      if isfield(s,'iteraciones'), iter(i) = s.iteraciones; endif
      Ps_motriz(i) = numero_local(s,'P_succion_eductor',NaN);
      dP_motriz_req(i) = numero_local(s,'deltaP_motriz_requerida',NaN);
      Pm_req(i) = numero_local(s,'P_motriz_fondo_requerida',NaN);
      Pm_disp(i) = numero_local(s,'P_motriz_fondo_disponible',NaN);
      Pm_ef(i) = numero_local(s,'P_motriz_fondo_efectiva',NaN);
      Psup_req(i) = numero_local(s,'P_iny_sup_requerida',NaN);
      Psup_disp(i) = numero_local(s,'P_iny_sup_disponible',NaN);
      Psup_ef(i) = numero_local(s,'P_iny_sup_efectiva',NaN);
      dP_col(i) = numero_local(s,'deltaP_columna_gas_requerida',NaN);
      dP_fric(i) = numero_local(s,'deltaP_friccion_inyeccion',NaN);
      margen_sup(i) = numero_local(s,'margen_presion_superficie',NaN);
      presion_valida(i) = logico_local(s,'presion_requerida_valida_sensibilidad', ...
        logico_local(s,'presion_requerida_valida',isfinite(Psup_req(i))));
      fact_eval(i) = logico_local(s,'factibilidad_presion_evaluada_sensibilidad', ...
        logico_local(s,'factibilidad_presion_evaluada',false));
      if fact_eval(i)
        factible_presion(i) = double(logico_local(s,'factible_por_presion_sensibilidad', ...
          logico_local(s,'factible_por_presion',false)));
      endif
      estado_presion{i} = texto_local(s,'estado_presion_motriz','NO_EVALUADO');
      modo_presion{i} = texto_local(s,'modo_condicion_motriz','NO_INFORMADO');
      if isfield(s,'condicion_motriz') && isstruct(s.condicion_motriz)
        origen_presion{i} = texto_local(s.condicion_motriz,'origen_presion','NO_DEFINIDO');
      else
        origen_presion{i} = 'NO_DEFINIDO';
      endif
    endif
  endfor

  R = struct();
  R.qiny_solicitado = qiny_vals;
  R.qiny_efectivo = qef;
  R.soluciones = soluciones;
  R.seleccion_iterativa = repmat(strcmp(metodo_final,'iterativo'), 1, n);
  R.Ql = ql;
  R.Qo = qo;
  R.Ql_raw = ql_raw;
  R.Qo_raw = qo_raw;
  R.deltaP = dp;
  R.iteraciones = iter;
  R.estados = estados;
  R.modos = modos;
  R.error_directo_iterativo = NaN(1,n);
  R.modo_solicitado = upper(modo_solicitado);
  R.modo_final_uniforme = upper(metodo_final);
  R.preliminar = preliminar;
  R.convergido = convergido;
  R.aceptado = aceptado;
  R.valido_para_curva = valido_curva;
  R.valido_para_optimo = valido_optimo;
  R.residuo_Pa = residuo;
  R.motivos_rechazo = motivos;
  R.advertencias = advertencias;
  R.config_firma = firmas;
  R.P_succion_eductor = Ps_motriz;
  R.deltaP_motriz_requerida = dP_motriz_req;
  R.P_motriz_fondo_requerida = Pm_req;
  R.P_motriz_fondo_disponible = Pm_disp;
  R.P_motriz_fondo_efectiva = Pm_ef;
  R.P_iny_sup_requerida = Psup_req;
  R.P_iny_sup_disponible = Psup_disp;
  R.P_iny_sup_efectiva = Psup_ef;
  R.deltaP_columna_gas_requerida = dP_col;
  R.deltaP_friccion_inyeccion = dP_fric;
  R.margen_presion_superficie = margen_sup;
  R.presion_requerida_valida = presion_valida;
  R.factibilidad_presion_evaluada = fact_eval;
  R.factible_por_presion = factible_presion;
  R.estado_presion_motriz = estado_presion;
  R.modo_condicion_motriz = modo_presion;
  R.origen_presion_motriz = origen_presion;
  R.politica = 'SENS-GLJGL-03_METODO_UNIFORME_CONDICION_MOTRIZ_EXPLICITA';
  R.abreviado = struct('activo',preliminar,'metodo',etiqueta_modo, ...
                       'valido_para_optimo',false);
endfunction

function v = numero_local(s,c,d)
  v = d;
  if isstruct(s) && isfield(s,c)
    x = s.(c);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = double(x(1)); endif
  endif
endfunction

function tf = logico_local(s,c,d)
  tf = d;
  if isstruct(s) && isfield(s,c)
    x = s.(c);
    if islogical(x) && ~isempty(x), tf = x(1);
    elseif isnumeric(x) && ~isempty(x) && isfinite(x(1)), tf = x(1) ~= 0;
    endif
  endif
endfunction

function t = texto_local(s,c,d)
  t = d;
  if isstruct(s) && isfield(s,c) && ischar(s.(c)) && ~isempty(s.(c)), t = s.(c); endif
endfunction


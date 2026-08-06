function R = sens_jgl_gl_malla(parametros, qiny_vals, modo_jgl)
% SENS_JGL_GL_MALLA Ejecuta la misma configuracion y el mismo Qiny en JGL y GL.
% SENS-GLJGL-03:
% - JGL usa un metodo uniforme en toda la curva.
% - GL usa el evaluador canonico con malla completa.
% - Resultados no convergidos se conservan como raw y se publican como NaN.

  if nargin < 3 || isempty(modo_jgl), modo_jgl = 'automatico'; endif
  qiny_vals = qiny_vals(:)';
  n = numel(qiny_vals);

  if isstruct(parametros)
    p0 = parametros;
    parametros = cell(1,n);
    for i = 1:n, parametros{i} = p0; endfor
  endif
  if ~iscell(parametros) || numel(parametros) ~= n
    error('sens_jgl_gl_malla: parametros y qiny_vals deben tener igual cantidad de puntos.');
  endif

  RJ = jgl_sensibilidad_parametrica(parametros,qiny_vals,modo_jgl);

  ql_gl = NaN(1,n); qo_gl = NaN(1,n);
  ql_gl_raw = NaN(1,n); qo_gl_raw = NaN(1,n);
  qg_gl = NaN(1,n); qiny_gl = NaN(1,n);
  qg_form_gl = NaN(1,n); qg_total_vlp_gl = NaN(1,n);
  p_req_gl = NaN(1,n); p_s_gl = NaN(1,n); residuo_gl = NaN(1,n);
  estado_gl = cell(1,n); detalle_gl = cell(1,n);
  convergido_gl = false(1,n); aceptado_gl = false(1,n);
  valido_curva_gl = false(1,n); valido_optimo_gl = false(1,n);
  motivos_gl = cell(1,n); advertencias_gl = cell(1,n); firmas_gl = cell(1,n);

  for i = 1:n
    q = max(qiny_vals(i),0);
    E = sens_gl_evaluar_punto(parametros{i},q,struct('n_puntos',1201,'preliminar',false));
    ql_gl(i) = E.Ql;
    qo_gl(i) = E.Qo;
    ql_gl_raw(i) = E.Ql_raw;
    qo_gl_raw(i) = E.Qo_raw;
    qg_gl(i) = E.Qgas_total_raw;
    qiny_gl(i) = E.Qiny_efectivo;
    estado_gl{i} = E.estado;
    convergido_gl(i) = E.convergido;
    aceptado_gl(i) = E.aceptado;
    valido_curva_gl(i) = E.valido_para_curva;
    valido_optimo_gl(i) = E.valido_para_optimo;
    residuo_gl(i) = E.residuo_Pa;
    motivos_gl{i} = E.motivos_rechazo;
    advertencias_gl{i} = E.advertencias;
    firmas_gl{i} = E.config_firma;
    det = E.detalle;
    det.diagnostico = E.diagnostico;
    detalle_gl{i} = det;
    if isfield(det,'balance_solucion') && isstruct(det.balance_solucion)
      b = det.balance_solucion;
      if isfield(b,'Qg_inyectado_std'), qiny_gl(i) = b.Qg_inyectado_std; endif
      if isfield(b,'Qg_formacion_std'), qg_form_gl(i) = b.Qg_formacion_std; endif
      if isfield(b,'Qg_total_std'), qg_total_vlp_gl(i) = b.Qg_total_std; endif
      if isfield(b,'P_req'), p_req_gl(i) = b.P_req; endif
      if isfield(b,'P_s'), p_s_gl(i) = b.P_s; endif
    endif
  endfor

  R = struct();
  R.qiny_solicitado = qiny_vals;
  R.jgl = RJ;
  R.Ql_JGL = RJ.Ql;
  R.Qo_JGL = RJ.Qo;
  R.Ql_JGL_raw = RJ.Ql_raw;
  R.Qo_JGL_raw = RJ.Qo_raw;
  R.Ql_GL = ql_gl;
  R.Qo_GL = qo_gl;
  R.Ql_GL_raw = ql_gl_raw;
  R.Qo_GL_raw = qo_gl_raw;
  R.Qgas_GL = qg_gl;
  R.qiny_efectivo_GL = qiny_gl;
  R.Qg_formacion_GL = qg_form_gl;
  R.Qg_total_VLP_GL = qg_total_vlp_gl;
  R.P_req_GL = p_req_gl;
  R.P_s_GL = p_s_gl;
  R.residuo_GL_Pa = residuo_gl;
  R.estado_GL = estado_gl;
  R.estados_GL = estado_gl;
  R.detalle_GL = detalle_gl;
  R.convergido_GL = convergido_gl;
  R.aceptado_GL = aceptado_gl;
  R.valido_para_curva_GL = valido_curva_gl;
  R.valido_para_optimo_GL = valido_optimo_gl;
  R.motivos_rechazo_GL = motivos_gl;
  R.advertencias_GL = advertencias_gl;
  R.config_firma_GL = firmas_gl;
  R.deltaP_JGL = RJ.deltaP;
  R.iteraciones_JGL = RJ.iteraciones;
  R.modos_JGL = RJ.modos;
  R.estados_JGL = RJ.estados;
  R.error_directo_iterativo = RJ.error_directo_iterativo;
  R.seleccion_iterativa = RJ.seleccion_iterativa;
  R.convergido_JGL = RJ.convergido;
  R.aceptado_JGL = RJ.aceptado;
  R.valido_para_curva_JGL = RJ.valido_para_curva;
  R.valido_para_optimo_JGL = RJ.valido_para_optimo;
  R.residuo_JGL_Pa = RJ.residuo_Pa;
  R.motivos_rechazo_JGL = RJ.motivos_rechazo;
  R.advertencias_JGL = RJ.advertencias;
  R.modo_solicitado_JGL = RJ.modo_solicitado;
  R.modo_final_uniforme_JGL = RJ.modo_final_uniforme;
  R.preliminar_JGL = RJ.preliminar;
  R.preliminar = RJ.preliminar;
  R.config_firma_JGL = RJ.config_firma;
  R.P_succion_eductor_JGL = RJ.P_succion_eductor;
  R.deltaP_motriz_requerida_JGL = RJ.deltaP_motriz_requerida;
  R.P_motriz_fondo_requerida_JGL = RJ.P_motriz_fondo_requerida;
  R.P_motriz_fondo_disponible_JGL = RJ.P_motriz_fondo_disponible;
  R.P_motriz_fondo_efectiva_JGL = RJ.P_motriz_fondo_efectiva;
  R.P_iny_sup_requerida_JGL = RJ.P_iny_sup_requerida;
  R.P_iny_sup_disponible_JGL = RJ.P_iny_sup_disponible;
  R.P_iny_sup_efectiva_JGL = RJ.P_iny_sup_efectiva;
  R.deltaP_columna_gas_requerida_JGL = RJ.deltaP_columna_gas_requerida;
  R.deltaP_friccion_inyeccion_JGL = RJ.deltaP_friccion_inyeccion;
  R.margen_presion_superficie_JGL = RJ.margen_presion_superficie;
  R.presion_requerida_valida_JGL = RJ.presion_requerida_valida;
  R.factibilidad_presion_evaluada_JGL = RJ.factibilidad_presion_evaluada;
  R.factible_por_presion_JGL = RJ.factible_por_presion;
  R.estado_presion_motriz_JGL = RJ.estado_presion_motriz;
  R.modo_condicion_motriz_JGL = RJ.modo_condicion_motriz;
  R.origen_presion_motriz_JGL = RJ.origen_presion_motriz;
  R.aceptado = RJ.aceptado & aceptado_gl;
  R.valido_para_curva = RJ.valido_para_curva & valido_curva_gl;
  R.valido_para_optimo = RJ.valido_para_optimo & valido_optimo_gl;
  R.politica = 'SENS-GLJGL-03_PARIDAD_PUBLICACION_Y_PRESION_MOTRIZ';
endfunction

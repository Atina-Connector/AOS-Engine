function s = jgl_armar_solucion(p, Q, Qiny, e, modo, estado)
% JGL_ARMAR_SOLUCION Construye el resultado canonico y auditable JGL.
  p = jgl_defaults(p);
  s = struct();
  s.modo_utilizado = modo;
  s.estado = estado;
  s.Ql = max(Q,0);
  s.Qo = s.Ql * (1-p.WC);
  s.Qw = s.Ql * p.WC;
  s.Qiny = max(Qiny,0);
  s.Qgas_total = s.Qiny + s.Ql * p.GLR;
  s.eductor = e;
  s.deltaP = e.deltaP;
  s.Ps = e.Ps;
  s.Pd = e.Pd;
  s.Pm = e.Pm;
  if isfield(e,'condicion_motriz') && isstruct(e.condicion_motriz)
    C = e.condicion_motriz;
  else
    C = jgl_condicion_motriz(p,Qiny,e.Ps);
  endif
  s.condicion_motriz = C;
  s.P_succion_eductor = valor_num(C,'P_succion_Pa',e.Ps);
  s.deltaP_motriz_requerida = valor_num(C,'deltaP_motriz_requerida_Pa',NaN);
  s.P_motriz_fondo_requerida = valor_num(C,'P_motriz_fondo_requerida_Pa',NaN);
  s.P_motriz_fondo_disponible = valor_num(C,'P_motriz_fondo_disponible_Pa',NaN);
  s.P_motriz_fondo_efectiva = valor_num(C,'P_motriz_fondo_efectiva_Pa',e.Pm);
  s.P_iny_sup_requerida = valor_num(C,'P_iny_sup_requerida_Pa',NaN);
  s.P_iny_sup_disponible = valor_num(C,'P_iny_sup_disponible_Pa',NaN);
  s.P_iny_sup_efectiva = valor_num(C,'P_iny_sup_efectiva_Pa',NaN);
  s.deltaP_columna_gas_requerida = valor_num(C,'deltaP_columna_gas_requerida_Pa',NaN);
  s.deltaP_friccion_inyeccion = valor_num(C,'deltaP_friccion_inyeccion_Pa',NaN);
  s.margen_presion_superficie = valor_num(C,'margen_presion_superficie_Pa',NaN);
  s.factibilidad_presion_evaluada = valor_logico(C,'factibilidad_evaluada',false);
  s.factible_por_presion = valor_logico(C,'factible_por_presion',false);
  s.estado_presion_motriz = valor_txt(C,'estado','NO_EVALUADO');
  s.modo_condicion_motriz = valor_txt(C,'modo_efectivo','NO_INFORMADO');
  s.potencia_disponible = e.pot_disp;
  s.potencia_transferida = e.pot_trans;
  s.eficiencia = e.eta;
  s.entrainment = e.entrainment;
  s.iteraciones = 0;
  s.verificado_iterativo = false;

  s.audit = struct();
  s.audit.Qiny_solicitado = max(Qiny,0);
  s.audit.Qiny_efectivo = s.Qiny;
  s.audit.Qg_formacion_std = s.Ql * p.GLR;
  s.audit.Qg_total_std = s.Qgas_total;
  s.audit.GLR_efectivo = p.GLR;
  s.audit.IP_efectivo = valor_num(p,'IP',NaN);
  s.audit.P_res_efectiva = valor_num(p,'P_res',NaN);
  s.audit.P_wh_efectiva = valor_num(p,'P_wh',NaN);
  s.audit.P_iny_sup_importada = valor_num(C,'P_iny_sup_importada_Pa', ...
    valor_num(p,'P_iny_sup',NaN));
  s.audit.P_iny_sup_configurada = valor_num(C,'P_iny_sup_configurada_Pa', ...
    valor_num(p,'P_iny_sup',NaN));
  s.audit.P_iny_sup_requerida = s.P_iny_sup_requerida;
  s.audit.P_iny_sup_disponible = s.P_iny_sup_disponible;
  s.audit.P_iny_sup_efectiva = s.P_iny_sup_efectiva;
  s.audit.P_motriz_fondo_requerida = s.P_motriz_fondo_requerida;
  s.audit.P_motriz_fondo_disponible = s.P_motriz_fondo_disponible;
  s.audit.P_motriz_fondo_efectiva = s.P_motriz_fondo_efectiva;
  s.audit.deltaP_motriz_requerida = s.deltaP_motriz_requerida;
  s.audit.deltaP_columna_gas_requerida = s.deltaP_columna_gas_requerida;
  s.audit.deltaP_friccion_inyeccion = s.deltaP_friccion_inyeccion;
  s.audit.margen_presion_superficie = s.margen_presion_superficie;
  s.audit.factibilidad_presion_evaluada = s.factibilidad_presion_evaluada;
  s.audit.factible_por_presion = s.factible_por_presion;
  s.audit.estado_presion_motriz = s.estado_presion_motriz;
  s.audit.modo_condicion_motriz = s.modo_condicion_motriz;
  s.audit.D_iny_efectiva = valor_num(p,'D_iny',NaN);
  s.audit.A_n_efectiva = valor_num(p,'A_n',NaN);
  s.audit.d_t_efectivo = valor_num(p,'d_t',NaN);
  s.audit.deltaP_aplicado = s.deltaP;
  s.audit.Ps = s.Ps;
  s.audit.Pd = s.Pd;
  s.audit.Pm = s.Pm;
  s.audit.potencia_disponible = s.potencia_disponible;
  s.audit.potencia_transferida = s.potencia_transferida;
end

function v = valor_num(p,c,d)
  v = d;
  if isstruct(p) && isfield(p,c)
    x = p.(c);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); end
  end
end


function v = valor_logico(p,c,d)
  v = d;
  if isstruct(p) && isfield(p,c)
    x = p.(c);
    if islogical(x) && ~isempty(x), v = x(1); return; endif
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1) ~= 0; endif
  endif
end

function v = valor_txt(p,c,d)
  v = d;
  if isstruct(p) && isfield(p,c) && ischar(p.(c)) && ~isempty(p.(c))
    v = p.(c);
  endif
end

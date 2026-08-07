function C = jgl_condicion_motriz(p, Qiny, P_s)
% JGL_CONDICION_MOTRIZ Contrato auditable de presion motriz JGL.
% SENS-GLJGL-03 separa:
%   - presion superficial disponible/importada;
%   - presion motriz minima requerida por Qiny y tobera;
%   - presion efectiva utilizada por el eductor;
%   - columna compresible, perdidas y margen de factibilidad.
%
% No reemplaza silenciosamente P_iny_sup. La derivacion desde Qiny solo se
% activa cuando jgl_condicion_motriz_modo=DERIVADA_DESDE_QINY.

  if nargin < 1 || ~isstruct(p), p = struct(); endif
  if nargin < 2 || isempty(Qiny), Qiny = 0; endif
  if nargin < 3 || isempty(P_s) || ~isfinite(P_s), P_s = 1e5; endif
  p = jgl_defaults(p);
  Qiny = max(Qiny,0);
  P_s = max(P_s,1e5);

  modo = jgl_modo_condicion_motriz(p);
  [dP_req, det_tobera] = jgl_deltaP_cinetica_qiny(P_s,Qiny,p);
  if ~isfinite(dP_req), dP_req = NaN; endif
  Pm_req = P_s + dP_req;

  P_sup_configurada = numero_local(p,'P_iny_sup',NaN);
  P_sup_importada = numero_local(p,'P_iny_sup_importada_original',P_sup_configurada);
  if ~isfinite(P_sup_configurada) || P_sup_configurada <= 0
    P_sup_disponible = NaN;
  else
    P_sup_disponible = P_sup_configurada;
  endif

  [Pm_cero, det_col] = jgl_presion_motriz_fondo(p,Qiny,0); %#ok<ASGLU>
  factor_col = numero_local(det_col,'factor_columna',NaN);
  dP_fric = numero_local(det_col,'deltaP_friccion_Pa',NaN);
  if ~isfinite(factor_col) || factor_col <= 0
    factor_col = NaN;
  endif

  if isfinite(Pm_req) && isfinite(factor_col) && isfinite(dP_fric)
    P_sup_req = max((Pm_req + dP_fric) / factor_col, 0);
    dP_col_req = max(P_sup_req * (factor_col - 1), 0);
  else
    P_sup_req = NaN;
    dP_col_req = NaN;
  endif

  if isfinite(P_sup_disponible)
    [Pm_disp, det_disp] = jgl_presion_motriz_fondo(p,Qiny,P_sup_disponible);
    dP_col_disp = numero_local(det_disp,'deltaP_columna_Pa',NaN);
  else
    Pm_disp = NaN;
    dP_col_disp = NaN;
  endif

  tol_bar = numero_local(p,'jgl_tol_presion_factibilidad_bar',0.10);
  tol_Pa = max(tol_bar,0) * 1e5;
  fact_eval = isfinite(P_sup_disponible) && isfinite(P_sup_req);
  if fact_eval
    factible = P_sup_disponible + tol_Pa >= P_sup_req;
    margen_sup = P_sup_disponible - P_sup_req;
    margen_fondo = Pm_disp - Pm_req;
  else
    factible = false;
    margen_sup = NaN;
    margen_fondo = NaN;
  endif

  C = struct();
  C.schema = 'AOS_JGL_MOTIVE_PRESSURE_1.0';
  C.hotfix = 'SENS-GLJGL-03';
  C.modo_solicitado = modo;
  C.modo_efectivo = modo;
  C.estado = 'NO_EVALUADO';
  C.origen_presion = 'NO_DEFINIDO';
  C.Qiny_std_m3_s = Qiny;
  C.P_succion_Pa = P_s;
  C.deltaP_motriz_requerida_Pa = dP_req;
  C.P_motriz_fondo_requerida_Pa = Pm_req;
  C.P_motriz_fondo_disponible_Pa = Pm_disp;
  C.P_motriz_fondo_efectiva_Pa = NaN;
  C.P_iny_sup_importada_Pa = P_sup_importada;
  C.P_iny_sup_configurada_Pa = P_sup_configurada;
  C.P_iny_sup_disponible_Pa = P_sup_disponible;
  C.P_iny_sup_requerida_Pa = P_sup_req;
  C.P_iny_sup_efectiva_Pa = NaN;
  C.factor_columna = factor_col;
  C.deltaP_columna_gas_requerida_Pa = dP_col_req;
  C.deltaP_columna_gas_disponible_Pa = dP_col_disp;
  C.deltaP_friccion_inyeccion_Pa = dP_fric;
  C.margen_presion_superficie_Pa = margen_sup;
  C.margen_presion_fondo_Pa = margen_fondo;
  C.factibilidad_evaluada = fact_eval;
  C.factible_por_presion = factible;
  C.presion_requerida_valida = isfinite(P_sup_req) && isfinite(Pm_req);
  C.bloquea_operacion = false;
  C.detalle_tobera = det_tobera;

  if Qiny <= 1e-12
    C.P_motriz_fondo_efectiva_Pa = Pm_req;
    C.P_iny_sup_efectiva_Pa = P_sup_req;
    C.estado = 'QINY_CERO_PRESION_ESTATICA_REQUERIDA';
    C.origen_presion = 'BALANCE_ESTATICO_SIN_GAS_MOTRIZ';
    return;
  endif

  if ~C.presion_requerida_valida
    C.estado = 'PRESION_REQUERIDA_NO_CALCULABLE';
    C.bloquea_operacion = true;
    return;
  endif

  switch modo
    case 'DERIVADA_DESDE_QINY'
      C.P_motriz_fondo_efectiva_Pa = Pm_req;
      C.P_iny_sup_efectiva_Pa = P_sup_req;
      C.origen_presion = 'DERIVADA_DESDE_QINY_Y_TOBERA';
      if ~fact_eval
        C.estado = 'QINY_FORZADO_PRESION_DERIVADA_FACTIBILIDAD_NO_EVALUADA';
      elseif factible
        C.estado = 'QINY_FORZADO_PRESION_DERIVADA_FACTIBLE';
      else
        C.estado = 'QINY_FORZADO_PRESION_DERIVADA_SUPERA_DISPONIBLE';
      endif

    case 'PRESION_DISPONIBLE'
      C.P_motriz_fondo_efectiva_Pa = Pm_disp;
      C.P_iny_sup_efectiva_Pa = P_sup_disponible;
      C.origen_presion = 'P_INY_SUP_INFORMADA';
      if ~fact_eval
        C.estado = 'SIN_PRESION_MOTRIZ_INFORMADA';
        C.bloquea_operacion = true;
      elseif factible
        C.estado = 'QINY_FORZADO_PRESION_VERIFICADA';
      else
        C.estado = 'QINY_NO_FACTIBLE_POR_PRESION';
        C.bloquea_operacion = true;
      endif

    case 'AUTO_LEGACY'
      if isfinite(Pm_disp) && Pm_disp >= Pm_req
        C.P_motriz_fondo_efectiva_Pa = Pm_disp;
        C.P_iny_sup_efectiva_Pa = P_sup_disponible;
        C.origen_presion = 'AUTO_LEGACY_PRESION_DISPONIBLE';
      else
        C.P_motriz_fondo_efectiva_Pa = Pm_req;
        C.P_iny_sup_efectiva_Pa = P_sup_req;
        C.origen_presion = 'AUTO_LEGACY_QINY_DERIVADO';
      endif
      C.estado = 'AUTO_LEGACY';

    otherwise
      C.P_motriz_fondo_efectiva_Pa = 0;
      C.P_iny_sup_efectiva_Pa = 0;
      C.origen_presion = 'CERO_FISICO_CONFIRMADO';
      C.estado = 'SIN_PRESION_MOTRIZ';
      C.bloquea_operacion = true;
  endswitch
endfunction

function v = numero_local(s,c,d)
  v = d;
  if isstruct(s) && isfield(s,c)
    x = s.(c);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1))
      v = double(x(1));
    endif
  endif
endfunction

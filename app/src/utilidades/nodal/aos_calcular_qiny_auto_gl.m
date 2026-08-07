function [Q_iny, detalle] = aos_calcular_qiny_auto_gl(param, D_iny)
% AOS_CALCULAR_QINY_AUTO_GL Caudal de inyeccion por presion/orificio.
% Devuelve Q_iny en m3/s estandar y un detalle trazable. Esta rutina comun
% evita que GL y JGL usen caudales distintos en una misma sensibilidad.
% GNU Octave objetivo.

  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || isempty(D_iny)
    D_iny = aos_profundidad_inyeccion(param, 1500);
  end
  detalle = struct('estado','NO_EVALUADO','P_valv',NaN,'P_down',NaN, ...
                   'T_valv',NaN,'D_iny',D_iny,'Qiny',0);
  Q_iny = 0;

  P_iny_sup = getnum(param,'P_iny_sup',0);
  T_sup = normalizar_TK(getnum(param,'T_sup',298.15));
  T_fondo = normalizar_TK(getnum(param,'T_fondo',358.15));
  rho_g_std = max(getnum(param,'rho_g_std',0.8),1e-12);
  gamma_g = max(getnum(param,'gamma_g',0.7),0.05);
  d_orif = getnum(param,'d_orif',0.012);
  C_d = getnum(param,'C_d_orif',0.85);
  delta_P_ap = getnum(param,'delta_P_apertura',5e5);
  R_especifica = getnum(param,'R_gas',519.6);

  if P_iny_sup <= 0 || D_iny < 0 || d_orif <= 0
    detalle.estado = 'SIN_CONDICION_DE_INYECCION';
    return;
  end

  survey = [];
  if isfield(param,'survey') && isstruct(param.survey), survey = param.survey; end
  TVD_iny = D_iny;
  if ~isempty(survey)
    try, TVD_iny = aos_tvd_at_md(survey,D_iny); catch, end
  end

  Z = getnum(param,'Z_gas_inyeccion',0.85);
  R_universal = 8.314462618;
  M_g = gamma_g * 0.028967;
  T_prom = 0.5*(T_sup+T_fondo);
  P_valv = P_iny_sup * exp(M_g*9.81*TVD_iny/(max(Z,0.2)*R_universal*max(T_prom,200)));
  if ~isempty(survey) && isfield(survey,'TVD') && ~isempty(survey.TVD)
    T_valv = T_sup + (T_fondo-T_sup)*TVD_iny/max(max(survey.TVD),1);
  else
    D_res = max(getnum(param,'D_res',max(D_iny,1)),1);
    T_valv = T_sup + (T_fondo-T_sup)*TVD_iny/D_res;
  end
  P_down = max(P_valv-delta_P_ap,1e5);

  detalle.P_valv = P_valv;
  detalle.P_down = P_down;
  detalle.T_valv = T_valv;
  if P_valv <= P_down || P_valv <= 1e5
    detalle.estado = 'SIN_MARGEN_DE_PRESION';
    return;
  end

  try
    mdot = thornhill_craver(P_valv,P_down,T_valv,d_orif,R_especifica,1.30,C_d);
    Q_iny = max(mdot/rho_g_std,0);
    detalle.Qiny = Q_iny;
    if Q_iny > 0, detalle.estado='CALCULADO'; else, detalle.estado='SIN_CAUDAL'; end
  catch err
    detalle.estado = ['ERROR: ',err.message];
    Q_iny = 0;
  end
end

function T = normalizar_TK(T)
  if ~isfinite(T) || T <= 0, T=300; end
  if T < 150, T=T+273.15; end
end

function v = getnum(s,c,d)
  v=d;
  if isstruct(s) && isfield(s,c)
    x=s.(c);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v=x(1); end
  end
end

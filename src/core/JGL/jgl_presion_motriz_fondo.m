function [Pm, detalle] = jgl_presion_motriz_fondo(p,Qiny,P_sup)
% JGL_PRESION_MOTRIZ_FONDO Propaga la presion superficial al eductor.
% SENS-GLJGL-03 agrega un segundo resultado auditable y permite indicar una
% P_sup alternativa para invertir exactamente el mismo modelo de columna.
%
% Modelo heredado conservado:
%   Pm = P_sup * factor_columna - deltaP_friccion

  if nargin < 1 || ~isstruct(p), p = struct(); endif
  if nargin < 2 || isempty(Qiny), Qiny = 0; endif
  p = jgl_defaults(p);
  if nargin < 3 || isempty(P_sup)
    P_sup = p.P_iny_sup;
  endif
  if ~isnumeric(P_sup) || isempty(P_sup)
    P_sup = NaN;
  else
    P_sup = double(P_sup(1));
  endif
  Qiny = max(Qiny,0);

  T1 = p.T_sup;
  T2 = p.T_fondo;
  if T1 < 150, T1 = T1 + 273.15; endif
  if T2 < 150, T2 = T2 + 273.15; endif
  gamma = 0.7;
  if isfield(p,'gamma_g') && isnumeric(p.gamma_g) && ~isempty(p.gamma_g) && isfinite(p.gamma_g(1))
    gamma = p.gamma_g(1);
  endif
  M = max(gamma * 0.028967,0.002);
  Z = 0.85;
  if isfield(p,'Z') && isnumeric(p.Z) && ~isempty(p.Z) && isfinite(p.Z(1)) && p.Z(1) > 0
    Z = p.Z(1);
  endif
  R = 8.314462618;
  T = max((T1+T2)/2,200);
  D = max(numero_local(p,'D_iny',0),0);
  factor = exp(M * 9.81 * D / (Z * R * T));

  k = max(numero_local(p,'jgl_k_perdida_gas',0),0);
  dP_fric = k * Qiny^2;

  if isfinite(P_sup) && P_sup >= 0
    P_estatica_fondo = P_sup * factor;
    Pm = max(P_estatica_fondo - dP_fric,0);
    dP_col = max(P_estatica_fondo - P_sup,0);
  else
    P_estatica_fondo = NaN;
    Pm = NaN;
    dP_col = NaN;
  endif

  detalle = struct();
  detalle.schema = 'AOS_JGL_GAS_COLUMN_1.0';
  detalle.P_sup_Pa = P_sup;
  detalle.P_estatica_fondo_Pa = P_estatica_fondo;
  detalle.P_motriz_fondo_Pa = Pm;
  detalle.factor_columna = factor;
  detalle.deltaP_columna_Pa = dP_col;
  detalle.deltaP_friccion_Pa = dP_fric;
  detalle.k_perdida_gas = k;
  detalle.D_iny_m = D;
  detalle.gamma_g = gamma;
  detalle.M_kg_mol = M;
  detalle.Z = Z;
  detalle.T_prom_K = T;
  detalle.Qiny_std_m3_s = Qiny;
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

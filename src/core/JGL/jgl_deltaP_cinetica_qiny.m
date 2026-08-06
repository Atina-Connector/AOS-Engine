function [dP, detalle] = jgl_deltaP_cinetica_qiny(P_s, Qiny, param)
% JGL_DELTAP_CINETICA_QINY Diferencial motriz minimo asociado al Qiny.
% Qiny se expresa en m3/s estandar y P_s en Pa. La formulacion conserva la
% aproximacion historica de AOS utilizada por eductor_jgl.

  if nargin < 3 || ~isstruct(param), param = struct(); endif
  if nargin < 2 || isempty(Qiny), Qiny = 0; endif
  if nargin < 1 || isempty(P_s) || ~isfinite(P_s), P_s = 1e5; endif
  P_s = max(P_s,1e5);
  Qiny = max(Qiny,0);

  A_n = numero_local(param,'A_n',12e-6);
  eta_n = numero_local(param,'eta_n',0.98);
  rho_g_std = numero_local(param,'rho_g_std',0.8);
  T_fondo = numero_local(param,'T_fondo',358.15);
  if T_fondo < 150, T_fondo = T_fondo + 273.15; endif

  detalle = struct('estado','OK','P_s',P_s,'Qiny_std_m3_s',Qiny, ...
    'A_n_m2',A_n,'eta_n',eta_n,'rho_g_std',rho_g_std, ...
    'T_fondo_K',T_fondo,'Q_local_m3_s',NaN,'velocidad_tobera_m_s',NaN, ...
    'rho_g_local_kg_m3',NaN,'deltaP_cinetico_Pa',NaN);

  if Qiny <= 1e-12
    dP = 0;
    detalle.estado = 'QINY_CERO';
    detalle.Q_local_m3_s = 0;
    detalle.velocidad_tobera_m_s = 0;
    detalle.rho_g_local_kg_m3 = rho_g_std * (P_s/101325) * (288.15/T_fondo);
    detalle.deltaP_cinetico_Pa = 0;
    return;
  endif
  if ~isfinite(A_n) || A_n <= 0 || ~isfinite(rho_g_std) || rho_g_std <= 0
    dP = NaN;
    detalle.estado = 'GEOMETRIA_O_DENSIDAD_INVALIDA';
    return;
  endif

  Q_local = Qiny * (101325 / P_s) * (T_fondo / 288.15);
  v_n = Q_local / A_n;
  rho_local = rho_g_std * (P_s / 101325) * (288.15 / T_fondo);
  dP = max(0.5 * rho_local * v_n^2 * max(eta_n,0), 0);

  detalle.Q_local_m3_s = Q_local;
  detalle.velocidad_tobera_m_s = v_n;
  detalle.rho_g_local_kg_m3 = rho_local;
  detalle.deltaP_cinetico_Pa = dP;
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

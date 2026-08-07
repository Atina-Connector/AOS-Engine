function tub = gibbs3_tubing_motion(param, F_bomba_N)
% GIBBS3_TUBING_MOTION Modelo elastico cuasiestatico de tuberia.
%
% Convencion de signos GF3:
%   - desplazamiento axial positivo: hacia arriba;
%   - elongacion del tubing: magnitud positiva;
%   - el extremo inferior de una tuberia libre se desplaza hacia abajo,
%     por lo que u_fondo_m = -elongacion_m.
%
% La tuberia no se integra como una segunda ecuacion de onda y no modifica
% las cargas del solver de varillas. La variacion ciclica se obtiene de la
% carga de bomba:
%
%   elongacion_max = DeltaF * L / (E * A_metal)
%   elongacion(t)  = elongacion_max * lambda(t)
%   u_fondo(t)     = -elongacion(t)
%
% x_tuberia_m se conserva como alias historico de la elongacion positiva.
% No debe utilizarse como posicion axial firmada del barril.

  F = F_bomba_N(:);
  n = numel(F);

  OD = param.OD_tuberia_mm * 1e-3;
  ID = param.ID_tuberia_mm * 1e-3;
  A = pi/4 * (OD^2 - ID^2);
  if ~isfinite(A) || A <= 0
    error('Geometria de tubing invalida: OD e ID no producen area positiva.');
  endif

  if isfield(param, 'longitud_tuberia_m') && ...
      isfinite(param.longitud_tuberia_m) && param.longitud_tuberia_m > 0
    L = param.longitud_tuberia_m;
  elseif isfield(param, 'D_bomba') && isfinite(param.D_bomba) && ...
      param.D_bomba > 0
    L = param.D_bomba;
  else
    error('No se pudo definir una longitud valida de tubing.');
  endif

  if ~isfinite(param.E_tuberia_Pa) || param.E_tuberia_Pa <= 0
    error('Modulo elastico de tubing invalido.');
  endif

  rigidez = param.E_tuberia_Pa * A / L;
  if ~isfinite(rigidez) || rigidez <= 0
    error('Rigidez axial de tubing invalida.');
  endif

  tub = struct();
  tub.anclada = logical(param.tuberia_anclada);
  tub.modelo = 'elongacion_elastica_carga_bomba_signo_fisico';
  tub.convencion_signo = 'desplazamiento_positivo_hacia_arriba';
  tub.schema_signo = 'GF3_TUBING_SIGN_1_8';
  tub.x_tuberia_m = zeros(n,1);       % alias legacy: elongacion positiva
  tub.elongacion_m = zeros(n,1);      % magnitud positiva
  tub.u_fondo_m = zeros(n,1);         % posicion axial firmada del barril
  tub.lambda_carga = zeros(n,1);
  tub.delta_max_m = 0.0;
  tub.area_metal_m2 = A;
  tub.longitud_m = L;
  tub.fuerza_variable_N = 0.0;
  tub.rigidez_axial_N_m = rigidez;

  if tub.anclada
    tub.modelo = 'tuberia_anclada_sin_movimiento';
    return;
  endif

  if isempty(F) || any(~isfinite(F))
    error('La carga de bomba para calcular tubing contiene NaN o Inf.');
  endif

  Fmin = min(F);
  Fmax = max(F);
  dF = Fmax - Fmin;

  if dF > eps(max(max(abs(F)), 1))
    lambda = (F - Fmin) / dF;
  else
    lambda = zeros(size(F));
  endif
  lambda = min(max(lambda, 0), 1);

  delta_max = dF / rigidez;
  if ~isfinite(delta_max) || delta_max < 0
    error('La elongacion calculada del tubing es invalida.');
  endif

  elongacion = delta_max .* lambda;
  u_fondo = -elongacion;

  tub.x_tuberia_m = elongacion;
  tub.elongacion_m = elongacion;
  tub.u_fondo_m = u_fondo;
  tub.lambda_carga = lambda;
  tub.delta_max_m = delta_max;
  tub.fuerza_variable_N = dF;
endfunction

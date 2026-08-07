function [V_real, V_eros, V_carga, alerta, regimenes] = velocidad_critica(survey, Qgas_std, P_wh, T_sup, T_fondo, Ql)
  % velocidad_critica.m
  % Wrapper compatible con versiones anteriores.
  %
  % La logica detallada vive ahora en calcular_perfil_tuberia_produccion.m,
  % para que JGL, GL, BES, BM y sistemas futuros usen el mismo criterio.
  %
  % Qgas_std: caudal de gas a condiciones estandar (m3/s). En llamadas viejas
  % puede representar gas inyectado o gas total; aqui se usa como gas total.

  if nargin < 6 || isempty(Ql), Ql = 0; end
  if nargin < 5 || isempty(T_fondo), T_fondo = 358.15; end
  if nargin < 4 || isempty(T_sup), T_sup = 298.15; end
  if nargin < 3 || isempty(P_wh), P_wh = 10e5; end
  if nargin < 2 || isempty(Qgas_std), Qgas_std = 0; end

  param = struct();
  param.P_wh = P_wh;
  param.T_sup = T_sup;
  param.T_fondo = T_fondo;
  param.GLR = 0;
  param.survey = survey;

  opciones = struct();
  opciones.Qgas_form_std = max(Qgas_std, 0);
  opciones.Qgas_total_std = max(Qgas_std, 0);
  opciones.D_inyeccion = NaN;

  perfil = calcular_perfil_tuberia_produccion(param, survey, Ql, 0, opciones);
  V_real = perfil.Vsg;
  V_eros = perfil.V_eros;
  V_carga = perfil.V_carga;
  alerta = perfil.alerta;
  regimenes = perfil.regimenes;
end

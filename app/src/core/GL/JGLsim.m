function [Q_l, Q_o, Q_gas_total, Q_iny] = JGLsim(param)
% JGLsim.m – Wrapper para JGL_core (JGL unificado)
% Compatible con los módulos de sensibilidad.
%
% Entradas:
%   param : estructura de parámetros (igual que para JGL_core)
%
% Salidas:
%   Q_l, Q_o, Q_gas_total, Q_iny : caudales en m³/s estándar

    [Q_l, Q_o, Q_gas_total, Q_iny, ~, ~] = JGL_core(param);
end

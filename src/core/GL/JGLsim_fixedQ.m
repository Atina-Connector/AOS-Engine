function [Q_l, Q_o, Q_gas_total, Q_iny] = JGLsim_fixedQ(param, Q_iny)
% JGLsim_fixedQ.m – Wrapper con caudal fijo para JGL_core.
% Usa el motor JGL unificado (JGL_core) para mantener consistencia.

    % Forzar el caudal de inyección
    param.Q_iny = Q_iny;
    
    [Q_l, Q_o, Q_gas_total, Q_iny_out, ~, ~] = JGL_core(param);
    
    % Devolver el caudal de inyección que se usó
    Q_iny = Q_iny_out;
end

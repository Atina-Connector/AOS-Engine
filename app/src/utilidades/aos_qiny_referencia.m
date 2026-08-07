function [q_m3s, fuente] = aos_qiny_referencia(p)
% AOS_QINY_REFERENCIA Devuelve el Qiny configurado de referencia.
% Usa el normalizador transversal de aliases historicos.
  [q_m3s, ~, fuente] = aos_resolver_qiny_configurado(p);
endfunction

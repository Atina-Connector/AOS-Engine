function [carta_sup, carta_fondo, resumen] = generar_tabla_cartas(cinematica, varillas, param)
  % generar_tabla_cartas.m - Compatibilidad historica.
  if nargin < 3, param = struct(); end
  [carta_sup, carta_fondo, ~, ~, resumen] = ecuacion_onda_gibbs(cinematica, varillas, param);
end

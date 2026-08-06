function P_s = presion_succion(Ql, param)
  % Presión de succión en la profundidad del eductor JGL.
  % Ahora utiliza la función unificada calcular_columna_succion.
  % Se mantiene por compatibilidad con llamadas existentes.
  P_s = calcular_columna_succion(Ql, param);
end

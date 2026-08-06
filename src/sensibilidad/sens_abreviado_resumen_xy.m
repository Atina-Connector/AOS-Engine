function A = sens_abreviado_resumen_xy(x,y,etiqueta)
% Ajuste auxiliar para visualizacion y auditoria. No cambia valores solver.
  if nargin<3, etiqueta='respuesta'; end
  A=sens_abreviado_seleccionar(x,y);
  if strcmp(A.estado,'OK')
    fprintf('\nModo abreviado %s: grado %d, RMS %.6g, puntos de control %d/%d.\n', ...
      etiqueta,A.grado,A.rms,sum(A.seleccion),numel(x));
  else
    fprintf('\nModo abreviado %s: %s.\n',etiqueta,A.estado);
  end
end

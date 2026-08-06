function sens_abreviado_imprimir(R,nsol)
  if nargin<2, nsol=NaN; end
  if ~isstruct(R)||~isfield(R,'abreviado')||~isstruct(R.abreviado)||~isfield(R.abreviado,'estado'), return; end
  A=R.abreviado;
  fprintf('\n--- RESUMEN MODO ABREVIADO ---\n');
  fprintf('Puntos de malla          : %d\n',nsol);
  fprintf('Grado polinomico elegido : %d\n',A.grado);
  fprintf('Error RMS auxiliar       : %.6g\n',A.rms);
  fprintf('Puntos verificados       : %d\n',sum(A.seleccion));
  fprintf('Uso del polinomio        : seleccion de puntos; no reemplaza resultados fisicos.\n');
end

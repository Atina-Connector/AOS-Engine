function aos_imprimir_reparaciones(reporte, x)
% Imprime trazabilidad de reparaciones de discontinuidades locales.
  if nargin < 1 || isempty(reporte) || ~isstruct(reporte) || ~isfield(reporte, 'n') || reporte.n <= 0
      return;
  end
  if nargin < 2, x = []; end
  fprintf('\n--- POSTPROCESO DE SENSIBILIDAD: %s ---\n', reporte.nombre);
  fprintf('Puntos reparados por discontinuidad numerica local: %d\n', reporte.n);
  for k = 1:reporte.n
      idx = reporte.indices(k);
      if ~isempty(x) && idx <= length(x)
          fprintf('  i=%d, x=%.4g: %.4g -> %.4g (%s)\n', idx, x(idx), reporte.valor_original(k), reporte.valor_corregido(k), reporte.metodos{k});
      else
          fprintf('  i=%d: %.4g -> %.4g (%s)\n', idx, reporte.valor_original(k), reporte.valor_corregido(k), reporte.metodos{k});
      end
  end
  fprintf('La curva cruda se conserva en variables *_raw cuando el script las genera.\n');
end

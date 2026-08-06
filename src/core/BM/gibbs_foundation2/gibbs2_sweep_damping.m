function delta_elegido = gibbs2_sweep_damping(param)
  % Barrido interactivo de δ, con figuras separadas.
  if nargin < 1 || ~isstruct(param), param = struct(); end
  param = gibbs2_defaults(param);
  fprintf('\n=== BARRIDO DE AMORTIGUAMIENTO (δ) GF2 ===\n');
  delta_ini = 0.50; delta_fin = 0.02;
  fprintf('Rango actual: %.3f a %.3f\n', delta_ini, delta_fin);
  if aos_preguntar_sn('Modificar rango? (s/n) [n]: ', false)
      val = input(sprintf('Inicio [%.3f]: ', delta_ini));
      if ~isempty(val) && isnumeric(val) && val>=0, delta_ini = val; end
      val = input(sprintf('Fin [%.3f]: ', delta_fin));
      if ~isempty(val) && isnumeric(val) && val>=0, delta_fin = val; end
  end
  deltas = linspace(delta_ini, delta_fin, 8);
  for i = 1:length(deltas)
      delta_i = deltas(i);
      fprintf('  δ = %.3f ...', delta_i);
      try
          p = param; p.gibbs2_delta_damping = delta_i;
          res = gibbs2_run_case(p, struct('graficar',false,'imprimir',false));
          pos = res.promedio.u_superficie_m;
          carga = res.promedio.F_superficie_N/1000;
          figure('Name',sprintf('δ=%.3f',delta_i));
          plot(pos, carga, 'b-', 'LineWidth',1.8); grid on;
          xlabel('Posición PR (m)'); ylabel('Carga sup. (kN)');
          title(sprintf('δ = %.3f', delta_i));
          fprintf(' OK\n');
      catch err
          fprintf(' ERROR: %s\n', err.message);
      end
  end
  resp = aos_preguntar_sn('Fijar nuevo delta? (s/n) [n]: ',false);
  if resp
      val = input(sprintf('Nuevo δ [%.3f]: ', param.gibbs2_delta_damping));
      delta_elegido = param.gibbs2_delta_damping;
      if ~isempty(val) && isnumeric(val) && val>=0, delta_elegido = val; end
  else
      delta_elegido = NaN;
  end
end

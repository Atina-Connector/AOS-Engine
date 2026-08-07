function R = jgl_sensibilidad_ejecutar(p, Qvals, modo)
% Ejecuta una sensibilidad Qiny usando el mismo motor parametrico de malla.
  if nargin < 3 || isempty(modo), modo = 'automatico'; end
  Qvals = Qvals(:)';
  P = cell(1, numel(Qvals));
  for i = 1:numel(Qvals)
      P{i} = p;
  end
  R = jgl_sensibilidad_parametrica(P, Qvals, modo);
  R.Qiny = Qvals; % compatibilidad con consumidores anteriores
end

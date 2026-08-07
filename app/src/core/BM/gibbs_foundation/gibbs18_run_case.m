function resultado = gibbs18_run_case(param, opciones)
% Ejecuta el caso foundation v18 completo.
  if nargin < 2 || ~isstruct(opciones), opciones = struct(); end
  if ~isfield(opciones,'graficar'), opciones.graficar = false; end
  if ~isfield(opciones,'imprimir'), opciones.imprimir = true; end
  param = gibbs18_defaults(param);
  malla = gibbs18_build_rod_mesh(param);
  resultado = gibbs18_solver_forward(param, malla);
  resultado = gibbs18_postprocess(resultado);
  if opciones.imprimir, gibbs18_print(resultado); end
  if opciones.graficar, gibbs18_plot(resultado); end
end

function sol = jgl_solver_directo(p, Qiny)
% JGL_SOLVER_DIRECTO Una pasada rapida de la misma fisica comun.
% GNU Octave es el entorno objetivo.

  p = jgl_defaults(p);
  Qiny = max(Qiny, 0);

  [Qgl, ~, ~, ~, diagnostico_gl] = GL_sim(p, Qiny);
  Ps_gl = calcular_columna_succion(max(Qgl,1e-12), p);

  if Qiny <= 1e-12
    e = jgl_eductor_estado_aplicado(p, Qgl, 0, Ps_gl, 0, 'QINY_CERO');
    if Qgl > 1e-10
      estado = 'FLUJO_NATURAL_CALCULADO';
    else
      estado = 'SIN_FLUJO_NATURAL';
    end
    sol = jgl_armar_solucion(p, Qgl, 0, e, 'DIRECTO', estado);
    sol.diagnostico = diagnostico_gl;
    sol.iteraciones = 0;
    sol.historial = [];
    sol.error_directo_iterativo = NaN;
    sol.confianza = jgl_confianza(p, sol);
    return;
  end

  e0 = jgl_eductor_comun(p, max(Qgl,1e-12), Qiny, Ps_gl);
  [Q, det_nodal] = jgl_resolver_nodal_deltaP(p, Qiny, e0.deltaP);
  Ps = calcular_columna_succion(max(Q,1e-12), p);
  e = jgl_eductor_estado_aplicado(p, Q, Qiny, Ps, e0.deltaP, 'DIRECTO_UNA_PASADA');

  estado = det_nodal.estado;
  if ~strcmp(e.estado,'OK')
    estado = e.estado;
  end
  sol = jgl_armar_solucion(p, Q, Qiny, e, 'DIRECTO', estado);
  sol.diagnostico = diagnostico_gl;
  sol.nodal = det_nodal;
  sol.iteraciones = 1;
  sol.historial = [];
  sol.error_directo_iterativo = NaN;
  sol.confianza = jgl_confianza(p, sol);
end

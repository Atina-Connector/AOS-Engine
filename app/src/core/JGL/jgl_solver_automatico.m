function sol = jgl_solver_automatico(p, Qiny)
% JGL_SOLVER_AUTOMATICO Directo para explorar e iterativo para confirmar.
% GNU Octave es el entorno objetivo.

  p = jgl_defaults(p);
  Qiny = max(Qiny,0);
  directo = jgl_solver_directo(p,Qiny);

  % Qiny=0 no contiene una aproximacion de eductor que deba verificarse.
  if Qiny <= 1e-12
    sol = directo;
    sol.modo_utilizado = 'AUTOMATICO_DIRECTO_QINY_CERO';
    return;
  end

  if strcmp(directo.confianza.nivel,'ALTA') && ...
     any(strcmp(directo.estado,{'CONVERGIDO_NODAL','CONVERGIDO'}))
    sol = directo;
    sol.modo_utilizado = 'AUTOMATICO_DIRECTO';
    return;
  end

  iterativo = jgl_solver_iterativo(p,Qiny);
  iterativo.verificado_iterativo = true;
  iterativo.error_directo_iterativo = abs(directo.Ql-iterativo.Ql) / max(abs(iterativo.Ql),1e-12);
  iterativo.resultado_directo = directo;
  iterativo.modo_utilizado = 'AUTOMATICO_ITERATIVO';
  iterativo.confianza = jgl_confianza(p,iterativo);
  sol = iterativo;
end

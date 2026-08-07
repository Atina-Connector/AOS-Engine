function res = gibbs2_solver_forward(param, malla)
  param = gibbs2_defaults(param);
  modo = param.gibbs2_modo_solver;
  if strcmpi(modo,'automatico')
      if param.N_velocidad <= param.gibbs2_spm_limite_cuasiestatico
          modo_resuelto = 'cuasiestatico';
      else
          modo_resuelto = 'dinamico';
      end
  else, modo_resuelto = modo; end
  if strcmpi(modo_resuelto,'cuasiestatico')
      res = gibbs2_solver_quasi_static(param, malla);
  else
      res = gibbs2_solver_dynamic(param, malla);
  end
  res.modo_solver_resuelto = modo_resuelto;
end

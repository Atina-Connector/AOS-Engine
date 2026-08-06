function res = gibbs2_run_case(param)
  param = gibbs2_defaults(param);
  malla = gibbs2_build_rod_mesh(param);
  res = gibbs2_solver_forward(param, malla);
  res = gibbs2_postprocess(res);
  gibbs2_print(res);
  gibbs2_plot(res);
end

function ok = test_sens_gljgl03_limite_presion()
% El limite por presion se interpola dentro del barrido y nunca extrapola.
  ok = false;
  x = [0 1000 2000 3000];
  req = [10 20 30 40];
  disp = [25 25 25 25];
  L = sens_jgl_limite_presion(x,req,disp);
  assert(L.evaluado);
  assert(strcmp(L.estado,'LIMITE_INTERPOLADO_EN_EL_BARRIDO'));
  assert(abs(L.Qiny_max_presion_Sm3_d - 1500) < 1e-10);
  assert(L.n_factibles == 2);

  L2 = sens_jgl_limite_presion(x,req,NaN(size(x)));
  assert(~L2.evaluado);
  assert(strcmp(L2.estado,'PRESION_DISPONIBLE_NO_INFORMADA'));
  assert(isnan(L2.Qiny_max_presion_Sm3_d));

  L3 = sens_jgl_limite_presion(x,req,[50 50 50 50]);
  assert(strcmp(L3.estado,'TODO_EL_BARRIDO_FACTIBLE'));
  assert(L3.Qiny_max_presion_Sm3_d == max(x));

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_limite_presion APROBADO\n');
endfunction

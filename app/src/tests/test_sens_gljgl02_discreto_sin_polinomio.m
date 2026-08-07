function ok = test_sens_gljgl02_discreto_sin_polinomio()
% El modo predeterminado conserva un analisis puramente discreto.
  ok=false;
  x=0:10000:100000;
  ql=100+0.001*x-8e-9*x.^2;
  qo=0.7*ql;
  r=10+0.0002*x-1.2e-9*x.^2;
  valido=true(size(x));
  T=sens_menu_tratamiento_curva('GL','DISCRETO',struct('opcion',1));
  O=sens_optimo_inyeccion(x,r,ql,qo,valido,struct('habilitado',false),T);
  assert(strcmp(O.estado,'OK'));
  assert(strcmp(O.tratamiento_curva.modo,'DISCRETO'));
  assert(isempty(fieldnames(O.ajuste_polinomico)));
  assert(isempty(O.x_ajuste_sm3d));
  assert(isempty(O.ql_polinomio_en_puntos_m3d));
  assert(isequal(O.ql_m3d,ql));
  assert(isequal(O.qo_m3d,qo));
  assert(isfield(O,'recomendado_discreto'));
  assert(strcmp(O.estado_recomendacion,'OPTIMO_DISCRETO'));

  [O2,V]=sens_verificar_optimo_polinomico(O,'GL',struct(),struct());
  assert(~V.verificado);
  assert(strcmp(V.estado,'NO_SOLICITADA'));
  assert(strcmp(O2.estado_recomendacion,'OPTIMO_DISCRETO'));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_discreto_sin_polinomio APROBADO\n');
endfunction

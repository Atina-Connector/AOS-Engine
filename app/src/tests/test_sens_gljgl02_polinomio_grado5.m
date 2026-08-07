function ok = test_sens_gljgl02_polinomio_grado5()
% Recupera el grado 5 historico y calcula un maximo por derivada cero.
  ok=false;
  x=linspace(0,100000,21);
  u=(x-50000)/50000;
  ql=100+10*u-8*u.^2+0.3*u.^3+0.1*u.^4-0.05*u.^5;
  qo=0.78*ql;
  r=15+0.08*ql;
  ql0=ql;qo0=qo;
  T=sens_menu_tratamiento_curva('GL','DISCRETO',struct('opcion',3,'grado',5,'n_grid',401));
  T.limite_ql_m3d=200;
  O=sens_optimo_inyeccion(x,r,ql,qo,true(size(x)),struct('habilitado',false),T);
  assert(strcmp(O.estado,'OK'));
  assert(O.ajuste_polinomico.ql.grado_efectivo==5);
  assert(O.ajuste_polinomico.qo.grado_efectivo==5);
  assert(O.ajuste_polinomico.qo.apto_informativo);
  assert(isfinite(O.ajuste_polinomico.qo.maximo_interior.qiny_sm3d));
  assert(O.candidato_verificacion.disponible);
  assert(O.candidato_verificacion.qiny_sm3d>min(x));
  assert(O.candidato_verificacion.qiny_sm3d<max(x));
  assert(isequal(O.ql_m3d,ql0));
  assert(isequal(O.qo_m3d,qo0));
  assert(numel(O.ql_polinomio_en_puntos_m3d)==numel(x));
  assert(strcmp(O.recomendado.criterio,O.recomendado_discreto.criterio));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_polinomio_grado5 APROBADO\n');
endfunction

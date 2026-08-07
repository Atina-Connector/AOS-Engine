function ok = test_sens_gljgl02_informativo_no_recomienda()
% El polinomio informativo se muestra, pero no reemplaza la recomendacion.
  ok=false;
  x=0:10000:100000;
  u=(x-50000)/50000;
  ql=110+12*u-7*u.^2+0.2*u.^3-0.1*u.^4+0.03*u.^5;
  qo=0.72*ql;
  r=12+0.04*ql;
  T=sens_menu_tratamiento_curva('GL','DISCRETO',struct('opcion',2,'grado',5,'n_grid',301));
  T.limite_ql_m3d=250;
  O=sens_optimo_inyeccion(x,r,ql,qo,true(size(x)),struct('habilitado',false),T);
  assert(strcmp(O.estado,'OK'));
  assert(strcmp(O.tratamiento_curva.modo,'POLINOMICO_INFORMATIVO'));
  assert(O.ajuste_polinomico.ql.grado_efectivo==5);
  assert(O.ajuste_polinomico.qo.apto_informativo);
  assert(~O.candidato_verificacion.disponible);
  assert(strcmp(O.estado_recomendacion,'OPTIMO_DISCRETO'));
  assert(strcmp(O.recomendado.criterio,O.recomendado_discreto.criterio));
  assert(isequal(O.ql_m3d,ql));
  assert(isequal(O.qo_m3d,qo));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_informativo_no_recomienda APROBADO\n');
endfunction

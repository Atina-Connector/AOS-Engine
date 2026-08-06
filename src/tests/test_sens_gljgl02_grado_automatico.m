function ok = test_sens_gljgl02_grado_automatico()
% El modo AUTO elige un grado entre 2 y 5 y conserva limites fisicos.
  ok=false;
  x=linspace(0,120000,17);
  u=(x-60000)/60000;
  ql=95+18*u-11*u.^2+0.4*u.^3;
  qo=0.68*ql;
  r=20+0.03*ql;
  T=sens_menu_tratamiento_curva('JGL','DISCRETO',struct('opcion',2,'grado',0,'n_grid',251));
  T.limite_ql_m3d=200;
  O=sens_optimo_inyeccion(x,r,ql,qo,true(size(x)),struct('habilitado',false),T);
  assert(strcmp(O.estado,'OK'));
  g=O.ajuste_polinomico.ql.grado_efectivo;
  assert(isfinite(g) && g>=2 && g<=5);
  assert(O.ajuste_polinomico.ql.apto_informativo);
  assert(~O.ajuste_polinomico.ql.violacion_limite_inferior);
  assert(~O.ajuste_polinomico.ql.violacion_limite_superior);
  assert(strcmp(O.estado_recomendacion,'OPTIMO_DISCRETO'));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_grado_automatico APROBADO\n');
endfunction

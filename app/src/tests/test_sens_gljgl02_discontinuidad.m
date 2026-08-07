function ok = test_sens_gljgl02_discontinuidad()
% Un polinomio no puede unir silenciosamente dos ramas separadas.
  ok=false;
  x=0:10000:100000;
  ql=100+0.001*x-7e-9*x.^2;
  qo=0.75*ql;
  r=10+0.05*ql;
  valido=true(size(x));
  valido(6)=false;ql(6)=NaN;qo(6)=NaN;r(6)=NaN;
  T=sens_menu_tratamiento_curva('JGL','DISCRETO',struct('opcion',3,'grado',3));
  T.limite_ql_m3d=250;
  O=sens_optimo_inyeccion(x,r,ql,qo,valido,struct('habilitado',false),T);
  assert(strcmp(O.estado,'OK'));
  assert(O.ajuste_polinomico.ql.discontinuidad);
  assert(O.validacion_polinomica.discontinuidad);
  assert(~O.validacion_polinomica.apto_para_optimizacion);
  assert(~O.candidato_verificacion.disponible);
  assert(strcmp(O.estado_recomendacion,'OPTIMO_DISCRETO_POLINOMIO_NO_APTO'));
  assert(isnan(O.ql_polinomio_en_puntos_m3d(6)) || ...
    O.ajuste_polinomico.ql.dominio_max < x(6) || O.ajuste_polinomico.ql.dominio_min > x(6));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_discontinuidad APROBADO\n');
endfunction

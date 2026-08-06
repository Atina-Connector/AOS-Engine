function ok = test_sens_gljgl02_mascaras_curva_optimo()
% La curva informativa puede usar puntos publicables aunque no sean aptos
% para declarar un optimo. No se fabrica recomendacion desde modo preliminar.
  ok=false;
  x=0:10000:100000;
  u=(x-50000)/50000;
  ql=105+14*u-9*u.^2+0.2*u.^3;
  qo=0.73*ql;
  r=18+0.03*ql;
  valido_curva=true(size(x));
  valido_optimo=false(size(x));
  T=sens_menu_tratamiento_curva('JGL','DISCRETO',struct('opcion',2,'grado',5,'n_grid',301));
  T.limite_ql_m3d=250;
  O=sens_optimo_inyeccion(x,r,ql,qo,valido_optimo,struct('habilitado',false),T,valido_curva);
  assert(strcmp(O.estado,'OK'));
  assert(O.ajuste_polinomico.ql.apto_informativo);
  assert(O.ajuste_polinomico.ql.grado_efectivo==5);
  assert(strcmp(O.estado_recomendacion,'OPTIMO_NO_DISPONIBLE_PUNTOS_VALIDOS_INSUFICIENTES'));
  assert(isempty(fieldnames(O.recomendado)));
  assert(numel(O.ql_polinomio_en_puntos_m3d)==numel(x));
  assert(isequal(O.ql_m3d,ql));
  assert(isequal(O.qo_m3d,qo));
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_mascaras_curva_optimo APROBADO\n');
endfunction

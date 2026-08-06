function ok = test_sens_gljgl02_menu_explicito()
% El tratamiento y el grado pueden forzarse sin entrada interactiva.
  ok=false;
  T1=sens_menu_tratamiento_curva('GL','DISCRETO',struct('opcion',1));
  assert(strcmp(T1.modo,'DISCRETO'));
  assert(~T1.habilitado && ~T1.usar_polinomio && ~T1.oculto);

  T2=sens_menu_tratamiento_curva('JGL','DISCRETO',struct('opcion',2,'grado',5,'n_grid',200));
  assert(strcmp(T2.modo,'POLINOMICO_INFORMATIVO'));
  assert(T2.habilitado && ~T2.verificar_optimo && T2.grado_solicitado==5);
  assert(mod(T2.n_grid,2)==1);

  T3=sens_menu_tratamiento_curva('GL/JGL','DISCRETO',struct('opcion',3,'grado',0));
  assert(strcmp(T3.modo,'POLINOMICO_VERIFICADO'));
  assert(T3.habilitado && T3.verificar_optimo && T3.grado_solicitado==0);
  ok=true;
  fprintf('RESULTADO: test_sens_gljgl02_menu_explicito APROBADO\n');
endfunction

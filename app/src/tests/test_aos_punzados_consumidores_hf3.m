function ok = test_aos_punzados_consumidores_hf3()
% Los solvers y diagnosticos consumen solamente intervalos activos.
  ok=false; iniciar_aos(true);
  global CONFIG_ACTIVA geologia;
  prev={CONFIG_ACTIVA,geologia};
  unwind_protect
    a=struct('id','ACT','MD_desde',1000,'MD_hasta',1010, ...
      'densidad_tpm',10,'diametro_punzado_m',0.010,'activo',true, ...
      'permeabilidad_mD',20,'skin',0);
    b=a;b.id='OFF';b.MD_desde=1020;b.MD_hasta=1030;b.activo=false;
    p=aos_punzados_normalizar(struct('tramos',[a b]));
    CONFIG_ACTIVA=struct('punzados',p);geologia=[];
    activos=aos_obtener_punzados_activos(struct(),struct());
    assert(numel(activos.tramos)==1&&strcmp(activos.tramos(1).id,'ACT'));
    dist=aos_distribuir_produccion_punzados(1/86400,struct(),p,struct('WC',0.2));
    assert(dist.n_tramos==1&&dist.n_tiros_total==100);
    q=calcular_erosion_punzados(struct('rho_petroleo',850),p);
    vcrit=(120/sqrt(850*0.062428))*0.3048;
    esperado=100*pi*(0.010/2)^2*vcrit;
    assert(abs(q-esperado)<max(1e-12,1e-10*abs(esperado)));
    ok=true;
  unwind_protect_cleanup
    CONFIG_ACTIVA=prev{1};geologia=prev{2};
  end_unwind_protect
  if ok,fprintf('RESULTADO: test_aos_punzados_consumidores_hf3 APROBADO\n');endif
endfunction

function ok = test_aos_punzados_sin_geologia_hf3()
% Punzados independientes, commit atomico e invalidacion transversal.
  ok=false; iniciar_aos(true);
  global CONFIG_ACTIVA geologia ULTIMO_QL ULTIMO_QO ULTIMO_PARAM;
  prev={CONFIG_ACTIVA,geologia,ULTIMO_QL,ULTIMO_QO,ULTIMO_PARAM};
  unwind_protect
    CONFIG_ACTIVA=struct('nombre_pozo','SIN_GEOLOGIA', ...
      'aos_estado_resultados','EJECUTADO');
    geologia=[];ULTIMO_QL=1;ULTIMO_QO=2;ULTIMO_PARAM=struct('x',1);
    t=struct('id','MAN-01','MD_desde',1500,'MD_hasta',1510, ...
      'densidad_tpm',10,'diametro_punzado_m',0.010,'activo',true, ...
      'formacion','DESCONOCIDA','origen','MANUAL');
    p=aos_punzados_normalizar(struct('tramos',t));
    info=aos_punzados_commit(p,'TEST_SIN_GEOLOGIA');
    assert(info.ok&&info.cambio);
    assert(isfield(CONFIG_ACTIVA,'punzados'));
    assert(numel(CONFIG_ACTIVA.punzados.tramos)==1);
    assert(~isfield(CONFIG_ACTIVA,'geologia'));
    assert(isempty(geologia));
    assert(strcmp(CONFIG_ACTIVA.aos_estado_resultados,'RESULTADOS_OBSOLETOS'));
    assert(isempty(ULTIMO_QL)&&isempty(ULTIMO_QO)&&isempty(ULTIMO_PARAM));
    r=aos_punzados_validar(CONFIG_ACTIVA.punzados,[],false);
    assert(r.ok&&r.n_activos==1);

    candidato=CONFIG_ACTIVA.punzados;
    [candidato,~]=aos_punzados_operacion(candidato,'EDITAR',1, ...
      struct('densidad_tpm',20));
    assert(CONFIG_ACTIVA.punzados.tramos(1).densidad_tpm==10);
    assert(candidato.tramos(1).densidad_tpm==20);
    ok=true;
  unwind_protect_cleanup
    CONFIG_ACTIVA=prev{1};geologia=prev{2};ULTIMO_QL=prev{3}; ...
      ULTIMO_QO=prev{4};ULTIMO_PARAM=prev{5};
  end_unwind_protect
  if ok,fprintf('RESULTADO: test_aos_punzados_sin_geologia_hf3 APROBADO\n');endif
endfunction

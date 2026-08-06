function ok = test_aos_punzados_aosdat_roundtrip_hf3()
% Round-trip legacy + metadatos extendidos sin perdida de campos.
  ok=false; iniciar_aos(true);
  tmp=[tempname() '_aos_punzados_hf3'];mkdir(tmp);
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  prev={CONFIG_ACTIVA,AOSDAT_ACTIVO,geologia};
  unwind_protect
    t1=struct('id','PZ-001','nombre','Arena Norte','MD_desde',2000, ...
      'MD_hasta',2008,'densidad_tpm',13,'diametro_punzado_m',0.011, ...
      'activo',true,'fase_deg',60,'penetracion_m',0.32, ...
      'tipo_disparo','TCP','formacion','F1','permeabilidad_mD',18, ...
      'skin',1.2,'estado_validacion','VALIDADO','observaciones','principal', ...
      'origen','MANUAL','extras',struct('proveedor_cargas','AESIR # Lote','lote',42));
    t2=t1;t2.id='PZ-002';t2.nombre='Reserva';t2.MD_desde=2010; ...
      t2.MD_hasta=2014;t2.densidad_tpm=9;t2.activo=false; ...
      t2.formacion='F2';t2.observaciones='inactivo';
    p=aos_punzados_normalizar(struct('tramos',[t1 t2]));
    cfg=struct('nombre_pozo','TEST_PUNZADOS_HF3','punzados',p);
    archivo=fullfile(tmp,'punzados_hf3.aosdat');
    exportar_aosdat(cfg,archivo,{'PUNZADOS'});
    txt=fileread(archivo);
    assert(~isempty(strfind(txt,'[PUNZADOS]')));
    assert(~isempty(strfind(txt,'[PUNZADOS_META]')));
    assert(~isempty(strfind(txt,'activo_2=false')));

    opts=struct('activar_caso',false,'imprimir_resumen',false,'normalizar',false);
    leido=importar_aosdat(archivo,opts);
    assert(isfield(leido,'punzados'));
    q=leido.punzados;
    assert(numel(q.tramos)==2);
    assert(strcmp(q.tramos(1).id,'PZ-001'));
    assert(strcmp(q.tramos(1).formacion,'F1'));
    assert(abs(q.tramos(1).permeabilidad_mD-18)<1e-12);
    assert(abs(q.tramos(1).skin-1.2)<1e-12);
    assert(~q.tramos(2).activo);
    assert(abs(q.tramos(2).densidad_tpm-9)<1e-12);
    assert(strcmp(q.tramos(2).observaciones,'inactivo'));
    assert(isfield(q.tramos(1).extras,'proveedor_cargas'));
    assert(strcmp(q.tramos(1).extras.proveedor_cargas,'AESIR # Lote'));
    ok=true;
  unwind_protect_cleanup
    CONFIG_ACTIVA=prev{1};AOSDAT_ACTIVO=prev{2};geologia=prev{3};
    if exist(tmp,'dir')==7
      try,aos_rmdir_seguro(tmp,tempdir());catch,end_try_catch
    endif
  end_unwind_protect
  if ok,fprintf('RESULTADO: test_aos_punzados_aosdat_roundtrip_hf3 APROBADO\n');endif
endfunction

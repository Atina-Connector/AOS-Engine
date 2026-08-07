function ok = test_aos_geologia_transaccional_hf2()
% TEST_AOS_GEOLOGIA_TRANSACCIONAL_HF2 Valida edicion, punzados y rollback.
  ok = false;
  iniciar_aos(true);
  global geologia CONFIG_ACTIVA;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  previo = {geologia,CONFIG_ACTIVA,ULTIMO_QL,ULTIMO_QO,ULTIMO_QINY,ULTIMO_TIPO,ULTIMO_PARAM};

  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  archivo = fullfile(raiz,'config','geologia','config_geologia.txt');
  base = cargar_geologia(archivo);
  base.intervalos = struct('tramos',tramo_local(1000,1010));

  unwind_protect
    geologia = base;
    CONFIG_ACTIVA = struct('nombre_pozo','GEO-HF2','geologia',base, ...
      'punzados',base.intervalos);
    ULTIMO_QL=1;ULTIMO_QO=2;ULTIMO_QINY=3;ULTIMO_TIPO='TEST';ULTIMO_PARAM=struct('x',1);

    candidata = base;
    candidata.UCS = base.UCS * 1.10;
    candidata.intervalos = struct('tramos',tramo_local(1020,1030));

    [conserva,info_c] = aos_geologia_resolver_punzados(base,candidata,'CONSERVAR_ACTUALES');
    assert(isfield(info_c,'n_salida') && isfield(info_c,'n_finales'));
    assert(info_c.n_salida==1 && info_c.n_finales==1 && ...
      conserva.intervalos.tramos.MD_desde==1000);
    [usa,info_u] = aos_geologia_resolver_punzados(base,candidata,'USAR_NUEVOS');
    assert(info_u.n_salida==1 && info_u.n_finales==1 && ...
      usa.intervalos.tramos.MD_desde==1020);
    [fusion,info_f] = aos_geologia_resolver_punzados(base,candidata,'FUSIONAR');
    assert(info_f.n_salida==2 && info_f.n_finales==2 && ...
      numel(fusion.intervalos.tramos)==2);

    info = aos_geologia_commit(candidata,'TEST_HF2');
    assert(info.ok && info.cambio);
    assert(abs(geologia.UCS-candidata.UCS)<1e-9);
    assert(CONFIG_ACTIVA.punzados.tramos.MD_desde==1020);
    assert(isempty(ULTIMO_QL) && isempty(ULTIMO_PARAM));

    ULTIMO_QL=99;ULTIMO_PARAM=struct('vigente',true);
    misma = geologia;
    info2 = aos_geologia_commit(misma,'TEST_HF2_RECONFIRMACION');
    assert(info2.ok && ~info2.cambio);
    assert(ULTIMO_QL==99 && isfield(ULTIMO_PARAM,'vigente'));

    fuente = fileread(which('AOS_menu_datos_pozo'));
    assert(isempty(strfind(lower(fuente),'reemplazar o editar')));
    assert(~isempty(strfind(fuente,'aos_geologia_administrar')));
    ok = true;
  unwind_protect_cleanup
    geologia=previo{1};CONFIG_ACTIVA=previo{2};ULTIMO_QL=previo{3};ULTIMO_QO=previo{4};
    ULTIMO_QINY=previo{5};ULTIMO_TIPO=previo{6};ULTIMO_PARAM=previo{7};
  end_unwind_protect

  fprintf('RESULTADO: test_aos_geologia_transaccional_hf2 APROBADO\n');
endfunction

function t = tramo_local(a,b)
  t=struct('MD_desde',a,'MD_hasta',b,'densidad_tpm',10, ...
    'diametro_punzado_m',0.010);
endfunction

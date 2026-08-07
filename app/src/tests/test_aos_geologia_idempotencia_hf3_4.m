function ok = test_aos_geologia_idempotencia_hf3_4()
% Valida que reconfirmar la misma geologia, incluso con NaN, no invalide.
  ok = false;
  iniciar_aos(true);
  global geologia CONFIG_ACTIVA;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  previo = {geologia,CONFIG_ACTIVA,ULTIMO_QL,ULTIMO_QO,ULTIMO_QINY,ULTIMO_TIPO,ULTIMO_PARAM};

  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  archivo = fullfile(raiz,'config','geologia','config_geologia.txt');
  base = cargar_geologia(archivo);
  tramo = struct('MD_desde',1200,'MD_hasta',1210,'densidad_tpm',12, ...
    'diametro_punzado_m',0.010,'fase_deg',NaN,'penetracion_m',NaN, ...
    'permeabilidad_mD',NaN,'skin',NaN);
  base.intervalos = struct('tramos',tramo);

  unwind_protect
    geologia = [];
    CONFIG_ACTIVA = struct('nombre_pozo','GEO-IDEMP-HF34');
    ULTIMO_QL=[];ULTIMO_QO=[];ULTIMO_QINY=[];ULTIMO_TIPO='';ULTIMO_PARAM=struct();

    info1 = aos_geologia_commit(base,'TEST_HF3_4_INICIAL');
    assert(info1.ok && info1.cambio);

    ULTIMO_QL=77; ULTIMO_QO=66; ULTIMO_QINY=55;
    ULTIMO_TIPO='VIGENTE'; ULTIMO_PARAM=struct('vigente',true);
    misma = geologia;
    info2 = aos_geologia_commit(misma,'TEST_HF3_4_RECONFIRMACION');
    assert(info2.ok && ~info2.cambio);
    assert(ULTIMO_QL==77 && ULTIMO_QO==66 && ULTIMO_QINY==55);
    assert(strcmp(ULTIMO_TIPO,'VIGENTE') && isfield(ULTIMO_PARAM,'vigente'));
    ok = true;
  unwind_protect_cleanup
    geologia=previo{1};CONFIG_ACTIVA=previo{2};ULTIMO_QL=previo{3};ULTIMO_QO=previo{4};
    ULTIMO_QINY=previo{5};ULTIMO_TIPO=previo{6};ULTIMO_PARAM=previo{7};
  end_unwind_protect

  fprintf('RESULTADO: test_aos_geologia_idempotencia_hf3_4 APROBADO\n');
endfunction

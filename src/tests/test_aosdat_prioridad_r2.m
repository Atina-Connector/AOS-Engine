function ok = test_aosdat_prioridad_r2()
% TEST_AOSDAT_PRIORIDAD_R2 El caso .aosdat pisa defaults sin ser mutado.
  ok = false;
  iniciar_aos(true);
  archivo = [tempname() '_prioridad_r2.aosdat'];

  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  previo = {CONFIG_ACTIVA, AOSDAT_ACTIVO, geologia, ...
    ULTIMO_QL, ULTIMO_QO, ULTIMO_QINY, ULTIMO_TIPO, ULTIMO_PARAM};

  unwind_protect
    fid = fopen(archivo, 'wt');
    if fid < 0, error('No se pudo crear archivo temporal .aosdat.'); endif
    fprintf(fid, '[AOS_DATA]\n');
    fprintf(fid, 'version=0.1.9-R2-test\n');
    fprintf(fid, 'nombre_pozo=PRIORIDAD_R2\n');
    fprintf(fid, 'secciones=CONFIG\n\n');
    fprintf(fid, '[CONFIG]\n');
    fprintf(fid, 'API=42.5\n');
    fprintf(fid, 'diam_tbg=0.0777\n');
    fprintf(fid, 'factor_VLP=1.2345\n');
    fprintf(fid, 'marcador_prioridad_r2=987654\n');
    fclose(fid);

    cfg_importada = importar_aosdat(archivo, struct( ...
      'activar_caso', true, 'imprimir_resumen', false, 'normalizar', true));
    assert(strcmp(cfg_importada.nombre_pozo, 'PRIORIDAD_R2'));
    assert(abs(cfg_importada.API - 42.5) < 1e-12);
    assert(abs(cfg_importada.diam_tbg - 0.0777) < 1e-12);

    [cfg_bm, origen] = aos_config_base('BM');
    assert(abs(cfg_bm.API - 42.5) < 1e-12);
    assert(abs(cfg_bm.diam_tbg - 0.0777) < 1e-12);
    assert(abs(cfg_bm.factor_VLP - 1.2345) < 1e-12);
    assert(cfg_bm.marcador_prioridad_r2 == 987654);
    assert(~isempty(strfind(lower(origen), '.aosdat')));
    ok = true;
  unwind_protect_cleanup
    CONFIG_ACTIVA = previo{1};
    AOSDAT_ACTIVO = previo{2};
    geologia = previo{3};
    ULTIMO_QL = previo{4};
    ULTIMO_QO = previo{5};
    ULTIMO_QINY = previo{6};
    ULTIMO_TIPO = previo{7};
    ULTIMO_PARAM = previo{8};
    if exist(archivo, 'file') == 2
      try
        delete(archivo);
      catch
      end_try_catch
    endif
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aosdat_prioridad_r2 APROBADO\n');
  endif
endfunction

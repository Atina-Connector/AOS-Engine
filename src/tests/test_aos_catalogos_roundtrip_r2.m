function ok = test_aos_catalogos_roundtrip_r2()
% TEST_AOS_CATALOGOS_ROUNDTRIP_R2 Contrato simetrico y fusion no destructiva.
  ok = false;
  iniciar_aos(true);
  tmp = [tempname() '_aos_catalogos_r2'];
  mkdir(tmp);

  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  previo = {CONFIG_ACTIVA, AOSDAT_ACTIVO, geologia, ...
    ULTIMO_QL, ULTIMO_QO, ULTIMO_QINY, ULTIMO_TIPO, ULTIMO_PARAM};

  unwind_protect
    bombas = struct('modelo', 'PUMP-R2', 'Q', [10 20 30], ...
      'head', [100 90 70], 'potencia', [5 7 9], 'etapas', 120);
    valvulas = struct('codigo', 'V-R2', 'diam_orificio_m', 0.004, ...
      'R_fuelle', 1.25, 'pres_max_domo_Pa', 2.5e7);
    varillas = struct('nombre', 'ROD-R2', 'densidad_kg_m3', 7850, ...
      'modulo_young_GPa', 207, 'limite_fatiga_MPa', 250, ...
      'resistencia_ultima_MPa', 700);
    unidades = struct('modelo', 'UNIT-R2', 'tipo', 'CONVENCIONAL', ...
      'carrera_max_m', 3.0, 'vel_max_gpm', 12, ...
      'torque_max_klb_in', 800, 'peso_kg', 12000);

    tipos = {'bombas', 'valvulas', 'varillas', 'unidades_bm'};
    conjuntos = {bombas, valvulas, varillas, unidades};
    for i = 1:numel(tipos)
      archivo = fullfile(tmp, [tipos{i} '.aosdat']);
      [~, exp_info] = exportar_catalogo(tipos{i}, conjuntos{i}, archivo);
      assert(exp_info.ok);
      assert(strcmp(exp_info.contract, 'AOS_CATALOGO_R2'));

      [leido, imp_info] = importar_catalogo(tipos{i}, archivo);
      assert(imp_info.ok && imp_info.cantidad == 1 && numel(leido) == 1);
      assert(strcmp(imp_info.contract, 'AOS_CATALOGO_R2'));
      if strcmp(tipos{i}, 'bombas')
        assert(strcmp(leido.modelo, 'PUMP-R2'));
        assert(max(abs(leido.Q - [10 20 30])) < 1e-10);
        assert(max(abs(leido.head - [100 90 70])) < 1e-10);
        assert(leido.etapas == 120);
      elseif strcmp(tipos{i}, 'valvulas')
        assert(strcmp(leido.codigo, 'V-R2'));
        assert(abs(leido.pres_max_domo_Pa - 2.5e7) < 1);
      elseif strcmp(tipos{i}, 'varillas')
        assert(strcmp(leido.nombre, 'ROD-R2'));
      else
        assert(strcmp(leido.modelo, 'UNIT-R2'));
      endif
    endfor

    CONFIG_ACTIVA = struct('nombre_pozo', 'CASO_TEST_R2', ...
      'marcador_no_borrar', 12345);
    AOSDAT_ACTIVO = 'CASO_TEST_R2';
    geologia = [];
    ULTIMO_QL = 1;
    ULTIMO_QO = 2;
    ULTIMO_QINY = 3;
    ULTIMO_TIPO = 'TEST';
    ULTIMO_PARAM = struct('x', 1);

    opciones = struct('registrar', true, ...
      'directorio_registro', fullfile(tmp, 'registro'), ...
      'invalidar_resultados', true);
    resumen = aos_catalogos_fusionar_desde_aosdat( ...
      fullfile(tmp, 'bombas.aosdat'), 'EXTERNO', opciones);
    assert(resumen.ok && resumen.fusionado);
    assert(CONFIG_ACTIVA.marcador_no_borrar == 12345);
    assert(isfield(CONFIG_ACTIVA, 'aosdat_sections'));
    assert(isfield(CONFIG_ACTIVA.aosdat_sections, 'bombas'));
    assert(isempty(ULTIMO_QL) && isempty(ULTIMO_PARAM));
    assert(exist(resumen.registrado, 'file') == 2);
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
    if exist(tmp, 'dir') == 7
      try
        aos_rmdir_seguro(tmp, tempdir());
      catch
      end_try_catch
    endif
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_catalogos_roundtrip_r2 APROBADO\n');
  endif
endfunction

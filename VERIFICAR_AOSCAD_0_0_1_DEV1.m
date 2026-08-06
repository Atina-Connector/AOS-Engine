function ok = VERIFICAR_AOSCAD_0_0_1_DEV1(ejecutar_pruebas)
% Verificador de entrada para AOSCAD 0.0.1 DEV1.
  if nargin < 1, ejecutar_pruebas = false; endif
  root = fileparts(mfilename('fullpath'));
  addpath(fullfile(root, 'src'), '-begin');
  addpath(fullfile(root, 'src', 'modulos', 'cad_topo'), '-begin');

  fprintf('\n====================================================\n');
  fprintf(' VERIFICAR AOSCAD 0.0.1 DEV1 - GNU OCTAVE\n');
  fprintf('====================================================\n');

  ok = aos_cad_verificar_octave_only(false);
  iniciar_aos(true);
  clear aos_cad_abrir_externo aos_cad_abrir_externo_impl;
  clear AOS_menu_cad_topologia aos_cad_topologia_menu_impl aos_cad_hidraulica_menu;
  clear aos_cad_verificar_rutas_unicas;
  rehash();
  rutas_ok = aos_cad_verificar_rutas_unicas(true);
  ok = ok && rutas_ok;
  schema = fullfile(root, 'src', 'modulos', 'cad_topo', 'schema', ...
                    'AOSCAD_0_0_1_DEV1_SCHEMA.json');
  if exist(schema, 'file') ~= 2
    fprintf(2, 'FALTA schema DEV1: %s\n', schema);
    ok = false;
  else
    fprintf('OK  schema DEV1 presente\n');
  endif

  if ejecutar_pruebas && ok
    % Sprint 2: tests de servicios geometry_3d (asset_id + geom)
    fprintf('\nSelftest servicios geometry_3d (Sprint 2)...\n');
    try
      if ~test_aos_asset_identity()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR asset_identity: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_geom_servicios()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR geom_servicios: %s\n', err.message);
      ok = false;
    end_try_catch

    % Sprint 5: indice STEP, visor 3D y vinculo asset_id<->geometry_id
    fprintf('\nSelftest indice geometrico STEP / visor 3D / vinculo (Sprint 5)...\n');
    try
      if ~test_aos_cad_step_indice()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR step_indice: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_cad_visor_3d()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR visor_3d: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_cad_vinculo_asset_3d()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR vinculo_asset_3d: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_cad_step_edicion_externa()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR step_edicion_externa: %s\n', err.message);
      ok = false;
    end_try_catch

    % Sprint 6: puertos/conexiones 3D, interferencias AABB, escena federada, overlay
    fprintf('\nSelftest Sprint 6 (puertos, interferencias, federada, overlay)...\n');
    try
      if ~test_aos_cad_puertos_conexiones()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR puertos_conexiones: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_cad_interferencias()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR interferencias: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_escena_federada()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR escena_federada: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      if ~test_aos_cad_overlay_3d()
        ok = false;
      endif
    catch err
      fprintf(2, ' ERROR overlay_3d: %s\n', err.message);
      ok = false;
    end_try_catch

    % Sprint 7: invalidacion, sync 2D/3D, DXF edicion, recursos visuales (fail-fast)
    if ok
      fprintf('\nSelftest Sprint 7 (invalidacion / sync / DXF / recursos)...\n');
    endif
    if ok
      try
        if ~test_aos_cad_invalidar_simulacion()
          ok = false;
        endif
      catch err
        fprintf(2, ' ERROR invalidar_simulacion: %s\n', err.message);
        ok = false;
      end_try_catch
    endif
    if ok
      try
        if ~test_aos_cad_sincronizacion_2d_3d()
          ok = false;
        endif
      catch err
        fprintf(2, ' ERROR sincronizacion_2d_3d: %s\n', err.message);
        ok = false;
      end_try_catch
    endif
    if ok
      try
        if ~test_aos_cad_dxf_edicion_externa()
          ok = false;
        endif
      catch err
        fprintf(2, ' ERROR dxf_edicion_externa: %s\n', err.message);
        ok = false;
      end_try_catch
    endif
    if ok
      try
        if ~test_aos_aoscad_recursos_visuales()
          ok = false;
        endif
      catch err
        fprintf(2, ' ERROR recursos_visuales: %s\n', err.message);
        ok = false;
      end_try_catch
    endif
    if ok
      try
        if ~test_aos_cad_auditoria_estatica()
          ok = false;
        endif
      catch err
        fprintf(2, ' ERROR auditoria_estatica: %s\n', err.message);
        ok = false;
      end_try_catch
    endif

    actual = pwd();
    unwind_protect
      cd(fullfile(root, 'src', 'modulos', 'cad_topo'));
      ok = ok && VERIFICAR_CAD_TOPO();
    unwind_protect_cleanup
      cd(actual);
    end_unwind_protect
  elseif ~ejecutar_pruebas
    fprintf('Pruebas funcionales no ejecutadas. Use VERIFICAR_AOSCAD_0_0_1_DEV1(true).\n');
  endif

  if ok
    fprintf('RESULTADO: VERIFICACION AOSCAD DEV1 APROBADA\n');
  else
    fprintf(2, 'RESULTADO: VERIFICACION AOSCAD DEV1 NO APROBADA\n');
  endif
endfunction

function ok = test_aos_cad_hidraulica_dxf()
% TEST_AOS_CAD_HIDRAULICA_DXF Prueba end-to-end DXF -> red -> .aoscad.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_hidraulica_dxf ===\n');
  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_hidraulica_dev1.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALLO falta demo: %s\n', dxf); ok = false; return;
  endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    if ~aos_cad_importar_dxf(dxf, true)
      fprintf(2, 'FALLO import DXF\n'); ok = false; return;
    endif
    aos_cad_construir_topologia(0.05, true);
    resultados = aos_cad_hidraulica_ejecutar(true);
    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    red = aos_cad_hidraulica_preparar(modelo, aos_cad_hidraulica_defaults(modelo));
    ok = check_local(ok, ~red.requiere_solver_lazos, 'requiere_solver_lazos=false (serie)');

    ok = check_local(ok, strcmp(modelo.simulacion.motor, 'AOSCAD-HIDRAULICA-0.0.1-DEV1'), 'motor oficial DEV1');
    ok = check_local(ok, any(strcmp(modelo.simulacion.estado, {'EJECUTADA','EJECUTADA_CON_ADVERTENCIAS'})), 'estado ejecutado');
    ok = check_local(ok, numel(resultados.tramos) == 2, 'dos tramos resueltos');
    ok = check_local(ok, numel(resultados.nodos) == 3, 'tres nodos resueltos');
    if numel(resultados.tramos) >= 2
      q1 = resultados.tramos{1}.caudal_liquido_m3s;
      q2 = resultados.tramos{2}.caudal_liquido_m3s;
      ok = check_local(ok, abs(q1 - 0.001) < 1e-9 && abs(q2 - 0.001) < 1e-9, 'balance de caudal en serie');
      ok = check_local(ok, resultados.tramos{1}.P_out_Pa < resultados.tramos{1}.P_in_Pa, 'perdida de presion tramo 1');
      ok = check_local(ok, resultados.tramos{2}.P_out_Pa < resultados.tramos{2}.P_in_Pa, 'perdida de presion/tramo ascendente');
    endif

    out = fullfile(tempdir(), sprintf('aoscad_hid_test_%s_%06d.aoscad', datestr(now,'yyyymmddHHMMSS'), randi(999999)));
    aos_aoscad_escribir(out, 'SIMPLE', true);
    ok = check_local(ok, exist(out, 'file') == 2, 'archivo .aoscad generado');
    leido = aos_aoscad_leer(out, true);
    ok = check_local(ok, isfield(leido, 'tablas_resultados') && ...
                          isfield(leido.tablas_resultados, 'tramos'), 'round-trip resultados');
    if exist(out, 'file') == 2, delete(out); endif

    % Verificar que los motores multifasicos comunes estan disponibles.
    ok = check_local(ok, exist('vlp_HB_full', 'file') == 2, 'motor HB disponible');
    ok = check_local(ok, exist('vlp_duns_ros', 'file') == 2, 'motor Duns-Ros disponible');
    ok = check_local(ok, exist('vlp_simplified_corregida', 'file') == 2, 'motor simplificado disponible');
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_hidraulica_dxf APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_hidraulica_dxf NO APROBADO\n');
  endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond, fprintf('OK  %s\n', msg); else fprintf(2, 'FALLO  %s\n', msg); ok = false; endif
endfunction

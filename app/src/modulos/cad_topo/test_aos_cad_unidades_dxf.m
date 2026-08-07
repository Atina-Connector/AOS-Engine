function ok = test_aos_cad_unidades_dxf()
% TEST_AOS_CAD_UNIDADES_DXF Compara DXF en m vs mm tras normalizacion SI.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_unidades_dxf ===\n');
  root = aos_cad_raiz();
  dxf_m = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_hidraulica_dev1.dxf');
  dxf_mm = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_unidades_mm.dxf');
  ok = check_local(ok, exist(dxf_m, 'file') == 2, 'fixture metros');
  ok = check_local(ok, exist(dxf_mm, 'file') == 2, 'fixture mm');
  if ~ok, report_final(ok); return; endif

  prev = CONFIG_ACTIVA;
  unwind_protect
    CONFIG_ACTIVA = struct();
    aos_cad_importar_dxf(dxf_m, true);
    m_m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    nodos_m = m_m.tablas_entrada.nodos;
    tramos_m = m_m.tablas_entrada.tramos;
    ok = check_local(ok, isfield(m_m, 'unidades_dxf'), 'unidades_dxf presente (m)');
    if isfield(m_m, 'unidades_dxf')
      ok = check_local(ok, abs(m_m.unidades_dxf.factor - 1) < 1e-15, 'factor=1 metros');
    endif

    CONFIG_ACTIVA = struct();
    aos_cad_importar_dxf(dxf_mm, true);
    m_mm = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    nodos_mm = m_mm.tablas_entrada.nodos;
    tramos_mm = m_mm.tablas_entrada.tramos;
    ok = check_local(ok, isfield(m_mm, 'unidades_dxf') && ...
      abs(m_mm.unidades_dxf.factor - 0.001) < 1e-15, 'factor=0.001 mm');
    ok = check_local(ok, strcmp(m_mm.unidades_dxf.nombre, 'mm') || ...
      strcmp(m_mm.unidades_dxf.origen, 'TEXTO_AOS_META'), 'origen unidades mm');
    ok = check_local(ok, numel(nodos_m) == numel(nodos_mm), 'mismo n nodos');
    ok = check_local(ok, numel(tramos_m) == numel(tramos_mm), 'mismo n tramos');

    if numel(nodos_m) == numel(nodos_mm) && numel(nodos_m) >= 1
      for i = 1:numel(nodos_m)
        dx = abs(nodos_m{i}.x - nodos_mm{i}.x);
        dy = abs(nodos_m{i}.y - nodos_mm{i}.y);
        dz = abs(nodos_m{i}.z - nodos_mm{i}.z);
        ok = check_local(ok, dx < 1e-6 && dy < 1e-6 && dz < 1e-6, ...
          sprintf('nodo %d coordenadas iguales tras escala', i));
      endfor
    endif
    if numel(tramos_m) == numel(tramos_mm) && numel(tramos_m) >= 1
      for i = 1:numel(tramos_m)
        Lm = aos_aoscad_valor(tramos_m{i}.longitud_m);
        Lmm = aos_aoscad_valor(tramos_mm{i}.longitud_m);
        ok = check_local(ok, abs(Lm - Lmm) < 1e-6, sprintf('tramo %d longitud SI', i));
        Dm = aos_aoscad_valor(tramos_m{i}.diametro_m);
        Dmm = aos_aoscad_valor(tramos_mm{i}.diametro_m);
        ok = check_local(ok, abs(Dm - Dmm) < 1e-9, sprintf('tramo %d diametro SI', i));
      endfor
    endif

    % Validacion UNIDADES_DXF
    hay_u = false;
    if isfield(m_mm, 'validaciones') && isfield(m_mm.validaciones, 'items')
      for i = 1:numel(m_mm.validaciones.items)
        if strcmp(m_mm.validaciones.items{i}.codigo, 'UNIDADES_DXF')
          hay_u = true; break;
        endif
      endfor
    endif
    ok = check_local(ok, hay_u, 'item UNIDADES_DXF en validaciones');

    % Claves explicitas y heuristica
    app1 = aos_cad_meta_aplicar(struct('D_MM', '101.6'), 'TEST');
    ok = check_local(ok, abs(app1.diametro_m - 0.1016) < 1e-12, 'D_MM=101.6 -> 0.1016 m');
    app2 = aos_cad_meta_aplicar(struct('D_IN', '4'), 'TEST');
    ok = check_local(ok, abs(app2.diametro_m - 0.1016) < 1e-9, 'D_IN=4 -> 0.1016 m');
    app3 = aos_cad_meta_aplicar(struct('D_M', '0.1016'), 'TEST');
    ok = check_local(ok, abs(app3.diametro_m - 0.1016) < 1e-12, 'D_M=0.1016');
    app4 = aos_cad_meta_aplicar(struct('D', '101.6'), 'TEST');
    ok = check_local(ok, abs(app4.diametro_m - 0.1016) < 1e-12, 'D heuristica mm');
    ok = check_local(ok, ~isempty(strfind(app4.adv_diametro, 'META_UNIDAD_HEURISTICA')), ...
      'META_UNIDAD_HEURISTICA en D>1');

    % INSUNITS desconocido no es fatal
    fake = struct('insunits', 99, 'unidades', 'INSUNITS_99', 'entidades', {{}});
    [f, n, o, adv] = aos_cad_unidades_dxf(fake, struct()); %#ok<ASGLU>
    ok = check_local(ok, abs(f - 1) < 1e-15, 'INSUNITS desconocido factor=1');
    ok = check_local(ok, any(strcmp(adv, 'INSUNITS_NO_SOPORTADO_99')), ...
      'advertencia INSUNITS_NO_SOPORTADO');
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  report_final(ok);
endfunction

function ok = check_local(ok, cond, msg)
  if cond, fprintf('OK  %s\n', msg); else fprintf(2, 'FALLO  %s\n', msg); ok = false; endif
endfunction

function report_final(ok)
  if ok
    fprintf('RESULTADO: test_aos_cad_unidades_dxf APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_unidades_dxf NO APROBADO\n');
  endif
endfunction

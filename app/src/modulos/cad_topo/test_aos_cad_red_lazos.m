function ok = test_aos_cad_red_lazos()
% Extremo a extremo desde DXF: anillo y dos lazos con dominio LOOP_SUBNETWORK.
  global CONFIG_ACTIVA;
  ok = true;
  fprintf('\n=== test_aos_cad_red_lazos ===\n');
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  unwind_protect
    for caso = 1:2
      if caso == 1
        dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_anillo.dxf');
        etiqueta = 'anillo';
        n_lazos_esp = 1;
      else
        dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_dos_lazos.dxf');
        etiqueta = 'dos_lazos';
        n_lazos_esp = 2;
      endif
      ok = check_local(ok, exist(dxf, 'file') == 2, sprintf('%s: fixture existe', etiqueta));
      if exist(dxf, 'file') ~= 2, continue; endif

      CONFIG_ACTIVA = struct();
      aos_cad_importar_dxf(dxf, true);
      aos_cad_mapear_objetos([], true);
      aos_cad_construir_topologia(0.05, true);
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      modelo = aos_cad_hidraulica_aplicar_metadatos(modelo);
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

      cfg = aos_cad_hidraulica_defaults(modelo);
      [diag, items] = aos_cad_hidraulica_diagnosticar_topologia(modelo, cfg);
      ok = check_local(ok, strcmp(diag.solver_requerido, 'HYD_LOOP'), ...
        sprintf('%s: solver_requerido HYD_LOOP', etiqueta));
      ok = check_local(ok, diag.n_lazos_independientes >= n_lazos_esp, ...
        sprintf('%s: n_lazos >= %d', etiqueta, n_lazos_esp));

      ids = diag.ids_nodo;
      ok = check_local(ok, numel(ids) >= 4, sprintf('%s: >=4 nodos', etiqueta));
      id0 = ids{1}; id1 = ids{min(3, numel(ids))};
      % Preferir extremos con BC si existen
      if isfield(modelo.tablas_entrada, 'condiciones_borde')
        bcs = modelo.tablas_entrada.condiciones_borde;
        if isstruct(bcs), bcs = num2cell(bcs); endif
        pnode = ''; qnode = '';
        for i = 1:numel(bcs)
          bc = bcs{i};
          if ~isfield(bc, 'nodo_ref'), continue; endif
          tipo = upper(char(bc.tipo_bc));
          if strcmp(tipo, 'PRESION'), pnode = char(bc.nodo_ref); endif
          if strcmp(tipo, 'CAUDAL') && isempty(qnode), qnode = char(bc.nodo_ref); endif
        endfor
        if ~isempty(pnode), id0 = pnode; endif
        if ~isempty(qnode), id1 = qnode; endif
      endif

      [dominio, modelo] = aos_cad_hidraulica_dominio_programatico( ...
        modelo, id0, id1, 'TODOS');
      ok = check_local(ok, strcmp(dominio.tipo, 'LOOP_SUBNETWORK'), ...
        sprintf('%s: LOOP_SUBNETWORK', etiqueta));
      ok = check_local(ok, strcmp(dominio.estado_solver, 'LISTO_LAZO_KIRCHHOFF'), ...
        sprintf('%s: LISTO_LAZO_KIRCHHOFF', etiqueta));
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

      aos_cad_hidraulica_dominio_definir_condiciones(20, 100, 0, true);
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok_val = aos_cad_hidraulica_dominio_validar(true);
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, ok_val, sprintf('%s: dominio_validar OK', etiqueta));
      ok = check_local(ok, tiene_codigo_local(modelo, 'HID_LAZO_MODO_CONDICION_OK'), ...
        sprintf('%s: HID_LAZO_MODO_CONDICION_OK', etiqueta));

      resultados = aos_cad_hidraulica_ejecutar(true);
      modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, isfield(resultados, 'resumen'), ...
        sprintf('%s: resultados', etiqueta));
      rr = resultados.resumen{1};
      ok = check_local(ok, isfield(rr, 'convergio') && logical(rr.convergio), ...
        sprintf('%s: convergio', etiqueta));
      ok = check_local(ok, isfield(modelo.simulacion, 'solver_usado') && ...
        strcmp(modelo.simulacion.solver_usado, 'HYD_LOOP'), ...
        sprintf('%s: solver HYD_LOOP', etiqueta));

      % Persistencia .aoscad
      tmp = fullfile(tempdir(), sprintf('aos_test_lazos_%s.aoscad', etiqueta));
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
      aos_aoscad_escribir(tmp, 'SIMPLE', true);
      ok = check_local(ok, exist(tmp, 'file') == 2, ...
        sprintf('%s: .aoscad escrito', etiqueta));
      modelo2 = aos_aoscad_leer(tmp, true);
      ok = check_local(ok, isfield(modelo2, 'info') && ...
        strcmp(char(modelo2.info.schema), 'AOSCAD-0.0.1-DEV1'), ...
        sprintf('%s: schema intacto', etiqueta));
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo2;
      res2 = aos_cad_hidraulica_ejecutar(true);
      q1 = caudal_vector_local(resultados);
      q2 = caudal_vector_local(res2);
      ok = check_local(ok, numel(q1) == numel(q2) && max(abs(q1 - q2)) < 1e-9, ...
        sprintf('%s: recálculo reproduce caudales', etiqueta));
      if exist(tmp, 'file'), delete(tmp); endif
    endfor
  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_red_lazos APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_red_lazos NO APROBADO\n');
  endif
endfunction

function q = caudal_vector_local(res)
  q = [];
  for i = 1:numel(res.tramos)
    r = res.tramos{i};
    if isfield(r, 'caudal_orientado_m3s')
      q(end+1) = r.caudal_orientado_m3s; %#ok<AGROW>
    elseif isfield(r, 'caudal_liquido_m3s')
      q(end+1) = r.caudal_liquido_m3s; %#ok<AGROW>
    else
      q(end+1) = 0; %#ok<AGROW>
    endif
  endfor
endfunction

function tf = tiene_codigo_local(modelo, codigo)
  tf = false;
  if ~isfield(modelo, 'validaciones') || ~isfield(modelo.validaciones, 'items'), return; endif
  items = modelo.validaciones.items;
  if isstruct(items), items = num2cell(items); endif
  for i = 1:numel(items)
    if isstruct(items{i}) && isfield(items{i}, 'codigo') && ...
        strcmp(char(items{i}.codigo), codigo)
      tf = true; return;
    endif
  endfor
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO  %s\n', msg);
    ok = false;
  endif
endfunction

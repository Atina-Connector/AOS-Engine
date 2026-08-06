function ok = test_aos_cad_invalidar_simulacion()
% TEST_AOS_CAD_INVALIDAR_SIMULACION Invalidacion unica atomica (Sprint 7 / T2).
% Headless. No modifica fixtures.
  ok = true;
  fprintf('\n=== test_aos_cad_invalidar_simulacion ===\n');
  global CONFIG_ACTIVA;
  prev = CONFIG_ACTIVA;
  root = aos_cad_raiz();
  tmpdir = fullfile(root, 'intercambio', 'cad', 'tmp_invalidar_sim');
  if exist(tmpdir, 'dir') ~= 7, mkdir(tmpdir); endif

  unwind_protect
    % ---------- U1 helper: estados base ----------
    estados = {'EJECUTADA', 'EJECUTADA_CON_ADVERTENCIAS', 'NO_EJECUTADA', ...
               'INVALIDADA_POR_EDICION'};
    for ie = 1:numel(estados)
      try
        m = modelo_ejecutado_local(estados{ie});
        [m2, items] = aos_cad_invalidar_simulacion(m, ...
          sprintf('motivo unitario %s', estados{ie}), struct());
        ok = check_local(ok, strcmp(char(m2.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
          sprintf('U1 estado=%s -> INVALIDADA_POR_EDICION', estados{ie}));
        ok = check_local(ok, isempty(m2.tablas_resultados.nodos) ...
          && isempty(m2.tablas_resultados.tramos), ...
          sprintf('U1 %s tablas_resultados vacias', estados{ie}));
        ok = check_local(ok, isempty(m2.simulacion.motor) ...
          || ~strcmpi(char(m2.simulacion.estado), 'EJECUTADA'), ...
          sprintf('U1 %s motor no vigente', estados{ie}));
        ok = check_local(ok, ~isempty(items) && isstruct(items{1}) ...
          && isfield(items{1}, 'codigo') && isfield(items{1}, 'mensaje') ...
          && isfield(items{1}, 'severidad'), ...
          sprintf('U1 %s item trazable', estados{ie}));
        ok = check_local(ok, historial_tiene_previo_local(m2), ...
          sprintf('U1 %s historial preserva previo', estados{ie}));
        ok = check_local(ok, ~m2.escena_3d.vigente && ~m2.vinculo_3d.vigente, ...
          sprintf('U1 %s escena/vinculo no vigentes', estados{ie}));
        ok = check_local(ok, recursos_obsoletos_local(m2), ...
          sprintf('U1 %s recursos obsoletos', estados{ie}));
        % Idempotencia
        [m3, ~] = aos_cad_invalidar_simulacion(m2, 'segunda', struct());
        ok = check_local(ok, strcmp(char(m3.simulacion.estado), 'INVALIDADA_POR_EDICION') ...
          && isempty(m3.tablas_resultados.nodos), ...
          sprintf('U1 %s idempotente', estados{ie}));
      catch err
        fprintf(2, 'FALLO U1 %s excepcion: %s\n', estados{ie}, err.message);
        ok = false;
      end_try_catch
    endfor

    % ---------- U2 leer no fuerza EJECUTADA ----------
    try
      m = modelo_ejecutado_local('INVALIDADA_POR_EDICION');
      m.simulacion.motor = 'MOTOR_STUB';
      m.simulacion.corrida_id = 'C_PREV';
      m.simulacion.fecha = '2020-01-01 00:00:00';
      m.tablas_resultados = struct('nodos', {{}}, 'tramos', {{}});
      arch = fullfile(tmpdir, 'leer_respeta_invalidacion.aoscad');
      fid = fopen(arch, 'wt');
      if fid < 0, error('no se pudo crear temporal leer'); endif
      fwrite(fid, jsonencode(m));
      fclose(fid);
      m_leido = aos_aoscad_leer(arch, true);
      ok = check_local(ok, strcmp(char(m_leido.simulacion.estado), ...
        'INVALIDADA_POR_EDICION'), ...
        'U2a leer respeta INVALIDADA_POR_EDICION con motor presente');

      % U2b: sin campo estado + motor + sin resultados => no inferir EJECUTADA
      m2 = modelo_ejecutado_local('EJECUTADA');
      m2.simulacion.motor = 'MOTOR_STUB';
      m2.tablas_resultados = struct('nodos', {{}}, 'tramos', {{}});
      m2.simulacion = rmfield(m2.simulacion, 'estado');
      arch2 = fullfile(tmpdir, 'leer_sin_estado_sin_resultados.aoscad');
      fid = fopen(arch2, 'wt');
      if fid < 0, error('no se pudo crear temporal leer2'); endif
      fwrite(fid, jsonencode(m2));
      fclose(fid);
      m_leido2 = aos_aoscad_leer(arch2, true);
      ok = check_local(ok, ~strcmp(char(m_leido2.simulacion.estado), 'EJECUTADA'), ...
        'U2b leer no fuerza EJECUTADA solo por motor sin resultados');
    catch err
      fprintf(2, 'FALLO U2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- U3 configuracion: estado schema-allowed + motivo especifico ----------
    try
      CONFIG_ACTIVA = struct();
      CONFIG_ACTIVA.cad_topologia = struct();
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local('EJECUTADA');
      cfg = struct('modo', 'TEST_CFG', 'valor', 1);
      aos_cad_hidraulica_aplicar_configuracion(cfg, true);
      mcfg = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(mcfg.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'U3 config usa INVALIDADA_POR_EDICION (schema)');
      ok = check_local(ok, ~strcmp(char(mcfg.simulacion.estado), ...
        'INVALIDADA_POR_CONFIGURACION'), ...
        'U3 config no usa enum incompatible');
      ok = check_local(ok, motivo_config_presente_local(mcfg), ...
        'U3 motivo CONFIGURACION en historial/item');
      ok = check_local(ok, isempty(mcfg.tablas_resultados.nodos) ...
        && isempty(mcfg.tablas_resultados.tramos), ...
        'U3 config limpia resultados');
    catch err
      fprintf(2, 'FALLO U3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- I1 STEP import deja EJECUTADA (gap) -> debe invalidar ----------
    try
      step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
      if exist(step, 'file') ~= 2
        fprintf(2, 'FALLO I1 fixture STEP ausente\n');
        ok = false;
      else
        CONFIG_ACTIVA = struct();
        CONFIG_ACTIVA.cad_topologia = struct();
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local('EJECUTADA');
        CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
        CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);
        ok_imp = aos_cad_importar_step(step, true);
        ok = check_local(ok, ok_imp, 'I1 import STEP ok');
        m_i1 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        ok = check_local(ok, strcmp(char(m_i1.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
          'I1 import STEP invalida simulacion');
        ok = check_local(ok, isempty(m_i1.tablas_resultados.nodos), ...
          'I1 import STEP limpia resultados');
      endif
    catch err
      fprintf(2, 'FALLO I1 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- I2 traer STEP exportado invalida simulacion ----------
    try
      step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
      dir_ed = fullfile(root, 'intercambio', 'cad', 'edicion');
      if exist(dir_ed, 'dir') ~= 7, mkdir(dir_ed); endif
      exportado = fullfile(dir_ed, 'tmp_invalidar_export.step');
      copiar_binario_test_local(step, exportado);
      fid = fopen(exportado, 'a');
      if fid >= 0
        fprintf(fid, '\n/* AOS_INVALIDAR_EXPORT %s */\n', datestr(now, 30));
        fclose(fid);
      endif
      CONFIG_ACTIVA = struct();
      aos_cad_importar_step(step, true);
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local('EJECUTADA');
      CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);
      ok_tr = aos_cad_traer_step_exportado(exportado, true);
      ok = check_local(ok, ok_tr, 'I2 traer ok');
      m_i2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m_i2.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'I2 traer STEP invalida simulacion');
      ok = check_local(ok, isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d') ...
        && ~CONFIG_ACTIVA.cad_topologia.escena_3d.vigente, ...
        'I2 escena no vigente');
    catch err
      fprintf(2, 'FALLO I2 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- I3 recarga mtime STEP invalida simulacion ----------
    try
      step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_sin_ensamble.step');
      dir_ed = fullfile(root, 'intercambio', 'cad', 'edicion');
      if exist(dir_ed, 'dir') ~= 7, mkdir(dir_ed); endif
      [copia, ~] = aos_cad_step_copia_edicion(step, struct('forzar_recopia', true));
      CONFIG_ACTIVA = struct();
      aos_cad_importar_step(copia, true);
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local('EJECUTADA');
      CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);
      aos_cad_registrar_mtime(copia);
      pause(1.05);
      fid = fopen(copia, 'a');
      if fid >= 0
        fprintf(fid, '\n/* AOS_INVALIDAR_MTIME %s */\n', datestr(now, 30));
        fclose(fid);
      endif
      hubo = aos_cad_recargar_si_cambio(false, true);
      ok = check_local(ok, hubo, 'I3 recargar detecta mtime');
      m_i3 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m_i3.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'I3 mtime STEP invalida simulacion');
    catch err
      fprintf(2, 'FALLO I3 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- I4 DXF import con modelo EJECUTADA invalida ----------
    try
      dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_simple.dxf');
      if exist(dxf, 'file') ~= 2
        dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_red_ramificada.dxf');
      endif
      if exist(dxf, 'file') ~= 2
        fprintf(2, 'FALLO I4 fixture DXF ausente\n');
        ok = false;
      else
        CONFIG_ACTIVA = struct();
        CONFIG_ACTIVA.cad_topologia = struct();
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local('EJECUTADA');
        CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
        ok_dxf = aos_cad_importar_dxf(dxf, true);
        ok = check_local(ok, ok_dxf, 'I4 import DXF ok');
        m_i4 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        ok = check_local(ok, strcmp(char(m_i4.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
          'I4 import DXF invalida simulacion');
      endif
    catch err
      fprintf(2, 'FALLO I4 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- I5 editar_campo usa helper coherente ----------
    try
      CONFIG_ACTIVA = struct();
      CONFIG_ACTIVA.cad_topologia = struct();
      m = modelo_ejecutado_local('EJECUTADA');
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m;
      CONFIG_ACTIVA.cad_topologia.escena_3d = m.escena_3d;
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = m.vinculo_3d;
      nid = char(m.tablas_entrada.nodos{1}.id);
      edito = aos_aoscad_editar_campo('nodos', nid, 'z', 9.87, true);
      ok = check_local(ok, edito, 'I5 editar ok');
      m5 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m5.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'I5 editar -> INVALIDADA_POR_EDICION');
      ok = check_local(ok, isempty(m5.tablas_resultados.nodos), 'I5 resultados vacios');
      ok = check_local(ok, ~m5.escena_3d.vigente, 'I5 escena no vigente');
      ok = check_local(ok, recursos_obsoletos_local(m5), 'I5 recursos obsoletos');
    catch err
      fprintf(2, 'FALLO I5 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

    % ---------- I6 invalidar_escena_3d no deja sim vigente ----------
    try
      CONFIG_ACTIVA = struct();
      CONFIG_ACTIVA.cad_topologia = struct();
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo_ejecutado_local('EJECUTADA');
      CONFIG_ACTIVA.cad_topologia.escena_3d = struct('vigente', true);
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = struct('vigente', true);
      aos_cad_invalidar_escena_3d('motivo escena I6', 'step');
      m6 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      ok = check_local(ok, strcmp(char(m6.simulacion.estado), 'INVALIDADA_POR_EDICION'), ...
        'I6 invalidar_escena tambien invalida simulacion');
      ok = check_local(ok, ~CONFIG_ACTIVA.cad_topologia.escena_3d.vigente, ...
        'I6 escena no vigente');
    catch err
      fprintf(2, 'FALLO I6 excepcion: %s\n', err.message);
      ok = false;
    end_try_catch

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev;
    try
      if exist(tmpdir, 'dir') == 7
        delete(fullfile(tmpdir, '*'));
        rmdir(tmpdir);
      endif
    catch
    end_try_catch
  end_unwind_protect

  if ok
    fprintf('RESULTADO: test_aos_cad_invalidar_simulacion APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_invalidar_simulacion NO APROBADO\n');
  endif
endfunction

function m = modelo_ejecutado_local(estado)
  m = aos_aoscad_nuevo_paquete('ENRIQUECIDO', 'INSTALACION', 'HIDRAULICO');
  m.tablas_entrada.nodos = {struct('id', 'N001', 'x', 0, 'y', 0, 'z', 0)};
  m.tablas_entrada.tramos = {struct('id', 'T001', 'nodo_i', 'N001', 'nodo_j', 'N001', ...
    'diametro_m', 0.1, 'longitud_m', 10)};
  m.simulacion.motor = 'MOTOR_STUB';
  m.simulacion.estado = char(estado);
  m.simulacion.corrida_id = 'CORRIDA_PREV';
  m.simulacion.fecha = '2024-01-01 12:00:00';
  m.simulacion.advertencias = {};
  m.tablas_resultados.nodos = {struct('id', 'N001', 'P_Pa', 1e5)};
  m.tablas_resultados.tramos = {struct('id', 'T001', 'Q_m3s', 0.01)};
  if strcmp(estado, 'NO_EJECUTADA')
    m.simulacion.motor = '';
    m.simulacion.corrida_id = '';
    m.simulacion.fecha = '';
    m.tablas_resultados.nodos = {};
    m.tablas_resultados.tramos = {};
  elseif strcmp(estado, 'INVALIDADA_POR_EDICION')
    m.tablas_resultados.nodos = {};
    m.tablas_resultados.tramos = {};
  endif
  m.escena_3d = struct('vigente', true, 'n_objetos', 1);
  m.vinculo_3d = struct('vigente', true);
  m.puertos_3d = struct('vigente', true);
  m.conexiones_3d = struct('vigente', true);
  m.escena_federada = struct('vigente', true);
  m.overlay = struct('vigente', true);
  m.recursos_visuales = struct( ...
    'tipo', 'RECURSOS_VIEWER', ...
    'vigente', true, ...
    'obsoletos', false, ...
    'planos', {{struct('id', 'PLANO_2D_RED', 'vigente', true, 'obsoletos', false)}}, ...
    'graficos', {{}}, ...
    'nota', 'fixture test');
endfunction

function tf = historial_tiene_previo_local(m)
  tf = false;
  if ~isfield(m, 'historial_edicion') || isempty(m.historial_edicion), return; endif
  for i = 1:numel(m.historial_edicion)
    ev = m.historial_edicion{i};
    if ~isstruct(ev), continue; endif
    if isfield(ev, 'resultados_invalidados') && ev.resultados_invalidados
      if isfield(ev, 'motor_previo') || isfield(ev, 'corrida_id_previo') ...
          || isfield(ev, 'estado_previo') || isfield(ev, 'fecha_previa')
        tf = true;
        return;
      endif
    endif
  endfor
endfunction

function tf = recursos_obsoletos_local(m)
  tf = false;
  if ~isfield(m, 'recursos_visuales') || isempty(m.recursos_visuales), tf = true; return; endif
  rv = m.recursos_visuales;
  if ~isstruct(rv), return; endif
  if isfield(rv, 'vigente') && ~rv.vigente, tf = true; endif
  if isfield(rv, 'obsoletos') && rv.obsoletos, tf = true; endif
  if isfield(rv, 'planos') && ~isempty(rv.planos)
    p = rv.planos{1};
    if isstruct(p) && ((isfield(p, 'vigente') && ~p.vigente) ...
        || (isfield(p, 'obsoletos') && p.obsoletos))
      tf = true;
    endif
  endif
endfunction

function tf = motivo_config_presente_local(m)
  tf = false;
  if isfield(m, 'historial_edicion')
    for i = 1:numel(m.historial_edicion)
      ev = m.historial_edicion{i};
      if isstruct(ev) && isfield(ev, 'accion') ...
          && ~isempty(strfind(upper(char(ev.accion)), 'CONFIGURACION'))
        tf = true; return;
      endif
      if isstruct(ev) && isfield(ev, 'motivo') ...
          && ~isempty(strfind(upper(char(ev.motivo)), 'CONFIGURACION'))
        tf = true; return;
      endif
    endfor
  endif
  if isfield(m, 'validaciones') && isstruct(m.validaciones) ...
      && isfield(m.validaciones, 'items')
    for i = 1:numel(m.validaciones.items)
      it = m.validaciones.items{i};
      if ~isstruct(it), continue; endif
      blob = '';
      if isfield(it, 'codigo'), blob = [blob ' ' upper(char(it.codigo))]; endif
      if isfield(it, 'mensaje'), blob = [blob ' ' upper(char(it.mensaje))]; endif
      if isfield(it, 'origen'), blob = [blob ' ' upper(char(it.origen))]; endif
      if ~isempty(strfind(blob, 'CONFIGURACION')) || ~isempty(strfind(blob, 'HID_RECALCULO'))
        tf = true; return;
      endif
    endfor
  endif
  if isfield(m, 'simulacion') && isfield(m.simulacion, 'advertencias')
    for i = 1:numel(m.simulacion.advertencias)
      if ~isempty(strfind(upper(char(m.simulacion.advertencias{i})), 'CONFIGURACION'))
        tf = true; return;
      endif
    endfor
  endif
endfunction

function ok = check_local(ok, cond, msg)
  if cond
    fprintf('OK  %s\n', msg);
  else
    fprintf(2, 'FALLO: %s\n', msg);
    ok = false;
  endif
endfunction

function copiar_binario_test_local(origen, destino)
  [pd, ~, ~] = fileparts(destino);
  if ~isempty(pd) && exist(pd, 'dir') ~= 7, mkdir(pd); endif
  fid_i = fopen(origen, 'rb');
  if fid_i < 0, error('no se pudo leer %s', origen); endif
  data = fread(fid_i);
  fclose(fid_i);
  fid_o = fopen(destino, 'wb');
  if fid_o < 0, error('no se pudo escribir %s', destino); endif
  fwrite(fid_o, data);
  fclose(fid_o);
endfunction

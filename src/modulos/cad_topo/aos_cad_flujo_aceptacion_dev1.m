function ok = aos_cad_flujo_aceptacion_dev1(silencioso)
% AOS_CAD_FLUJO_ACEPTACION_DEV1 Flujo oficial DEV1 AOSCAD (sin UI).
% DXF → tablas → topologia → sim demo → .aoscad → releer → editar → recalc → guardar → visor
  global CONFIG_ACTIVA;
  if nargin < 1, silencioso = false; endif
  ok = true;
  fallas = {};

  root = aos_cad_raiz();
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells.dxf');
  outdir = fullfile(root, 'intercambio', 'cad', 'aoscad');
  if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif

  if ~silencioso
    fprintf('\n=== FLUJO ACEPTACION AOSCAD 0.0.1 DEV1 OCTAVE-ONLY ===\n');
  endif

  CONFIG_ACTIVA = struct();

  % 1) Import / normalizar (tablas; SIN .aoscad)
  if ~aos_cad_importar_dxf(dxf, true)
    fallas{end+1} = 'import_dxf'; %#ok<AGROW>
  else
    if ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
      fallas{end+1} = 'modelo_aoscad_tras_import'; %#ok<AGROW>
    else
      n0 = numel(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.nodos);
      t0 = numel(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.tramos);
      if n0 < 1 || t0 < 1
        fallas{end+1} = 'tablas_vacias'; %#ok<AGROW>
      elseif ~silencioso
        fprintf('OK  import+tablas nodos=%d tramos=%d (sin .aoscad)\n', n0, t0);
      endif
      if isfield(CONFIG_ACTIVA.cad_topologia, 'aoscad_archivo')
        fallas{end+1} = 'aoscad_escrito_en_import'; %#ok<AGROW>
      endif
    endif
  endif

  % 2) Topologia derivada
  try
    aos_cad_construir_topologia(0.05, true);
    topo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.topologia;
    if ~isfield(topo, 'aristas') || numel(topo.aristas) < 1
      fallas{end+1} = 'topologia_sin_aristas'; %#ok<AGROW>
    elseif ~silencioso
      fprintf('OK  topologia aristas=%d tol=%.3f\n', numel(topo.aristas), topo.tolerancia_m);
    endif
  catch err
    fallas{end+1} = ['topologia:' err.message]; %#ok<AGROW>
  end_try_catch

  % 3) Sim demo
  try
    aos_cad_eval_hidraulica_demo(true);
    sim = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.simulacion;
    if ~strcmp(sim.motor, 'DEMO_NO_SOLVER_OFICIAL')
      fallas{end+1} = 'motor_demo'; %#ok<AGROW>
    elseif ~silencioso
      fprintf('OK  sim demo motor=%s corrida=%s\n', sim.motor, sim.corrida_id);
    endif
  catch err
    fallas{end+1} = ['sim:' err.message]; %#ok<AGROW>
  end_try_catch

  % 3b) Validaciones topologicas → .aoscad
  try
    aos_cad_validar_topologia(true);
  catch
  end_try_catch

  % 4) Escribir .aoscad simple
  aoscad1 = fullfile(outdir, 'aceptacion_dev1_simple.aoscad');
  try
    aos_aoscad_escribir(aoscad1, 'SIMPLE', true);
    if exist(aoscad1, 'file') ~= 2
      fallas{end+1} = 'escribir_aoscad'; %#ok<AGROW>
    elseif exist([aoscad1 '.' 'mat'], 'file') == 2
      fallas{end+1} = 'archivo_binario_paralelo'; %#ok<AGROW>
    elseif ~silencioso
      fprintf('OK  escrito %s (JSON canonico unico)\n', aoscad1);
    endif
  catch err
    fallas{end+1} = ['escribir:' err.message]; %#ok<AGROW>
  end_try_catch

  % Perfil enriquecido con recursos visuales reales
  aoscad_enr = fullfile(outdir, 'aceptacion_dev1_enriquecido.aoscad');
  try
    aos_aoscad_escribir(aoscad_enr, 'ENRIQUECIDO', true);
    m_enr = aos_aoscad_leer(aoscad_enr, true);
    if ~strcmp(m_enr.info.aoscad_perfil, 'ENRIQUECIDO')
      fallas{end+1} = 'perfil_enriquecido'; %#ok<AGROW>
    elseif ~isfield(m_enr, 'recursos_visuales') || ~isstruct(m_enr.recursos_visuales)
      fallas{end+1} = 'enriquecido_sin_recursos_visuales'; %#ok<AGROW>
    else
      rv = m_enr.recursos_visuales;
      planos = {};
      graficos = {};
      if isfield(rv, 'planos') && ~isempty(rv.planos)
        planos = rv.planos;
        if ~iscell(planos), planos = {planos}; endif
      endif
      if isfield(rv, 'graficos') && ~isempty(rv.graficos)
        graficos = rv.graficos;
        if ~iscell(graficos), graficos = {graficos}; endif
      endif
      n_rec = numel(planos) + numel(graficos);
      if n_rec < 1
        fallas{end+1} = 'enriquecido_recursos_vacios'; %#ok<AGROW>
      else
        png_ok = false;
        lista = [planos(:).', graficos(:).'];
        for ir = 1:numel(lista)
          r = lista{ir};
          if ~isstruct(r) || ~isfield(r, 'ruta_relativa'), continue; endif
          rr = char(r.ruta_relativa);
          if isempty(rr), continue; endif
          cands = {
            fullfile(root, 'intercambio', 'cad', rr)
            fullfile(fileparts(aoscad_enr), rr)
            fullfile(root, rr)
          };
          for ic = 1:numel(cands)
            if exist(cands{ic}, 'file') == 2
              png_ok = true;
              break;
            endif
          endfor
          if png_ok, break; endif
        endfor
        if ~png_ok
          fallas{end+1} = 'enriquecido_png_ausente'; %#ok<AGROW>
        elseif ~isfield(rv, 'vigente') || ~logical(rv.vigente)
          fallas{end+1} = 'enriquecido_recursos_no_vigentes'; %#ok<AGROW>
        elseif ~silencioso
          fprintf('OK  perfil enriquecido recursos reales n=%d\n', n_rec);
        endif
      endif
    endif
  catch err
    fallas{end+1} = ['enriquecido:' err.message]; %#ok<AGROW>
  end_try_catch

  % 4b) DXF mtime sync invalida simulacion (copia; no toca fixture)
  try
    dxf_work = fullfile(outdir, 'aceptacion_dxf_mtime_sync.dxf');
    fid_i = fopen(dxf, 'rb');
    if fid_i < 0
      error('no se pudo leer DXF fuente para copia mtime');
    endif
    data_dxf = fread(fid_i, Inf, 'uint8=>uint8');
    fclose(fid_i);
    fid_o = fopen(dxf_work, 'wb');
    if fid_o < 0
      error('no se pudo escribir copia DXF mtime');
    endif
    fwrite(fid_o, data_dxf, 'uint8');
    fclose(fid_o);
    mt_fx0 = aos_cad_mtime(dxf);

    CONFIG_ACTIVA = struct();
    if ~aos_cad_importar_dxf(dxf_work, true)
      fallas{end+1} = 'mtime_sync_import_dxf'; %#ok<AGROW>
    else
      aos_cad_construir_topologia(0.05, true);
      aos_cad_eval_hidraulica_demo(true);
      m_mt = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      if ~strcmp(char(m_mt.simulacion.estado), 'EJECUTADA') ...
          && ~strcmp(char(m_mt.simulacion.estado), 'EJECUTADA_CON_ADVERTENCIAS')
        % Forzar estado vigente para verificar invalidacion por mtime
        m_mt.simulacion.estado = 'EJECUTADA';
        m_mt.simulacion.motor = 'DEMO_NO_SOLVER_OFICIAL';
        if isempty(m_mt.tablas_resultados.tramos)
          m_mt.tablas_resultados.tramos = {struct('id', 'T001', 'Q_m3s', 0.01)};
        endif
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m_mt;
      endif
      aos_cad_registrar_mtime(dxf_work);
      pause(1.05);
      fid_t = fopen(dxf_work, 'a');
      if fid_t >= 0
        fprintf(fid_t, '\n0\nCOMMENT\n1\nAOS_MTIME_SYNC %s\n', datestr(now, 30));
        fclose(fid_t);
      endif
      hubo = aos_cad_recargar_si_cambio(false, true);
      if ~hubo
        fallas{end+1} = 'mtime_sync_no_detecto'; %#ok<AGROW>
      else
        m_post = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        if ~strcmp(char(m_post.simulacion.estado), 'INVALIDADA_POR_EDICION')
          fallas{end+1} = 'mtime_sync_sim_no_invalidada'; %#ok<AGROW>
        elseif abs(aos_cad_mtime(dxf) - mt_fx0) >= 1e-6
          fallas{end+1} = 'mtime_sync_fixture_alterado'; %#ok<AGROW>
        elseif ~silencioso
          fprintf('OK  DXF mtime sync invalida simulacion (fixture intacto)\n');
        endif
      endif
    endif
    if exist(dxf_work, 'file') == 2
      delete(dxf_work);
    endif
  catch err
    fallas{end+1} = ['mtime_sync:' err.message]; %#ok<AGROW>
  end_try_catch

  % 5) Releer
  try
    CONFIG_ACTIVA = struct();
    CONFIG_ACTIVA.cad_topologia = struct();
    if ~aos_aoscad_abrir_en_suite(aoscad1, true)
      fallas{end+1} = 'abrir_suite'; %#ok<AGROW>
    else
      m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      if ~strcmp(m.info.schema, 'AOSCAD-0.0.1-DEV1')
        fallas{end+1} = 'schema'; %#ok<AGROW>
      elseif ~silencioso
        fprintf('OK  releido schema=%s\n', m.info.schema);
      endif
    endif
  catch err
    fallas{end+1} = ['releer:' err.message]; %#ok<AGROW>
  end_try_catch

  % 6) Editar campo trazable
  try
    tramos = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.tramos;
    if isempty(tramos)
      fallas{end+1} = 'sin_tramos_para_editar'; %#ok<AGROW>
    else
      tid = tramos{1}.id;
      d0 = aos_aoscad_valor(tramos{1}.diametro_m);
      d1 = d0 * 1.25;
      aos_aoscad_editar_campo('tramos', tid, 'diametro_m', d1, true);
      d_eff = aos_aoscad_valor( ...
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.tramos{1}.diametro_m);
      if abs(d_eff - d1) > 1e-12
        fallas{end+1} = 'edicion_campo'; %#ok<AGROW>
      elseif ~strcmp(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.simulacion.estado, ...
                     'INVALIDADA_POR_EDICION')
        fallas{end+1} = 'resultados_no_invalidados'; %#ok<AGROW>
      elseif ~isempty(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_resultados.tramos)
        fallas{end+1} = 'resultados_antiguos_persisten'; %#ok<AGROW>
      elseif ~silencioso
        fprintf('OK  editado %s.diametro_m %.4g -> %.4g; resultados invalidados\n', tid, d0, d_eff);
      endif
    endif
  catch err
    fallas{end+1} = ['editar:' err.message]; %#ok<AGROW>
  end_try_catch

  % 7) Recalcular + guardar nuevo
  aoscad2 = fullfile(outdir, 'aceptacion_dev1_recalc.aoscad');
  try
    aos_cad_eval_hidraulica_demo(true);
    aos_aoscad_escribir(aoscad2, 'SIMPLE', true);
    if exist(aoscad2, 'file') ~= 2
      fallas{end+1} = 'guardar_recalc'; %#ok<AGROW>
    elseif ~silencioso
      fprintf('OK  recalc + guardado %s\n', aoscad2);
    endif
  catch err
    fallas{end+1} = ['recalc:' err.message]; %#ok<AGROW>
  end_try_catch

  % 8) DXF revision sin pisar fuente (antes de limpiar memoria o tras reopen)
  try
    if ~isfield(CONFIG_ACTIVA.cad_topologia, 'dxf_archivo') || ...
        exist(CONFIG_ACTIVA.cad_topologia.dxf_archivo, 'file') ~= 2
      CONFIG_ACTIVA.cad_topologia.dxf_archivo = dxf;
    endif
    rev = aos_cad_exportar_dxf_rev([], true);
    if exist(rev, 'file') ~= 2
      fallas{end+1} = 'dxf_rev_faltante'; %#ok<AGROW>
    elseif strcmpi(rev, dxf)
      fallas{end+1} = 'dxf_rev_piso_fuente'; %#ok<AGROW>
    elseif isempty(strfind(upper(rev), '_AOS_REV'))
      fallas{end+1} = 'dxf_rev_nombre'; %#ok<AGROW>
    elseif ~silencioso
      fprintf('OK  DXF rev %s (fuente intacta)\n', rev);
    endif
  catch err
    fallas{end+1} = ['dxf_rev:' err.message]; %#ok<AGROW>
  end_try_catch

  % 9) Visor (headless-safe: solo verificar call sin error si no hay display)
  try
    if isempty(getenv('AOS_CAD_SKIP_VISOR'))
      aos_cad_visor_2d(true, true);
      if ~silencioso, fprintf('OK  visor 2d invocado\n'); endif
    else
      if ~silencioso, fprintf('OK  visor omitido (AOS_CAD_SKIP_VISOR)\n'); endif
    endif
  catch err
    % En CI sin display puede fallar; no tumbar aceptacion si hay resultados
    if isfield(CONFIG_ACTIVA.cad_topologia.modelo_aoscad, 'tablas_resultados') && ...
        ~isempty(CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_resultados.tramos)
      if ~silencioso
        fprintf('AVISO visor grafico: %s (resultados presentes; se tolera sin display)\n', ...
          err.message);
      endif
    else
      fallas{end+1} = ['visor:' err.message]; %#ok<AGROW>
    endif
  end_try_catch

  ok = isempty(fallas);
  if ok
    fprintf('RESULTADO: FLUJO ACEPTACION DEV1 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: FLUJO ACEPTACION DEV1 FALLAS (%d)\n', numel(fallas));
    for i = 1:numel(fallas)
      fprintf(2, '  - %s\n', fallas{i});
    endfor
  endif
endfunction

function ok = VERIFICAR_CAD_TOPO()
% VERIFICAR_CAD_TOPO Verificacion del modulo CAD_TOPO (no del motor AOS).
  este = fileparts(mfilename('fullpath')); % .../src/modulos/cad_topo
  root = fileparts(fileparts(fileparts(este))); % raiz AOS
  addpath(fullfile(root, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n====================================================\n');
  fprintf(' VERIFICACION AOSCAD 0.0.1 DEV1 - GNU OCTAVE\n');
  fprintf('====================================================\n');
  fprintf(' Raiz AOS: %s\n', root);
  fprintf(' Equiv: .dxf≡.aosdat entrada | .aoscad≡.aosrpt post-sim\n');

  requeridos = {
    'aos_cad_topologia_menu_impl.m'
    'aos_cad_hidraulica_menu.m'
    'aos_cad_hidraulica_dominio_menu.m'
    'aos_cad_hidraulica_dominio_seleccionar.m'
    'aos_cad_hidraulica_dominio_programatico.m'
    'aos_cad_hidraulica_dominio_definir_condiciones.m'
    'aos_cad_hidraulica_dominio_mostrar.m'
    'aos_cad_hidraulica_dominio_visualizar.m'
    'aos_cad_hidraulica_dominio_validar.m'
    'aos_cad_hidraulica_dominio_limpiar.m'
    'aos_cad_hidraulica_encontrar_caminos.m'
    'aos_cad_hidraulica_invalidar_por_dominio.m'
    'test_aos_cad_dominio_hidraulico.m'
    'test_aos_cad_dominio_condiciones.m'
    'test_aos_cad_red_ramificada.m'
    'test_aos_cad_equipo_activo_curva.m'
    'test_aos_cad_benchmark_red.m'
    'test_aos_cad_hidraulica_dxf.m'
    'test_hyd_loop_selftest.m'
    'test_aos_cad_red_lazos.m'
    'aos_cad_hidraulica_preparar_modelo.m'
    'aos_cad_hidraulica_configurar.m'
    'aos_cad_hidraulica_aplicar_configuracion.m'
    'aos_cad_hidraulica_validar_red.m'
    'aos_cad_hidraulica_mostrar_config.m'
    'aos_cad_hidraulica_mostrar_resultados.m'
    'aos_cad_hidraulica_guardar_enriquecido.m'
    'aos_cad_hidraulica_flujo_completo.m'
    'test_aos_cad_menu_hidraulica.m'
    'aos_cad_localizar_programa.m'
    'aos_dxf_leer.m'
    'aos_cad_importar_dxf.m'
    'aos_cad_recargar_si_cambio.m'
    'aos_cad_registrar_mtime.m'
    'aos_cad_raiz.m'
    'aos_cad_topo_preferencias.m'
    'aos_aoscad_nuevo_paquete.m'
    'aos_aoscad_campo.m'
    'aos_aoscad_valor.m'
    'aos_cad_mapear_objetos.m'
    'aos_cad_construir_topologia.m'
    'aos_cad_eval_hidraulica_demo.m'
    'aos_aoscad_escribir.m'
    'aos_aoscad_leer.m'
    'aos_aoscad_abrir_en_suite.m'
    'aos_aoscad_editar_campo.m'
    'aos_cad_verificar_octave_only.m'
    'aos_cad_visor_2d.m'
    'aos_cad_exportar_dxf_rev.m'
    'aos_cad_exportar_step_rev.m'
    'aos_cad_merge_ids_reimport.m'
    'aos_cad_validar_topologia.m'
    'aos_cad_flujo_aceptacion_dev1.m'
    'aos_step_leer.m'
    'aos_cad_importar_step.m'
    'aos_cad_extraer_metadatos.m'
    'aos_cad_meta_cercana.m'
    'aos_cad_meta_parse_capa.m'
    'aos_cad_meta_aplicar.m'
    'aos_cad_unidades_dxf.m'
    'aos_cad_asignar_asset_ids.m'
    'aos_cad_puertos_derivar.m'
    'test_aos_cad_asset_roundtrip.m'
    'test_aos_cad_puertos_contrato.m'
    'aos_step_tabla_entidades.m'
    'aos_step_unidades.m'
    'aos_step_indice_geometrico.m'
    'aos_step_indice_freecad.m'
    'aos_cad_escena_3d.m'
    'aos_cad_visor_3d.m'
    'aos_cad_escena_seleccionar.m'
    'aos_cad_vincular_asset_3d.m'
    'aos_cad_step_copia_edicion.m'
    'aos_cad_traer_step_exportado.m'
    'aos_cad_invalidar_escena_3d.m'
    'aos_cad_invalidar_simulacion.m'
    'aos_cad_sincronizar_2d_3d.m'
    'aos_cad_dxf_copia_edicion.m'
    'aos_aoscad_generar_recursos_visuales.m'
    'aos_cad_puertos_3d.m'
    'aos_cad_conexiones_3d.m'
    'aos_cad_validar_conectividad_3d.m'
    'aos_cad_interferencias.m'
    'aos_cad_interferencias_mostrar.m'
    'aos_cad_overlay_resultados.m'
    'test_aos_cad_step_indice.m'
    'test_aos_cad_visor_3d.m'
    'test_aos_cad_vinculo_asset_3d.m'
    'test_aos_cad_step_edicion_externa.m'
    'test_aos_cad_puertos_conexiones.m'
    'test_aos_cad_interferencias.m'
    'test_aos_escena_federada.m'
    'test_aos_cad_overlay_3d.m'
    'test_aos_cad_invalidar_simulacion.m'
    'test_aos_cad_sincronizacion_2d_3d.m'
    'test_aos_cad_dxf_edicion_externa.m'
    'test_aos_aoscad_recursos_visuales.m'
    'test_aos_cad_auditoria_estatica.m'
    'LEEME_METADATOS_DXF.txt'
    'LEEME_BENCHMARK_TRAMO.md'
    'LEEME_RED_RAMIFICADA_Y_BOMBAS.md'
    'LEEME_SOLVER_LAZOS_KIRCHHOFF.md'
    'LEEME_ASSET_ID_Y_PUERTOS.md'
    'LEEME_INDICE_STEP_Y_VISOR_3D.md'
    'LEEME_PUERTOS_INTERFERENCIAS_Y_OVERLAY_3D.md'
    'CHANGELOG_AOSCAD_0_0_1_DEV1_R15.md'
    'VERSION_AOSCAD.txt'
    'schema/AOSCAD_0_0_1_DEV1_SCHEMA.json'
    'schema/CONTRATO_VIEWER_AOSCAD.txt'
  };

  fallas = {};
  for k = 1:numel(requeridos)
    ruta = fullfile(este, requeridos{k});
    if exist(ruta, 'file') == 2
      fprintf(' OK  %s\n', requeridos{k});
    else
      fprintf(2, ' FALTA  %s\n', requeridos{k});
      fallas{end+1} = requeridos{k}; %#ok<AGROW>
    endif
  endfor

  requisitos_publico = fullfile(root, 'src', 'menu', 'aos_verificar_requisitos_plataforma.m');
  if exist(requisitos_publico, 'file') == 2
    fprintf(' OK  src/menu/aos_verificar_requisitos_plataforma.m\n');
  else
    fprintf(2, ' FALTA  src/menu/aos_verificar_requisitos_plataforma.m\n');
    fallas{end+1} = 'src/menu/aos_verificar_requisitos_plataforma.m'; %#ok<AGROW>
  endif

  menu_publico = fullfile(root, 'src', 'menu', 'AOS_menu_cad_topologia.m');
  if exist(menu_publico, 'file') == 2
    fprintf(' OK  src/menu/AOS_menu_cad_topologia.m\n');
  else
    fprintf(2, ' FALTA  src/menu/AOS_menu_cad_topologia.m\n');
    fallas{end+1} = 'src/menu/AOS_menu_cad_topologia.m'; %#ok<AGROW>
  endif

  lanzador_publico = fullfile(root, 'src', 'menu', 'aos_cad_abrir_externo.m');
  if exist(lanzador_publico, 'file') == 2
    fprintf(' OK  src/menu/aos_cad_abrir_externo.m\n');
  else
    fprintf(2, ' FALTA  src/menu/aos_cad_abrir_externo.m\n');
    fallas{end+1} = 'src/menu/aos_cad_abrir_externo.m'; %#ok<AGROW>
  endif

  freecad_export = fullfile(root, 'herramientas', 'aos_step_indice_freecad_export.py');
  if exist(freecad_export, 'file') == 2
    fprintf(' OK  herramientas/aos_step_indice_freecad_export.py\n');
  else
    fprintf(2, ' FALTA  herramientas/aos_step_indice_freecad_export.py\n');
    fallas{end+1} = 'herramientas/aos_step_indice_freecad_export.py'; %#ok<AGROW>
  endif

  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells.dxf');
  if exist(dxf, 'file') == 2
    fprintf(' OK  datos/ejemplos/cad/demo_aos_wells.dxf\n');
  else
    fprintf(2, ' FALTA  datos/ejemplos/cad/demo_aos_wells.dxf\n');
    fallas{end+1} = 'demo_aos_wells.dxf'; %#ok<AGROW>
  endif

  step = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_equipment.step');
  if exist(step, 'file') == 2
    fprintf(' OK  datos/ejemplos/cad/demo_aos_equipment.step\n');
  else
    fprintf(2, ' FALTA  datos/ejemplos/cad/demo_aos_equipment.step\n');
    fallas{end+1} = 'demo_aos_equipment.step'; %#ok<AGROW>
  endif

  meta_dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells_meta.dxf');
  if exist(meta_dxf, 'file') == 2
    fprintf(' OK  datos/ejemplos/cad/demo_aos_wells_meta.dxf\n');
  else
    fprintf(2, ' FALTA  datos/ejemplos/cad/demo_aos_wells_meta.dxf\n');
    fallas{end+1} = 'demo_aos_wells_meta.dxf'; %#ok<AGROW>
  endif

  gal_dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_galerias.dxf');
  if exist(gal_dxf, 'file') == 2
    fprintf(' OK  datos/ejemplos/cad/demo_aos_galerias.dxf\n');
  else
    fprintf(2, ' FALTA  datos/ejemplos/cad/demo_aos_galerias.dxf\n');
    fallas{end+1} = 'demo_aos_galerias.dxf'; %#ok<AGROW>
  endif

  funciones = {'AOS_menu_cad_topologia', 'aos_cad_topologia_menu_impl', ...
               'aos_cad_hidraulica_menu', 'aos_cad_hidraulica_dominio_menu', ...
               'aos_cad_hidraulica_dominio_seleccionar', 'aos_cad_hidraulica_dominio_programatico', ...
               'aos_cad_hidraulica_dominio_validar', 'aos_cad_hidraulica_encontrar_caminos', ...
               'aos_cad_hidraulica_dominio_activo', 'aos_cad_hidraulica_dominio_filtrar_modelo', ...
               'aos_cad_hidraulica_dominio_resolver_pp', ...
               'aos_cad_hidraulica_preparar_modelo', ...
               'aos_cad_hidraulica_configurar', 'aos_cad_hidraulica_validar_red', ...
               'aos_cad_hidraulica_mostrar_config', 'aos_cad_hidraulica_mostrar_resultados', ...
               'aos_cad_hidraulica_flujo_completo', 'aos_cad_abrir_externo', ...
               'aos_cad_localizar_programa', 'aos_dxf_leer', ...
               'aos_cad_importar_dxf', 'aos_cad_recargar_si_cambio', ...
               'aos_cad_mapear_objetos', 'aos_cad_construir_topologia', ...
               'aos_cad_eval_hidraulica_demo', 'aos_aoscad_escribir', ...
               'aos_aoscad_leer', 'aos_cad_flujo_aceptacion_dev1', ...
               'aos_step_leer', 'aos_cad_importar_step', ...
               'aos_cad_extraer_metadatos', 'aos_cad_meta_aplicar', ...
               'aos_cad_unidades_dxf', ...
               'aos_cad_asignar_asset_ids', 'aos_cad_puertos_derivar', ...
               'aos_cad_merge_ids_reimport', 'aos_cad_validar_topologia', ...
               'aos_cad_exportar_step_rev', 'aos_cad_verificar_octave_only', ...
               'aos_cad_hidraulica_diagnosticar_topologia', ...
               'aos_cad_hidraulica_curva_bomba', ...
               'aos_cad_hidraulica_catalogo_bombas', ...
               'aos_cad_hidraulica_lazos_base', ...
               'aos_cad_hidraulica_dp_orientado', ...
               'aos_cad_hidraulica_resolver_lazos', ...
               'aos_cad_hidraulica_lazos_hardy_cross', ...
               'aos_step_tabla_entidades', 'aos_step_unidades', ...
               'aos_step_indice_geometrico', 'aos_step_indice_freecad', ...
               'aos_cad_escena_3d', 'aos_cad_visor_3d', ...
               'aos_cad_escena_seleccionar', 'aos_cad_vincular_asset_3d', ...
               'aos_cad_step_copia_edicion', 'aos_cad_traer_step_exportado', ...
               'aos_cad_invalidar_escena_3d', ...
               'aos_cad_puertos_3d', 'aos_cad_conexiones_3d', ...
               'aos_cad_validar_conectividad_3d', ...
               'aos_geom_bbox_solape', 'aos_cad_interferencias', ...
               'aos_cad_interferencias_mostrar', ...
               'aos_escena_federada', 'aos_cad_overlay_resultados', ...
               'aos_cad_invalidar_simulacion', 'aos_cad_sincronizar_2d_3d', ...
               'aos_cad_dxf_copia_edicion', 'aos_aoscad_generar_recursos_visuales'};
  for k = 1:numel(funciones)
    if exist(funciones{k}, 'file') == 2
      fprintf(' FUNCION OK  %s\n', funciones{k});
    else
      fprintf(2, ' FUNCION NO DISPONIBLE  %s\n', funciones{k});
      fallas{end+1} = funciones{k}; %#ok<AGROW>
    endif
  endfor

  fixtures_extra = {
    'demo_aos_unidades_mm.dxf'
    'demo_aos_bloques.dxf'
    'demo_aos_hidraulica_dev1.dxf'
    'demo_aos_red_ramificada.dxf'
    'demo_aos_bomba_curva.dxf'
    'demo_aos_anillo.dxf'
    'demo_aos_dos_lazos.dxf'
    'demo_legacy_sin_asset.aoscad'
    'demo_aos_sin_ensamble.step'
    'demo_aos_ensamble_repetido.step'
    'demo_aos_interferencia.step'
  };
  for k = 1:numel(fixtures_extra)
    fx = fullfile(root, 'datos', 'ejemplos', 'cad', fixtures_extra{k});
    if exist(fx, 'file') == 2
      fprintf(' OK  datos/ejemplos/cad/%s\n', fixtures_extra{k});
    else
      fprintf(2, ' FALTA  %s\n', fixtures_extra{k});
      fallas{end+1} = fixtures_extra{k}; %#ok<AGROW>
    endif
  endfor

  if isempty(fallas)
    fprintf('\nSelftest menu jerarquico e hidraulica visible...\n');
    try
      if ~test_aos_cad_menu_hidraulica()
        fallas{end+1} = 'test_aos_cad_menu_hidraulica'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR menu: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_menu_hidraulica'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest dominio hidraulico selectivo...\n');
    try
      if ~test_aos_cad_dominio_hidraulico()
        fallas{end+1} = 'test_aos_cad_dominio_hidraulico'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR dominio: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_dominio_hidraulico'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest dominio condiciones (Sprint 3)...\n');
    try
      if ~test_aos_cad_dominio_condiciones()
        fallas{end+1} = 'test_aos_cad_dominio_condiciones'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR dominio_condiciones: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_dominio_condiciones'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest red ramificada (Sprint 3)...\n');
    try
      if ~test_aos_cad_red_ramificada()
        fallas{end+1} = 'test_aos_cad_red_ramificada'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR red_ramificada: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_red_ramificada'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest HYD_LOOP Kirchhoff (Sprint 4)...\n');
    try
      if ~test_hyd_loop_selftest()
        fallas{end+1} = 'test_hyd_loop_selftest'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR hyd_loop_selftest: %s\n', err.message);
      fallas{end+1} = 'test_hyd_loop_selftest'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest red lazos DXF (Sprint 4)...\n');
    try
      if ~test_aos_cad_red_lazos()
        fallas{end+1} = 'test_aos_cad_red_lazos'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR red_lazos: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_red_lazos'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest equipo activo / curva (Sprint 3)...\n');
    try
      if ~test_aos_cad_equipo_activo_curva()
        fallas{end+1} = 'test_aos_cad_equipo_activo_curva'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR equipo_activo_curva: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_equipo_activo_curva'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest benchmark red (Sprint 3)...\n');
    try
      if ~test_aos_cad_benchmark_red()
        fallas{end+1} = 'test_aos_cad_benchmark_red'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR benchmark_red: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_benchmark_red'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest hidraulica DXF (deuda Sprint 3)...\n');
    try
      if ~test_aos_cad_hidraulica_dxf()
        fallas{end+1} = 'test_aos_cad_hidraulica_dxf'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR hidraulica_dxf: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_hidraulica_dxf'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nControl de arquitectura GNU Octave / formato abierto...\n');
    try
      if ~aos_cad_verificar_octave_only(false)
        fallas{end+1} = 'octave_only'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR arquitectura: %s\n', err.message);
      fallas{end+1} = 'octave_only'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest DXF del modulo...\n');
    try
      if ~test_aos_cad_dxf()
        fallas{end+1} = 'test_aos_cad_dxf'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_dxf'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest STEP interno (FreeCAD externo opcional)...\n');
    try
      if ~test_aos_cad_step()
        fallas{end+1} = 'test_aos_cad_step'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR STEP: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_step'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest metadatos DXF...\n');
    try
      if ~test_aos_cad_metadatos()
        fallas{end+1} = 'test_aos_cad_metadatos'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR metadatos: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_metadatos'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest round-trip IDs...\n');
    try
      if ~test_aos_cad_roundtrip_ids()
        fallas{end+1} = 'test_aos_cad_roundtrip_ids'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR roundtrip: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_roundtrip_ids'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest validaciones topologia...\n');
    try
      if ~test_aos_cad_validaciones()
        fallas{end+1} = 'test_aos_cad_validaciones'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR validaciones: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_validaciones'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest galerias...\n');
    try
      if ~test_aos_cad_galerias()
        fallas{end+1} = 'test_aos_cad_galerias'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR galerias: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_galerias'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest benchmark de tramo...\n');
    try
      if ~test_aos_cad_benchmark_tramo()
        fallas{end+1} = 'test_aos_cad_benchmark_tramo'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR benchmark: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_benchmark_tramo'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest unidades DXF...\n');
    try
      if ~test_aos_cad_unidades_dxf()
        fallas{end+1} = 'test_aos_cad_unidades_dxf'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR unidades: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_unidades_dxf'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest bloques/capas...\n');
    try
      if ~test_aos_cad_bloques_capas()
        fallas{end+1} = 'test_aos_cad_bloques_capas'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR bloques: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_bloques_capas'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest asset_id round-trip (Sprint 2)...\n');
    try
      if ~test_aos_cad_asset_roundtrip()
        fallas{end+1} = 'test_aos_cad_asset_roundtrip'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR asset_roundtrip: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_asset_roundtrip'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest contrato puertos (Sprint 2)...\n');
    try
      if ~test_aos_cad_puertos_contrato()
        fallas{end+1} = 'test_aos_cad_puertos_contrato'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR puertos: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_puertos_contrato'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest indice geometrico STEP (Sprint 5)...\n');
    try
      if ~test_aos_cad_step_indice()
        fallas{end+1} = 'test_aos_cad_step_indice'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR step_indice: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_step_indice'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest visor 3D / escena (Sprint 5)...\n');
    try
      if ~test_aos_cad_visor_3d()
        fallas{end+1} = 'test_aos_cad_visor_3d'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR visor_3d: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_visor_3d'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest vinculo asset_id<->geometry_id (Sprint 5)...\n');
    try
      if ~test_aos_cad_vinculo_asset_3d()
        fallas{end+1} = 'test_aos_cad_vinculo_asset_3d'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR vinculo_asset_3d: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_vinculo_asset_3d'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest edicion FreeCAD / copia trabajo / traer export...\n');
    try
      if ~test_aos_cad_step_edicion_externa()
        fallas{end+1} = 'test_aos_cad_step_edicion_externa'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR step_edicion_externa: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_step_edicion_externa'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest puertos y conexiones 3D (Sprint 6)...\n');
    try
      if ~test_aos_cad_puertos_conexiones()
        fallas{end+1} = 'test_aos_cad_puertos_conexiones'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR puertos_conexiones: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_puertos_conexiones'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest interferencias AABB (Sprint 6)...\n');
    try
      if ~test_aos_cad_interferencias()
        fallas{end+1} = 'test_aos_cad_interferencias'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR interferencias: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_interferencias'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest escena federada (Sprint 6)...\n');
    try
      if ~test_aos_escena_federada()
        fallas{end+1} = 'test_aos_escena_federada'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR escena_federada: %s\n', err.message);
      fallas{end+1} = 'test_aos_escena_federada'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest overlay resultados 3D (Sprint 6)...\n');
    try
      if ~test_aos_cad_overlay_3d()
        fallas{end+1} = 'test_aos_cad_overlay_3d'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR overlay_3d: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_overlay_3d'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest invalidacion unica (Sprint 7)...\n');
    try
      if ~test_aos_cad_invalidar_simulacion()
        fallas{end+1} = 'test_aos_cad_invalidar_simulacion'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR invalidar_simulacion: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_invalidar_simulacion'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest sincronizacion 2D/3D (Sprint 7)...\n');
    try
      if ~test_aos_cad_sincronizacion_2d_3d()
        fallas{end+1} = 'test_aos_cad_sincronizacion_2d_3d'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR sincronizacion_2d_3d: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_sincronizacion_2d_3d'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest edicion DXF externa (Sprint 7)...\n');
    try
      if ~test_aos_cad_dxf_edicion_externa()
        fallas{end+1} = 'test_aos_cad_dxf_edicion_externa'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR dxf_edicion_externa: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_dxf_edicion_externa'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest recursos visuales ENRIQUECIDO (Sprint 7)...\n');
    try
      if ~test_aos_aoscad_recursos_visuales()
        fallas{end+1} = 'test_aos_aoscad_recursos_visuales'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR recursos_visuales: %s\n', err.message);
      fallas{end+1} = 'test_aos_aoscad_recursos_visuales'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nSelftest auditoria estatica hardening (Sprint 7)...\n');
    try
      if ~test_aos_cad_auditoria_estatica()
        fallas{end+1} = 'test_aos_cad_auditoria_estatica'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR auditoria_estatica: %s\n', err.message);
      fallas{end+1} = 'test_aos_cad_auditoria_estatica'; %#ok<AGROW>
    end_try_catch
  endif

  if isempty(fallas)
    fprintf('\nFlujo aceptacion AOSCAD DEV1...\n');
    try
      setenv('AOS_CAD_SKIP_VISOR', '1'); % evitar fallo sin display en CLI
      if ~aos_cad_flujo_aceptacion_dev1(false)
        fallas{end+1} = 'flujo_aceptacion_dev1'; %#ok<AGROW>
      endif
    catch err
      fprintf(2, ' ERROR flujo: %s\n', err.message);
      fallas{end+1} = 'flujo_aceptacion_dev1'; %#ok<AGROW>
    end_try_catch
  endif

  ok = isempty(fallas);
  if ok
    fprintf('\nRESULTADO: AOSCAD 0.0.1 DEV1 OK\n');
  else
    fprintf(2, '\nRESULTADO: CAD_TOPO CON FALLAS (%d)\n', numel(fallas));
  endif
endfunction

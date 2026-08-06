function AOS_menu_3d_core(origen)
% AOS_MENU_3D_CORE Servicio transversal de geometria y escena 3D.
  if nargin < 1 || isempty(origen), origen = 'GENERAL'; endif
  while true
    fprintf('\n--- AOS 3D CORE [TRANSVERSAL | ORIGEN %s] ---\n', upper(origen));
    fprintf(' 1 - Ver contrato y responsabilidades del nucleo 3D\n');
    fprintf(' 2 - Visualizar trayectoria 3D del pozo [ACTIVO]\n');
    fprintf(' 3 - Importar geometria STEP [ACTIVO]\n');
    fprintf(' 4 - Editar STEP en FreeCAD [ACTIVO]\n');
    fprintf(' 5 - Traer STEP exportado (FreeCAD) [ACTIVO]\n');
    fprintf(' 6 - Ver geometria DXF/STEP activa\n');
    fprintf(' 7 - Vincular componentes y asset_id [ACTIVO]\n');
    fprintf(' 8 - Componentes AOSBCK: STEP, metadatos e instancias [BETA R1]\n');
    fprintf(' 9 - Visualizar componente AOSBCK bajo demanda [BETA R1]\n');
    fprintf('10 - Puertos, conexiones e interferencias [ACTIVO]\n');
    fprintf('11 - Escena federada pozo-red-instalaciones [ACTIVO]\n');
    fprintf('12 - Colorear resultados fisicos sobre 3D [ACTIVO]\n');
    fprintf('13 - Ver contrato para el frame AOS 0.2.0\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, contrato_local();
      case 2, trayectoria_local();
      case 3, aos_cad_importar_step();
      case 4, aos_cad_abrir_externo('STEP');
      case 5, aos_cad_traer_step_exportado();
      case 6, aos_mostrar_seccion_activa({'cad_topologia','cad','step','survey','topologia'}, 'GEOMETRIA ACTIVA');
      case 7, menu_vinculo_escena_local();
      case 8, AOS_menu_aosbck(origen);
      case 9, visualizar_aosbck_local();
      case 10, menu_puertos_interferencias_local();
      case 11, menu_escena_federada_local();
      case 12, menu_overlay_resultados_local();
      case 13, contrato_frame_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function contrato_local()
  fprintf('\nAOS 3D Core no es un solver ni un workbench aislado.\n');
  fprintf('Administra geometria, escenas, asset_id, AOSBCK, seleccion y representacion.\n');
  fprintf('Workbenches consumidores: Wells, CAD, Networks, Electrical, Facilities, Geology y Global.\n');
  fprintf('La fisica permanece en AOS Solvers y los datos en contratos versionados.\n');
  fprintf('AOSCAD R16: sync 2D/3D, recursos visuales e interferencias AABB activos.\n');
endfunction

function trayectoria_local()
  try
    [survey, punzados, info] = aos_obtener_geometria_activa();
    aos_visualizar_geometria_pozo('survey3d', survey, punzados, info);
  catch err
    fprintf(2, 'No se pudo visualizar la trayectoria 3D: %s\n', err.message);
  end_try_catch
endfunction

function visualizar_aosbck_local()
  try
    aosbck_visualizar();
  catch err
    fprintf(2, 'No se pudo visualizar AOSBCK: %s\n', err.message);
    fprintf('Abra o cree primero un componente desde la opcion 8.\n');
  end_try_catch
endfunction

function contrato_frame_local()
  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  fprintf('Contrato de frame y cinta:\n%s\n', fullfile(raiz,'src','roadmap','aos_frame_ribbon_contract_0_2_0.json'));
  fprintf('Contrato de servicios:\n%s\n', fullfile(raiz,'src','roadmap','aos_services_0_2_0_dev1.json'));
endfunction

function menu_vinculo_escena_local()
  while true
    fprintf('\n--- VINCULO asset_id <-> geometry_id / ESCENA 3D ---\n');
    fprintf(' 1 - Ver registro de activos (con geometry_id)\n');
    fprintf(' 2 - Construir / refrescar vinculo 3D\n');
    fprintf(' 3 - Ver escena 3D (dato)\n');
    fprintf(' 4 - Abrir visor 3D (headless PNG o visible)\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, mostrar_registro_activos_local();
      case 2, construir_vinculo_local();
      case 3, ver_escena_local();
      case 4, abrir_visor_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_registro_activos_local()
  global CONFIG_ACTIVA;
  fprintf('\n--- REGISTRO DE ACTIVOS (asset_id / geometry_id) ---\n');
  activos = {};
  fuente = '';

  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) ...
      && isfield(CONFIG_ACTIVA, 'cad_topologia') && isstruct(CONFIG_ACTIVA.cad_topologia)
    cad = CONFIG_ACTIVA.cad_topologia;
    if isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad) ...
        && isfield(cad.modelo_aoscad, 'activos') && ~isempty(cad.modelo_aoscad.activos)
      activos = cad.modelo_aoscad.activos;
      fuente = 'modelo_aoscad.activos';
    elseif isfield(cad, 'id_index_step') && isstruct(cad.id_index_step) ...
        && isfield(cad.id_index_step, 'items') && ~isempty(cad.id_index_step.items)
      items = cad.id_index_step.items;
      if ~iscell(items), items = {items}; endif
      for i = 1:numel(items)
        ent = items{i};
        if isempty(ent) || ~isstruct(ent), continue; endif
        act = struct();
        if isfield(ent, 'asset_id'), act.asset_id = char(ent.asset_id);
        else, act.asset_id = ''; endif
        act.asset_type = 'STEP_PRODUCT';
        act.source = 'STEP';
        act.validation_status = 'OK';
        act.links = struct('id', '', 'tabla', 'equipos', 'producto', '');
        if isfield(ent, 'id'), act.links.id = char(ent.id); endif
        if isfield(ent, 'producto'), act.links.producto = char(ent.producto); endif
        if isfield(ent, 'geometry_id'), act.geometry_id = char(ent.geometry_id); endif
        activos{end+1} = act; %#ok<AGROW>
      endfor
      fuente = 'id_index_step';
    endif
  endif

  if isempty(activos)
    fprintf('No hay registro de activos en la sesion activa.\n');
    fprintf('Importe un DXF (mapear objetos) o un STEP y use "Construir vinculo 3D".\n');
    return;
  endif
  if ~iscell(activos), activos = {activos}; endif

  fprintf('Fuente : %s\n', fuente);
  fprintf('Total  : %d activos\n', numel(activos));
  fprintf('%-24s %-12s %-8s %-10s %-28s\n', ...
    'asset_id', 'tipo', 'source', 'estado', 'geometry_id');
  fprintf('%s\n', repmat('-', 1, 90));
  for i = 1:numel(activos)
    a = activos{i};
    if isempty(a) || ~isstruct(a), continue; endif
    aid = campo_txt_local(a, 'asset_id');
    tip = campo_txt_local(a, 'asset_type');
    src = campo_txt_local(a, 'source');
    est = campo_txt_local(a, 'validation_status');
    gid = campo_txt_local(a, 'geometry_id');
    if isempty(gid) && isfield(a, 'geometry_ids') && iscell(a.geometry_ids) ...
        && ~isempty(a.geometry_ids)
      gid = char(a.geometry_ids{1});
    endif
    fprintf('%-24s %-12s %-8s %-10s %-28s\n', ...
      trunc_local(aid, 24), trunc_local(tip, 12), trunc_local(src, 8), ...
      trunc_local(est, 10), trunc_local(gid, 28));
  endfor
endfunction

function construir_vinculo_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia') ...
      || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    fprintf('No hay cad_topologia activa. Importe DXF o STEP primero.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  modelo = struct();
  if isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad)
    modelo = cad.modelo_aoscad;
  endif
  opts = struct('cad_topologia', cad);
  if isfield(cad, 'step_indice_geometrico')
    opts.indice_geometrico = cad.step_indice_geometrico;
  endif
  if isfield(cad, 'id_index_step')
    opts.id_index_step = cad.id_index_step;
  endif
  try
    [vinculo, modelo, items] = aos_cad_vincular_asset_3d(modelo, opts);
  catch err
    fprintf(2, 'Error al vincular: %s\n', err.message);
    return;
  end_try_catch
  cad.modelo_aoscad = modelo;
  cad.vinculo_3d = vinculo;
  if isfield(modelo, 'step_indice_geometrico')
    cad.step_indice_geometrico = modelo.step_indice_geometrico;
  endif
  CONFIG_ACTIVA.cad_topologia = cad;
  fprintf('Vinculo 3D: %d vinculados, %d asset sin geometria, %d geometria sin asset.\n', ...
    vinculo.n_vinculados, vinculo.n_asset_sin_geometria, vinculo.n_geometria_sin_asset);
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo')
      fprintf('  [%s] %s\n', char(it.codigo), campo_txt_local(it, 'mensaje'));
    endif
  endfor
endfunction

function ver_escena_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    fprintf('No hay cad_topologia activa.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if isfield(cad, 'escena_3d') && isstruct(cad.escena_3d) ...
      && isfield(cad.escena_3d, 'vigente') && ~cad.escena_3d.vigente
    fprintf('Escena 3D no vigente (invalidada por edicion). Se reconstruye.\n');
  endif
  try
    [escena, items] = aos_cad_escena_3d(cad, struct());
  catch err
    fprintf(2, 'Error al construir escena: %s\n', err.message);
    return;
  end_try_catch
  cad.escena_3d = escena;
  CONFIG_ACTIVA.cad_topologia = cad;
  if isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad)
    cad.modelo_aoscad.escena_3d = escena;
    CONFIG_ACTIVA.cad_topologia = cad;
  endif
  fprintf('Escena 3D: %d objetos, vigente=%d, unidades=%s\n', ...
    escena.n_objetos, logical(escena.vigente), char(escena.unidades));
  if isfield(escena, 'n_objetos_por_tipo') && isstruct(escena.n_objetos_por_tipo)
    fn = fieldnames(escena.n_objetos_por_tipo);
    for i = 1:numel(fn)
      fprintf('  %s: %d\n', fn{i}, escena.n_objetos_por_tipo.(fn{i}));
    endfor
  endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo')
      fprintf('  [%s] %s\n', char(it.codigo), campo_txt_local(it, 'mensaje'));
    endif
  endfor
endfunction

function abrir_visor_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    fprintf('No hay cad_topologia activa.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'escena_3d') || ~isstruct(cad.escena_3d) ...
      || (isfield(cad.escena_3d, 'vigente') && ~cad.escena_3d.vigente)
    ver_escena_local();
    cad = CONFIG_ACTIVA.cad_topologia;
  endif
  if ~isfield(cad, 'escena_3d') || ~isstruct(cad.escena_3d)
    fprintf('No se pudo obtener escena 3D.\n');
    return;
  endif
  opts = struct('visible', false);
  raiz = aos_cad_raiz();
  png = fullfile(raiz, 'intercambio', 'cad', 'visor_3d_menu.png');
  recv = fileparts(png);
  if exist(recv, 'dir') ~= 7, mkdir(recv); endif
  opts.png = png;
  try
    [info, ~] = aos_cad_visor_3d(cad.escena_3d, opts);
  catch err
    fprintf(2, 'Error en visor 3D: %s\n', err.message);
    return;
  end_try_catch
  fprintf('Visor 3D: %d objetos dibujados', info.n_objetos_dibujados);
  if isfield(info, 'png') && ~isempty(info.png)
    fprintf(', PNG=%s', char(info.png));
  endif
  fprintf('.\n');
endfunction

function menu_puertos_interferencias_local()
  while true
    fprintf('\n--- PUERTOS / CONEXIONES / INTERFERENCIAS 3D ---\n');
    fprintf(' 1 - Materializar puertos 3D\n');
    fprintf(' 2 - Emparejar conexiones 3D\n');
    fprintf(' 3 - Validar conectividad 3D vs topologia 2D\n');
    fprintf(' 4 - Detectar interferencias AABB\n');
    fprintf(' 5 - Mostrar tabla de interferencias\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, materializar_puertos_3d_local();
      case 2, emparejar_conexiones_3d_local();
      case 3, validar_conectividad_3d_local();
      case 4, detectar_interferencias_local();
      case 5, mostrar_interferencias_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_escena_federada_local()
  while true
    fprintf('\n--- ESCENA FEDERADA POZO-RED-INSTALACIONES ---\n');
    fprintf(' 1 - Construir escena federada\n');
    fprintf(' 2 - Ver resumen escena federada\n');
    fprintf(' 3 - Abrir visor 3D (escena federada)\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, construir_escena_federada_local();
      case 2, ver_escena_federada_local();
      case 3, abrir_visor_federada_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_overlay_resultados_local()
  while true
    fprintf('\n--- OVERLAY RESULTADOS FISICOS SOBRE 3D ---\n');
    fprintf(' 1 - Aplicar overlay (mapear tablas_resultados)\n');
    fprintf(' 2 - Abrir visor 3D con overlay\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, aplicar_overlay_local();
      case 2, abrir_visor_overlay_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function materializar_puertos_3d_local()
  [modelo, ok] = modelo_aoscad_activo_local();
  if ~ok, return; endif
  try
    [puertos_3d, items] = aos_cad_puertos_3d(modelo, struct());
  catch err
    fprintf(2, 'Error al materializar puertos 3D: %s\n', err.message);
    return;
  end_try_catch
  global CONFIG_ACTIVA;
  cad = CONFIG_ACTIVA.cad_topologia;
  cad.puertos_3d = puertos_3d;
  if isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad)
    cad.modelo_aoscad.puertos_3d = puertos_3d;
  endif
  CONFIG_ACTIVA.cad_topologia = cad;
  fprintf('Puertos 3D: n=%d unidades=%s\n', puertos_3d.n, char(puertos_3d.unidades));
  imprimir_items_local(items);
endfunction

function emparejar_conexiones_3d_local()
  global CONFIG_ACTIVA;
  [modelo, ok] = modelo_aoscad_activo_local();
  if ~ok, return; endif
  cad = CONFIG_ACTIVA.cad_topologia;
  puertos_3d = struct();
  if isfield(cad, 'puertos_3d') && isstruct(cad.puertos_3d)
    puertos_3d = cad.puertos_3d;
  else
    try
      [puertos_3d, ~] = aos_cad_puertos_3d(modelo, struct());
    catch err
      fprintf(2, 'Error al materializar puertos 3D: %s\n', err.message);
      return;
    end_try_catch
    cad.puertos_3d = puertos_3d;
  endif
  try
    [tabla_conexiones, items] = aos_cad_conexiones_3d(puertos_3d, struct());
  catch err
    fprintf(2, 'Error al emparejar conexiones 3D: %s\n', err.message);
    return;
  end_try_catch
  cad.conexiones_3d = tabla_conexiones;
  CONFIG_ACTIVA.cad_topologia = cad;
  fprintf('Conexiones 3D: n=%d\n', numel(tabla_conexiones));
  imprimir_items_local(items);
endfunction

function validar_conectividad_3d_local()
  global CONFIG_ACTIVA;
  [modelo, ok] = modelo_aoscad_activo_local();
  if ~ok, return; endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'conexiones_3d') || isempty(cad.conexiones_3d)
    fprintf('No hay conexiones 3D. Use opcion 2 del submenu primero.\n');
    return;
  endif
  try
    [reporte, items] = aos_cad_validar_conectividad_3d(cad.conexiones_3d, modelo, struct());
  catch err
    fprintf(2, 'Error al validar conectividad 3D: %s\n', err.message);
    return;
  end_try_catch
  cad.validacion_conectividad_3d = reporte;
  CONFIG_ACTIVA.cad_topologia = cad;
  if isstruct(reporte)
    fn = fieldnames(reporte);
    for i = 1:numel(fn)
      v = reporte.(fn{i});
      if isnumeric(v) && isscalar(v)
        fprintf('  %s: %g\n', fn{i}, double(v));
      endif
    endfor
  endif
  imprimir_items_local(items);
endfunction

function detectar_interferencias_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    fprintf('No hay cad_topologia activa.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  escena = struct();
  if isfield(cad, 'escena_3d') && isstruct(cad.escena_3d)
    escena = cad.escena_3d;
  else
    try
      [escena, ~] = aos_cad_escena_3d(cad, struct());
    catch err
      fprintf(2, 'Error al construir escena: %s\n', err.message);
      return;
    end_try_catch
    cad.escena_3d = escena;
  endif
  try
    [tabla, items] = aos_cad_interferencias(escena, struct());
  catch err
    fprintf(2, 'Error al detectar interferencias: %s\n', err.message);
    return;
  end_try_catch
  cad.interferencias_3d = tabla;
  cad.interferencias_3d_items = items;
  CONFIG_ACTIVA.cad_topologia = cad;
  fprintf('Interferencias AABB: n_pares=%d (conservador; no es colision BRep)\n', ...
    numel(tabla));
  imprimir_items_local(items);
endfunction

function mostrar_interferencias_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    fprintf('No hay cad_topologia activa.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'interferencias_3d')
    fprintf('No hay tabla de interferencias. Use opcion 4 del submenu primero.\n');
    return;
  endif
  items = {};
  if isfield(cad, 'interferencias_3d_items')
    items = cad.interferencias_3d_items;
  endif
  try
    aos_cad_interferencias_mostrar(cad.interferencias_3d, items);
  catch err
    fprintf(2, 'Error al mostrar interferencias: %s\n', err.message);
  end_try_catch
endfunction

function construir_escena_federada_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('No hay sesion activa.\n');
    return;
  endif
  fuentes = struct();
  if isfield(CONFIG_ACTIVA, 'cad_topologia') && isstruct(CONFIG_ACTIVA.cad_topologia)
    fuentes.red = CONFIG_ACTIVA.cad_topologia;
    cad = CONFIG_ACTIVA.cad_topologia;
    if isfield(cad, 'step_indice_geometrico') && isstruct(cad.step_indice_geometrico)
      fuentes.instalaciones = cad.step_indice_geometrico;
    elseif isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad) ...
        && isfield(cad.modelo_aoscad, 'indice_geometrico')
      fuentes.instalaciones = cad.modelo_aoscad.indice_geometrico;
    endif
  endif
  if isfield(CONFIG_ACTIVA, 'survey') && ~isempty(CONFIG_ACTIVA.survey)
    fuentes.pozo = CONFIG_ACTIVA.survey;
  elseif isfield(CONFIG_ACTIVA, 'geometria') && isstruct(CONFIG_ACTIVA.geometria) ...
      && isfield(CONFIG_ACTIVA.geometria, 'survey')
    fuentes.pozo = CONFIG_ACTIVA.geometria.survey;
  endif
  try
    [escena, items] = aos_escena_federada(fuentes, struct());
  catch err
    fprintf(2, 'Error al construir escena federada: %s\n', err.message);
    return;
  end_try_catch
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif
  CONFIG_ACTIVA.cad_topologia.escena_federada = escena;
  fprintf('Escena federada: n_objetos=%d\n', escena.n_objetos);
  if isfield(escena, 'n_objetos_por_tipo') && isstruct(escena.n_objetos_por_tipo)
    fn = fieldnames(escena.n_objetos_por_tipo);
    for i = 1:numel(fn)
      fprintf('  %s: %d\n', fn{i}, escena.n_objetos_por_tipo.(fn{i}));
    endfor
  endif
  imprimir_items_local(items);
endfunction

function ver_escena_federada_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia') ...
      || ~isfield(CONFIG_ACTIVA.cad_topologia, 'escena_federada')
    fprintf('No hay escena federada. Use opcion 1 del submenu primero.\n');
    return;
  endif
  escena = CONFIG_ACTIVA.cad_topologia.escena_federada;
  fprintf('Escena federada: n_objetos=%d unidades=%s vigente=%d\n', ...
    escena.n_objetos, char(escena.unidades), logical(escena.vigente));
  if isfield(escena, 'fuentes') && isstruct(escena.fuentes)
    fn = fieldnames(escena.fuentes);
    for i = 1:numel(fn)
      fprintf('  fuente %s: %d\n', fn{i}, logical(escena.fuentes.(fn{i})));
    endfor
  endif
  if isfield(escena, 'n_objetos_por_tipo') && isstruct(escena.n_objetos_por_tipo)
    fn = fieldnames(escena.n_objetos_por_tipo);
    for i = 1:numel(fn)
      fprintf('  %s: %d\n', fn{i}, escena.n_objetos_por_tipo.(fn{i}));
    endfor
  endif
endfunction

function abrir_visor_federada_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia') ...
      || ~isfield(CONFIG_ACTIVA.cad_topologia, 'escena_federada')
    fprintf('No hay escena federada. Use opcion 1 del submenu primero.\n');
    return;
  endif
  escena = CONFIG_ACTIVA.cad_topologia.escena_federada;
  opts = struct('visible', false);
  raiz = aos_cad_raiz();
  png = fullfile(raiz, 'intercambio', 'cad', 'visor_3d_federada.png');
  recv = fileparts(png);
  if exist(recv, 'dir') ~= 7, mkdir(recv); endif
  opts.png = png;
  try
    [info, ~] = aos_cad_visor_3d(escena, opts);
  catch err
    fprintf(2, 'Error en visor 3D federado: %s\n', err.message);
    return;
  end_try_catch
  fprintf('Visor federado: %d objetos dibujados', info.n_objetos_dibujados);
  if isfield(info, 'png') && ~isempty(info.png)
    fprintf(', PNG=%s', char(info.png));
  endif
  fprintf('.\n');
endfunction

function aplicar_overlay_local()
  global CONFIG_ACTIVA;
  [modelo, ok] = modelo_aoscad_activo_local();
  if ~ok, return; endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'escena_3d') || ~isstruct(cad.escena_3d)
    try
      [escena, ~] = aos_cad_escena_3d(cad, struct());
    catch err
      fprintf(2, 'Error al construir escena: %s\n', err.message);
      return;
    end_try_catch
    cad.escena_3d = escena;
  else
    escena = cad.escena_3d;
  endif
  tablas = struct();
  if isfield(modelo, 'tablas_resultados')
    tablas = modelo.tablas_resultados;
  endif
  if isempty(fieldnames(tablas))
    fprintf('No hay tablas_resultados en el modelo. Resuelva hidraulica primero.\n');
    fprintf('El overlay solo mapea valores ya calculados (sin fisica).\n');
  endif
  try
    [escena_ov, items] = aos_cad_overlay_resultados(escena, tablas, struct());
  catch err
    fprintf(2, 'Error al aplicar overlay: %s\n', err.message);
    return;
  end_try_catch
  cad.escena_3d_overlay = escena_ov;
  CONFIG_ACTIVA.cad_topologia = cad;
  fprintf('Overlay aplicado sobre %d objetos (SIN_DATO si no hay resultado).\n', ...
    escena_ov.n_objetos);
  imprimir_items_local(items);
endfunction

function abrir_visor_overlay_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    fprintf('No hay cad_topologia activa.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'escena_3d_overlay') || ~isstruct(cad.escena_3d_overlay)
    fprintf('No hay escena con overlay. Use opcion 1 del submenu primero.\n');
    return;
  endif
  opts = struct('visible', false);
  raiz = aos_cad_raiz();
  png = fullfile(raiz, 'intercambio', 'cad', 'visor_3d_overlay.png');
  recv = fileparts(png);
  if exist(recv, 'dir') ~= 7, mkdir(recv); endif
  opts.png = png;
  try
    [info, ~] = aos_cad_visor_3d(cad.escena_3d_overlay, opts);
  catch err
    fprintf(2, 'Error en visor overlay: %s\n', err.message);
    return;
  end_try_catch
  fprintf('Visor overlay: %d objetos dibujados', info.n_objetos_dibujados);
  if isfield(info, 'png') && ~isempty(info.png)
    fprintf(', PNG=%s', char(info.png));
  endif
  fprintf('.\n');
endfunction

function [modelo, ok] = modelo_aoscad_activo_local()
  global CONFIG_ACTIVA;
  modelo = struct();
  ok = false;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia') ...
      || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    fprintf('No hay cad_topologia activa. Importe DXF/STEP primero.\n');
    return;
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad)
    modelo = cad.modelo_aoscad;
    ok = true;
  else
    fprintf('No hay modelo_aoscad en la sesion activa.\n');
  endif
endfunction

function imprimir_items_local(items)
  if isempty(items), return; endif
  if ~iscell(items), items = {items}; endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo')
      fprintf('  [%s] %s\n', char(it.codigo), campo_txt_local(it, 'mensaje'));
    endif
  endfor
endfunction

function s = campo_txt_local(st, nom)
  s = '';
  if isfield(st, nom) && ~isempty(st.(nom))
    s = char(st.(nom));
  endif
endfunction

function s = trunc_local(s, n)
  s = char(s);
  if numel(s) > n, s = [s(1:n-1) '~']; endif
endfunction

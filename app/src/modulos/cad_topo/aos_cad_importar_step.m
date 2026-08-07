function ok = aos_cad_importar_step(archivo, silencioso)
% AOS_CAD_IMPORTAR_STEP Importa inventario STEP a CONFIG_ACTIVA.cad_topologia.
% No modifica el archivo; no escribe .aoscad.
  global CONFIG_ACTIVA;
  ok = false;
  if nargin < 2, silencioso = false; endif
  if nargin < 1 || isempty(archivo)
    archivo = seleccionar_local();
  endif
  if isempty(archivo)
    if ~silencioso, fprintf('Importacion STEP cancelada.\n'); endif
    return;
  endif
  if exist(archivo, 'file') ~= 2
    cand = fullfile(aos_cad_raiz(), archivo);
    if exist(cand, 'file') == 2
      archivo = cand;
    else
      fprintf('No existe el STEP: %s\n', archivo);
      return;
    endif
  endif

  try
    modelo = aos_step_leer(archivo);
  catch err
    fprintf('Error al leer STEP: %s\n', err.message);
    return;
  end_try_catch

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  prev = struct();
  if isfield(CONFIG_ACTIVA, 'cad_topologia') && isstruct(CONFIG_ACTIVA.cad_topologia)
    prev = CONFIG_ACTIVA.cad_topologia;
  endif

  cad = prev;
  cad.step_archivo = char(archivo);
  cad.step_formato = modelo.formato;
  cad.step_schema = modelo.schema;
  cad.step_file_name = modelo.file_name;
  cad.step_productos = modelo.productos;
  cad.step_conteo_tipos = modelo.conteo_tipos;
  cad.step_n_entidades = modelo.n_entidades;
  cad.step_n_productos = modelo.n_productos;
  cad.step_n_solidos = modelo.n_solidos;
  cad.step_importado_en = modelo.importado_en;
  cad.step_mtime = aos_cad_mtime(archivo);
  cad.step_mtime_texto = datestr(cad.step_mtime, 'yyyy-mm-dd HH:MM:SS');
  cad.motor_cad_3d_actual = 'EXTERNO';

  % Indice geometrico aditivo (Sprint 5); no altera inventario ni asset_id.
  if isfield(modelo, 'indice_geometrico')
    cad.step_indice_geometrico = modelo.indice_geometrico;
  endif
  if isfield(modelo, 'items')
    cad.step_items = modelo.items;
  endif
  cad.step_unidades = struct('factor_a_metros', 1, 'origen', '', 'consistente', true);
  if isfield(modelo, 'indice_geometrico') && isstruct(modelo.indice_geometrico) && ...
      isfield(modelo.indice_geometrico, 'unidades')
    cad.step_unidades = modelo.indice_geometrico.unidades;
  endif
  cad.step_geometry_ids = {};
  if isfield(modelo, 'indice_geometrico') && isstruct(modelo.indice_geometrico) && ...
      isfield(modelo.indice_geometrico, 'ocurrencias')
    for gi = 1:numel(modelo.indice_geometrico.ocurrencias)
      oc = modelo.indice_geometrico.ocurrencias{gi};
      if isfield(oc, 'geometry_id')
        cad.step_geometry_ids{end+1} = oc.geometry_id; %#ok<AGROW>
      endif
    endfor
  endif

  % Identidad STEP via servicio asset_id (aos_cad_build_id_index_step).
  % asset_id es determinista por PRODUCT name; no se resuelve inline.
  id_prev = [];
  if isfield(prev, 'id_index_step'), id_prev = prev.id_index_step; endif
  id_new = aos_cad_build_id_index_step(cad);
  % Campo aditivo geometry_id por item (ocurrencia primaria del producto)
  id_new = anexar_geometry_id_step_local(id_new, modelo);
  if ~isempty(id_prev) && isstruct(id_prev) && isfield(id_prev, 'por_handle')
    % Inventario de bajas (productos ausentes); IDs ya vienen del servicio
    pk = fieldnames(id_prev.por_handle);
    bajas = {};
    for i = 1:numel(pk)
      if ~isfield(id_new.por_handle, pk{i})
        bajas{end+1} = id_prev.por_handle.(pk{i}); %#ok<AGROW>
      endif
    endfor
    cad.step_id_bajas = bajas;
  endif
  cad.id_index_step = id_new;

  CONFIG_ACTIVA.cad_topologia = cad;

  % Invalidar simulacion si hay modelo_aoscad (geometria 3D cambio).
  if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad)
    m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    motivo = sprintf('Importacion/reimport STEP: %s', char(archivo));
    opts = struct( ...
      'codigo', 'INVALIDADA_POR_EDICION', ...
      'invalidar_escena', true, ...
      'limpiar_resultados', true, ...
      'invalidar_recursos', true, ...
      'accion', 'IMPORTAR_STEP', ...
      'origen', 'STEP');
    [m, ~] = aos_cad_invalidar_simulacion(m, motivo, opts);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m;
    if isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.escena_3d)
      CONFIG_ACTIVA.cad_topologia.escena_3d.vigente = false;
    endif
    if isfield(CONFIG_ACTIVA.cad_topologia, 'vinculo_3d') ...
        && isstruct(CONFIG_ACTIVA.cad_topologia.vinculo_3d)
      CONFIG_ACTIVA.cad_topologia.vinculo_3d.vigente = false;
    endif
  endif

  ok = true;

  if ~silencioso
    fprintf('\n--- STEP IMPORTADO ---\n');
    fprintf('Archivo     : %s\n', cad.step_archivo);
    fprintf('Schema      : %s\n', cad.step_schema);
    fprintf('Productos   : %d\n', cad.step_n_productos);
    fprintf('Solidos     : %d\n', cad.step_n_solidos);
    fprintf('Entidades   : %d\n', cad.step_n_entidades);
    if isstruct(cad.step_conteo_tipos) && ~isempty(fieldnames(cad.step_conteo_tipos))
      tipos = fieldnames(cad.step_conteo_tipos);
      % Mostrar solo los mas relevantes
      interes = {'PRODUCT','MANIFOLD_SOLID_BREP','CLOSED_SHELL','ADVANCED_FACE','CARTESIAN_POINT'};
      for i = 1:numel(interes)
        if isfield(cad.step_conteo_tipos, interes{i})
          fprintf('  %-22s : %d\n', interes{i}, cad.step_conteo_tipos.(interes{i}));
        endif
      endfor
    endif
    for i = 1:min(5, numel(cad.step_productos))
      p = cad.step_productos{i};
      fprintf('  PRODUCT[%d] : %s | %s\n', i, p.id, p.nombre);
    endfor
    fprintf('mtime       : %s\n', cad.step_mtime_texto);
    fprintf('El STEP original no fue modificado.\n');
    fprintf('.aoscad NO se escribe en import STEP.\n');
  endif
endfunction

function archivo = seleccionar_local()
  archivo = '';
  root = aos_cad_raiz();
  candidatos = {};
  vistos = {};
  ej = fullfile(root, 'datos', 'ejemplos', 'cad');
  bandeja = fullfile(root, 'intercambio', 'cad', 'recibidos');
  for base = {ej, bandeja}
    if exist(base{1}, 'dir') ~= 7, continue; endif
    lista = [dir(fullfile(base{1}, '*.step')); dir(fullfile(base{1}, '*.stp'))];
    for i = 1:numel(lista)
      nom = lista(i).name;
      if es_basura_step_local(nom), continue; endif
      key = lower(nom);
      if any(strcmp(vistos, key)), continue; endif
      vistos{end+1} = key; %#ok<AGROW>
      candidatos{end+1} = fullfile(base{1}, nom); %#ok<AGROW>
    endfor
  endfor

  if ~isempty(candidatos)
    fprintf('STEP disponibles:\n');
    for i = 1:numel(candidatos)
      fprintf('  %d - %s\n', i, candidatos{i});
    endfor
    fprintf('  0 - Elegir otro archivo\n');
    op = aos_leer_opcion(sprintf('Seleccione [0-%d]: ', numel(candidatos)), []);
    if ~isempty(op) && op >= 1 && op <= numel(candidatos)
      archivo = candidatos{op};
      return;
    endif
  endif

  try
    [f, p] = uigetfile({'*.step;*.stp', 'Archivos STEP'}, 'Importar STEP');
    if isnumeric(f) && f == 0, return; endif
    archivo = fullfile(p, f);
  catch
    archivo = strtrim(input('Ruta del archivo STEP: ', 's'));
  end_try_catch
endfunction

function tf = es_basura_step_local(nom)
  nom = char(nom);
  tf = false;
  if isempty(nom), tf = true; return; endif
  if nom(1) == '.', tf = true; return; endif
  if ~isempty(regexp(nom, '~$', 'once')), tf = true; return; endif
  if ~isempty(regexp(upper(nom), '_AOS_REV', 'once')), tf = true; return; endif
endfunction

function id_new = anexar_geometry_id_step_local(id_new, modelo)
  if isempty(id_new) || ~isstruct(id_new) || ~isfield(id_new, 'items')
    return;
  endif
  gmap = struct();
  if isfield(modelo, 'indice_geometrico') && isstruct(modelo.indice_geometrico) && ...
      isfield(modelo.indice_geometrico, 'productos')
    for i = 1:numel(modelo.indice_geometrico.productos)
      p = modelo.indice_geometrico.productos{i};
      nom = '';
      if isfield(p, 'nombre'), nom = char(p.nombre); endif
      gid = '';
      if isfield(p, 'geometry_id'), gid = char(p.geometry_id); endif
      if isempty(nom), continue; endif
      key = upper(nom);
      key = regexprep(key, '[^A-Z0-9_]', '_');
      gmap.(['n_' key]) = gid;
    endfor
  endif
  for i = 1:numel(id_new.items)
    ent = id_new.items{i};
    gid = '';
    nom = '';
    if isfield(ent, 'producto'), nom = char(ent.producto); endif
    if ~isempty(nom)
      key = upper(nom);
      key = regexprep(key, '[^A-Z0-9_]', '_');
      fk = ['n_' key];
      if isfield(gmap, fk), gid = gmap.(fk); endif
    endif
    ent.geometry_id = gid;
    id_new.items{i} = ent;
    if isfield(ent, 'handle')
      raw = char(ent.handle);
      safe = upper(raw);
      safe = regexprep(safe, '[^A-Z0-9_]', '_');
      if ~isempty(safe) && safe(1) >= '0' && safe(1) <= '9', safe = ['H_' safe]; endif
      if isfield(id_new, 'por_handle') && isfield(id_new.por_handle, safe)
        id_new.por_handle.(safe).geometry_id = gid;
      endif
    endif
  endfor
endfunction

function ok = aos_cad_importar_dxf(archivo, silencioso)
% AOS_CAD_IMPORTAR_DXF Importa un DXF al modelo cad_topologia de CONFIG_ACTIVA.
% No modifica el archivo DXF; solo lee e inventaria.
  global CONFIG_ACTIVA;
  ok = false;
  if nargin < 2, silencioso = false; endif
  if nargin < 1 || isempty(archivo)
    archivo = seleccionar_local();
  endif
  if isempty(archivo)
    if ~silencioso, fprintf('Importacion cancelada.\n'); endif
    return;
  endif
  if exist(archivo, 'file') ~= 2
    % Intentar relativo a raiz AOS
    cand = fullfile(aos_cad_raiz(), archivo);
    if exist(cand, 'file') == 2
      archivo = cand;
    else
      fprintf('No existe el DXF: %s\n', archivo);
      return;
    endif
  endif

  try
    modelo = aos_dxf_leer(archivo);
  catch err
    fprintf('Error al leer DXF: %s\n', err.message);
    return;
  end_try_catch

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif

  prev = struct();
  if isfield(CONFIG_ACTIVA, 'cad_topologia') && isstruct(CONFIG_ACTIVA.cad_topologia)
    prev = CONFIG_ACTIVA.cad_topologia;
  endif
  habia_modelo_prev = isfield(prev, 'modelo_aoscad') && isstruct(prev.modelo_aoscad);
  modelo_prev_snap = [];
  if habia_modelo_prev
    modelo_prev_snap = prev.modelo_aoscad;
  endif

  cad = prev;
  campos = fieldnames(modelo);
  for i = 1:numel(campos)
    cad.(campos{i}) = modelo.(campos{i});
  endfor
  cad.dxf_archivo = char(archivo);
  cad.dxf_mtime = aos_cad_mtime(archivo);
  cad.dxf_mtime_texto = datestr(cad.dxf_mtime, 'yyyy-mm-dd HH:MM:SS');
  cad.motor_cad_actual = 'EXTERNO';
  if ~isfield(cad, 'sistema_coordenadas') || isempty(cad.sistema_coordenadas)
    cad.sistema_coordenadas = 'LOCAL_METRICO';
  endif

  CONFIG_ACTIVA.cad_topologia = cad;

  % Conservar id_index si es el mismo DXF (reimport) o una revision *_AOS_REV
  same_dxf = isfield(prev, 'dxf_archivo') && ...
    strcmpi(strrep(char(prev.dxf_archivo), '\', '/'), strrep(char(archivo), '\', '/'));
  is_rev = ~isempty(regexp(upper(char(archivo)), '_AOS_REV', 'once'));
  if (same_dxf || is_rev) && isfield(prev, 'id_index')
    CONFIG_ACTIVA.cad_topologia.id_index = prev.id_index;
  elseif isfield(CONFIG_ACTIVA.cad_topologia, 'id_index')
    CONFIG_ACTIVA.cad_topologia = rmfield(CONFIG_ACTIVA.cad_topologia, 'id_index');
  endif

  % Normalizar a tablas AOSCAD en memoria (NO escribe .aoscad).
  % mapear aplica merge de IDs si hay id_index previo.
  try
    aos_cad_mapear_objetos(CONFIG_ACTIVA.cad_topologia, true);
  catch err
    fprintf(2, 'Aviso: normalizacion tabular fallo: %s\n', err.message);
  end_try_catch

  % Invalidar simulacion/derivados si habia modelo previo con resultados vigentes
  % o siempre tras reimport sobre sesion existente (coherencia geometria vs resultados).
  if habia_modelo_prev ...
      && isfield(CONFIG_ACTIVA, 'cad_topologia') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia) ...
      && isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad)
    m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    % Transferir derivados 3D/recursos previos al modelo nuevo para marcarlos
    m = transferir_derivados_prev_local(m, modelo_prev_snap);
    motivo = sprintf('Importacion/reimport DXF: %s', char(archivo));
    opts = struct( ...
      'codigo', 'INVALIDADA_POR_EDICION', ...
      'invalidar_escena', true, ...
      'limpiar_resultados', true, ...
      'invalidar_recursos', true, ...
      'accion', 'IMPORTAR_DXF', ...
      'origen', 'DXF');
    % Preservar motor/corrida previos del snap en historial via helper
    if isstruct(modelo_prev_snap) && isfield(modelo_prev_snap, 'simulacion')
      if ~isfield(m, 'simulacion') || ~isstruct(m.simulacion)
        m.simulacion = struct();
      endif
      sp = modelo_prev_snap.simulacion;
      if isfield(sp, 'motor'), m.simulacion.motor = sp.motor; endif
      if isfield(sp, 'corrida_id'), m.simulacion.corrida_id = sp.corrida_id; endif
      if isfield(sp, 'fecha'), m.simulacion.fecha = sp.fecha; endif
      if isfield(sp, 'estado'), m.simulacion.estado = sp.estado; endif
      if isfield(modelo_prev_snap, 'tablas_resultados')
        m.tablas_resultados = modelo_prev_snap.tablas_resultados;
      endif
    endif
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
    fprintf('\n--- DXF IMPORTADO ---\n');
    fprintf('Archivo     : %s\n', cad.dxf_archivo);
    fprintf('Unidades    : %s\n', cad.unidades);
    fprintf('Capas       : %d\n', cad.n_capas);
    fprintf('Entidades   : %d\n', cad.n_entidades);
    if isstruct(cad.conteo_tipos) && ~isempty(fieldnames(cad.conteo_tipos))
      tipos = fieldnames(cad.conteo_tipos);
      for i = 1:numel(tipos)
        fprintf('  %-12s : %d\n', tipos{i}, cad.conteo_tipos.(tipos{i}));
      endfor
    endif
    fprintf('mtime       : %s\n', cad.dxf_mtime_texto);
    fprintf('El DXF original no fue modificado.\n');
    fprintf('.aoscad NO se escribe en import (equiv. entrada .aosdat).\n');
    if isfield(CONFIG_ACTIVA.cad_topologia, 'inventario_tabular')
      inv = CONFIG_ACTIVA.cad_topologia.inventario_tabular;
      fprintf('Tablas      : nodos=%d tramos=%d equipos=%d\n', ...
        inv.n_nodos, inv.n_tramos, inv.n_equipos);
    endif
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
    lista = dir(fullfile(base{1}, '*.dxf'));
    for i = 1:numel(lista)
      nom = lista(i).name;
      if es_basura_cad_local(nom), continue; endif
      key = lower(nom);
      if any(strcmp(vistos, key)), continue; endif
      vistos{end+1} = key; %#ok<AGROW>
      candidatos{end+1} = fullfile(base{1}, nom); %#ok<AGROW>
    endfor
  endfor

  if ~isempty(candidatos)
    fprintf('DXF disponibles:\n');
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
    [f, p] = uigetfile({'*.dxf', 'Archivos DXF'}, 'Importar DXF');
    if isnumeric(f) && f == 0, return; endif
    archivo = fullfile(p, f);
  catch
    archivo = strtrim(input('Ruta del archivo DXF: ', 's'));
  end_try_catch
endfunction

function tf = es_basura_cad_local(nom)
  nom = char(nom);
  tf = false;
  if isempty(nom), tf = true; return; endif
  if nom(1) == '.', tf = true; return; endif
  if ~isempty(regexp(nom, '~$', 'once')), tf = true; return; endif
  if ~isempty(regexp(upper(nom), '_AOS_REV', 'once')), tf = true; return; endif
endfunction

function m = transferir_derivados_prev_local(m, prev)
  if nargin < 2 || isempty(prev) || ~isstruct(prev), return; endif
  campos = {'escena_3d', 'vinculo_3d', 'puertos_3d', 'conexiones_3d', ...
            'escena_federada', 'overlay', 'recursos_visuales'};
  for i = 1:numel(campos)
    c = campos{i};
    if (~isfield(m, c) || isempty(m.(c))) && isfield(prev, c) && ~isempty(prev.(c))
      m.(c) = prev.(c);
    endif
  endfor
endfunction
